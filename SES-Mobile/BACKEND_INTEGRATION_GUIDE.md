# Backend Integration Guide - Audio Upload API

## 🎯 Overview

This guide documents the required backend endpoint and integration points for the audio upload feature in the Flutter app.

---

## 🔌 Required Endpoint

### POST /api/emergency/upload-audio

**Purpose**: Accept audio file uploads, analyze for threat detection, and create emergency events

**Requirements**:

- JWT Bearer token authentication required
- Multipart form-data request handling
- Audio file processing and threat detection
- Emergency event creation on threat
- Alert/notification dispatch

---

## 📨 Request Format

### Headers

```http
Authorization: Bearer <JWT_TOKEN>
Content-Type: multipart/form-data; boundary=<BOUNDARY>
```

### Form Fields

| Field     | Type  | Required | Description                   |
| --------- | ----- | -------- | ----------------------------- |
| audio     | File  | Yes      | WAV audio file (16bit, 16kHz) |
| latitude  | Float | No       | GPS latitude (default: 0)     |
| longitude | Float | No       | GPS longitude (default: 0)    |

### Example Request (curl)

```bash
curl -X POST http://localhost:5000/api/emergency/upload-audio \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIs..." \
  -F "audio=@/path/to/emergency_1713261234567.wav" \
  -F "latitude=40.7128" \
  -F "longitude=-74.0060"
```

---

## 📤 Response Format

### Success Response (201 Created)

```json
{
  "success": true,
  "message": "Audio analyzed successfully",
  "isThreat": true,
  "confidence": 0.95,
  "transcription": "help me save me from danger",
  "keywords": ["help", "save me", "danger"],
  "eventId": "507f1f77bcf86cd799439011",
  "event": {
    "_id": "507f1f77bcf86cd799439011",
    "createdBy": "user123",
    "status": "active",
    "urgencyLevel": "critical",
    "location": {
      "latitude": 40.7128,
      "longitude": -74.006,
      "address": "123 Main St, New York, NY"
    },
    "audioFile": "emergency_1713261234567.wav",
    "transcription": "help me save me from danger",
    "alertsSent": 5,
    "contactsNotified": ["contact1@example.com", "contact2@example.com"],
    "createdAt": "2024-04-16T15:20:34.467Z",
    "updatedAt": "2024-04-16T15:20:34.467Z"
  }
}
```

### Threat-Free Response (200 OK)

```json
{
  "success": true,
  "message": "No threat detected",
  "isThreat": false,
  "confidence": 0.05,
  "transcription": "hello how are you",
  "keywords": [],
  "eventId": null,
  "event": null
}
```

### Error Response (4xx/5xx)

```json
{
  "success": false,
  "message": "Error description",
  "code": "ERROR_CODE"
}
```

---

## 🛠️ Express.js Implementation Example

### Setup (assuming middleware already configured)

```javascript
const express = require("express");
const multer = require("multer");
const aiService = require("./services/aiService");
const emergencyService = require("./services/emergencyService");
const authMiddleware = require("./middleware/authMiddleware");

const router = express.Router();

// Configure multer for audio files
const upload = multer({
  dest: "uploads/audio/",
  limits: { fileSize: 50 * 1024 * 1024 }, // 50MB
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith("audio/")) {
      cb(null, true);
    } else {
      cb(new Error("Only audio files allowed"));
    }
  },
});
```

### Handler Implementation

