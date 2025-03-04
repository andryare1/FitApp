import 'package:flutter/material.dart';
import 'package:urbanfit/services/exercise_service.dart';

class ExerciseListPage extends StatefulWidget {
  final String muscleGroup;
  const ExerciseListPage({super.key, required this.muscleGroup});

  @override
  _ExerciseListPageState createState() => _ExerciseListPageState();
}

class _ExerciseListPageState extends State<ExerciseListPage> {
  final ExerciseService _exerciseService = ExerciseService();
  late Future<List<Map<String, dynamic>>> _exercisesFuture;

  @override
  void initState() {
    super.initState();
    _exercisesFuture =
        _exerciseService.getExercisesByMuscleGroup(widget.muscleGroup);
  }

String getMuscleGroupName(dynamic muscleGroup) {
  if (muscleGroup is String) {
    // Если передана строка на английском
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
    // Если передан ID группы
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
  return 'Неизвестная группа'; // на случай, если тип не соответствует
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getMuscleGroupName(widget.muscleGroup)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Вернуться назад
          },
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _exercisesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка загрузки: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Нет упражнений'));
          }

          final exercises = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                  child: InkWell(
                    onTap: () {
                      // // Переход на страницу деталей
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => ExerciseDetailPage(exercise: exercise),
                      //   ),
                      // );
                    },
                    child: Row(
                      children: [
                        // Изображение упражнения с логикой ошибки
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomLeft: Radius.circular(10),
                          ),
                          child: Image.asset(
                            'assets/exercises/${exercise['image']}',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/error.png',
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                        // Текстовое описание
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
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Icon(Icons.fitness_center,
                                        size: 16, color: Colors.purple),
                                    const SizedBox(width: 5),
                                    Text(
                                      getMuscleGroupName(
                                          exercise["muscleGroup"]),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.purple,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
