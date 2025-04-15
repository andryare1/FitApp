class TrainingProgress {
  final int exerciseId;
  final int set;
  final double weight;
  final int reps;

  TrainingProgress({
    required this.exerciseId,
    required this.set,
    required this.weight,
    required this.reps,
  });

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'set': set,
      'weight': weight,
      'reps': reps,
    };
  }
}