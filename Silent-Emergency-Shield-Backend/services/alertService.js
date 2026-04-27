const axios      = require("axios");
const { sendSMSToContacts } = require("./smsService");

// ─── Primary Telegram Alert ───────────────────────────────────────────────────

/**
 * Sends a Telegram message + location pin to a single chatId.
 * Throws if TELEGRAM_BOT_TOKEN is missing.
 * Returns { success, reason? } — never crashes the caller.
 */
const sendTelegramAlert = async (chatId, location) => {
  const botToken = process.env.TELEGRAM_BOT_TOKEN;

  if (!botToken) {
    throw new Error("TELEGRAM_BOT_TOKEN is not configured in environment");
  }

  if (!chatId) {
    console.log("⚠️  User has not connected Telegram. Alert not sent.");
    return { success: false, reason: "no_chat_id" };
  }

  const baseUrl = `https://api.telegram.org/bot${botToken}`;
  const mapUrl  = `https://maps.google.com/?q=${location.latitude},${location.longitude}`;
  const time    = new Date().toLocaleString();

  const message =
    `🚨 *EMERGENCY ALERT* 🚨\n\n` +
    `Your contact may be in danger and needs immediate help.\n\n` +
    `📍 *Location:*\n${mapUrl}\n\n` +
    `⏱ *Time:* ${time}\n\n` +
    `Please respond immediately.`;

  console.log("📤 Sending Telegram Alert...");

  try {
    await axios.post(`${baseUrl}/sendMessage`, {
      chat_id:    chatId,
      text:       message,
      parse_mode: "Markdown",
    });

    await axios.post(`${baseUrl}/sendLocation`, {
      chat_id:   chatId,
      latitude:  location.latitude,
      longitude: location.longitude,
    });

    console.log("✅ Telegram Alert Delivered");
    return { success: true };
  } catch (err) {
    console.error(`❌ Telegram Alert Failed: ${err.message}`);
    return { success: false, reason: err.message };
  }
};

// ─── Send Telegram + SMS to all contacts ─────────────────────────────────────

/**
 * Fires a Telegram alert to every contact that has a telegramChatId AND
 * an SMS alert to every contact that has a phone number.
 *
 * Both channels run independently via Promise.allSettled.
 * A failure in one channel never blocks the other.
 *
 * @param {Array}  contacts - Array of EmergencyContact documents
 * @param {Object} location - { latitude, longitude }
 * @param {string} userName - Name of the person in distress (for SMS personalisation)
 */
const sendTelegramToContacts = async (contacts, location, userName = "Your contact") => {
  if (!contacts || contacts.length === 0) return;

  // ── Telegram ─────────────────────────────────────────────────────────────────
  const withTelegram = contacts.filter((c) => c.telegramChatId);
  const telegramJob = withTelegram.length > 0
    ? (async () => {
        console.log(`📤 Sending Telegram alerts to ${withTelegram.length} contact(s)...`);
        await Promise.allSettled(
          withTelegram.map(async (contact) => {
            const result = await sendTelegramAlert(contact.telegramChatId, location);
            console.log(
              result.success
                ? `   ✅ Telegram sent  → ${contact.name}`
                : `   ❌ Telegram failed → ${contact.name}: ${result.reason}`,
            );
          }),
        );
      })()
    : Promise.resolve();

  // ── SMS (Fast2SMS) ───────────────────────────────────────────────────────────
  // Runs completely independently — if SMS fails for any reason the Telegram path
  // is already in-flight and unaffected.
  const smsJob = sendSMSToContacts(contacts, location, userName).catch((err) => {
    // sendSMSToContacts itself never throws, but belt-and-suspenders:
    console.error("[SMS] Unexpected top-level error — ignored:", err.message);
  });

  // ── Wait for both channels ───────────────────────────────────────────────────
  await Promise.allSettled([telegramJob, smsJob]);
};

// ─── Contact Tracker + Telegram + SMS ────────────────────────────────────────

/**
 * Entry point for manual / protect-mode emergencies.
 * Logs contacts, sends Telegram + SMS in parallel, returns a summary.
 *
 * @param {Array}  contacts - EmergencyContact documents
 * @param {Object} location - { latitude, longitude }
 * @param {string} userName - Name of the person in distress
 */
const sendAlert = async (contacts, location, userName = "The user") => {
  if (!contacts || contacts.length === 0) {
    console.log("⚠️  No emergency contacts registered");
    return { success: true, alertsSent: 0, contactsNotified: [] };
  }

  console.log(`📋 ${contacts.length} contact(s) registered for this emergency:`);
  contacts.forEach((c, i) => {
    console.log(`   [${i + 1}] ${c.name} (${c.relation}) — ${c.phone}${c.telegramChatId ? " 📱" : ""}`);
  });

  // Both Telegram and SMS are dispatched here; failures in either are self-contained
  await sendTelegramToContacts(contacts, location, userName);

  return {
    success:          true,
    alertsSent:       contacts.length,
    contactsNotified: contacts.map((c) => c._id),
  };
};

// ─── Email (mock — extend with Nodemailer/SendGrid when needed) ───────────────

const sendEmailAlert = (email, userName, location) => {
  console.log(`📧 Email Alert → ${email}`);
  console.log(`   Subject: EMERGENCY from ${userName}`);
  console.log(`   Location: ${location.latitude}, ${location.longitude}`);
};

module.exports = { sendTelegramAlert, sendTelegramToContacts, sendAlert, sendEmailAlert };
