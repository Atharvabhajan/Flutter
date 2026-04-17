/**
 * Standardized API response helpers.
 *
 * All responses follow this shape:
 *   { success: boolean, message: string, data?: object }
 *
 * For lists, pass data as { count, items } so callers never have top-level
 * fields mixed with the data payload.
 */

const sendSuccess = (res, statusCode, message, data = null) => {
  const body = { success: true, message };
  if (data !== null) body.data = data;
  return res.status(statusCode).json(body);
};

const sendError = (res, statusCode, message) => {
  return res.status(statusCode).json({ success: false, message });
};

module.exports = { sendSuccess, sendError };
