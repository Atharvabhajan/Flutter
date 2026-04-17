import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'audio_service.dart';
import 'emergency_service.dart';

class ProtectModeController with WidgetsBindingObserver {
  static final ProtectModeController _instance = ProtectModeController._internal();
  factory ProtectModeController() => _instance;

  ProtectModeController._internal();

  bool _isProcessing = false;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  final ValueNotifier<bool> isProtectModeActive = ValueNotifier(false);

  void initialize() {
    WidgetsBinding.instance.addObserver(this);
    debugPrint('🛡️ ProtectModeController initialized');
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    debugPrint('App lifecycle state changed to: $_lifecycleState');
  }

  /// Called by the volume listener when the pattern is met.
  Future<void> activateProtectMode() async {
    if (_isProcessing) {
      debugPrint('🛡️ Already processing Protect Mode... ignoring trigger');
      return;
    }
    _isProcessing = true;
    isProtectModeActive.value = true;
    
    debugPrint('🚨 PROTECT MODE ACTIVATED');
    try {
      // Step 1: Start 10 seconds of recording
      final audioService = AudioService();
      final path = await audioService.startRecording();
      
      if (path != null) {
        debugPrint('🎙️ Recording started, waiting 10 seconds...');
        await Future.delayed(const Duration(seconds: 10));
        await audioService.stopRecording();
        debugPrint('🎙️ Recording stopped: $path');

        // Step 2: Grab location safely (non-blocking)
        double lat = 0.0, lng = 0.0;
        try {
          // If in background, only use getLastKnownPosition to prevent crash
          if (_lifecycleState == AppLifecycleState.resumed) {
            final pos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 4),
            );
            lat = pos.latitude;
            lng = pos.longitude;
          } else {
            final pos = await Geolocator.getLastKnownPosition();
            if (pos != null) {
              lat = pos.latitude;
              lng = pos.longitude;
            }
          }
        } catch (e) {
          debugPrint('Location fetch failed, proceeding with 0.0. Error: $e');
        }

        // Step 3: Dispatch to backend
        debugPrint('🚀 Sending audio payload to backend...');
        final result = await EmergencyService.uploadAudioFile(
          filePath: path,
          latitude: lat,
          longitude: lng,
        );

        if (result.success) {
          debugPrint('✅ Protect Mode alert sent successfully!');
        } else {
          debugPrint('❌ Failed to send Protect Mode alert: ${result.message}');
        }
      } else {
        debugPrint('❌ Failed to start recording - missing permissions?');
      }
    } catch (e) {
      debugPrint('❌ Critical error in ProtectMode flow: $e');
    } finally {
      _isProcessing = false;
      isProtectModeActive.value = false;
      debugPrint('🛡️ Protect Mode ready for new triggers');
    }
  }
}
