import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'user_data';

  /// Register a new user
  static Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      final response = await ApiService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );

      final data = response['data'] as Map<String, dynamic>?;

      // Save token if provided
      if (data?['token'] != null) {
        await _saveToken(data!['token']);
      }

      if (data != null) {
        await _saveUserData(data);
      }

      return AuthResult(
        success: true,
        message: response['message'] ?? 'Registration successful',
      );
    } on ApiException catch (e) {
      return AuthResult(
        success: false,
        message: e.message,
      );
    }
  }

  /// Login an existing user
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiService.login(
        email: email,
        password: password,
      );

      final data = response['data'] as Map<String, dynamic>?;

      // Save token
      if (data?['token'] != null) {
        await _saveToken(data!['token']);
      }

      // Save user data
      if (data != null) {
        await _saveUserData(data);
      }

      return AuthResult(
        success: true,
        message: response['message'] ?? 'Login successful',
      );
    } on ApiException catch (e) {
      return AuthResult(
        success: false,
        message: e.message,
      );
    }
  }

  /// Get stored JWT token
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Save JWT token to local storage
  static Future<void> _saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Save user data to local storage
  static Future<void> _saveUserData(Map<String, dynamic> userData) async {
    await _storage.write(key: _userKey, value: jsonEncode(userData));
  }

  /// Get saved user data
  static Future<Map<String, dynamic>?> getUserData() async {
    final userJson = await _storage.read(key: _userKey);
    return userJson != null ? jsonDecode(userJson) : null;
  }

  /// Logout - clear all stored data
  static Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
    
    // Clear normal shared prefs related tracking too
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_trigger_time');
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}

/// Response class for authentication operations
class AuthResult {
  final bool success;
  final String message;

  AuthResult({
    required this.success,
    required this.message,
  });
}
