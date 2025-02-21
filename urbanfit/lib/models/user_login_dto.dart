// lib/models/user_login_dto.dart
class UserLoginDto {
  String username;
  String password;

  UserLoginDto({required this.username, required this.password});

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}
