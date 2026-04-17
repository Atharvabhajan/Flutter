const mongoose = require("mongoose");

const emergencyContactSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    name: {
      type: String,
      required: [true, "Please provide contact name"],
      trim: true,
      maxlength: [50, "Name cannot be more than 50 characters"],
    },
    phone: {
      type: String,
      required: [true, "Please provide phone number"],
      match: [/^[0-9]{10}$/, "Phone number must be 10 digits"],
    },
    relation: {
      type: String,
      required: [true, "Please specify the relation"],
      enum: ["Family", "Friend", "Doctor", "Other"],
    },
    email: {
      type: String,
      match: [
        /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/,
        "Please provide a valid email",
      ],
    },
    telegramChatId: {
      type: String,
      trim: true,
    },
    priority: {
      type: Number,
      default: 1,
      min: 1,
      max: 10,
    },
  },
  { timestamps: true },
);

module.exports = mongoose.model("EmergencyContact", emergencyContactSchema);
