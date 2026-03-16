
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/ride_model.dart';
import 'auth_service.dart'; // To get the token

class RideService {
  final String _apiUrl = '$kBaseUrl/rides';
  final AuthService _authService = AuthService(); // Used to fetch the token

  Future<List<RideModel>> searchRides({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required String departureDate, // Format: YYYY-MM-DD
  }) async {
    final queryParams = {
      'originLat': originLat.toString(),
      'originLng': originLng.toString(),
      'destLat': destLat.toString(),
      'destLng': destLng.toString(),
      'departureDate': departureDate,
    };

    final uri = Uri.parse(
      '$_apiUrl/search',
    ).replace(queryParameters: queryParams);

    final token = await _authService.getToken();

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['success'] == true && data['data'] != null) {
        return (data['data'] as List)
            .map((json) => RideModel.fromJson(json))
            .toList();
      }
      return []; // Return empty list if no results
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to fetch rides.');
    }
  }

  Future<String> postRide({
    required String originAddress,
    required String destinationAddress,
    required double originLng,
    required double originLat,
    required double destLng,
    required double destLat,
    required String departureTime,
    required int availableSeats,
    required double pricePerSeat,
    required String carDescription,
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
        'originAddress': originAddress,
        'destinationAddress': destinationAddress,
        'origin': {
          'type': 'Point',
          'coordinates': [originLng, originLat],
        },
        'destination': {
          'type': 'Point',
          'coordinates': [destLng, destLat],
        },
        'departureTime': departureTime,
        'availableSeats': availableSeats,
        'pricePerSeat': pricePerSeat,
        'carDescription': carDescription,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Ride posted successfully.';
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
        errorData['message'] ??
            'Failed to post ride. Status: ${response.statusCode}',
      );
    }
  }

  Future<List<RideModel>> getMyRides() async {
    final token = await _authService.getToken();

    if (token == null) {
      throw Exception('Not authenticated. Please log in again.');
    }

    final uri = Uri.parse('$_apiUrl/myrides');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['data'] != null && jsonResponse['data'] is List) {
        final List<dynamic> ridesList = jsonResponse['data'];
        return ridesList.map((json) => RideModel.fromJson(json)).toList();
      }
      return [];
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
        errorData['message'] ??
            'Failed to load your rides. Status: ${response.statusCode}',
      );
    }
  }
}
