const mongoose = require("mongoose");

const emergencyEventSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    timestamp: {
      type: Date,
      default: Date.now,
    },
    location: {
      latitude: {
        type: Number,
        required: [true, "Latitude is required"],
        min: -90,
        max: 90,
      },
      longitude: {
        type: Number,
        required: [true, "Longitude is required"],
        min: -180,
        max: 180,
      },
    },
    status: {
      type: String,
      enum: ["active", "resolved", "cancelled"],
      default: "active",
    },
    alertsSent: {
      type: Number,
      default: 0,
    },
    contactsNotified: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "EmergencyContact",
      },
    ],

    // ── Event metadata ──────────────────────────────────────────────────────
    // How the emergency was triggered
    triggerType: {
      type: String,
      enum: ["manual", "audio_ai", "text_ai"],
      default: "manual",
    },
    // Weighted threat score from AI analysis (0 for manual triggers)
    threatScore: {
      type: Number,
      default: 0,
    },
    // Keywords that contributed to the score, e.g. [{keyword:"help", weight:3}]
    detectedKeywords: [
      {
        keyword: { type: String },
        weight:  { type: Number },
      },
    ],
    // SHA-256 hash of the transcribed text — used for duplicate detection
    // null for manual triggers
    textHash: {
      type: String,
      default: null,
    },
  },
  { timestamps: true },
);

module.exports = mongoose.model("EmergencyEvent", emergencyEventSchema);
