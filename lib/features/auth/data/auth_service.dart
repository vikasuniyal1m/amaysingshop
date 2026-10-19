import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

class AuthSession {
  AuthSession({
    required this.token,
    required this.userId,
    required this.email,
  });

  final String token;
  final int userId;
  final String email;
}

class AuthService {
  AuthService({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/wp-json/jwt-auth/v1/token');
    final response = await _httpClient.post(uri, body: {
      'username': username,
      'password': password,
    });
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Login failed');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthSession(
      token: data['token'] as String? ?? '',
      userId: data['user_id'] as int? ?? 0,
      email: data['user_email'] as String? ?? username,
    );
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/wp-json/wp/v2/users/register');
    final response = await _httpClient.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Registration failed');
    }
  }
}
