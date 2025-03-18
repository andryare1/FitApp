import 'dart:convert';
import 'package:http/http.dart' as http;

const baseUrl = 'http://192.168.31.85:5016/api'; // для макбука
//const baseUrl = 'http://192.168.31.142:5016/api';   // для ПК

class ExerciseService {
  Future<List<Map<String, dynamic>>> getExercisesByMuscleGroup(
      String muscleGroup) async {
    final response =
        await http.get(Uri.parse('$baseUrl/exercises/group/$muscleGroup'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((exercise) => exercise as Map<String, dynamic>).toList();
    } else {
      throw Exception('Ошибка загрузки упражнений');
    }
  }
}
