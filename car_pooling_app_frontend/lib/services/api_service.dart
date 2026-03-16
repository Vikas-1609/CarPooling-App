import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import 'auth_service.dart'; // To get the stored token

class ApiService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final headers = {
      'Content-Type': 'application/json',
    };

    final token = await _authService.getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<http.Response> get(String endpoint) async {
    final uri = Uri.parse('$kBaseUrl$endpoint');
    final headers = await _getHeaders();
    return await http.get(uri, headers: headers);
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('$kBaseUrl$endpoint');
    final headers = await _getHeaders();
    return await http.post(uri, headers: headers, body: jsonEncode(body));
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('$kBaseUrl$endpoint');
    final headers = await _getHeaders();
    return await http.put(uri, headers: headers, body: jsonEncode(body));
  }

  Future<http.Response> delete(String endpoint) async {
    final uri = Uri.parse('$kBaseUrl$endpoint');
    final headers = await _getHeaders();
    return await http.delete(uri, headers: headers);
  }
}
