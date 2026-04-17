/**
 * Lightweight structured logger.
 * No external dependencies — wraps console with consistent formatting.
 *
 * Output format:
 *   [ISO timestamp] [LEVEL    ] message | {"key":"value"}
 *
 * Usage:
 *   logger.info("Server started", { port: 5000 });
 *   logger.emergency("Alert dispatched", { userId, triggerType });
 */

const LEVELS = {
  info:      "INFO     ",
  warn:      "WARN     ",
  error:     "ERROR    ",
  emergency: "EMERGENCY",
};

function format(level, message, meta) {
  const ts   = new Date().toISOString();
  const base = `[${ts}] [${LEVELS[level]}] ${message}`;
  return Object.keys(meta).length
    ? `${base} | ${JSON.stringify(meta)}`
    : base;
}

const logger = {
  info:      (msg, meta = {}) => console.log(format("info",      msg, meta)),
  warn:      (msg, meta = {}) => console.warn(format("warn",      msg, meta)),
  error:     (msg, meta = {}) => console.error(format("error",    msg, meta)),
  emergency: (msg, meta = {}) => console.error(format("emergency", msg, meta)),
};

module.exports = logger;
