const axios  = require("axios");
const logger = require("../utils/logger");

const getBaseUrl = () => {
  const token = process.env.TELEGRAM_BOT_TOKEN;
  if (!token) throw new Error("TELEGRAM_BOT_TOKEN is missing in .env");
  return `https://api.telegram.org/bot${token}`;
};

const sendMessage = async (chatId, text) => {
  await axios.post(`${getBaseUrl()}/sendMessage`, {
    chat_id:    chatId,
    text,
    parse_mode: "Markdown",
  });
};

// @desc    Handle incoming Telegram webhook events
// @route   POST /api/telegram/webhook
// @access  Public (called by Telegram servers)
exports.handleWebhook = async (req, res) => {
  // Acknowledge immediately so Telegram doesn't retry
  res.sendStatus(200);

  try {
    const message = req.body?.message;
    if (!message) return;

    const chatId = message.chat?.id?.toString();
    const text   = message.text?.trim();

    if (!chatId) return;

    logger.info("Telegram webhook received", { chatId, text });

    if (text === "/start") {
      await sendMessage(
        chatId,
        `✅ *Connected successfully!*\n\n` +
        `Your Chat ID is: \`${chatId}\`\n\n` +
        `Share this ID with your friend so they can add you as an emergency contact and send you alerts.`,
      );
      logger.info("Sent chat ID reply", { chatId });
    } else {
      await sendMessage(
        chatId,
        `Send /start to connect your Telegram for emergency alerts.`,
      );
    }
  } catch (err) {
    logger.error("Webhook handler error", { error: err.message });
  }
};

// @desc    Register this server's webhook URL with Telegram
// @route   GET /api/telegram/set-webhook
// @access  Public (call once during setup)
exports.setWebhook = async (req, res) => {
  try {
    const backendUrl = process.env.BACKEND_PUBLIC_URL;
    if (!backendUrl) {
      return res.status(500).json({ success: false, message: "BACKEND_PUBLIC_URL not set in .env" });
    }

    const webhookUrl = `${backendUrl}/api/telegram/webhook`;
    const response   = await axios.get(
      `${getBaseUrl()}/setWebhook?url=${encodeURIComponent(webhookUrl)}`,
    );

    logger.info("Webhook registered", { webhookUrl, result: response.data });

    return res.json({
      success: true,
      message: "Webhook registered successfully",
      webhookUrl,
      telegram: response.data,
    });
  } catch (err) {
    logger.error("setWebhook failed", { error: err.message });
    return res.status(500).json({ success: false, message: err.message });
  }
};
