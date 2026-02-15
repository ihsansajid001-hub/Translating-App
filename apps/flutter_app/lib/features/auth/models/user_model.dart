class UserModel {
  final String id;
  final String email;
  final String username;
  final String preferredLanguage;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.preferredLanguage,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      preferredLanguage: json['preferred_language'] ?? 'en',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'preferred_language': preferredLanguage,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
