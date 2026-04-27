const axios = require("axios");
const logger = require("../utils/logger");

// ─── Constants ────────────────────────────────────────────────────────────────

const FAST2SMS_URL    = "https://www.fast2sms.com/dev/bulkV2";
const REQUEST_TIMEOUT = 10_000; // 10 s — SMS APIs can be slow; don't stall the caller

// ─── Helpers ──────────────────────────────────────────────────────────────────

/**
 * Strips any country-code prefix and returns a clean 10-digit Indian number.
 * Fast2SMS requires exactly 10 digits — no +91, no spaces.
 * Returns null if the number cannot be normalised.
 */
function normalisePhone(raw) {
  if (!raw) return null;
  const digits = String(raw).replace(/\D/g, ""); // remove everything non-numeric

  if (digits.length === 10)  return digits;        // already clean
  if (digits.length === 12 && digits.startsWith("91")) return digits.slice(2); // +91XXXXXXXXXX
  if (digits.length === 11  && digits.startsWith("0"))  return digits.slice(1); // 0XXXXXXXXXX

  return null; // unknown format — skip rather than send to a wrong number
}

/**
 * Builds a human-readable emergency SMS.
 * The location link is omitted when coordinates are (0, 0) or missing.
 */
function buildMessage(userName, contactName, location) {
  const { latitude = 0, longitude = 0 } = location || {};
  const hasLocation = latitude !== 0 || longitude !== 0;

  const locationLine = hasLocation
    ? `Location: https://maps.google.com/?q=${latitude},${longitude}`
    : "Location: unavailable";

  // Keep under 160 chars per segment to avoid multi-part SMS charges where possible.
  // This message is ~155 chars with a short name — add ellipsis for very long names.
  const name = userName.length > 20 ? userName.slice(0, 17) + "..." : userName;

  return (
    `EMERGENCY ALERT\n` +
    `Hi ${contactName}, ${name} needs urgent help!\n` +
    `${locationLine}\n` +
    `Please call them or emergency services immediately.\n` +
    `-VeilNote Safety App`
  );
}

// ─── Core sender ──────────────────────────────────────────────────────────────

/**
 * Sends an SMS to a single phone number via Fast2SMS.
 *
 * Design principle: NEVER throws.
 * Returns { success: boolean, phone: string, reason?: string }
 * so callers can log failures without crashing the emergency flow.
 */
async function sendSingleSMS(phone, message) {
  const apiKey = process.env.FAST2SMS_API_KEY;

  // ── Config guard ─────────────────────────────────────────────────────────────
  if (!apiKey) {
    logger.warn("[SMS] FAST2SMS_API_KEY not set — SMS skipped", { phone });
    return { success: false, phone, reason: "api_key_not_configured" };
  }

  const normalisedPhone = normalisePhone(phone);
  if (!normalisedPhone) {
    logger.warn("[SMS] Could not normalise phone number — skipped", { phone });
    return { success: false, phone, reason: "invalid_phone_format" };
  }

  try {
    const response = await axios.post(
      FAST2SMS_URL,
      {
        route:   "q",           // Quick SMS — no pre-approved DLT template required
        message,
        numbers: normalisedPhone,
        flash:   0,             // 0 = normal SMS, 1 = flash (appears on screen directly)
      },
      {
        headers:        { authorization: apiKey },
        timeout:        REQUEST_TIMEOUT,
        validateStatus: () => true, // let us handle all HTTP statuses ourselves
      },
    );

    if (response.data?.return === true) {
      logger.info("[SMS] Delivered", { phone: normalisedPhone });
      return { success: true, phone: normalisedPhone };
    }

    // Fast2SMS returns { return: false, message: "..." } on logical failures
    const reason = response.data?.message || `HTTP ${response.status}`;
    logger.warn("[SMS] API rejected request", { phone: normalisedPhone, reason });
    return { success: false, phone: normalisedPhone, reason };

  } catch (err) {
    // Network timeout, DNS failure, etc. — log and move on.
    const reason = err.code === "ECONNABORTED" ? "timeout" : err.message;
    logger.error("[SMS] Request failed", { phone: normalisedPhone, reason });
    return { success: false, phone: normalisedPhone, reason };
  }
}

// ─── Public API ───────────────────────────────────────────────────────────────

/**
 * Sends emergency SMS alerts to every contact in the list.
 *
 * - Runs all sends in parallel (Promise.allSettled — one failure never blocks others).
 * - Returns a summary: { sent, failed, results[] }
 * - NEVER throws — SMS failure must not affect event creation or Telegram delivery.
 *
 * @param {Array}  contacts  - Array of EmergencyContact documents (needs .name, .phone)
 * @param {Object} location  - { latitude, longitude }
 * @param {string} userName  - Full name of the person in distress
 */
async function sendSMSToContacts(contacts, location, userName) {
  // ── Early-exit guards ────────────────────────────────────────────────────────
  if (!contacts || contacts.length === 0) {
    logger.info("[SMS] No contacts to notify");
    return { sent: 0, failed: 0, results: [] };
  }

  if (!process.env.FAST2SMS_API_KEY) {
    logger.warn("[SMS] FAST2SMS_API_KEY not configured — skipping all SMS alerts");
    return { sent: 0, failed: contacts.length, results: [] };
  }

  console.log(`📱 Sending SMS alerts to ${contacts.length} contact(s)...`);

  // ── Build one message per contact (personalised greeting) ───────────────────
  const sendJobs = contacts.map((contact) => {
    const message = buildMessage(userName, contact.name, location);
    return sendSingleSMS(contact.phone, message).then((result) => ({
      contactName: contact.name,
      ...result,
    }));
  });

  // Promise.allSettled: every SMS is attempted even if others fail
  const settled = await Promise.allSettled(sendJobs);

  const results = settled.map((s) =>
    s.status === "fulfilled" ? s.value : { success: false, reason: s.reason?.message || "unknown" },
  );

  const sent   = results.filter((r) => r.success).length;
  const failed = results.filter((r) => !r.success).length;

  // ── Per-contact summary log ──────────────────────────────────────────────────
  results.forEach((r) => {
    if (r.success) {
      console.log(`   ✅ SMS sent    → ${r.contactName} (${r.phone})`);
    } else {
      console.log(`   ❌ SMS failed  → ${r.contactName}: ${r.reason}`);
    }
  });

  console.log(`📱 SMS summary: ${sent} sent, ${failed} failed`);

  return { sent, failed, results };
}

module.exports = { sendSMSToContacts };
