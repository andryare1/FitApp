import 'package:flutter/material.dart';
import 'package:urbanfit/models/training.dart';
import 'package:urbanfit/pages/trainingsPage/create_training_page.dart';
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
  return ListView.separated( // Используем ListView.separated вместо builder
    padding: const EdgeInsets.symmetric(vertical: 8),
    itemCount: trainings.length,
    separatorBuilder: (context, index) => const SizedBox(height: 8), // Отступ между элементами
    itemBuilder: (context, index) {
      final training = trainings[index];
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Dismissible(
            key: ValueKey(training.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
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
            onDismissed: (direction) => _deleteTraining(training.id),
            child: Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2, // Легкая тень для глубины
              child: InkWell( // Добавляем эффект нажатия
                borderRadius: BorderRadius.circular(12),
                onTap: () => _navigateToTrainingDetails(context, training.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    title: Text(
                      training.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _formatDate(training.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).primaryColor,
                      size: 28,
                    ),
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
    // TODO: Реализовать переход к деталям тренировки
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Открываем тренировку $trainingId')),
    );
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
}