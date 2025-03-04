import 'package:flutter/material.dart';
import 'package:urbanfit/pages/exercisesPage/exercises_list_page.dart';

final Map<String, String> muscleGroupMapping = {
  'Грудь': 'Chest',
  'Спина': 'Back',
  'Плечи': 'Shoulders',
  'Руки': 'Arms',
  'Ноги': 'Legs',
  'Пресс': 'Abs',
};

class ExercisesPage extends StatelessWidget {
  const ExercisesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> muscleGroups = [
      {
        'name': 'Грудь',
        'image': 'assets/muscleGroup/chest.png',
      },
      {
        'name': 'Спина',
        'image': 'assets/muscleGroup/back.png',
      },
      {
        'name': 'Плечи',
        'image': 'assets/muscleGroup/shoulders.png',
      },
      {
        'name': 'Руки',
        'image': 'assets/muscleGroup/arms.png',
      },
      {
        'name': 'Ноги',
        'image': 'assets/muscleGroup/legs.png',
      },
      {
        'name': 'Пресс',
        'image': 'assets/muscleGroup/abs.png',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Упражнения'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
            ),
            itemCount: muscleGroups.length,
            itemBuilder: (context, index) {
              final group = muscleGroups[index];
              return GestureDetector(
                onTap: () {
                  String? mappedMuscleGroup = muscleGroupMapping[group['name']];
                  if (mappedMuscleGroup != null) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                ExerciseListPage(muscleGroup: mappedMuscleGroup)));
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          group['image']!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                        Container(
                          color: Colors.black.withOpacity(0.4),
                        ),
                        Text(
                          group['name']!,
                          style: const TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
