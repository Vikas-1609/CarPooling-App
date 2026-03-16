
class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String? token;
  final double averageRating;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.token,
    this.averageRating = 0.0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'],
      fullName: json['fullName'],
      email: json['email'] ?? '',
      phone: (json['phoneNumber'] != null && json['phoneNumber'].toString().isNotEmpty)
          ? json['phoneNumber']
          : ((json['phone'] != null && json['phone'].toString().isNotEmpty)
              ? json['phone']
              : 'N/A'),
      role: json['role'] ?? '',
      token: json['token'],
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
