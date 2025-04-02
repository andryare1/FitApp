import 'dart:convert';
import 'package:http/http.dart' as http;

const baseUrl = 'http://192.168.31.85:5016'; // для макбука
//const baseUrl = 'http://192.168.31.142:5016';   // для ПК

class ExerciseService {
  Future<List<Map<String, dynamic>>> getExercisesByMuscleGroup(
      String muscleGroup, String token) async {
    final response =
        await http.get(Uri.parse('$baseUrl/api/exercises/group/$muscleGroup'),  headers: {
        'Authorization': 'Bearer $token',
      });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((exercise) {
        exercise['imageUrl'] = '$baseUrl${exercise['imageUrl']}';
        return exercise as Map<String, dynamic>;
      }).toList();
    } else {
      throw Exception('Ошибка загрузки упражнений');
    }
  }


   Future<List<Map<String, dynamic>>> searchExercises(String query) async {
    final response = await http.get(Uri.parse('$baseUrl/api/exercises/search?query=$query'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((exercise) {
        exercise['imageUrl'] = '$baseUrl${exercise['imageUrl']}';
        return exercise as Map<String, dynamic>;
      }).toList();
    } else {
      throw Exception('Ошибка поиска упражнений');
    }
  }

   // Метод для получения списка тренировок пользователя
  Future<List<Map<String, dynamic>>> getWorkoutsByUser(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/trainings'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((workout) {
        return workout as Map<String, dynamic>;
      }).toList();
    } else {
      throw Exception('Ошибка загрузки тренировок');
    }
  }

 Future<void> saveWorkout(String? token, String name, List<Map<String, dynamic>> exercises) async {
  final url = Uri.parse('$baseUrl/api/trainings');

  final workoutData = {
    "name": name,
    "trainingExercises": exercises.map((exercise) {
      return {
        "exercise_id": exercise["id"],  // ID упражнения
        "sets": exercise["sets"] ?? 4,
        "reps": exercise["reps"] ?? 12,
        "weight": exercise["weight"] ?? 30,
        "comment": exercise["comment"] ?? '',  // Можно добавить комментарий (если он есть)
      };
    }).toList(),
  };

  final response = await http.post(
    url,
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode(workoutData),
  );

  if (response.statusCode != 200) {
    throw Exception('Ошибка при сохранении тренировки: ${response.body}');
  }

  final workoutResponse = jsonDecode(response.body);

  // Извлекаем ID тренировки из ответа
  final trainingId = workoutResponse['training']['id'];

  print('Тренировка создана с ID: $trainingId');
}



}
