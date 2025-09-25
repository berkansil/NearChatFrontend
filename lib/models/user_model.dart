import 'dart:convert';

class User {
  final int userId;
  final String? about;
  final String username;
  final DateTime? lastActive;
  final String? profilePicture;
  final String? status;

  User({required this.userId, required this.username, this.about, this.lastActive, this.profilePicture, this.status});

  factory User.fromJson(Map<String, dynamic> json) { 
    return User(userId: json["UserId"], username: json["Username"], about: json["About"], lastActive: json["LastActive"] == null ? null : DateTime.parse(json["LastActive"]), profilePicture: json["ProfilePicture"], status: json["Status"]);
  }

  static User fromRawJson(String str) => User.fromJson(jsonDecode(str));
}
