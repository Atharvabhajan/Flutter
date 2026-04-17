import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PracticeService {
  static final StreamController<String> _practiceEventController = StreamController<String>.broadcast();
  static bool _isRealMode = false;

  /// Stream of practice events triggered
  static Stream<String> get practiceEventStream => _practiceEventController.stream;

  /// Whether the app is in Real Emergency Mode (true) or Practice Mode (false)
  static bool get isRealMode => _isRealMode;

  /// Initialize state from SharedPreferences
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isRealMode = prefs.getBool('isRealEmergencyMode') ?? false; // Default to practice mode
  }

  /// Toggle mode
  static Future<void> setRealMode(bool realMode) async {
    _isRealMode = realMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isRealEmergencyMode', realMode);
  }

  /// Trigger a practice feedback event
  static void triggerPracticeFeedback(String triggerType) {
    if (!_isRealMode) {
      debugPrint('🧪 Practice Mode: Intercepted $triggerType trigger');
      _practiceEventController.add(triggerType);
    }
  }

  static void dispose() {
    _practiceEventController.close();
  }
}
