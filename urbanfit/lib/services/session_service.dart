import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:urbanfit/services/auth_service.dart';

class SessionService {
  //static const _baseUrl = 'http://192.168.31.142:5016/api'; // для ПК
  static const _baseUrl = 'http://192.168.31.169:5016/api'; // для макбука
  final AuthService _authService = AuthService();


  // Универсальный обработчик ответа
  T _handleResponse<T>(
      http.Response response, T Function(dynamic data) onSuccess) {
    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        return onSuccess(null); // или брось исключение, если ожидаешь данные
      }

      final data = jsonDecode(response.body);
      return onSuccess(data);
    } else {
      throw Exception('Ошибка: ${response.statusCode}');
    }
  }

  Map<String, String> _getHeaders(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

 // Начало сессии тренировки
  Future<int?> startTrainingSession(int trainingId, String token) async {
    try {
      // Отправляем POST-запрос на сервер для начала тренировки
      final response = await http.post(
        Uri.parse('$baseUrl/api/session/start-session'), // Убедись, что endpoint корректный
        headers: _getHeaders(token),
        body: jsonEncode({'trainingId': trainingId}),
      );

      // Проверка успешного ответа от сервера
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Получаем sessionId из ответа
        final sessionId = responseData['sessionId'];
        return sessionId;
      } else {
        throw Exception('Ошибка запуска тренировки: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Ошибка при запуске сессии: $error');
    }
  }


  Future<Map<String, dynamic>> completeTraining(int trainingId, String token, {required int sessionId}) async {
  try {
    final response = await http.put(
      Uri.parse('$baseUrl/api/session/$sessionId/complete'), // Эндпоинт для завершения тренировки
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final completionPercentage = responseData['completionPercentage'];
      final message = responseData['message'];

      return {
        'completionPercentage': completionPercentage,
        'message': message,
      };
    } else {
      throw Exception('Ошибка завершения тренировки: ${response.statusCode}');
    }
  } catch (error) {
    throw Exception('Ошибка при завершении тренировки: $error');
  }
}

 Future<void> deleteTrainingSession(int sessionId) async {
    try {
      final token = await _authService.getToken();

      if (token == null) {
      throw Exception('Требуется авторизация');
    }
    
      final response = await http.delete(
        Uri.parse('$_baseUrl/session/$sessionId'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 204) {
        return; // Успешное удаление (NoContent)
      } else if (response.statusCode == 404) {
        throw Exception('Сессия не найдена');
      } else {
        throw Exception('Ошибка удаления: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка при удалении сессии: ${e.toString()}');
    }
  }

}