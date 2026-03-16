import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';
import '../models/user_model.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();
  final String _apiUrl = '$kBaseUrl/users'; // http://10.0.2.2:5000/api/users

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
    await _storage.write(
      key: 'login_timestamp',
      value: DateTime.now().toIso8601String(),
    );
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'login_timestamp');
  }

  Future<bool> isTokenValid() async {
    final timestampStr = await _storage.read(key: 'login_timestamp');
    if (timestampStr == null) return false;

    final loginDate = DateTime.tryParse(timestampStr);
    if (loginDate == null) return false;

    final difference = DateTime.now().difference(loginDate);
    return difference.inDays < 30;
  }

  Future<String> signup({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required String role, // To register as 'driver' or 'passenger'
  }) async {
    final uri = Uri.parse('$_apiUrl/signup');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'password': password,
        'phoneNumber': phoneNumber,
        'phone': phoneNumber,
        'role': role,
      }),
    );

    if (response.statusCode == 202 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['message'] ??
          'Registration successful. Check email for verification.';
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
        errorData['message'] ??
            'Registration failed. Status code: ${response.statusCode}',
      );
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_apiUrl/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = UserModel.fromJson(data);

      if (user.token != null) {
        await saveToken(user.token!);
}
      return user;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
        errorData['message'] ??
            'Login failed. Status code: ${response.statusCode}',
      );
    }
  }

  Future<UserModel> getCurrentUser() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final uri = Uri.parse('$_apiUrl/me');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = UserModel.fromJson(data);
      return user;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
        errorData['message'] ??
            'Failed to get user profile. Status: ${response.statusCode}',
      );
    }
  }
}
