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
        _exercisesFuture =
            _exerciseService.getExercisesByMuscleGroup(widget.muscleGroup, token);
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
        case 'Chest': return 'Грудь';
        case 'Back': return 'Спина';
        case 'Shoulders': return 'Плечи';
        case 'Arms': return 'Руки';
        case 'Legs': return 'Ноги';
        case 'Abs': return 'Пресс';
        default: return 'Неизвестная группа';
      }
    } else if (muscleGroup is int) {
      switch (muscleGroup) {
        case 0: return 'Грудь';
        case 1: return 'Спина';
        case 2: return 'Плечи';
        case 3: return 'Руки';
        case 4: return 'Ноги';
        case 5: return 'Пресс';
        default: return 'Неизвестная группа';
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
                style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
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

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final exercise = snapshot.data![index];
              final isSelected = _selectedExercises.any((e) => e['id'] == exercise['id']);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: isSelected ? Colors.blue[50] : null,
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      exercise['imageUrl'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.error),
                    ),
                  ),
                  title: Text(exercise['name']),
                  subtitle: Text(getMuscleGroupName(exercise['muscleGroup'])),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleExerciseSelection(exercise),
                  ),
                  onTap: () => _toggleExerciseSelection(exercise),
                ),
              );
            },
          );
        },
      ),
    );
  }
}