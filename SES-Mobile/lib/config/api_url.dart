import 'package:shared_preferences/shared_preferences.dart';

class ApiUrl {
  static String _baseUrl = 'http://10.228.25.175:5000/api';

  static Future<void> loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('custom_api_base_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _baseUrl = savedUrl;
    }
  }

  static Future<void> saveBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_api_base_url', url);
    _baseUrl = url;
  }

  static String get baseUrl => _baseUrl;

  // Auth endpoints
  static String get register => '$_baseUrl/auth/register';
  static String get login => '$_baseUrl/auth/login';

  // Emergency endpoints
  static String get triggerEmergency => '$_baseUrl/emergency/trigger';
  static String get uploadAudio => '$_baseUrl/emergency/upload-audio';
  static String get analyzeText => '$_baseUrl/emergency/analyze-text';
  static String get getEmergencyEvents => '$_baseUrl/emergency/events';

  // Contact endpoints
  static String get addContact => '$_baseUrl/contacts';
  static String get getContacts => '$_baseUrl/contacts';
  static String get updateContact => '$_baseUrl/contacts';
  static String get deleteContact => '$_baseUrl/contacts';

  // Telegram endpoints
  static String get telegramConnect => '$_baseUrl/telegram/connect';
  static String get telegramSaveChatId => '$_baseUrl/telegram/save-chat-id';
  static String get telegramTriggerAlert => '$_baseUrl/alert/trigger';
}
