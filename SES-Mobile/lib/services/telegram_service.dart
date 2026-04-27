import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_urls.dart';
import 'auth_service.dart';

class TelegramService {
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Check Telegram Updates and fetch Chat ID
  static Future<String?> connectTelegram() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse(ApiUrl.telegramConnect),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['chatId'];
      }
      return null;
    } catch (e) {
      print('Telegram connect error: $e');
      return null;
    }
  }

  /// Save fetched Chat ID to backend
  static Future<bool> saveChatId(String chatId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse(ApiUrl.telegramSaveChatId),
            headers: headers,
            body: jsonEncode({'chatId': chatId}),
          )
          .timeout(const Duration(seconds: 15));

      return response.statusCode == 200;
    } catch (e) {
      print('Telegram saveChatId error: $e');
      return false;
    }
  }

  /// Trigger Direct Telegram Alert
  static Future<bool> triggerDirectAlert(double lat, double lng) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse(ApiUrl.telegramTriggerAlert),
            headers: headers,
            body: jsonEncode({
              'latitude': lat,
              'longitude': lng,
            }),
          )
          .timeout(const Duration(seconds: 20));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Telegram trigger alert error: $e');
      return false;
    }
  }
}
