const crypto    = require("crypto");
const mongoose  = require("mongoose");
const EmergencyEvent   = require("../models/EmergencyEvent");
const EmergencyContact = require("../models/EmergencyContact");
const User             = require("../models/User");
const { sendTelegramAlert, sendTelegramToContacts, sendAlert, sendEmailAlert } = require("../services/alertService");
const { analyzeAudio, analyzeText } = require("../services/aiService");
const { sendSuccess, sendError }    = require("../utils/response");
const logger = require("../utils/logger");


// ─── Constants ────────────────────────────────────────────────────────────────

const COOLDOWN_SECONDS       = 30;   // min gap between any two triggers
const DUPLICATE_WINDOW_SECS  = 300;  // 5 min window for text-hash dedup

// ─── Guard functions ──────────────────────────────────────────────────────────

/**
 * Throws 429 if the user has triggered an emergency within the cooldown window.
 * Computes remaining seconds so the client can display a countdown.
 */
async function checkCooldown(userId) {
  const cutoff = new Date(Date.now() - COOLDOWN_SECONDS * 1000);
  const recent = await EmergencyEvent
    .findOne({ userId, createdAt: { $gt: cutoff } })
    .sort({ createdAt: -1 });

  if (recent) {
    const elapsed   = Math.floor((Date.now() - new Date(recent.createdAt).getTime()) / 1000);
    const remaining = COOLDOWN_SECONDS - elapsed;
    logger.warn("Cooldown active — trigger rejected", { userId: String(userId), remaining });

    const err    = new Error(`Cooldown active. Please wait ${remaining} second${remaining !== 1 ? "s" : ""} before triggering again.`);
    err.status   = 429;
    err.remaining = remaining;
    throw err;
  }
}

/**
 * Throws 409 if the same text was already used to trigger an emergency recently.
 * Only called for AI-triggered events that have a textHash.
 * Note: with mock STT, every audio call returns random text so hashes will differ
 * in practice — this guard kicks in when real STT is wired up.
 */
async function checkDuplicate(userId, textHash) {
  const cutoff   = new Date(Date.now() - DUPLICATE_WINDOW_SECS * 1000);
  const existing = await EmergencyEvent.findOne({ userId, textHash, createdAt: { $gt: cutoff } });

  if (existing) {
    logger.warn("Duplicate alert blocked", { userId: String(userId), textHash });
    const err  = new Error("Duplicate alert: this content was already processed recently.");
    err.status = 409;
    throw err;
  }
}

// ─── Shared helper ────────────────────────────────────────────────────────────

/**
 * Core dispatch logic used by all three trigger paths.
 * metadata shape: { triggerType, threatScore, detectedKeywords, textHash }
 */
async function createAndDispatchEmergency(userId, latitude, longitude, metadata = {}) {
  const {
    triggerType      = "manual",
    threatScore      = 0,
    detectedKeywords = [],
    textHash         = null,
  } = metadata;

  const location = { latitude, longitude };

  logger.info("Emergency trigger attempt", { userId: String(userId), triggerType, threatScore });

  // ── Guards ──────────────────────────────────────────────────────────────────
  await checkCooldown(userId);
  if (textHash) await checkDuplicate(userId, textHash);

  // ── Fetch user & contacts ───────────────────────────────────────────────────
  const user = await User.findById(userId);
  if (!user) {
    const err = new Error("User not found");
    err.status = 404;
    throw err;
  }

  const contacts = await EmergencyContact.find({ userId }).sort({ priority: 1 });

  // ── Persist event ───────────────────────────────────────────────────────────
  const event = await EmergencyEvent.create({
    userId,
    location,
    status: "active",
    triggerType,
    threatScore,
    detectedKeywords,
    textHash,
  });

  // ── Dispatch alerts ─────────────────────────────────────────────────────────
  console.log("\n🚨 EMERGENCY ALERT TRIGGERED");
  console.log(`📍 Location: ${latitude}, ${longitude}`);
  console.log(`🕐 Time: ${new Date().toISOString()}`);
  console.log(`⚡ Trigger: ${triggerType}\n`);

  if (triggerType === "audio_ai" || triggerType === "text_ai") {
    // AI-triggered: send Telegram + SMS to user + all contacts
    if (user.telegramChatId) {
      try {
        await sendTelegramAlert(user.telegramChatId, location);
      } catch (err) {
        logger.error("Telegram alert failed", { userId: String(userId), error: err.message });
      }
    } else {
      logger.warn("User has not connected Telegram. Alert not sent.", { userId: String(userId) });
    }
    // Pass user.name so SMS messages are personalised per contact
    await sendTelegramToContacts(contacts, location, user.name);
  } else {
    // Manual / protect-mode trigger: track contacts + send email
    const alertResult = await sendAlert(contacts, location, user.name);
    if (alertResult.contactsNotified.length > 0) {
      event.contactsNotified = alertResult.contactsNotified;
      event.alertsSent       = alertResult.alertsSent;
      await event.save();
    }

    if (user.email) {
      sendEmailAlert(user.email, user.name, location);
    }

    // Also send Telegram to user if connected
    if (user.telegramChatId) {
      try {
        await sendTelegramAlert(user.telegramChatId, location);
      } catch (err) {
        logger.error("Telegram alert failed", { userId: String(userId), error: err.message });
      }
    }
  }

  logger.emergency("Emergency dispatched", {
    eventId:    String(event._id),
    triggerType,
    threatScore,
    lat:        latitude,
    lng:        longitude,
  });

  return { event };
}

