
import 'point_model.dart';
import 'user_model.dart'; // To represent the driver details

class RideModel {
  final String id;
  final UserModel driver; // The driver's user data
  final PointModel origin;
  final PointModel destination;
  final String originAddress;
  final String destinationAddress;
  final DateTime departureTime;
  final int availableSeats;
  final double pricePerSeat;
  final String status;

  RideModel({
    required this.id,
    required this.driver,
    required this.origin,
    required this.destination,
    required this.originAddress,
    required this.destinationAddress,
    required this.departureTime,
    required this.availableSeats,
    required this.pricePerSeat,
    required this.status,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: json['_id'] ?? '',
      driver: json['driver'] is Map<String, dynamic>
          ? UserModel.fromJson(json['driver'] as Map<String, dynamic>)
          : UserModel(
              id: json['driver'] is String ? json['driver'] : '',
              fullName: 'Driver',
              email: '',
              phone: '',
              role: 'driver',
            ),
      origin: PointModel.fromJson(json['origin'] as Map<String, dynamic>),
      destination: PointModel.fromJson(
        json['destination'] as Map<String, dynamic>,
      ),
      originAddress: json['originAddress'] ?? '',
      destinationAddress: json['destinationAddress'] ?? '',
      departureTime: DateTime.parse(json['departureTime']),
      availableSeats: json['availableSeats'] ?? 0,
      pricePerSeat: (json['pricePerSeat'] as num).toDouble(),
      status: json['status'] ?? 'scheduled',
    );
  }
}
