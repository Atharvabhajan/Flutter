import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StealthModeService {
  static const _storage = FlutterSecureStorage();
  static final ValueNotifier<bool> isStealthNotifier = ValueNotifier(false);

  static String? _secretPhrase;
  static String? _alertKeyword;
  static String? _recordStartKeyword;
  static String? _recordStopKeyword;

  static bool   get isStealthMode      => isStealthNotifier.value;
  static String get secretPhrase       => _secretPhrase      ?? '';
  static String get alertKeyword       => _alertKeyword      ?? '';
  static String get recordStartKeyword => _recordStartKeyword ?? '';
  static String get recordStopKeyword  => _recordStopKeyword  ?? '';

  static Future<void> initialize() async {
    _secretPhrase       = await _storage.read(key: 'stealth_secret_phrase');
    _alertKeyword       = await _storage.read(key: 'stealth_alert_keyword');
    _recordStartKeyword = await _storage.read(key: 'stealth_record_start');
    _recordStopKeyword  = await _storage.read(key: 'stealth_record_stop');
    final v = await _storage.read(key: 'is_stealth_mode');
    isStealthNotifier.value = (v == 'true');
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
    await _storage.write(key: 'is_stealth_mode',        value: 'true');
    isStealthNotifier.value = true;
  }

  static Future<void> disableStealthMode() async {
    await _storage.write(key: 'is_stealth_mode', value: 'false');
    isStealthNotifier.value = false;
  }
}
