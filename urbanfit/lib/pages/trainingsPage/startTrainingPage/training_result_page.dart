import 'package:flutter/material.dart';

class TrainingResultPage extends StatelessWidget {
  final int elapsedTime;
  final List<Map<String, dynamic>> stats;
  final double completionPercentage;

  const TrainingResultPage({
    Key? key,
    required this.elapsedTime,
    required this.stats,
    required this.completionPercentage,
  }) : super(key: key);

  String _formatTime(int seconds) {
    final d = Duration(seconds: seconds);
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    int skippedExercises = stats.where((e) => e['skipped'] == true).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Итоги тренировки'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Выйти',
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Общее время: ${_formatTime(elapsedTime)}',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 10),
          Text(
            'Процент выполнения: ${completionPercentage.toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 10),
          Text(
            'Пропущено упражнений: $skippedExercises',
            style: const TextStyle(fontSize: 18),
          ),
          const Divider(height: 30),
          const Text(
            'Упражнения:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // Упражнения
          ...stats.map((exercise) {
            final int sets = exercise['sets'];
            final int completed = exercise['completed'];
            final double percent = sets == 0 ? 0 : (completed / sets) * 100;
            final String? imageUrl = exercise['imageUrl'];

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: ListTile(
                contentPadding: const EdgeInsets.all(8),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.fitness_center, size: 40),
                        )
                      : const Icon(Icons.fitness_center, size: 40),
                ),
                title: Text(exercise['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  exercise['skipped']
                      ? 'Пропущено'
                      : 'Выполнено: $completed / $sets (${percent.toStringAsFixed(1)}%)',
                ),
                trailing: exercise['skipped']
                    ? const Icon(Icons.cancel, color: Colors.red)
                    : Icon(
                        percent == 100 ? Icons.check_circle : Icons.check_circle_outline,
                        color: percent == 100 ? Colors.green : Colors.orange,
                      ),
              ),
            );
          }),
        ],
      ),
    );
  }
}