import 'package:flutter/material.dart';

class ExerciseDetailPage extends StatelessWidget {
  final Map<String, dynamic> exercise;

  const ExerciseDetailPage({super.key, required this.exercise});

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
        title: Text(exercise['name']),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображение упражнения
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/exercises/${exercise['image']}',
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/error.png',
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Группа мышц
            Text(
              'Группа мышц:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              getMuscleGroupName(exercise['muscleGroup']),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),

            // Описание
            Text(
              'Описание:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              exercise['description'] ?? 'Описание отсутствует',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}