import 'package:flutter/material.dart';
import 'package:urbanfit/pages/exercisesPage/exercises_list_page.dart';
import 'package:urbanfit/pages/workoutPage/worcout_add_page.dart';
import 'package:urbanfit/services/auth_service.dart';
import 'package:urbanfit/services/exercise_service.dart';

class WorkoutCreationPage extends StatefulWidget {
  const WorkoutCreationPage({super.key});

  @override
  _WorkoutCreationPageState createState() => _WorkoutCreationPageState();
}

class _WorkoutCreationPageState extends State<WorkoutCreationPage> {
  final TextEditingController _workoutNameController = TextEditingController();
   final ExerciseService _exerciseService = ExerciseService();
  final List<Map<String, dynamic>> _selectedExercises = [];
   final AuthService _authService = AuthService();

  void _onExerciseSelected(Map<String, dynamic> exercise) {
    setState(() {
      if (_selectedExercises.contains(exercise)) {
        _selectedExercises.remove(exercise);
      } else {
        _selectedExercises.add(exercise);
      }
    });
  }

void _saveWorkout() async {
  if (_workoutNameController.text.isNotEmpty && _selectedExercises.isNotEmpty) {
    try {
      final token = await _authService.getToken(); // Получаем токен

      await _exerciseService.saveWorkout(
        token,
        _workoutNameController.text,
        _selectedExercises,
      );

      Navigator.pop(context); // Закрываем страницу после сохранения
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Введите название тренировки и выберите хотя бы одно упражнение.')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создание тренировки'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveWorkout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Введите название тренировки',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _workoutNameController,
              decoration: const InputDecoration(
                hintText: 'Название тренировки',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Выберите упражнения:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              onPressed: () async {
                final List<Map<String, dynamic>> exercises = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExerciseAddPage(muscleGroup: 'Chest'), // Пример для группы "Грудь"
                  ),
                );
                if (exercises != null) {
                  setState(() {
                    _selectedExercises.addAll(exercises);
                  });
                }
              },
              child: const Text('Добавить новое упражнение +'),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _selectedExercises.length,
                itemBuilder: (context, index) {
                  final exercise = _selectedExercises[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(exercise['name']),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          setState(() {
                            _selectedExercises.removeAt(index);
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
