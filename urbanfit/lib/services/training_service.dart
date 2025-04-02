import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:urbanfit/models/training.dart';
import 'package:urbanfit/models/training_exercise.dart';
import 'package:urbanfit/services/auth_service.dart';

class TrainingService {
  static const _baseUrl = 'http://192.168.31.142:5016/api';
  final AuthService _authService = AuthService();

 Future<List<Training>> getUserTrainings() async {
  final token = await _authService.getToken();
  final response = await http.get(
    Uri.parse('$_baseUrl/trainings'),
    headers: _getHeaders(token),
  );

  return _handleResponse<List<Training>>(
    response,
    (body) {
      // Если сервер возвращает список напрямую
      if (body is List) {
        return body.map((e) => Training.fromJson(e)).toList();
      }
      // Если сервер возвращает объект с полем 'data' или 'trainings'
      else if (body is Map<String, dynamic>) {
        final data = body['data'] ?? body['trainings'] ?? body['items'];
        if (data is List) {
          return data.map((e) => Training.fromJson(e)).toList();
        }
      }
      throw Exception('Неверный формат данных от сервера');
    },
  );
}

Future<Training> createTrainingWithExercises({
  required String name,
  required List<TrainingExercise> exercises,
}) async {
  final token = await _authService.getToken();
  
  // Подготовка данных для отправки
  final requestData = {
    'name': name,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };

  final response = await http.post(
    Uri.parse('$_baseUrl/trainings/create-full'),
    headers: _getHeaders(token),
    body: jsonEncode(requestData),
  );

  return _handleResponse<Training>(
    response,
    (body) => Training.fromJson(body),
  );
}

  Future<void> updateTrainingExercises({
    required int trainingId,
    required List<TrainingExercise> exercises,
  }) async {
    final token = await _authService.getToken();
    final response = await http.put(
      Uri.parse('$_baseUrl/trainings/$trainingId/exercises'),
      headers: _getHeaders(token),
      body: jsonEncode({
        'exercises': exercises.map((e) => e.toJson()).toList(),
      }),
    );

    _handleResponse<void>(response, (_) => null);
  }

  Future<void> deleteTraining(int trainingId) async {
    final token = await _authService.getToken();
    final response = await http.delete(
      Uri.parse('$_baseUrl/trainings/$trainingId'),
      headers: _getHeaders(token),
    );

    _handleResponse<void>(response, (_) => null);
  }

  Map<String, String> _getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  T _handleResponse<T>(http.Response response, T Function(dynamic) parser) {
    switch (response.statusCode) {
      case 200:
      case 201:
        return parser(json.decode(response.body));
      case 401:
        throw Exception('Необходима авторизация');
      case 404:
        throw Exception('Ресурс не найден');
      case 500:
        throw Exception('Ошибка сервера: ${response.body}');
      default:
        throw Exception('Ошибка: ${response.statusCode}');
    }
  }
}