// lib/models/user_register_dto.dart
class UserRegisterDto {
  String username;
  String email;
  String password;

  UserRegisterDto(
      {required this.username, required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
    };
  }
}
