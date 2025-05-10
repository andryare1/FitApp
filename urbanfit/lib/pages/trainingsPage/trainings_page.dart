import 'package:flutter/material.dart';
import 'package:urbanfit/models/training.dart';
import 'package:urbanfit/pages/trainingsPage/create_training_page.dart';
import 'package:urbanfit/pages/trainingsPage/startTrainingPage/training_start_page.dart';
import 'package:urbanfit/pages/trainingsPage/training_detail_page.dart';
import 'package:urbanfit/services/auth_service.dart';
import 'package:urbanfit/services/training_service.dart';

class TrainingsPage extends StatefulWidget {
  const TrainingsPage({Key? key}) : super(key: key);

  @override
  _TrainingsPageState createState() => _TrainingsPageState();
}

class _TrainingsPageState extends State<TrainingsPage> {
  late Future<List<Training>> _trainingsFuture;
  final TrainingService _trainingService = TrainingService();

  @override
  void initState() {
    super.initState();
    _loadTrainings();
  }

  void _loadTrainings() {
     if (!mounted) return;
    setState(() {
      _trainingsFuture = _trainingService.getUserTrainings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои тренировки'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTrainings,
          ),
        ],
      ),
      body: FutureBuilder<List<Training>>(
        future: _trainingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final trainings = snapshot.data ?? [];

          if (trainings.isEmpty) {
            return _buildEmptyState();
          }

          return _buildTrainingsList(trainings);
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _navigateToCreateTraining(context),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Тренировок еще нет',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            child: const Text('Создать тренировку'),
            onPressed: () => _navigateToCreateTraining(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingsList(List<Training> trainings) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: trainings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final training = trainings[index];
        final double percent = training.completionPercentage;
        final Color progressColor = percent < 20
            ? Colors.red
            : percent < 80
                ? Colors.orange
                : Colors.green;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Dismissible(
            key: ValueKey(training.id),
            direction: DismissDirection.horizontal,
            background: Container(
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Начать',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            secondaryBackground: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.delete, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Удалить',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            onDismissed: (direction) {
              if (direction == DismissDirection.startToEnd) {
                _startTraining(training.id);
              } else if (direction == DismissDirection.endToStart) {
                _deleteTraining(training.id);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _navigateToTrainingDetails(context, training.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    title: Text(
                      training.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _formatDate(training.createdAt),
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    trailing: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 55,
                          height: 55,
                          child: CircularProgressIndicator(
                            value: percent.clamp(0, 100) / 100,
                            strokeWidth: 4,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(progressColor),
                            backgroundColor: Colors.grey.shade300,
                          ),
                        ),
                        Text(
                          '${percent.toInt()}%',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void _navigateToCreateTraining(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateTrainingPage()),
    ).then((_) => _loadTrainings());
  }

  void _navigateToTrainingDetails(BuildContext context, int trainingId) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => TrainingDetailsPage(trainingId: trainingId)),
    ).then((_) => _loadTrainings());
  }

  void _deleteTraining(int trainingId) async {
    try {
      await _trainingService.deleteTraining(trainingId);
      _loadTrainings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при удалении: $e')),
      );
    }
  }

  void _startTraining(int trainingId) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось получить токен')),
        );
        return;
      }
      final training =
          await _trainingService.getTrainingWithExercises(trainingId);

      // Преобразуем список упражнений в List<Map<String, dynamic>>
      final exercises = training.exercises.map((exercise) {
        return {
          'id': exercise.id,
          'exerciseId': exercise.exerciseId,
          'name': exercise.exerciseName,
          'imageUrl': exercise.imageUrl,
          'videoUrl': exercise.videoUrl,
          'sets': exercise.sets,
          'reps': exercise.reps,
          'weight': exercise.weight,
          'orderIndex': exercise.orderIndex,
        };
      }).toList();

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TrainingStartPage(
            trainingId: trainingId,
            exercises: exercises, // Передаем список Map
          ),
        ),
      ).then((_) => _loadTrainings());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при загрузке упражнений: $e')),
      );
    }
  }
}
