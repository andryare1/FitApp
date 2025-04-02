class Exercise {
  final int id;
  final String name;
  final String muscleGroup;
  final String imageUrl;
  int? sets;
  int? reps;
  double? weight;

  Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.imageUrl,
    this.sets,
    this.reps,
    this.weight,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      name: json['name'],
      muscleGroup: json['muscleGroup'],
      imageUrl: json['imageUrl'],
    );
  }
}