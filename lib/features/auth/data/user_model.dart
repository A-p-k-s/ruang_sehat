// lib/features/auth/data/user_model.dart
class UserModel {
  final String id;
  final String name;
  final String username;
  final String? email;
  final String? token;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    this.email,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Backend menggunakan MongoDB ObjectId (String)
    final rawId = json['id'];
    return UserModel(
      id: rawId != null ? rawId.toString() : '',
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      email: json['email'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'token': token,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    String? token,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      token: token ?? this.token,
    );
  }
}