```javascript
router.post(
  "/upload-audio",
  authMiddleware,
  upload.single("audio"),
  async (req, res) => {
    try {
      // 1. Validate request
      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: "No audio file provided",
        });
      }

      const filePath = req.file.path;
      const userId = req.userId;
      const { latitude = 0, longitude = 0 } = req.body;

      // 2. Analyze audio
      const analysis = await aiService.analyzeAudio(filePath);
      const { isThreat, confidence, transcription, keywords } = analysis;

      // 3. Create response
      let response = {
        success: true,
        message: isThreat ? "Threat detected" : "No threat detected",
        isThreat,
        confidence,
        transcription,
        keywords,
        eventId: null,
        event: null,
      };

      // 4. If threat detected, create emergency event
      if (isThreat) {
        const event = await emergencyService.createEmergency({
          createdBy: userId,
          location: { latitude, longitude },
          audioFile: req.file.filename,
          transcription,
          source: "audio_upload",
          urgencyLevel: "critical",
        });

        // Add event to response
        response.eventId = event._id;
        response.event = event;

        // 5. Dispatch alerts to emergency contacts
        await emergencyService.dispatchAlerts(event._id, userId);
      }

      // 6. Cleanup audio file
      cleanupAudioFile(filePath);

      return res.status(isThreat ? 201 : 200).json(response);
    } catch (error) {
      console.error("Audio upload error:", error);

      // Cleanup on error
      if (req.file) {
        cleanupAudioFile(req.file.path);
      }

      return res.status(500).json({
        success: false,
        message: error.message || "Failed to process audio",
      });
    }
  },
);

function cleanupAudioFile(filePath) {
  const fs = require("fs");
  fs.unlink(filePath, (err) => {
    if (err) console.error("Cleanup error:", err);
  });
}

module.exports = router;
```

---

## 🧠 AI Service Requirements

The backend must provide an `aiService.analyzeAudio()` function:

```javascript
// services/aiService.js

class AIService {
  async analyzeAudio(filePath) {
    try {
      // 1. Convert audio to text
      const transcription = await this.convertAudioToText(filePath);

      // 2. Detect threat keywords
      const { hasThreats, keywords, confidence } =
        this.detectThreatKeywords(transcription);

      return {
        isThreat: hasThreats,
        confidence: confidence,
        transcription: transcription,
        keywords: keywords,
      };
    } catch (error) {
      console.error("Audio analysis error:", error);
      throw new Error("Failed to analyze audio");
    }
  }

  async convertAudioToText(filePath) {
    // TODO: Implement actual speech-to-text
    // Options:
    // 1. Google Cloud Speech-to-Text API
    // 2. AWS Transcribe
    // 3. Azure Speech Services
    // 4. IBM Watson Speech to Text
    // 5. OpenAI Whisper API

    // Mock implementation for testing:
    const keywords = ["help", "save me", "danger", "stop", "leave me"];
    const mockPhrases = [
      "help me save me from danger",
      "please stop what you are doing",
      "leave me alone someone help",
      "help please save me now",
    ];

    // Return random phrase
    return mockPhrases[Math.floor(Math.random() * mockPhrases.length)];
  }

  detectThreatKeywords(transcription) {
    const threatKeywords = [
      "help",
      "save me",
      "danger",
      "stop",
      "leave me",
      "emergency",
      "attack",
      "robbery",
      "intruder",
      "rape",
      "gun",
      "knife",
    ];

    const lowerText = transcription.toLowerCase();
    const foundKeywords = [];
    let totalMatches = 0;

    // Check for threat keywords
    for (const keyword of threatKeywords) {
      const pattern = new RegExp(`\\b${keyword}\\b`, "gi");
      const matches = lowerText.match(pattern) || [];
      if (matches.length > 0) {
        foundKeywords.push(keyword);
        totalMatches += matches.length;
      }
    }

    // Calculate confidence score
    const wordCount = lowerText.split(/\s+/).length;
    const confidence = Math.min(
      (totalMatches / (wordCount || 1)) * 2, // Weight keywords higher
      1.0, // Max confidence is 1.0
    );

    const hasThreats = foundKeywords.length > 0 && confidence > 0.3;

    return {
      hasThreats,
      keywords: foundKeywords,
      confidence: hasThreats ? Math.max(confidence, 0.5) : confidence,
    };
  }
}

module.exports = new AIService();
```

---

## 🔧 Integration Checklist

### Phase 1: Endpoint Setup

- [ ] Create POST /api/emergency/upload-audio route
- [ ] Setup Multer for audio file uploads
- [ ] Configure file size limits (50MB recommended)
- [ ] Add auth middleware (JWT Bearer token)
- [ ] Setup upload directory with proper permissions

