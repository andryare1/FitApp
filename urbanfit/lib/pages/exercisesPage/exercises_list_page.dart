import 'package:flutter/material.dart';
import 'package:urbanfit/pages/exercisesPage/exercises_detail_page.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getMuscleGroupName(widget.muscleGroup)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
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
            padding: const EdgeInsets.all(8), 
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 4), 
                child: Card(
                  color: Colors.white, 
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(10), 
                  ),
                  elevation: 1, 
                  margin: EdgeInsets.zero, 
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ExerciseDetailPage(exercise: exercise),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                              10), 
                          child: Image.network(
                            exercise['imageUrl'],
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
                              ],
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child:
                              Icon(Icons.arrow_forward_ios, color: Colors.grey),
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
