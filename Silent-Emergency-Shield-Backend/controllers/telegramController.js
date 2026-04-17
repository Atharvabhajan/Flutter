const axios = require('axios');
const User = require('../models/User');
const { sendSuccess, sendError } = require("../utils/response");

const getBaseUrl = () => {
  const token = process.env.TELEGRAM_BOT_TOKEN;
  if (!token) throw new Error("TELEGRAM_BOT_TOKEN is missing in .env");
  return `https://api.telegram.org/bot${token}`;
};

// @desc    Poll Telegram for the latest chat_id connecting to the bot
// @route   GET /api/telegram/connect
// @access  Private
exports.connectTelegram = async (req, res) => {
  try {
    const response = await axios.get(`${getBaseUrl()}/getUpdates`);
    const results = response.data.result;

    if (!results || results.length === 0) {
      return sendError(res, 404, "No recent messages found in Telegram bot. Ensure you clicked 'Start'.");
    }

    // Filter only private chats and look for /start commands if possible
    // Alternatively, grab the very latest private chat interaction
    const latestUpdate = results
      .slice()
      .reverse()
      .find(update => update.message && update.message.chat && update.message.chat.type === 'private');

    if (!latestUpdate) {
      return sendError(res, 404, "No valid private chat found.");
    }

    const chatId = latestUpdate.message.chat.id.toString();

    return sendSuccess(res, 200, "Telegram Chat ID found!", {
      chatId: chatId,
    });
  } catch (error) {
    console.error("connectTelegram failed:", error.message);
    return sendError(res, 500, "Error connecting to Telegram. Check Bot Token or API.");
  }
};

// @desc    Save the Telegram Chat ID to the current User's profile
// @route   POST /api/telegram/save-chat-id
// @access  Private
exports.saveChatId = async (req, res) => {
  try {
    const { chatId } = req.body;
    if (!chatId) {
      return sendError(res, 400, "chatId is required");
    }

    const user = await User.findById(req.userId);
    if (!user) {
      return sendError(res, 404, "User not found");
    }

    user.telegramChatId = chatId;
    await user.save();

    return sendSuccess(res, 200, "Telegram Chat ID saved successfully", {
      telegramChatId: user.telegramChatId,
    });
  } catch (error) {
    console.error("saveChatId failed:", error.message);
    return sendError(res, 500, "Server error saving chat ID");
  }
};
