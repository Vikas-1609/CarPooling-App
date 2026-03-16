
import 'package:car_pooling_app_frontend/models/ride_model.dart';
import 'package:car_pooling_app_frontend/models/user_model.dart';
import 'package:latlong2/latlong.dart';

class BookingModel {
  final String id;
  final RideModel? ride;
  final UserModel? passenger;
  final int seatsBooked;
  final String status; // 'pending', 'accepted', 'completed', 'cancelled'
  final String pickupAddress;
  final String dropoffAddress;
  final LatLng pickupLocation;
  final LatLng dropoffLocation;
  final DateTime createdAt;

  BookingModel({
    required this.id,
    this.ride,
    this.passenger,
    required this.seatsBooked,
    required this.status,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['_id'],

      ride: json['ride'] is Map ? RideModel.fromJson(json['ride']) : null,

      passenger: json['passenger'] is Map
          ? UserModel.fromJson(json['passenger'])
          : null,

      seatsBooked: json['seatsBooked'] ?? 1,
      status: json['status'] ?? 'pending',
      pickupAddress: json['pickupAddress'] ?? '',
      dropoffAddress: json['dropoffAddress'] ?? '',

      pickupLocation:
          json['pickupLocation'] != null &&
              json['pickupLocation']['coordinates'] != null
          ? LatLng(
              json['pickupLocation']['coordinates'][1] as double,
              json['pickupLocation']['coordinates'][0] as double,
            )
          : const LatLng(0, 0),

      dropoffLocation:
          json['dropoffLocation'] != null &&
              json['dropoffLocation']['coordinates'] != null
          ? LatLng(
              json['dropoffLocation']['coordinates'][1] as double,
              json['dropoffLocation']['coordinates'][0] as double,
            )
          : const LatLng(0, 0),

      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
