const { body, validationResult } = require("express-validator");

/**
 * Run after a rule array — sends the first validation error as a 400.
 * Keeps error messages short and human-readable (no internal details).
 */
const handleValidation = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: errors.array()[0].msg,
    });
  }
  next();
};

// ── Auth ──────────────────────────────────────────────────────────────────────

const registerRules = [
  body("name")
    .trim()
    .notEmpty()
    .withMessage("Name is required"),
  body("email")
    .isEmail()
    .withMessage("Valid email is required")
    .normalizeEmail(),
  body("password")
    .isLength({ min: 6 })
    .withMessage("Password must be at least 6 characters"),
  body("phone")
    .matches(/^[0-9]{10}$/)
    .withMessage("Phone number must be 10 digits"),
];

const loginRules = [
  body("email")
    .isEmail()
    .withMessage("Valid email is required")
    .normalizeEmail(),
  body("password")
    .notEmpty()
    .withMessage("Password is required"),
];

// ── Contacts ──────────────────────────────────────────────────────────────────

const addContactRules = [
  body("name")
    .trim()
    .notEmpty()
    .withMessage("Contact name is required"),
  body("phone")
    .matches(/^[0-9]{10}$/)
    .withMessage("Phone number must be 10 digits"),
  body("relation")
    .isIn(["Family", "Friend", "Doctor", "Other"])
    .withMessage("Relation must be one of: Family, Friend, Doctor, Other"),
  body("email")
    .optional({ nullable: true })
    .isEmail()
    .withMessage("Valid email is required"),
  body("priority")
    .optional()
    .isInt({ min: 1, max: 10 })
    .withMessage("Priority must be a whole number between 1 and 10")
    .toInt(),
];

const updateContactRules = [
  body("name")
    .optional()
    .trim()
    .notEmpty()
    .withMessage("Name cannot be empty"),
  body("phone")
    .optional()
    .matches(/^[0-9]{10}$/)
    .withMessage("Phone number must be 10 digits"),
  body("relation")
    .optional()
    .isIn(["Family", "Friend", "Doctor", "Other"])
    .withMessage("Relation must be one of: Family, Friend, Doctor, Other"),
  body("email")
    .optional({ nullable: true })
    .isEmail()
    .withMessage("Valid email is required"),
  body("priority")
    .optional()
    .isInt({ min: 1, max: 10 })
    .withMessage("Priority must be a whole number between 1 and 10")
    .toInt(),
];

// ── Emergency ─────────────────────────────────────────────────────────────────

const triggerEmergencyRules = [
  body("latitude")
    .exists({ checkNull: true })
    .withMessage("Latitude is required")
    .isFloat({ min: -90, max: 90 })
    .withMessage("Latitude must be between -90 and 90")
    .toFloat(),
  body("longitude")
    .exists({ checkNull: true })
    .withMessage("Longitude is required")
    .isFloat({ min: -180, max: 180 })
    .withMessage("Longitude must be between -180 and 180")
    .toFloat(),
];

const analyzeTextRules = [
  body("text")
    .trim()
    .notEmpty()
    .withMessage("Text is required"),
];

// ── Exports ───────────────────────────────────────────────────────────────────

module.exports = {
  handleValidation,
  registerRules,
  loginRules,
  addContactRules,
  updateContactRules,
  triggerEmergencyRules,
  analyzeTextRules,
};
