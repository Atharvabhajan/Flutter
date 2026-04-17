import 'dart:async';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  late final AudioRecorder _recorder;
  Timer? _recordTimer;
  int _recordDuration = 0;

  factory AudioService() {
    return _instance;
  }

  AudioService._internal() {
    _recorder = AudioRecorder();
  }

  /// Check if recording is currently active
  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  /// Request microphone permission
  static Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Check if microphone permission is granted
  static Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Start recording audio
  /// Returns the file path where audio will be saved
  Future<String?> startRecording() async {
    try {
      // Check permission
      final hasPermission = await hasMicrophonePermission();
      if (!hasPermission) {
        final granted = await requestMicrophonePermission();
        if (!granted) {
          return null;
        }
      }

      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'emergency_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final filePath = '${directory.path}/$fileName';

      // Reset duration
      _recordDuration = 0;

      // Start recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc, // Swapped to AAC for compression and Telegram support
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      // Start tracking duration
      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(milliseconds: 100), (Timer t) {
        _recordDuration += 100;
      });

      return filePath;
    } catch (e) {
      print('Error starting recording: $e');
      return null;
    }
  }

  /// Stop recording and return the file path
  Future<String?> stopRecording() async {
    try {
      _recordTimer?.cancel();
      final path = await _recorder.stop();
      // Allow slight delay for the OS to finalize the file headers before it is uploaded
      await Future.delayed(const Duration(milliseconds: 200));
      return path;
    } catch (e) {
      print('Error stopping recording: $e');
      return null;
    }
  }

  /// Cancel recording and delete the file
  Future<void> cancelRecording() async {
    try {
      _recordTimer?.cancel();
      await _recorder.stop();
    } catch (e) {
      print('Error canceling recording: $e');
    }
  }

  /// Get recording duration in milliseconds
  Future<int> getRecordingDuration() async {
    return _recordDuration;
  }

  /// Dispose recorder resources
  Future<void> dispose() async {
    _recordTimer?.cancel();
    await _recorder.dispose();
  }
}

/// Result class for audio recording operations
class AudioRecordResult {
  final bool success;
  final String message;
  final String? filePath;
  final int? duration; // in milliseconds

  AudioRecordResult({
    required this.success,
    required this.message,
    this.filePath,
    this.duration,
  });
}