// ─── Response formatter ───────────────────────────────────────────────────────

function formatEvent(event) {
  return {
    eventId:          event._id,
    eventTimestamp:   event.timestamp,
    location:         event.location,
    triggerType:      event.triggerType,
    threatScore:      event.threatScore,
    detectedKeywords: event.detectedKeywords,
    alertsSent:       event.alertsSent,
    contactsNotified: event.contactsNotified.length,
    status:           event.status,
  };
}

// ─── Controllers ─────────────────────────────────────────────────────────────

// @desc    Upload and analyze audio for threat detection
// @route   POST /api/emergency/upload-audio
// @access  Private
exports.uploadAndAnalyzeAudio = async (req, res) => {
  try {
    if (!req.file) {
      return sendError(res, 400, "No audio file provided");
    }

    logger.info("Audio upload received", { file: req.file.originalname, userId: req.userId });

    const analysisResult = await analyzeAudio(req.file.path);

    if (!analysisResult.threatDetected) {
      logger.info("Audio analyzed — no threat", {
        userId:     req.userId,
        threatScore: analysisResult.threatScore,
      });
      return sendSuccess(res, 200, "Audio analyzed - No threat detected", {
        analysis: {
          transcribedText:  analysisResult.transcribedText,
          threatDetected:   false,
          threatScore:      analysisResult.threatScore,
          detectedKeywords: analysisResult.detectedKeywords,
          confidenceScore:  analysisResult.confidenceScore,
        },
      });
    }

    const latitude  = parseFloat(req.body.latitude)  || 0;
    const longitude = parseFloat(req.body.longitude) || 0;
    const textHash  = crypto
      .createHash("sha256")
      .update(analysisResult.transcribedText.trim().toLowerCase())
      .digest("hex");

    const { event } = await createAndDispatchEmergency(req.userId, latitude, longitude, {
      triggerType: "audio_ai",
      threatScore:      analysisResult.threatScore,
      detectedKeywords: analysisResult.detectedKeywords,
      textHash,
      audioPath:        req.file.path,
    });

    return sendSuccess(res, 201, "Threat detected! Emergency alert triggered", {
      analysis: {
        transcribedText:  analysisResult.transcribedText,
        threatDetected:   true,
        threatScore:      analysisResult.threatScore,
        detectedKeywords: analysisResult.detectedKeywords,
        confidenceScore:  analysisResult.confidenceScore,
      },
      event: formatEvent(event),
    });
  } catch (error) {
    logger.error("Audio analysis failed", { userId: req.userId, error: error.message });
    return sendError(res, error.status || 500, error.status ? error.message : "Error analyzing audio");
  }
};

