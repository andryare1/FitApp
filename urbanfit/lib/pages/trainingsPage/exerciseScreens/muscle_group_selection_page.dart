import 'package:flutter/material.dart';
import 'package:urbanfit/pages/trainingsPage/exerciseScreens/exercises_list_page.dart';


final List<Map<String, String>> muscleGroups = [
  {'name': 'Грудь', 'image': 'assets/muscleGroup/chest.png'},
  {'name': 'Спина', 'image': 'assets/muscleGroup/back.png'},
  {'name': 'Плечи', 'image': 'assets/muscleGroup/shoulders.png'},
  {'name': 'Руки', 'image': 'assets/muscleGroup/arms.png'},
  {'name': 'Ноги', 'image': 'assets/muscleGroup/legs.png'},
  {'name': 'Пресс', 'image': 'assets/muscleGroup/abs.png'},
];

final Map<String, String> muscleGroupMapping = {
  'Грудь': 'Chest',
  'Спина': 'Back',
  'Плечи': 'Shoulders',
  'Руки': 'Arms',
  'Ноги': 'Legs',
  'Пресс': 'Abs',
};

class MuscleGroupsSelectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Выберите группу мышц')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.9,
        ),
        itemCount: muscleGroups.length,
        itemBuilder: (context, index) {
          final group = muscleGroups[index];
          return InkWell(
            onTap: () async {
              final exercises = await Navigator.push<List<Map<String, dynamic>>>(
                context,
                MaterialPageRoute(
                  builder: (context) => ExerciseListPageForTrainings(
                    muscleGroup: muscleGroupMapping[group['name']]!,
                  ),
                ),
              );
              
              if (exercises != null && exercises.isNotEmpty) {
                Navigator.pop(context, exercises);
              }
            },
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    group['image']!,
                    width: 80,
                    height: 80,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    group['name']!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}