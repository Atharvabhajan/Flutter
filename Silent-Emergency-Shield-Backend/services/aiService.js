const fs = require("fs");
/**
 * AI Service — weighted threat scoring
 *
 * How it works:
 *  1. Scan lowercased text for each keyword phrase
 *  2. Sum the weights of every match → threatScore
 *  3. If threatScore >= THREAT_THRESHOLD → emergency
 *
 * Weights reflect severity / urgency:
 *   3 = direct distress call  ("help", "save me", "leave me")
 *   2 = contextual threat cue ("danger", "stop")
 */

const THREAT_KEYWORDS = {
  "help": 3,
  "save me": 3,
  "leave me": 3,
  "danger": 2,
  "stop": 2,
  "emergency": 3,
  "police": 3,
  "killing": 3,
  "killed": 3,
  "please not": 2,
  "please don't": 3,
  "no no no": 3,
  "stop it": 2,
  "murder": 3,
};

// Minimum score required to trigger an emergency
const THREAT_THRESHOLD = 3;

// ─── Core scoring logic ───────────────────────────────────────────────────────

/**
 * Scans text for threat keywords and returns a weighted score.
 *
 * @param {string} text
 * @returns {{
 *   threatDetected: boolean,
 *   threatScore: number,
 *   detectedKeywords: Array<{keyword: string, weight: number}>,
 *   confidenceScore: number   // 0–100, percentage
 * }}
 */
const scoreThreat = (text) => {
  if (!text || typeof text !== "string") {
    return { threatDetected: false, threatScore: 0, detectedKeywords: [], confidenceScore: 0 };
  }

  const lowerText = text.toLowerCase();
  const detectedKeywords = [];
  let threatScore = 0;

  for (const [keyword, weight] of Object.entries(THREAT_KEYWORDS)) {
    if (lowerText.includes(keyword)) {
      detectedKeywords.push({ keyword, weight });
      threatScore += weight;
    }
  }

  // Confidence: 50% at threshold, 100% at 2× threshold — capped there
  const confidenceScore =
    threatScore === 0
      ? 0
      : Math.min(100, Math.round((threatScore / THREAT_THRESHOLD) * 50));

  return {
    threatDetected: threatScore >= THREAT_THRESHOLD,
    threatScore,
    detectedKeywords,
    confidenceScore,
  };
};

// ─── Speech-to-text (mock) ────────────────────────────────────────────────────

/**
 * Convert M4A/AAC to 16kHz WAV format required by Whisper
 */
const convertAudioToWav = (inputPath, outputPath) => {
  return new Promise((resolve, reject) => {
    ffmpeg(inputPath)
      .toFormat('wav')
      .audioChannels(1)
      .audioFrequency(16000)
      .on('error', (err) => {
        console.error('FFMPEG Error:', err);
        reject(err);
      })
      .on('end', () => {
        resolve(outputPath);
      })
      .save(outputPath);
  });
};

/**
 * Mock STT conversion.
 * Replace the body with a real API call (Whisper, Google STT, etc.)
 * when ready — the callers don't change.
 */
const convertAudioToText = async (filePath) => {
  if (!fs.existsSync(filePath)) {
    throw new Error("Audio file not found");
  }

  // Simulate API latency
  await new Promise((resolve) => setTimeout(resolve, 500));

  const mockTranscripts = [
    "Help me I am in danger",
    "Please save me from this situation",
    "Someone stop this person immediately",
    "I need help this is a dangerous situation",
    "Leave me alone this is dangerous",
    "Stop it please not today no no no",
    "They are killing someone help me",
    "I need the police there is a murder happening",
    "Emergency help me please don't do this",
  ];

  const transcript = mockTranscripts[Math.floor(Math.random() * mockTranscripts.length)];
  console.log(`📝 Transcribed: "${transcript}"`);
  return transcript;
};

// ─── Public API ───────────────────────────────────────────────────────────────

/**
 * Analyze an uploaded audio file.
 * Cleans up the file from disk before returning (success or failure).
 */
const analyzeAudio = async (filePath) => {
  try {
    console.log("\n🎙️  ========== AUDIO ANALYSIS STARTED ==========\n");

    const transcribedText = await convertAudioToText(filePath);
    const result = scoreThreat(transcribedText);

    console.log(`🔍 Threat Score : ${result.threatScore} (threshold: ${THREAT_THRESHOLD})`);
    console.log(`   Detected     : ${result.detectedKeywords.map((k) => `${k.keyword}(${k.weight})`).join(", ") || "none"}`);
    console.log(`   Threat       : ${result.threatDetected ? "✅ YES" : "❌ NO"}`);
    console.log(`   Confidence   : ${result.confidenceScore}%\n`);

    _deleteFile(filePath);

    return { success: true, transcribedText, ...result };
  } catch (error) {
    console.error("❌ Audio analysis failed:", error.message);
    _deleteFile(filePath);
    throw error;
  }
};

/**
 * Analyze a plain-text string directly (used for manual testing via API).
 */
const analyzeText = (text) => {
  const result = scoreThreat(text);
  return { success: true, transcribedText: text, ...result };
};

/**
 * Returns a random mock transcription — useful for development/testing.
 */
const getMockTranscription = () => {
  const samples = [
    { text: "help me please i am in danger", threat: true },
    { text: "this is a normal conversation", threat: false },
    { text: "save me someone help", threat: true },
    { text: "please stop this person is dangerous", threat: true },
    { text: "leave me alone i need help", threat: true },
    { text: "just a regular recording", threat: false },
  ];
  return samples[Math.floor(Math.random() * samples.length)];
};

// ─── Internal helpers ─────────────────────────────────────────────────────────

function _deleteFile(filePath) {
  try {
    if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
  } catch (_) {
    console.warn("⚠️  Could not delete audio file:", filePath);
  }
}

// ─── Exports ──────────────────────────────────────────────────────────────────

module.exports = {
  analyzeAudio,
  analyzeText,
  scoreThreat,           // exported for unit testing
  getMockTranscription,
  convertAudioToText,
  THREAT_KEYWORDS,
  THREAT_THRESHOLD,
};
