class TrainingExercise {
  final int id;
  final int exerciseId;
  final String? exerciseName;
  final int sets;
  final int reps;
  final double weight;
  final int orderIndex;
  final String? imageUrl;

  TrainingExercise({
    required this.id,
    required this.exerciseId,
    this.exerciseName,
    this.sets = 3,
    this.reps = 10,
    this.weight = 0,
    this.orderIndex = 0,

    this.imageUrl,
  });

  factory TrainingExercise.fromJson(Map<String, dynamic> json) {
    return TrainingExercise(
      id: json['id'],
      exerciseId: json['exerciseId'],
      exerciseName: json['exerciseName'],
      sets: json['sets'],
      reps: json['reps'],
      weight: json['weight']?.toDouble() ?? 0,
      orderIndex: json['orderIndex'],
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'orderIndex': orderIndex, // Оставляем orderIndex
      'imageUrl': imageUrl,
    };
  }
}
