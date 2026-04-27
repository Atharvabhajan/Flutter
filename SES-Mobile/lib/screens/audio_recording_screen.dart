import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/audio_service.dart';
import '../services/emergency_service.dart';
import '../config/app_theme.dart';

class AudioRecordingScreen extends StatefulWidget {
  final VoidCallback onRecordingComplete;

  const AudioRecordingScreen({
    Key? key,
    required this.onRecordingComplete,
  }) : super(key: key);

  @override
  State<AudioRecordingScreen> createState() => _AudioRecordingScreenState();
}

class _AudioRecordingScreenState extends State<AudioRecordingScreen> {
  final AudioService _audioService = AudioService();

  // Recording state
  bool _isRecording = false;
  String? _currentFilePath;
  int _recordingDuration = 0;
  bool _isUploading = false;

  // Timer for updating duration
  late Future<void>? _durationTimer;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  /// Check and request microphone permission
  Future<void> _checkPermissions() async {
    final hasPermission = await AudioService.hasMicrophonePermission();
    if (!hasPermission) {
      final granted = await AudioService.requestMicrophonePermission();
      if (!granted) {
        _showError('Microphone permission is required to record audio');
      }
    }
  }

  /// Start audio recording
  Future<void> _startRecording() async {
    try {
      final filePath = await _audioService.startRecording();

      if (filePath == null) {
        _showError('Failed to start recording. Check permissions.');
        return;
      }

      setState(() {
        _isRecording = true;
        _currentFilePath = filePath;
        _recordingDuration = 0;
      });

      // Start timer to update duration
      _startDurationUpdater();
    } catch (e) {
      _showError('Error starting recording: $e');
    }
  }

  /// Start updating recording duration
  void _startDurationUpdater() {
    Future.doWhile(() async {
      await Future.delayed(Duration(milliseconds: 100));

      if (!mounted || !_isRecording) {
        return false;
      }

      final duration = await _audioService.getRecordingDuration();
      setState(() => _recordingDuration = duration);

      return true;
    });
  }

  /// Stop audio recording
  Future<void> _stopRecording() async {
    try {
      final filePath = await _audioService.stopRecording();

      if (filePath == null) {
        _showError('Failed to stop recording');
        return;
      }

      setState(() {
        _isRecording = false;
        _currentFilePath = filePath;
      });

      _showSuccess(
        'Recording stopped',
        'Duration: ${_formatDuration(_recordingDuration)}',
      );
    } catch (e) {
      _showError('Error stopping recording: $e');
    }
  }

  /// Cancel recording and discard file
  Future<void> _cancelRecording() async {
    try {
      await _audioService.cancelRecording();

      setState(() {
        _isRecording = false;
        _currentFilePath = null;
        _recordingDuration = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recording cancelled')),
      );
    } catch (e) {
      _showError('Error canceling recording: $e');
    }
  }

  /// Upload recording to backend
  Future<void> _uploadRecording() async {
    if (_currentFilePath == null) {
      _showError('No recording to upload');
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Get GPS location
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition();
      } catch (e) {
        print('Warning: Could not get GPS location: $e');
        // Continue without location
        position = Position(
          latitude: 0,
          longitude: 0,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }

      // Upload audio file
      final result = await EmergencyService.uploadAudio(
        filePath: _currentFilePath!,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (mounted) {
        if (result.success) {
          if (result.threatDetected) {
            _showSuccess(
              '🚨 THREAT DETECTED!',
              'Confidence: ${(result.confidenceScore ?? 0).toStringAsFixed(2)}%\n'
                  'Message: ${result.message}',
            );
          } else {
            _showSuccess(
              '✓ Recording Uploaded',
              'No threat detected\n${result.message}',
            );
          }

          // Reset UI after successful upload
          setState(() {
            _currentFilePath = null;
            _recordingDuration = 0;
          });

          // Call callback after short delay
          Future.delayed(Duration(seconds: 1), () {
            widget.onRecordingComplete();
          });
        } else {
          _showError(result.message);
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Upload failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  /// Format duration to mm:ss format
  String _formatDuration(int milliseconds) {
    final seconds = (milliseconds / 1000).floor();
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    // NOTE: Do NOT call _audioService.dispose() here.
    // AudioService is a singleton also used by ProtectModeController.
    // Disposing it here would permanently break the volume-triple-press
    // emergency recording flow for the rest of the session.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Audio Recording'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recording Status Card
              Card(
                elevation: 4,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _isRecording ? Colors.red : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _isRecording ? Icons.mic : Icons.mic_none,
                        size: 48,
                        color: _isRecording ? Colors.white : Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        _isRecording ? 'Recording...' : 'Not Recording',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _isRecording ? Colors.white : Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _formatDuration(_recordingDuration),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _isRecording ? Colors.white : Colors.grey,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32),

              // Recording Controls
              if (!_isRecording && _currentFilePath == null)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _startRecording,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: Icon(Icons.mic, size: 24),
                    label: Text(
                      'Start Recording',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              else if (_isRecording)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _stopRecording,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: Icon(Icons.stop, size: 20),
                        label: Text('Stop'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _cancelRecording,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: Icon(Icons.close, size: 20),
                        label: Text('Cancel'),
                      ),
                    ),
                  ],
                )
              else if (_currentFilePath != null && !_isRecording)
                Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Recording saved',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Duration: ${_formatDuration(_recordingDuration)}',
                            style: TextStyle(color: Colors.green[700]),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isUploading ? null : _uploadRecording,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: _isUploading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Icon(Icons.cloud_upload, size: 20),
                            label: Text(
                              _isUploading
                                  ? 'Uploading...'
                                  : 'Upload & Analyze',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isUploading ? null : _cancelRecording,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: Icon(Icons.delete, size: 20),
                            label: Text(
                              'Discard',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

              SizedBox(height: 32),

              // Info Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How it works',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.blue[900],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Tap "Start Recording" to begin recording audio\n'
                      '2. Speak clearly into the microphone\n'
                      '3. Tap "Stop" when done recording\n'
                      '4. Tap "Upload & Analyze" to send to backend\n'
                      '5. AI will analyze for threat keywords',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
