import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/booking_model.dart';
import 'auth_service.dart';

class BookingService {
  final AuthService _authService = AuthService();
  final String _apiUrl =
      '$kBaseUrl/bookings'; // http://10.0.2.2:5000/api/bookings

  Future<Map<String, dynamic>> createBooking({
    required String rideId,
    required int seatsBooked,
    required String pickupAddress,
    required String dropoffAddress,
    required double pickupLng,
    required double pickupLat,
    required double dropoffLng,
    required double dropoffLat,
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
        'rideId': rideId,
        'seatsBooked': seatsBooked,
        'pickupAddress': pickupAddress,
        'dropoffAddress': dropoffAddress,
        'pickupLng': pickupLng,
        'pickupLat': pickupLat,
        'dropoffLng': dropoffLng,
        'dropoffLat': dropoffLat,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data; // Return full response which might include payment_session_id
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
        errorData['message'] ??
            'Booking failed. Status code: ${response.statusCode}',
      );
    }
  }

  Future<String> acceptBooking(String bookingId) async {
    final token = await _authService.getToken();

    if (token == null) {
      throw Exception('Not authenticated. Please log in again.');
    }

    final uri = Uri.parse('$_apiUrl/$bookingId/accept');
    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Booking accepted successfully!';
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
        errorData['message'] ??
            'Failed to accept booking. Status: ${response.statusCode}',
      );
    }
  }

  Future<List<BookingModel>> getMyBookings() async {
    final token = await _authService.getToken();

    if (token == null) {
      throw Exception('Not authenticated. Please log in again.');
    }

    final uri = Uri.parse('$_apiUrl/mybookings');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> bookingsList = jsonResponse['data'];
      return bookingsList.map((json) => BookingModel.fromJson(json)).toList();
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
        errorData['message'] ??
            'Failed to load bookings. Status: ${response.statusCode}',
      );
    }
  }

  Future<String> completeBooking(String bookingId) async {
    final token = await _authService.getToken();

    if (token == null) {
      throw Exception('Not authenticated.');
    }

    final uri = Uri.parse('$_apiUrl/$bookingId/complete');
    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Booking completed successfully!';
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
        errorData['message'] ??
            'Failed to complete booking. Status: ${response.statusCode}',
      );
    }
  }

  Future<String> cancelBooking(String bookingId) async {
    final token = await _authService.getToken();

    if (token == null) {
      throw Exception('Not authenticated.');
    }

    final uri = Uri.parse('$_apiUrl/$bookingId/cancel');
    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Booking cancelled successfully!';
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
        errorData['message'] ??
            'Failed to cancel booking. Status: ${response.statusCode}',
      );
    }
  }

  Future<String> confirmBooking(
    String orderId,
    Map<String, dynamic> bookingData,
  ) async {
    final token = await _authService.getToken();

    if (token == null) {
      throw Exception('Not authenticated.');
    }
    final response = await http.post(
      Uri.parse('$_apiUrl/confirm'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({"orderId": orderId, "bookingData": bookingData}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['message'];
    } else {
      throw Exception(data['message']);
    }
  }
}
