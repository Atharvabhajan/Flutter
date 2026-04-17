const axios = require('axios');

const getBaseUrl = () => {
  const token = process.env.TELEGRAM_BOT_TOKEN;
  if (!token) throw new Error("TELEGRAM_BOT_TOKEN is missing in .env");
  return `https://api.telegram.org/bot${token}`;
};

/**
 * Send a simple text message
 */
exports.sendMessage = async (chatId, text) => {
  try {
    const response = await axios.post(`${getBaseUrl()}/sendMessage`, {
      chat_id: chatId,
      text: text,
      parse_mode: 'Markdown'
    });
    return response.data;
  } catch (error) {
    console.error(`Telegram sendMessage failed: ${error.response?.data?.description || error.message}`);
    throw error;
  }
};

/**
 * Send interactive Map Location natively in Telegram
 */
exports.sendLocation = async (chatId, latitude, longitude) => {
  try {
    const response = await axios.post(`${getBaseUrl()}/sendLocation`, {
      chat_id: chatId,
      latitude: latitude,
      longitude: longitude
    });
    return response.data;
  } catch (error) {
    console.error(`Telegram sendLocation failed: ${error.response?.data?.description || error.message}`);
    throw error;
  }
};

/**
 * Higher level format wrapper explicitly formatted to requirements
 */
exports.sendAlert = async (chatId, userData, location) => {
  if (!chatId) throw new Error("No Telegram Chat ID provided");
  
  const lat = location?.latitude || 0.0;
  const lng = location?.longitude || 0.0;
  const time = new Date().toLocaleString();
  const name = userData?.name || 'Unknown User';

  // 1: Format exact string
  const alertMarkdown = `🚨 *EMERGENCY ALERT* 🚨\n\nUser: ${name}\nTime: ${time}\n\n📍 *Location*:\nhttps://maps.google.com/?q=${lat},${lng}\n\n⚠️ Immediate attention required!`;

  try {
    // 2: Send Message 
    console.log(`Disabling alert text payload to Telegram Chat ID: ${chatId}...`);
    await exports.sendMessage(chatId, alertMarkdown);

    // 3: Send Location Separately
    console.log(`Dispatching native map pin to Telegram...`);
    await exports.sendLocation(chatId, lat, lng);

    console.log("✅ Telegram Alert successfully delivered end-to-end");
    return { success: true };
  } catch (err) {
    console.error("❌ Telegram Alert completely failed", err);
    return { success: false, error: err.message };
  }
};
