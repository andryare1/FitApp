import 'package:flutter/material.dart';
import 'package:urbanfit/services/auth_service.dart';
import 'package:urbanfit/services/exercise_service.dart';

class ExerciseListPageForTrainings extends StatefulWidget {
  final String muscleGroup;
  const ExerciseListPageForTrainings({super.key, required this.muscleGroup});

  @override
  _ExerciseListPageState createState() => _ExerciseListPageState();
}

class _ExerciseListPageState extends State<ExerciseListPageForTrainings> {
  final ExerciseService _exerciseService = ExerciseService();
  final AuthService _authService = AuthService();
  late Future<List<Map<String, dynamic>>> _exercisesFuture;
  final List<Map<String, dynamic>> _selectedExercises = [];

  Future<void> _loadExercises() async {
    final token = await _authService.getToken();
    if (token != null) {
      setState(() {
        _exercisesFuture = _exerciseService.getExercisesByMuscleGroup(
            widget.muscleGroup, token);
      });
    } else {
      print("Ошибка: токен не найден");
    }
  }

  @override
  void initState() {
    super.initState();
    _exercisesFuture = Future.value([]);
    _loadExercises();
  }

  String getMuscleGroupName(dynamic muscleGroup) {
    if (muscleGroup is String) {
      switch (muscleGroup) {
        case 'Chest':
          return 'Грудь';
        case 'Back':
          return 'Спина';
        case 'Shoulders':
          return 'Плечи';
        case 'Arms':
          return 'Руки';
        case 'Legs':
          return 'Ноги';
        case 'Abs':
          return 'Пресс';
        default:
          return 'Неизвестная группа';
      }
    } else if (muscleGroup is int) {
      switch (muscleGroup) {
        case 0:
          return 'Грудь';
        case 1:
          return 'Спина';
        case 2:
          return 'Плечи';
        case 3:
          return 'Руки';
        case 4:
          return 'Ноги';
        case 5:
          return 'Пресс';
        default:
          return 'Неизвестная группа';
      }
    }
    return 'Неизвестная группа';
  }

  void _toggleExerciseSelection(Map<String, dynamic> exercise) {
    setState(() {
      if (_selectedExercises.any((e) => e['id'] == exercise['id'])) {
        _selectedExercises.removeWhere((e) => e['id'] == exercise['id']);
      } else {
        _selectedExercises.add(exercise);
      }
    });
  }

  void _confirmSelection() {
    if (_selectedExercises.isNotEmpty) {
      Navigator.pop(context, _selectedExercises);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите хотя бы одно упражнение')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getMuscleGroupName(widget.muscleGroup)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_selectedExercises.isNotEmpty)
            TextButton(
              onPressed: _confirmSelection,
              child: Text(
                'Готово (${_selectedExercises.length})',
                style: const TextStyle(
                    color: Colors.purple, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _exercisesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Нет упражнений'));
          }

          final exercises = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              final isSelected =
                  _selectedExercises.any((e) => e['id'] == exercise['id']);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Card(
                  color: isSelected ? Colors.blue[50] : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 1,
                  margin: EdgeInsets.zero,
                  child: InkWell(
                    onTap: () => _toggleExerciseSelection(exercise),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            exercise['imageUrl'],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/error.png',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exercise['name'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: isSelected ? Colors.purple : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
