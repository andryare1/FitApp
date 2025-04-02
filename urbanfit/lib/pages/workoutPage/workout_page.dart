import 'package:flutter/material.dart';
import 'package:urbanfit/pages/workoutPage/workout_create_page.dart';
import 'package:urbanfit/services/auth_service.dart'; 
import 'package:urbanfit/services/exercise_service.dart'; 

class WorkoutPage extends StatefulWidget {
  @override
  _WorkoutScreenState createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutPage> {
  final AuthService _authService = AuthService();
  final ExerciseService _exerciseService = ExerciseService();
  List<Map<String, dynamic>> _workouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  // Загружаем тренировки с сервера
  Future<void> _loadWorkouts() async {
    final token = await _authService.getToken();
    if (token == null) {
      // Если нет токена, вывести сообщение об ошибке
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Запрос на сервер для получения тренировок пользователя
    final response = await _exerciseService.getWorkoutsByUser(token);

    setState(() {
      _workouts = response;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои тренировки'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _workouts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('У вас еще нет тренировок!'),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const WorkoutCreationPage()),
                          );
                        },
                        child: const Text('Создать тренировку'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _workouts.length,
                  itemBuilder: (context, index) {
                    final workout = _workouts[index];
                    return WorkoutCard(workout: workout);
                  },
                ),
    );
  }
}



class WorkoutCard extends StatelessWidget {
  final Map<String, dynamic> workout;

  const WorkoutCard({Key? key, required this.workout}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      child: ListTile(
        title: Text(workout['name']),
        subtitle: Text(workout['exercises'].join(', ')),
        trailing: Icon(Icons.arrow_forward),
        onTap: () {
          // Здесь можно добавить логику для перехода к экрану с подробной информацией о тренировке
        },
      ),
    );
  }
}
