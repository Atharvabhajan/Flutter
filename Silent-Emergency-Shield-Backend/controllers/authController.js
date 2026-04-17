const User = require("../models/User");
const { generateToken } = require("../services/authService");
const { sendSuccess, sendError } = require("../utils/response");

// @desc    Register a new user
// @route   POST /api/auth/register
// @access  Public
exports.register = async (req, res) => {
  try {
    const { name, email, password, phone } = req.body;

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return sendError(res, 409, "Email already registered");
    }

    const user = await User.create({ name, email, password, phone });
    const token = generateToken(user._id);

    return sendSuccess(res, 201, "User registered successfully", {
      token,
      userId: user._id,
      name: user.name,
      email: user.email,
      phone: user.phone,
    });
  } catch (error) {
    console.error("Register error:", error);
    return sendError(res, 500, "Error during registration");
  }
};

// @desc    Login user
// @route   POST /api/auth/login
// @access  Public
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email }).select("+password");
    if (!user || !(await user.matchPassword(password))) {
      return sendError(res, 401, "Invalid email or password");
    }

    const token = generateToken(user._id);

    return sendSuccess(res, 200, "Logged in successfully", {
      token,
      userId: user._id,
      name: user.name,
      email: user.email,
      phone: user.phone,
    });
  } catch (error) {
    console.error("Login error:", error);
    return sendError(res, 500, "Error during login");
  }
};
