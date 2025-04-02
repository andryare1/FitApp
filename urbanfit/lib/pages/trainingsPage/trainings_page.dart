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
    return ListView.builder(
      itemCount: trainings.length,
      itemBuilder: (context, index) {
        final training = trainings[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(training.name),
            subtitle: Text(
              _formatDate(training.createdAt),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _navigateToTrainingDetails(context, training.id),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
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
}