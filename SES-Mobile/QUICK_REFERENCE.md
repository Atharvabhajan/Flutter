# Quick Reference Guide

## 🚀 Five-Minute Integration

### Installation

```bash
cd your_project
flutter pub get
```

### Permissions

**Android** (`android/app/src/main/AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

**iOS** (`ios/Runner/Info.plist`):

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Audio recording for emergency alerts</string>
```

---

## 📋 API Quick Reference

### AudioService

```dart
// Singleton instance
final audio = AudioService();

// Permissions
await AudioService.requestMicrophonePermission() → bool
await AudioService.hasMicrophonePermission() → bool

// Recording
await audio.startRecording() → String? (filePath)
await audio.stopRecording() → String? (savedPath)
await audio.cancelRecording() → Future<void>

// Query
await audio.getRecordingDuration() → int (milliseconds)
audio.isRecording → bool

// Cleanup
await audio.dispose() → Future<void>
```

### EmergencyService

```dart
// Upload audio with threat detection
await EmergencyService.uploadAudioFile(
  filePath: String,
  latitude: double,
  longitude: double,
) → EmergencyResult

// Result
result.success → bool
result.isThreat → bool
result.confidence → double (0-1)
result.transcription → String
result.eventId → String?
result.message → String
```

---

## 🎤 Basic Recording Example

```dart
class SimpleAudioRecorder extends StatefulWidget {
  @override
  State<SimpleAudioRecorder> createState() => _SimpleAudioRecorderState();
}

class _SimpleAudioRecorderState extends State<SimpleAudioRecorder> {
  late AudioService _audioService;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _audioService = AudioService();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    await AudioService.requestMicrophonePermission();
  }

  Future<void> _startRecording() async {
    final result = await _audioService.startRecording();
    if (result != null) {
      setState(() => _isRecording = true);
    }
  }

  Future<void> _stopAndUpload() async {
    final filePath = await _audioService.stopRecording();
    setState(() => _isRecording = false);

    if (filePath != null) {
      // Get location
      final position = await Geolocator.getCurrentPosition();

      // Upload
      final result = await EmergencyService.uploadAudioFile(
        filePath: filePath,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          result.isThreat ? '🚨 Threat: ${result.confidence * 100}%' : '✓ Safe'
        )),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _isRecording ? null : _startRecording,
          child: Text('Start'),
        ),
        ElevatedButton(
          onPressed: _isRecording ? _stopAndUpload : null,
          child: Text('Stop & Upload'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}
```

---

## 🔗 Navigate to Audio Recording

```dart
// From home screen
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AudioRecordingScreen()),
    );
  },
  child: Text('Record Audio'),
)
```

---

## 📤 File Upload Request Format

```
POST /api/emergency/upload-audio HTTP/1.1
Host: api.example.com
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary

------WebKitFormBoundary
Content-Disposition: form-data; name="audio"; filename="emergency_1713261234567.wav"
Content-Type: audio/wav

[BINARY WAV DATA]
------WebKitFormBoundary
Content-Disposition: form-data; name="latitude"

40.7128
------WebKitFormBoundary
Content-Disposition: form-data; name="longitude"

-74.0060
------WebKitFormBoundary--
```

---

## 🎯 Common Patterns

### Pattern 1: Simple Recording

```dart
final filePath = await AudioService().startRecording();
await Future.delayed(Duration(seconds: 5));
await AudioService().stopRecording();
```

### Pattern 2: Real-time Duration Display

```dart
Timer.periodic(Duration(milliseconds: 100), (timer) {
  final duration = await AudioService().getRecordingDuration();
  final seconds = duration ~/ 1000;
  print('Recording: ${seconds}s');
});
```

### Pattern 3: Upload with Progress

```dart
final result = await EmergencyService.uploadAudioFile(
  filePath: filePath,
  latitude: lat,
  longitude: lng,
);

if (result.success) {
  // Emergency created
  print('Event ID: ${result.eventId}');
} else {
  print('Error: ${result.message}');
}
```

### Pattern 4: Permission Flow

```dart
final hasPermission = await AudioService.hasMicrophonePermission();
if (!hasPermission) {
  final granted = await AudioService.requestMicrophonePermission();
  if (!granted) {
    showDialog(/* permission denied */);
    return;
  }
}
// Proceed with recording
```

---

## ⚠️ Error Handling

```dart
try {
  final filePath = await AudioService().startRecording();
  if (filePath == null) {
    throw Exception('Failed to initialize recording');
  }

  // Record...

  final result = await EmergencyService.uploadAudioFile(
    filePath: filePath,
    latitude: lat,
    longitude: lng,
  );

  if (!result.success) {
    print('Upload failed: ${result.message}');
  }
} catch (e) {
  print('Error: $e');
  showErrorDialog(context, 'Recording failed: $e');
}
```

---

## 📊 Response Parsing

```dart
final result = await EmergencyService.uploadAudioFile(
  filePath: filePath,
  latitude: lat,
  longitude: lng,
);

// Check if threat detected
if (result.success && result.isThreat) {
  print('🚨 THREAT DETECTED');
  print('Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%');
  print('Text: ${result.transcription}');
  print('Event: ${result.eventId}');
} else if (result.success) {
  print('✓ Safe - No threat detected');
} else {
  print('✗ Error: ${result.message}');
}
```

---

## 🔑 Key Classes

### AudioService

- **Constructor**: `AudioService()` (Singleton)
- **Lifecycle**: `startRecording()` → `stopRecording()` → cleanup
- **File Format**: WAV (16-bit, 16kHz)
- **Storage**: App documents directory

### AudioRecordingScreen

- **Route**: Stateful widget screen
- **Features**: Recording controls, timer, upload feedback
- **Integration**: Automatic GPS, threat detection
- **Response**: Dismiss on success

### EmergencyService

- **Static method**: `uploadAudioFile()`
- **Parameters**: filePath, latitude, longitude
- **Returns**: `EmergencyResult` with threat info
- **Authentication**: Automatic JWT injection

---

## 📱 Screen Layout

```
┌─────────────────────────────┐
│        Audio Alert          │
│  ╭─────────────────────╮    │
│  │      🎤 Recording   │    │ ← Status
│  │      00:15          │    │ ← Duration
│  ╰─────────────────────╯    │
│                             │
│  [ START ]  [ STOP ]        │ ← Controls
│  [   UPLOAD & ANALYZE   ]   │
│                             │
│  📊 Status:                 │
│  ├ Initializing...          │
│  ├ Recording...             │
│  ├ Uploading... 50%         │ ← Feedback
│  └ Analyzing...             │
│                             │
│  Result:                    │
│  🚨 THREAT DETECTED         │ ← Result
│  Confidence: 95%            │
│  Keywords found: 5          │
│                             │
└─────────────────────────────┘
```

---

## 🧪 Test Checklist

- [ ] Microphone permission requested
- [ ] Recording starts without errors
- [ ] Recording duration updates in real-time
- [ ] Recording stops and file is saved
- [ ] File exists at expected path
- [ ] Multipart upload request formatted correctly
- [ ] Bearer token included in headers
- [ ] GPS coordinates sent with request
- [ ] Backend receives file successfully
- [ ] Threat detection works (test with keywords)
- [ ] Emergency event created on threat
- [ ] Response displayed in UI
- [ ] File cleaned up after upload
- [ ] Error messages shown on failure

---

## 📞 Support Resources

- **Audio Recording**: See `lib/services/audio_service.dart`
- **UI Screen**: See `lib/screens/audio_recording_screen.dart`
- **Full Guide**: See `AUDIO_RECORDING_GUIDE.md`
- **Examples**: See `lib/examples/audio_recording_example.dart`
- **API**: See `lib/services/api_service.dart`

---

## 🚀 Deployment Checklist

- ✅ All packages installed (`flutter pub get`)
- ✅ Android permissions added to manifest
- ✅ iOS permissions added to Info.plist
- ✅ Backend `/api/emergency/upload-audio` endpoint working
- ✅ JWT tokens configured and working
- ✅ Geolocator permission setup
- ✅ Error handling implemented
- ✅ UI tested on device
- ✅ Audio file format verified (WAV)
- ✅ Threat detection backend tested

---

## 💡 Tips

1. **Always request permission before recording**
2. **Stop previous recording before starting new one**
3. **Clean up files after successful upload**
4. **Use try-catch for all async operations**
5. **Display real-time duration for user feedback**
6. **Show upload progress to users**
7. **Test with threat keywords: "help", "danger", "save me"**
8. **Verify GPS coordinates are being sent**
9. **Check network connectivity before upload**
10. **Handle 401 errors with automatic re-login**

---

Generated: 2024-01-01 | Audio Recording v1.0
