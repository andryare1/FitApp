import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

//const baseUrl = 'http://192.168.31.169:5016'; // для макбука
const baseUrl = 'http://192.168.31.142:5016';   // для ПК

class AuthService {
  Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username); // Сохраняем username
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs
        .getString('token'); // Должно совпадать с тем, как вы сохраняете токен
  }

  Future<String?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final token = data['token']; // Токен возвращается в поле 'token'

      // Сохраняем токен и username
      await saveToken(token);
      await saveUsername(username);

      return token;
    } else {
      return null;
    }
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token); // Сохраняем токен
  }

  // Future<String?> register(
  //     String username, String email, String password) async {
  //   final response = await http.post(
  //     Uri.parse('$baseUrl/api/auth/register'),
  //     headers: {'Content-Type': 'application/json'},
  //     body: json
  //         .encode({'username': username, 'email': email, 'password': password}),
  //   );

  //   if (response.statusCode == 200) {
  //     return null; // Регистрация успешна, возвращаем null (нет ошибки)
  //   } else {
  //     final errorData = json.decode(response.body);
  //     return errorData['message'] ??
  //         'Ошибка регистрации'; // Получаем сообщение об ошибке с сервера
  //   }
  // }

  Future<Map<String, dynamic>?> register(
    String username, String email, String password) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/auth/register'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'username': username,
      'email': email,
      'password': password,
    }),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data; // Предполагаем, что сервер возвращает { "userId": "...", "email": "..." }
  } else {
    final errorData = json.decode(response.body);
    throw Exception(errorData['message'] ?? 'Ошибка регистрации');
  }
}

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('username');
  }

  Future<Uint8List?> getAvatarFromServer(String token) async {
    // Получаем userId текущего пользователя (например, из SharedPreferences или токена)
    final userId =
        await getUserId(); // Замените на реальный способ получения userId

    // Формируем URL с userId
    final url = '$baseUrl/api/avatar/$userId';

    // Запрос аватарки с сервера
    final response = await http
        .get(Uri.parse(url), headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      // Сервер возвращает успешный ответ, можем обработать данные
      return response.bodyBytes; // Возвращаем путь или URL к аватарке
    } else {
      // Если сервер вернул ошибку, возвращаем null
      return null;
    }
  }

  Future<String?> getUserId() async {
    final token = await getToken();

    if (token == null) {
      return null; // Токен не найден
    }

    // Декодируем токен
    final parts = token.split('.');
    if (parts.length != 3) {
      return null; // Неверный формат токена
    }

    final payload = parts[1];
    final decoded = utf8.decode(base64Url.decode(base64Url.normalize(payload)));

    // Парсим payload и извлекаем userId
    final Map<String, dynamic> payloadData = json.decode(decoded);

    // Извлекаем userId
    return payloadData[
        "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier"];
  }

  // Метод для сохранения пути к аватарке
  Future<void> saveAvatarPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('avatarPath', path);
  }

  // Метод для загрузки аватарки
  Future<bool> uploadAvatar(File avatar) async {
    final token = await getToken();

    if (token == null) {
      return false; // Нет токена, не можем загрузить аватарку
    }

    final uri = Uri.parse('$baseUrl/api/avatar/upload');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath(
        'avatar',
        avatar.path,
        contentType: MediaType('image',
            'jpeg'), // Можно использовать mime_type пакеты для динамического типа
      ));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final data = json.decode(responseBody);
      final avatarUrl = '$baseUrl${data['avatarUrl']}';
      await saveAvatarPath(
          avatarUrl); // Сохраняем путь к аватарке в SharedPreferences
      return true;
    } else {
      return false;
    }
  }

  Future<bool> deleteAvatar() async {
    final token = await getToken();
    if (token == null) return false;

    final url = Uri.parse('$baseUrl/api/avatar/delete');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      await clearAvatarPath();
      return true;
    } else {
      return false;
    }
  }

  Future<void> clearAvatarPath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('avatarPath');
  }

  Future<String?> sendVerificationCode(String userId, String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/email-verification/send-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'email': email,
      }),
    );

    if (response.statusCode == 200) {
      return null; // код отправлен
    } else {
      final error = jsonDecode(response.body);
      return error['message'] ?? 'Не удалось отправить код';
    }
  }

Future<String?> verifyEmailCode(String userId, String code) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/email-verification/verify'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'userId': userId,
      'code': code,
    }),
  );

  if (response.statusCode == 200) {
    return null; // подтвержден успешно
  } else {
    try {
      final error = jsonDecode(response.body);
      return error['message'] ?? 'Ошибка подтверждения';
    } catch (_) {
      return response.body; // просто возвращаем как текст
    }
  }
}
}
