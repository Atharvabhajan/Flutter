import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StealthModeService {
  static const _storage = FlutterSecureStorage();
  
  // ── Runtime state ────────────────────────────────────────────────────────
  static final ValueNotifier<bool> isStealthNotifier = ValueNotifier(false);

  // ── Persistent Config ───────────────────────────────────────────────────
  static String? _secretPhrase;
  static String? _alertKeyword;
  static String? _recordStartKeyword;
  static String? _recordStopKeyword;
  static bool    _isProtectionEnabled = false;

  static bool   get isStealthMode           => isStealthNotifier.value;
  static bool   get isProtectionEnabled     => _isProtectionEnabled;
  static String get secretPhrase            => _secretPhrase      ?? '';
  static String get alertKeyword            => _alertKeyword      ?? '';
  static String get recordStartKeyword      => _recordStartKeyword ?? '';
  static String get recordStopKeyword       => _recordStopKeyword  ?? '';

  static Future<void> initialize() async {
    _secretPhrase       = await _storage.read(key: 'stealth_secret_phrase');
    _alertKeyword       = await _storage.read(key: 'stealth_alert_keyword');
    _recordStartKeyword = await _storage.read(key: 'stealth_record_start');
    _recordStopKeyword  = await _storage.read(key: 'stealth_record_stop');
    
    final protection = await _storage.read(key: 'is_stealth_protection_enabled');
    _isProtectionEnabled = (protection == 'true');
    
    // On app launch, the disguise state matches the persistent protection state
    isStealthNotifier.value = _isProtectionEnabled;
  }

  /// Master switch for the Stealth Protection feature.
  /// This only updates the persistent preference, not the current runtime state.
  static Future<void> setStealthProtection(bool enabled) async {
    _isProtectionEnabled = enabled;
    await _storage.write(key: 'is_stealth_protection_enabled', value: enabled.toString());
  }

  /// Session-based unlock: Exits the disguise but keeps the feature enabled for next launch.
  static void exitDisguise() {
    isStealthNotifier.value = false;
  }

  /// Re-enters the disguise manually (requires feature to be enabled).
  static void enterDisguise() {
    if (_isProtectionEnabled) {
      isStealthNotifier.value = true;
    }
  }

  static Future<void> enableStealthMode(
    String phrase, {
    String alertKeyword       = '',
    String recordStartKeyword = '',
    String recordStopKeyword  = '',
  }) async {
    _secretPhrase       = phrase.trim();
    _alertKeyword       = alertKeyword.trim().toLowerCase();
    _recordStartKeyword = recordStartKeyword.trim().toLowerCase();
    _recordStopKeyword  = recordStopKeyword.trim().toLowerCase();

    await _storage.write(key: 'stealth_secret_phrase',  value: _secretPhrase);
    await _storage.write(key: 'stealth_alert_keyword',  value: _alertKeyword);
    await _storage.write(key: 'stealth_record_start',   value: _recordStartKeyword);
    await _storage.write(key: 'stealth_record_stop',    value: _recordStopKeyword);
    
    // Enabling the feature for the first time
    await setStealthProtection(true);
  }

  static Future<void> disableStealthMode() async {
    await setStealthProtection(false);
  }
}
