class AuthResponse {
  final bool success;
  final String message;
  final UserData? data;
  final String? token;

  AuthResponse({
    required this.success,
    required this.message,
    this.data,
    this.token,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? UserData.fromJson(json['data']) : null,
      token: json['token'],
    );
  }
}

class UserData {
  final String userId;
  final String name;
  final String email;
  final String phone;

  UserData({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}
