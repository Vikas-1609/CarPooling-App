
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class LocationResult {
  final String displayName;
  final LatLng location;

  LocationResult({required this.displayName, required this.location});

  factory LocationResult.fromJson(Map<String, dynamic> json) {
    return LocationResult(
      displayName: json['display_name'] ?? '',
      location: LatLng(
        double.parse(json['lat']),
        double.parse(json['lon']),
      ),
    );
  }
}

class LocationService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';

  Future<List<LocationResult>> searchLocations(String query) async {
    if (query.isEmpty) return [];

    try {
      final uri = Uri.parse('$_baseUrl?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1');
      
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'CarPoolingApp/1.0',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => LocationResult.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load location data: ${response.statusCode}');
      }
    } catch (e) {
return [];
    }
  }
}
