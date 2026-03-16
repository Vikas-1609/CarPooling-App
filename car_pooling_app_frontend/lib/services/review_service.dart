
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import 'auth_service.dart';

class ReviewService {
  final AuthService _authService = AuthService();
  final String _apiUrl =
      '$kBaseUrl/reviews'; // http://10.0.2.2:5000/api/reviews

  Future<String> submitReview({
    required String bookingId,
    required String revieweeId,
    required int rating,
    required String comment,
  }) async {
    final token = await _authService.getToken();

    if (token == null) {
      throw Exception('Not authenticated. Please log in again.');
    }

    final uri = Uri.parse(_apiUrl);
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'bookingId': bookingId,
        'revieweeId': revieweeId,
        'rating': rating,
        'comment': comment,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Review submitted successfully.';
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
        errorData['message'] ??
            'Failed to submit review. Status code: ${response.statusCode}',
      );
    }
  }

  Future<List<dynamic>> getUserReviews(String userId) async {
    final uri = Uri.parse('$_apiUrl/$userId');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] as List<dynamic>;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
        errorData['message'] ??
            'Failed to load reviews. Status: ${response.statusCode}',
      );
    }
  }
}
