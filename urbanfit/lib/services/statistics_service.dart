import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:urbanfit/services/auth_service.dart';

class StatisticsService {
  //static const _baseUrl = 'http://192.168.31.169:5016/api'; 
  static const _baseUrl = 'http://192.168.31.142:5016/api'; // для ПК
  final AuthService _authService = AuthService();

  Map<String, String> _getHeaders(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // Получение общей статистики пользователя
  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('Пользователь не авторизован');

      final response = await http.get(
        Uri.parse('$_baseUrl/statistics/user'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Ошибка получения статистики: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка при загрузке статистики: ${e.toString()}');
    }
  }

Future<List<Map<String, dynamic>>> getMuscleGroupStats() async {
  try {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Пользователь не авторизован');

    final response = await http.get(
      Uri.parse('$_baseUrl/statistics/muscle-groups'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> decoded = jsonDecode(response.body);
      final List<dynamic> statsList = decoded['stats'];
      return statsList.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Ошибка получения статистики по мышцам: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Ошибка при получении данных: ${e.toString()}');
  }
}



}
