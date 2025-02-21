import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  Future<String?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('https://localhost:7081/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Сохраняем токен и имя пользователя в SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', data['token']);
      await prefs.setString('username', username); // Сохраняем имя пользователя
      return data['token'];
    } else {
      return null;
    }
  }

Future<String?> register(String username, String email, String password) async {
  final response = await http.post(
    Uri.parse('https://localhost:7081/api/auth/register'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'username': username, 'email': email, 'password': password}),
  );

  if (response.statusCode == 200) {
    return null; // Регистрация успешна, возвращаем null (нет ошибки)
  } else {
    final errorData = json.decode(response.body);
    return errorData['message'] ?? 'Ошибка регистрации'; // Получаем сообщение об ошибке с сервера
  }
}



  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }
  
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('username');
  }

    // Функция для получения токена
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token'); // Получаем токен из SharedPreferences
  }
}
