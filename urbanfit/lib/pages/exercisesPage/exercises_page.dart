import 'package:flutter/material.dart';
import 'package:urbanfit/pages/exercisesPage/exercises_detail_page.dart';
import 'package:urbanfit/pages/exercisesPage/exercises_list_page.dart';
import 'package:urbanfit/services/exercise_service.dart';

final Map<String, String> muscleGroupMapping = {
  'Грудь': 'Chest',
  'Спина': 'Back',
  'Плечи': 'Shoulders',
  'Руки': 'Arms',
  'Ноги': 'Legs',
  'Пресс': 'Abs',
};

class ExercisesPage extends StatefulWidget {
  const ExercisesPage({super.key});

  @override
  _ExercisesPageState createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  final ExerciseService _exerciseService = ExerciseService();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
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

  void _onSearchTextChanged(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults
            .clear(); 
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _exerciseService.searchExercises(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
      });
    }
  }

  void _cancelSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _searchResults.clear();
    });
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
        title: _isSearching
            ? SizedBox(
                height: 40,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Поиск',
                          filled: true,
                          fillColor: const Color.fromARGB(255, 237, 239, 241),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 0),
                        ),
                        onChanged: _onSearchTextChanged,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel),
                      onPressed: _cancelSearch,
                    ),
                  ],
                ),
              )
            : const Text('Упражнения'),
        centerTitle: true,
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 5),
          child: _isSearching
              ? _searchResults.isEmpty
                  ? _buildNoResultsWidget() 
                  : _buildSearchResults()
              : GridView.builder(
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
                        String? mappedMuscleGroup =
                            muscleGroupMapping[group['name']];
                        if (mappedMuscleGroup != null) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ExerciseListPage(
                                      muscleGroup: mappedMuscleGroup)));
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

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(8), 
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final exercise = _searchResults[index];
        return Padding(
          padding: const EdgeInsets.symmetric(
              vertical: 4), 
          child: Card(
            color: Colors.white, 
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), 
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
                          Row(
                            children: [
                              const Icon(Icons.fitness_center,
                                  size: 16, color: Colors.purple),
                              const SizedBox(width: 5),
                              Text(
                                getMuscleGroupName(exercise["muscleGroup"]),
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
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.arrow_forward_ios, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoResultsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          const Text(
            'Ничего не найдено',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Попробуйте изменить запрос',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
