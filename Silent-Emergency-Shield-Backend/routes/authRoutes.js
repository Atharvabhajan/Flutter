const express = require("express");
const { register, login } = require("../controllers/authController");
const {
  handleValidation,
  registerRules,
  loginRules,
} = require("../middlewares/validate");

const router = express.Router();

router.post("/register", registerRules, handleValidation, register);
router.post("/login",    loginRules,    handleValidation, login);

module.exports = router;
