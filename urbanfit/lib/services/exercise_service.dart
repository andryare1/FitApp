import 'dart:convert';
import 'package:http/http.dart' as http;

//const baseUrl = 'http://192.168.31.169:5016'; // для макбука
const baseUrl = 'http://192.168.31.142:5016';   // для ПК

class ExerciseService { 
  // Метод для получения заголовков с токеном
  Map<String, String> _getHeaders(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // Получение упражнений по группе мышц
  Future<List<Map<String, dynamic>>> getExercisesByMuscleGroup(
      String muscleGroup, String token) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/exercises/group/$muscleGroup'), headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((exercise) {
        exercise['imageUrl'] = '$baseUrl${exercise['imageUrl']}';
        exercise['videoUrl'] = '$baseUrl${exercise['videoUrl']}';
        
        return exercise as Map<String, dynamic>;
      }).toList();
    } else {
      throw Exception('Ошибка загрузки упражнений');
    }
  }

  // Получение группы мышц по ID упражнения
  Future<String> getMuscleGroupByExerciseId(
      int exerciseId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/exercises/$exerciseId/muscle-group'),
      headers: _getHeaders(token),
    );

    return _handleResponse<String>(response, (data) {
      // Извлекаем строку из JSON и вызываем trim()
      return data['muscleGroup'].trim();
    });
  }


  Future<List<Map<String, dynamic>>> searchExercises(
    String query, String token) async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/exercises/search?query=$query'),
    headers: _getHeaders(token),
  );

  return _handleResponse<List<Map<String, dynamic>>>(response, (data) {
    final List<dynamic> exercises = data; 
    return exercises.map<Map<String, dynamic>>((exercise) {
      final updatedExercise = Map<String, dynamic>.from(exercise);
      updatedExercise['imageUrl'] = '$baseUrl${updatedExercise['imageUrl']}';
      return updatedExercise;
    }).toList();
  });
}

  // Получение прогресса тренировки
  Future<List<Map<String, dynamic>>> getTrainingProgress(
      int trainingId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/trainings/$trainingId/progress'),
      headers: _getHeaders(token),
    );

    return _handleResponse<List<Map<String, dynamic>>>(response, (data) {
      return data.map((progress) => progress as Map<String, dynamic>).toList();
    });
  }

Future<void> completeExerciseProgress(
    int progressId, int setsCompleted, bool wasSkipped, String token, {required int sessionId}) async {
  final response = await http.put(
    Uri.parse('$baseUrl/api/trainings/progress/$progressId'),
    headers: _getHeaders(token),
    body: jsonEncode({
      'SetsCompleted': setsCompleted,
      'WasSkipped': wasSkipped,
      'SessionId': sessionId,  // Добавление sessionId
    }),
  );

  _handleResponse(response, (_) {});
}

Future<int> startExerciseProgress(
    int trainingId, int exerciseId, int setsPlanned, String token, {required int sessionId}) async {

  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/trainings/progress'),
      headers: _getHeaders(token),
      body: jsonEncode({
        'TrainingId': trainingId,
        'ExerciseId': exerciseId,
        'SetsPlanned': setsPlanned,
        'TrainingSessionId': sessionId,
      }),
    );

    final responseData = _handleResponse<Map<String, dynamic>>(response, (data) {
      return data;
    });

    return responseData['id'];
  } catch (e) {
    rethrow;  // Re-throw the error to handle it outside if needed
  }
}

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
}
