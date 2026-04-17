// ============================================================================
// AUDIO RECORDING IMPLEMENTATION GUIDE
// ============================================================================
// This file shows complete examples of using the AudioService and
// uploading recordings to the backend API

// ============================================================================
// 1. BASIC AUDIO RECORDING SERVICE USAGE
// ============================================================================

import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/emergency_service.dart';

class BasicAudioExample extends StatefulWidget {
  @override
  State<BasicAudioExample> createState() => _BasicAudioExampleState();
}

class _BasicAudioExampleState extends State<BasicAudioExample> {
  final AudioService _audioService = AudioService();

  bool _isRecording = false;
  String? _recordedFilePath;

  Future<void> startRecording() async {
    final filePath = await _audioService.startRecording();
    if (filePath != null) {
      setState(() {
        _isRecording = true;
        _recordedFilePath = filePath;
      });
      print('Recording started: $filePath');
    }
  }

  Future<void> stopRecording() async {
    final filePath = await _audioService.stopRecording();
    setState(() => _isRecording = false);
    print('Recording stopped: $filePath');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _isRecording ? null : startRecording,
          child: Text('Start Recording'),
        ),
        ElevatedButton(
          onPressed: _isRecording ? stopRecording : null,
          child: Text('Stop Recording'),
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

// ============================================================================
// 2. COMPLETE RECORDING WITH UPLOAD
// ============================================================================

class RecordingWithUploadExample extends StatefulWidget {
  @override
  State<RecordingWithUploadExample> createState() =>
      _RecordingWithUploadExampleState();
}

class _RecordingWithUploadExampleState
    extends State<RecordingWithUploadExample> {
  final AudioService _audioService = AudioService();

  bool _isRecording = false;
  String? _recordedFilePath;
  bool _isUploading = false;

  Future<void> _recordAndUpload() async {
    try {
      // Step 1: Check permissions
      final hasPermission = await AudioService.hasMicrophonePermission();
      if (!hasPermission) {
        final granted = await AudioService.requestMicrophonePermission();
        if (!granted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Microphone permission denied')),
          );
          return;
        }
      }

      // Step 2: Start recording
      final filePath = await _audioService.startRecording();
      if (filePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording')),
        );
        return;
      }

      setState(() {
        _isRecording = true;
        _recordedFilePath = filePath;
      });

      // Record for 5 seconds (example)
      await Future.delayed(Duration(seconds: 5));

      // Step 3: Stop recording
      final savedPath = await _audioService.stopRecording();
      setState(() => _isRecording = false);

      if (savedPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to stop recording')),
        );
        return;
      }

      // Step 4: Upload to backend
      setState(() => _isUploading = true);

      final result = await EmergencyService.uploadAudio(
        filePath: savedPath,
        latitude: 0, // Replace with actual GPS
        longitude: 0,
      );

      setState(() => _isUploading = false);

      if (result.success) {
        String message = result.threatDetected
            ? '🚨 THREAT DETECTED! Confidence: ${result.confidenceScore}%'
            : '✓ Safe - No threat detected';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${result.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: _isRecording || _isUploading ? null : _recordAndUpload,
        child: Text(
          _isRecording
              ? 'Recording...'
              : _isUploading
                  ? 'Uploading...'
                  : 'Record & Upload',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}

// ============================================================================
// 3. MULTIPART UPLOAD LOGIC (ALREADY IN ApiService)
// ============================================================================

/*
The multipart upload is already implemented in ApiService.uploadAudio():

static Future<Map<String, dynamic>> uploadAudio({
  required String filePath,
  double latitude = 0,
  double longitude = 0,
}) async {
  try {
    final token = await AuthService.getToken();
    if (token == null) {
      throw ApiException('Authentication token not found');
    }

    final request = http.MultipartRequest('POST', Uri.parse(ApiUrl.uploadAudio))
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['latitude'] = latitude.toString()
      ..fields['longitude'] = longitude.toString()
      ..files.add(await http.MultipartFile.fromPath('audio', filePath));

    final response = await request.send().timeout(_timeout);
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(responseBody);
    } else {
      final error = jsonDecode(responseBody);
      throw ApiException(error['message'] ?? 'Audio upload failed');
    }
  } catch (e) {
    throw ApiException('Audio upload failed: ${e.toString()}');
  }
}

How it works:
1. Get JWT token from SharedPreferences
2. Create multipart request to /api/emergency/upload-audio
3. Add Bearer token to Authorization header
4. Add location fields (latitude, longitude)
5. Add audio file with field name 'audio'
6. Send request and parse JSON response
7. Return result with threat detection status
*/

// ============================================================================
// 4. PERMISSION HANDLING
// ============================================================================

class PermissionHandlingExample extends StatefulWidget {
  @override
  State<PermissionHandlingExample> createState() =>
      _PermissionHandlingExampleState();
}

class _PermissionHandlingExampleState extends State<PermissionHandlingExample> {
  String _permissionStatus = 'Unknown';

  Future<void> _checkPermission() async {
    final hasPermission = await AudioService.hasMicrophonePermission();
    setState(() {
      _permissionStatus = hasPermission ? 'Granted' : 'Denied';
    });
  }

  Future<void> _requestPermission() async {
    final granted = await AudioService.requestMicrophonePermission();
    setState(() {
      _permissionStatus = granted ? 'Granted' : 'Denied';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Permission Status: $_permissionStatus'),
        ElevatedButton(onPressed: _checkPermission, child: Text('Check')),
        ElevatedButton(onPressed: _requestPermission, child: Text('Request')),
      ],
    );
  }
}

// ============================================================================
// 5. RECORDING DURATION TRACKING
// ============================================================================

class DurationTrackingExample extends StatefulWidget {
  @override
  State<DurationTrackingExample> createState() =>
      _DurationTrackingExampleState();
}

class _DurationTrackingExampleState extends State<DurationTrackingExample> {
  final AudioService _audioService = AudioService();

  bool _isRecording = false;
  int _recordingDuration = 0;

  Future<void> _startRecording() async {
    await _audioService.startRecording();
    setState(() => _isRecording = true);

    // Update duration every 100ms
    while (_isRecording) {
      await Future.delayed(Duration(milliseconds: 100));
      final duration = await _audioService.getRecordingDuration();
      setState(() => _recordingDuration = duration);
    }
  }

  Future<void> _stopRecording() async {
    await _audioService.stopRecording();
    setState(() => _isRecording = false);
  }

  String _formatDuration(int milliseconds) {
    final seconds = (milliseconds / 1000).floor();
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _formatDuration(_recordingDuration),
          style: TextStyle(fontSize: 32, fontFamily: 'monospace'),
        ),
        ElevatedButton(
          onPressed: _isRecording ? _stopRecording : _startRecording,
          child: Text(_isRecording ? 'Stop' : 'Start'),
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

// ============================================================================
// 6. ERROR HANDLING PATTERN
// ============================================================================

class ErrorHandlingExample extends StatelessWidget {
  final AudioService _audioService = AudioService();

  Future<void> _recordWithErrorHandling(BuildContext context) async {
    try {
      // Request permission
      final hasPermission = await AudioService.hasMicrophonePermission();
      if (!hasPermission) {
        throw Exception('Microphone permission not granted');
      }

      // Start recording
      final filePath = await _audioService.startRecording();
      if (filePath == null) {
        throw Exception('Failed to initialize recording');
      }

      // Record for 3 seconds
      await Future.delayed(Duration(seconds: 3));

      // Stop recording
      final path = await _audioService.stopRecording();
      if (path == null) {
        throw Exception('Failed to finalize recording');
      }

      // Upload
      final result = await EmergencyService.uploadAudio(filePath: path);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    } on Exception catch (e) {
      // Specific exception handling
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      // Unknown error
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _recordWithErrorHandling(context),
      child: Text('Record with Error Handling'),
    );
  }
}

// ============================================================================
// 7. BACKEND API ENDPOINT REFERENCE
// ============================================================================

/*
Upload Audio Endpoint:
POST /api/emergency/upload-audio

Headers:
- Authorization: Bearer <JWT_TOKEN>
- Content-Type: multipart/form-data

Form Fields:
- audio: <FILE> (the audio file)
- latitude: <FLOAT> (GPS latitude)
- longitude: <FLOAT> (GPS longitude)

Response (200/201):
{
  "success": true,
  "message": "Audio analyzed successfully",
  "isThreat": true,
  "confidence": 0.95,
  "transcription": "help me save me",
  "eventId": "507f1f77bcf86cd799439011"
}

Response (Error):
{
  "success": false,
  "message": "Error message here"
}
*/

// ============================================================================
// 8. COMPLETE AUDIO RECORDING FLOW DIAGRAM
// ============================================================================

/*
┌─────────────────────────────────────────┐
│   AudioRecordingScreen (UI)             │
│  - Start/Stop buttons                   │
│  - Duration display                     │
│  - Upload/Discard options               │
└──────────────┬──────────────────────────┘
               │
        ┌──────▼──────┐
        │ AudioService│
        │ - record    │
        │ - path      │
        │ - duration  │
        └──────┬──────┘
               │
        ┌──────▼─────────────┐
        │ Local File System  │
        │ /docs/emergency_*  │
        └──────┬─────────────┘
               │
        ┌──────▼──────────────────┐
        │ ApiService.uploadAudio()│
        │ - Multipart Request     │
        │ - JWT Auth              │
        │ - Location data         │
        └──────┬──────────────────┘
               │
        ┌──────▼────────────────┐
        │ Express Backend API   │
        │ POST /upload-audio    │
        │ - aiService analysis  │
        │ - Threat detection    │
        └──────┬────────────────┘
               │
        ┌──────▼──────────────┐
        │ Response to App     │
        │ - isThreat: bool    │
        │ - confidence: float │
        │ - message: string   │
        └─────────────────────┘
*/
