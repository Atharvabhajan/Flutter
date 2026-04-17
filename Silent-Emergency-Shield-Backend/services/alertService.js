const axios = require("axios");

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

// ─── Send Telegram alert to all contacts that have a chatId ──────────────────

/**
 * Fires a Telegram alert to every contact that has a telegramChatId.
 * Failures per contact are logged but do not throw — other contacts still get alerted.
 */
const sendTelegramToContacts = async (contacts, location) => {
  if (!contacts || contacts.length === 0) return;

  const withTelegram = contacts.filter((c) => c.telegramChatId);
  if (withTelegram.length === 0) {
    console.log("ℹ️  No contacts have Telegram linked — skipping contact Telegram alerts");
    return;
  }

  console.log(`📤 Sending Telegram alerts to ${withTelegram.length} contact(s)...`);

  await Promise.allSettled(
    withTelegram.map(async (contact) => {
      const result = await sendTelegramAlert(contact.telegramChatId, location);
      if (result.success) {
        console.log(`   ✅ Telegram sent → ${contact.name}`);
      } else {
        console.log(`   ❌ Telegram failed → ${contact.name}: ${result.reason}`);
      }
    }),
  );
};

// ─── Contact Tracker + per-contact Telegram ──────────────────────────────────

const sendAlert = async (contacts, location) => {
  if (!contacts || contacts.length === 0) {
    console.log("⚠️  No emergency contacts registered");
    return { success: true, alertsSent: 0, contactsNotified: [] };
  }

  console.log(`📋 ${contacts.length} contact(s) registered for this emergency:`);
  contacts.forEach((c, i) => {
    console.log(`   [${i + 1}] ${c.name} (${c.relation}) — ${c.phone}${c.telegramChatId ? " 📱" : ""}`);
  });

  await sendTelegramToContacts(contacts, location);

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