### Phase 2: Audio Processing

- [ ] Implement aiService.analyzeAudio()
- [ ] Setup speech-to-text service (Google/AWS/Azure/etc)
- [ ] Implement threat keyword detection
- [ ] Calculate confidence scores
- [ ] Handle processing errors

### Phase 3: Emergency Event Creation

- [ ] Create emerg- ency event on threat detection
- [ ] Store audio file reference
- [ ] Store transcription and keywords
- [ ] Set urgency level based on confidence
- [ ] Record GPS location

### Phase 4: Alerts & Notifications

- [ ] Retrieve emergency contacts for user
- [ ] Generate SMS/Email notification content
- [ ] Send alerts via notification service
- [ ] Log alert dispatch status
- [ ] Update event with contact list

### Phase 5: Testing

- [ ] Test with no threat (normal conversation)
- [ ] Test with threat keywords (help, danger, etc)
- [ ] Test with missing audio file
- [ ] Test with invalid token (401)
- [ ] Test with unsupported file format
- [ ] Test large files (>50MB)
- [ ] Test concurrent uploads
- [ ] Load test with multiple simultaneous requests

---

## 🧪 Testing Examples

### Test 1: No Threat Detected

```bash
# Record normal audio: "hello, how are you today?"

curl -X POST http://localhost:5000/api/emergency/upload-audio \
  -H "Authorization: Bearer <TOKEN>" \
  -F "audio=@safe_audio.wav" \
  -F "latitude=40.7128" \
  -F "longitude=-74.0060"

# Expected: isThreat: false, confidence: ~0.1, eventId: null
```

### Test 2: Threat Detected

```bash
# Record threat audio: "help me, save me from danger"

curl -X POST http://localhost:5000/api/emergency/upload-audio \
  -H "Authorization: Bearer <TOKEN>" \
  -F "audio=@threat_audio.wav" \
  -F "latitude=40.7128" \
  -F "longitude=-74.0060"

# Expected: isThreat: true, confidence: ~0.8+, eventId: <ID>, event: {...}
```

### Test 3: Missing File

```bash
curl -X POST http://localhost:5000/api/emergency/upload-audio \
  -H "Authorization: Bearer <TOKEN>" \
  -F "latitude=40.7128"

# Expected: 400 - No audio file provided
```

### Test 4: Invalid Token

```bash
curl -X POST http://localhost:5000/api/emergency/upload-audio \
  -H "Authorization: Bearer invalid_token" \
  -F "audio=@audio.wav"

# Expected: 401 - Unauthorized
```

---

## 📊 Database Schema (MongoDB Example)

### Emergency Event Collection

```javascript
{
  _id: ObjectId,
  createdBy: userId,
  source: 'audio_upload', // or 'manual_trigger', 'panic_button'
  status: 'active', // or 'resolved', 'dismissed'
  urgencyLevel: 'critical', // or 'high', 'medium', 'low'

  // Audio data
  audioFile: 'emergency_1713261234567.wav',
  transcription: 'help me save me from danger',
  keywords: ['help', 'save me', 'danger'],
  confidence: 0.95,

  // Location
  location: {
    latitude: 40.7128,
    longitude: -74.0060,
    address: '123 Main St, New York, NY'
  },

  // Alert tracking
  alertsSent: 5,
  contactsNotified: [
    'contact1@example.com',
    'contact2@example.com'
  ],

  // Timestamps
  createdAt: '2024-04-16T15:20:34.467Z',
  updatedAt: '2024-04-16T15:20:34.467Z',
  resolvedAt: null
}
```

---

## 🔄 State Flow Diagram

