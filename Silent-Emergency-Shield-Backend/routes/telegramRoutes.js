const express  = require('express');
const router   = express.Router();
const protect  = require('../middlewares/authMiddleware');
const telegramController        = require('../controllers/telegramController');
const telegramWebhookController = require('../controllers/telegramWebhookController');

// ─── Existing (auth-protected) ────────────────────────────────────────────────
router.get('/connect',      protect, telegramController.connectTelegram);
router.post('/save-chat-id', protect, telegramController.saveChatId);

// ─── Webhook (public — Telegram calls these directly) ────────────────────────
router.post('/webhook',    telegramWebhookController.handleWebhook);
router.get('/set-webhook', telegramWebhookController.setWebhook);

module.exports = router;
