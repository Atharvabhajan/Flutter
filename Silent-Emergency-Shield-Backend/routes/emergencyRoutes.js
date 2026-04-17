const express = require("express");
const {
  uploadAndAnalyzeAudio,
  analyzeTextThreat,
  triggerEmergency,
  getEmergencyEvents,
  getEmergencyEvent,
  resolveEmergency,
  cancelEmergency,
} = require("../controllers/emergencyController");
const authMiddleware = require("../middlewares/authMiddleware");
const upload = require("../config/multer");
const {
  handleValidation,
  triggerEmergencyRules,
  analyzeTextRules,
} = require("../middlewares/validate");

const router = express.Router();

router.use(authMiddleware);

// Audio and text analysis
router.post("/upload-audio", upload.single("audio"),                           uploadAndAnalyzeAudio);
router.post("/analyze-text", analyzeTextRules,  handleValidation,              analyzeTextThreat);

// Emergency trigger and event management
router.post("/trigger",           triggerEmergencyRules, handleValidation,     triggerEmergency);
router.get("/events",                                                           getEmergencyEvents);
router.get("/events/:id",                                                       getEmergencyEvent);
router.put("/events/:id/resolve",                                               resolveEmergency);
router.put("/events/:id/cancel",                                                cancelEmergency);

module.exports = router;