```
┌────────────┐
│   Start    │
└─────┬──────┘
      │
      ▼
┌──────────────────┐
│ Receive Request  │ (multipart/form-data)
└─────┬────────────┘
      │
      ▼
┌──────────────────┐
│ Verify Auth      │ (JWT token)
└─────┬────────────┘
      │
      ▼
┌──────────────────┐
│ Validate Audio   │ (file exists, type, size)
└─────┬────────────┘
      │
      ▼
┌──────────────────┐
│ Analyze Audio    │ (STT + keywords)
└─────┬────────────┐
      │            │
   isThreat      Safe ─────────┐
      │                        │
      ▼                        │
┌──────────────────┐           │
│ Create Event     │           │
└─────┬────────────┘           │
      │                        │
      ▼                        │
┌──────────────────┐           │
│ Dispatch Alerts  │           │
└─────┬────────────┘           │
      │                        │
      ▼                        ▼
┌──────────────────────────────────┐
│ Return Response (201 or 200)      │
└─────┬───────────────────────────┐
      │                           │
      ▼                           ▼
   Threat                     No Threat
   Event                      Created
```

---

## 💾 File Storage Recommendations

- **Location**: `/uploads/audio/` with timestamp
- **Naming**: `emergency_<timestamp>_<userId>.wav`
- **Retention**: Keep for 30+ days for legal/audit purposes
- **Backup**: Backup critical emergency recordings
- **Cleanup**: Auto-delete non-threatening recordings after 7 days

---

## 🔐 Security Considerations

1. **Authentication**: Require JWT Bearer token for all requests
2. **Rate Limiting**: Limit uploads per user/IP per minute
3. **File Validation**: Verify file type, size, format
4. **Input Sanitization**: Validate latitude/longitude ranges
5. **Data Encryption**: Encrypt audio files at rest
6. **HTTPS**: Always use HTTPS in production
7. **CORS**: Configure proper CORS headers
8. **Logging**: Log all upload attempts (success/failure)

---

## 📋 Deployment Checklist

- [ ] AI service (speech-to-text) configured and tested
- [ ] Database migrations run
- [ ] Email/SMS service for alerts configured
- [ ] Multer & file upload config tested
- [ ] Error handling and logging implemented
- [ ] Rate limiting enabled
- [ ] Database backups automated
- [ ] File storage quota configured
- [ ] Load testing completed
- [ ] Security audit completed
- [ ] Production environment variables set
- [ ] HTTPS/SSL certificate configured

---

## 🐛 Common Issues & Solutions

### Issue: "Cannot read property 'audio' of undefined"

**Cause**: Multer not receiving file  
**Solution**: Verify field name is exactly 'audio' in multipart form

### Issue: "File too large"

**Cause**: Audio file exceeds Multer size limit  
**Solution**: Increase `fileSize` limit in Multer config

### Issue: 401 Unauthorized repeatedly

**Cause**: JWT token validation failing  
**Solution**: Verify token format is `Bearer <token>` with space

### Issue: "Speech-to-text service timeout"

**Cause**: Large audio file or service unavailable  
**Solution**: Implement timeout handling and fallback transcription

### Issue: Audio file not cleaned up

**Cause**: Cleanup function failing silently  
**Solution**: Add error handling and logging to cleanup function

---

## 📞 Troubleshooting

**Check backend logs**:

```bash
# Find errors
grep -i "error\|fail" logs/app.log | tail -50

# Monitor real-time
tail -f logs/app.log | grep -i "audio\|upload"
```

**Test endpoint directly**:

```bash
# Get valid token first
TOKEN=$(curl -X POST http://localhost:5000/api/auth/login \
  -d "email=user@example.com&password=password" | jq -r '.token')

# Test upload
curl -v -X POST http://localhost:5000/api/emergency/upload-audio \
  -H "Authorization: Bearer $TOKEN" \
  -F "audio=@test.wav" \
  -F "latitude=40.7128" \
  -F "longitude=-74.0060"
```

---

## 📚 Related Documentation

- [Audio Recording Guide](./AUDIO_RECORDING_GUIDE.md)
- [Quick Reference](./QUICK_REFERENCE.md)
- [API Service Guide](./API_SERVICE_GUIDE.md)

---

Last Updated: 2024-04-16 | Backend API v1.0
