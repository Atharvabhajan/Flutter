import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'protect_mode_controller.dart';

class VolumeListenerService {
  static final VolumeListenerService _instance = VolumeListenerService._internal();
  factory VolumeListenerService() => _instance;

  VolumeListenerService._internal();

  bool _isListening = false;
  int _volumePressCount = 0;
  DateTime? _lastVolumeChangeTime;
  Timer? _debounceTimer;

  static const int VOLUME_TRIGGER_COUNT = 3;
  static const int DEBOUNCE_THRESHOLD_MS = 400; // Ignore rapid events < 400ms
  static const Duration RESET_TIMEOUT = Duration(seconds: 3); // Reset if 3 presses don't occur within 3s

  void initialize() {
    if (!_isListening) {
      _isListening = true;
      const EventChannel('ses.volume_button').receiveBroadcastStream().listen(
        (dynamic event) {
          if (event == 'volume_pressed') {
            _onVolumePressed();
          }
        }, 
        onError: (dynamic error) {
          debugPrint('VolumeListenerService error: $error');
        }
      );
      debugPrint('🔊 VolumeListenerService initialized via EventChannel');
    }
  }

  void _onVolumePressed() {
    final now = DateTime.now();

    // Debounce Check
    if (_lastVolumeChangeTime != null) {
      final timeDiff = now.difference(_lastVolumeChangeTime!).inMilliseconds;
      if (timeDiff < DEBOUNCE_THRESHOLD_MS) {
        return; // Ignore rapid duplicate events sent by OS or hardware bounce
      }
    }

    _lastVolumeChangeTime = now;
    _volumePressCount++;
    debugPrint('📱 Valid Volume Press: $_volumePressCount');

    _debounceTimer?.cancel();

    if (_volumePressCount >= VOLUME_TRIGGER_COUNT) {
      _volumePressCount = 0;
      ProtectModeController().activateProtectMode();
    } else {
      _debounceTimer = Timer(RESET_TIMEOUT, () {
        debugPrint('Volume press counter reset');
        _volumePressCount = 0;
      });
    }
  }

  void dispose() {
    _debounceTimer?.cancel();
    _isListening = false;
  }
}
