import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_url.dart';
import 'auth_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  static const Duration _timeout = Duration(seconds: 30);

  // Helper: Get headers with JWT token
  static Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requireAuth) {
      final token = await AuthService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        throw ApiException('Authentication token not found');
      }
    }

    return headers;
  }

  // ─── AUTH ENDPOINTS ──────────────────────────────────────────────────────

  // Register
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      final headers = await _getHeaders(requireAuth: false);
      
      final response = await http
          .post(
            Uri.parse(ApiUrl.register),
            headers: headers,
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'phone': phone,
            }),
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Registration failed: ${e.toString()}');
    }
  }

  // Login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final headers = await _getHeaders(requireAuth: false);
      
      final response = await http
          .post(
            Uri.parse(ApiUrl.login),
            headers: headers,
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Login failed: ${e.toString()}');
    }
  }

  // ─── EMERGENCY ENDPOINTS ────────────────────────────────────────────────

  // Trigger Emergency
  static Future<Map<String, dynamic>> triggerEmergency({
    required double latitude,
    required double longitude,
    String triggerType = 'manual',
  }) async {
    try {
      final headers = await _getHeaders(requireAuth: true);
      
      final response = await http
          .post(
            Uri.parse(ApiUrl.triggerEmergency),
            headers: headers,
            body: jsonEncode({
              'latitude': latitude,
              'longitude': longitude,
              'triggerType': triggerType,
            }),
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Failed to trigger emergency: ${e.toString()}');
    }
  }

  // Analyze Text for Threat
  static Future<Map<String, dynamic>> analyzeText({
    required String text,
    double latitude = 0,
    double longitude = 0,
  }) async {
    try {
      final headers = await _getHeaders(requireAuth: true);
      
      final response = await http
          .post(
            Uri.parse(ApiUrl.analyzeText),
            headers: headers,
            body: jsonEncode({
              'text': text,
              'latitude': latitude,
              'longitude': longitude,
            }),
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Text analysis failed: ${e.toString()}');
    }
  }

  // Upload Audio
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

  // Get Emergency Events
  static Future<Map<String, dynamic>> getEmergencyEvents() async {
    try {
      final headers = await _getHeaders(requireAuth: true);
      
      final response = await http
          .get(
            Uri.parse(ApiUrl.getEmergencyEvents),
            headers: headers,
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Failed to fetch emergency events: ${e.toString()}');
    }
  }

  // Get Emergency Event by ID
  static Future<Map<String, dynamic>> getEmergencyEvent(String eventId) async {
    try {
      final headers = await _getHeaders(requireAuth: true);
      
      final response = await http
          .get(
            Uri.parse('${ApiUrl.getEmergencyEvents}/$eventId'),
            headers: headers,
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Failed to fetch event: ${e.toString()}');
    }
  }

  // Resolve Emergency
  static Future<Map<String, dynamic>> resolveEmergency(String eventId) async {
    try {
      final headers = await _getHeaders(requireAuth: true);
      
      final response = await http
          .put(
            Uri.parse('${ApiUrl.getEmergencyEvents}/$eventId/resolve'),
            headers: headers,
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Failed to resolve emergency: ${e.toString()}');
    }
  }

  // Cancel Emergency
  static Future<Map<String, dynamic>> cancelEmergency(String eventId) async {
    try {
      final headers = await _getHeaders(requireAuth: true);
      
      final response = await http
          .put(
            Uri.parse('${ApiUrl.getEmergencyEvents}/$eventId/cancel'),
            headers: headers,
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Failed to cancel emergency: ${e.toString()}');
    }
  }

  // ─── CONTACT ENDPOINTS ──────────────────────────────────────────────────

  // Add Contact
  static Future<Map<String, dynamic>> addContact({
    required String name,
    required String phone,
    required String relation,
    String? email,
    String? telegramChatId,
    int priority = 1,
  }) async {
    try {
      final headers = await _getHeaders(requireAuth: true);
      
      final response = await http
          .post(
            Uri.parse(ApiUrl.addContact),
            headers: headers,
            body: jsonEncode({
              'name': name,
              'phone': phone,
              'relation': relation,
              'email': email,
              'telegramChatId': telegramChatId,
              'priority': priority,
            }),
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Failed to add contact: ${e.toString()}');
    }
  }

  // Get Contacts
  static Future<Map<String, dynamic>> getContacts() async {
    try {
      final headers = await _getHeaders(requireAuth: true);
      
      final response = await http
          .get(
            Uri.parse(ApiUrl.getContacts),
            headers: headers,
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Failed to fetch contacts: ${e.toString()}');
    }
  }

  // Update Contact
  static Future<Map<String, dynamic>> updateContact({
    required String contactId,
    required String name,
    required String phone,
    required String relation,
    String? email,
    String? telegramChatId,
    int priority = 1,
  }) async {
    try {
      final headers = await _getHeaders(requireAuth: true);
      
      final response = await http
          .put(
            Uri.parse('${ApiUrl.updateContact}/$contactId'),
            headers: headers,
            body: jsonEncode({
              'name': name,
              'phone': phone,
              'relation': relation,
              'email': email,
              'telegramChatId': telegramChatId,
              'priority': priority,
            }),
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Failed to update contact: ${e.toString()}');
    }
  }

  // Delete Contact
  static Future<Map<String, dynamic>> deleteContact(String contactId) async {
    try {
      final headers = await _getHeaders(requireAuth: true);
      
      final response = await http
          .delete(
            Uri.parse('${ApiUrl.deleteContact}/$contactId'),
            headers: headers,
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Failed to delete contact: ${e.toString()}');
    }
  }

  // ─── RESPONSE HANDLER ───────────────────────────────────────────────────

  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json;
      } else if (response.statusCode == 401) {
        // Fire and forget logout to clear hardware keys
        AuthService.logout();
        throw ApiException('Unauthorized. Please login again.', 401);
      } else if (response.statusCode == 403) {
        throw ApiException('Forbidden. Access denied.', 403);
      } else if (response.statusCode == 404) {
        throw ApiException('Not found.', 404);
      } else if (response.statusCode == 409) {
        throw ApiException(json['message'] ?? 'Conflict. Resource already exists.', 409);
      } else if (response.statusCode >= 500) {
        throw ApiException('Server error. Please try again later.', response.statusCode);
      } else {
        throw ApiException(
          json['message'] ?? 'Request failed',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to parse response: ${e.toString()}');
    }
  }
}