// @desc    Analyze text for threat keywords
// @route   POST /api/emergency/analyze-text
// @access  Private
exports.analyzeTextThreat = async (req, res) => {
  try {
    const analysisResult = analyzeText(req.body.text);

    if (!analysisResult.threatDetected) {
      logger.info("Text analyzed — no threat", {
        userId:      req.userId,
        threatScore: analysisResult.threatScore,
      });
      return sendSuccess(res, 200, "Text analyzed - No threat detected", {
        analysis: analysisResult,
      });
    }

    const latitude  = parseFloat(req.body.latitude)  || 0;
    const longitude = parseFloat(req.body.longitude) || 0;
    const textHash  = crypto
      .createHash("sha256")
      .update(req.body.text.trim().toLowerCase())
      .digest("hex");

    const { event } = await createAndDispatchEmergency(req.userId, latitude, longitude, {
      triggerType:      "text_ai",
      threatScore:      analysisResult.threatScore,
      detectedKeywords: analysisResult.detectedKeywords,
      textHash,
    });

    return sendSuccess(res, 201, "Threat detected! Emergency alert triggered", {
      analysis: analysisResult,
      event: formatEvent(event),
    });
  } catch (error) {
    logger.error("Text analysis failed", { userId: req.userId, error: error.message });
    return sendError(res, error.status || 500, error.status ? error.message : "Error analyzing text");
  }
};

// @desc    Trigger emergency alert manually
// @route   POST /api/emergency/trigger
// @access  Private
exports.triggerEmergency = async (req, res) => {
  try {
    const { latitude, longitude } = req.body;

    const { event } = await createAndDispatchEmergency(req.userId, latitude, longitude, {
      triggerType: "manual",
    });

    return sendSuccess(res, 201, "Emergency alert triggered successfully", {
      event: formatEvent(event),
    });
  } catch (error) {
    logger.error("Manual trigger failed", { userId: req.userId, error: error.message });
    return sendError(res, error.status || 500, error.status ? error.message : "Error triggering emergency alert");
  }
};


// @desc    Get all emergency events for user
// @route   GET /api/emergency/events
// @access  Private
exports.getEmergencyEvents = async (req, res) => {
  try {
    const events = await EmergencyEvent.find({ userId: req.userId })
      .populate("contactsNotified", "name phone relation")
      .sort({ timestamp: -1 })
      .limit(50);

    return sendSuccess(res, 200, "Emergency events retrieved successfully", {
      count: events.length,
      items: events,
    });
  } catch (error) {
    logger.error("Get events failed", { userId: req.userId, error: error.message });
    return sendError(res, 500, "Error fetching emergency events");
  }
};

// @desc    Get single emergency event
// @route   GET /api/emergency/events/:id
// @access  Private
exports.getEmergencyEvent = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return sendError(res, 400, "Invalid event ID");
    }

    const event = await EmergencyEvent.findById(id).populate(
      "contactsNotified",
      "name phone relation email",
    );

    if (!event) return sendError(res, 404, "Emergency event not found");

    if (event.userId.toString() !== req.userId) {
      return sendError(res, 403, "Not authorized to view this event");
    }

    return sendSuccess(res, 200, "Emergency event retrieved successfully", event);
  } catch (error) {
    logger.error("Get event failed", { id: req.params.id, error: error.message });
    return sendError(res, 500, "Error fetching emergency event");
  }
};

// ─── Shared status-update handler (resolve + cancel) ─────────────────────────

const updateEventStatus = (targetStatus) => async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return sendError(res, 400, "Invalid event ID");
    }

    const event = await EmergencyEvent.findById(id);
    if (!event) return sendError(res, 404, "Emergency event not found");

    if (event.userId.toString() !== req.userId) {
      return sendError(res, 403, "Not authorized to modify this event");
    }

    event.status = targetStatus;
    await event.save();

    logger.info(`Emergency event ${targetStatus}`, { eventId: id, userId: req.userId });

    return sendSuccess(res, 200, `Emergency event ${targetStatus}`, {
      eventId: event._id,
      status:  event.status,
    });
  } catch (error) {
    logger.error("Update event status failed", { id: req.params.id, error: error.message });
    return sendError(res, 500, "Error updating event status");
  }
};

// @desc    Resolve emergency event
// @route   PUT /api/emergency/events/:id/resolve
// @access  Private
exports.resolveEmergency = updateEventStatus("resolved");

// @desc    Cancel emergency event
// @route   PUT /api/emergency/events/:id/cancel
// @access  Private
exports.cancelEmergency = updateEventStatus("cancelled");
