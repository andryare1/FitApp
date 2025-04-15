import 'package:urbanfit/models/training_exercise.dart';

class Training {
  final int id;
  final String name;
  final DateTime createdAt;
  final List<TrainingExercise> exercises;
  final double completionPercentage; // Новое поле

  Training({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.exercises,
    required this.completionPercentage, // В конструкторе
  });

  factory Training.fromJson(Map<String, dynamic> json) {
    return Training(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
      exercises: (json['exercises'] as List?)
              ?.map((e) => TrainingExercise.fromJson(e))
              .toList() ??
          [],
      completionPercentage: (json['completionPercentage'] ?? 0).toDouble(),
    );
  }
}