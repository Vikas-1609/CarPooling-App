
class PointModel {
  final String type;
  final List<double> coordinates;

  PointModel({required this.type, required this.coordinates});

  factory PointModel.fromJson(Map<String, dynamic> json) {
    return PointModel(
      type: json['type'] ?? 'Point',
      coordinates: (json['coordinates'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
    );
  }
}
