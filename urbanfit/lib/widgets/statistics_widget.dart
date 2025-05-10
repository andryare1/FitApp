import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:urbanfit/services/statistics_service.dart';

class StatisticsWidget extends StatefulWidget {
  const StatisticsWidget({Key? key}) : super(key: key);

  @override
  _StatisticsWidgetState createState() => _StatisticsWidgetState();
}

class _StatisticsWidgetState extends State<StatisticsWidget> {
  final StatisticsService _statisticsService = StatisticsService();
  bool _isLoading = true;
  Map<String, dynamic>? _userStats;
  List<Map<String, dynamic>>? _muscleGroupStats;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final userStats = await _statisticsService.getUserStatistics();
      final muscleGroupStats = await _statisticsService.getMuscleGroupStats();

      if (mounted) {
        setState(() {
          _userStats = userStats;
          _muscleGroupStats = muscleGroupStats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки статистики: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  String getMuscleGroupName(String muscleGroup) {
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
        return 'Нет данных';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 16.0), // Уменьшенные отступы
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 16),
          _buildMuscleGroupChart(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
  return GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 10, // Уменьшил отступы между карточками
    crossAxisSpacing: 10,
    childAspectRatio: 1.3, // Уменьшил соотношение сторон (было 1.5)
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
      children: [
        _buildSummaryCard(
          'Всего тренировок',
          _userStats?['totalTrainings']?.toString() ?? '0',
          Icons.fitness_center,
          Colors.blue,
        ),
        _buildSummaryCard(
          'Дней с тренировками',
          _userStats?['trainingDays']?.toString() ?? '0',
          Icons.calendar_today,
          Colors.green,
        ),
        _buildSummaryCard(
          'Выполнено упражнений',
          _userStats?['completedExercises']?.toString() ?? '0',
          Icons.check_circle,
          Colors.teal,
        ),
        _buildSummaryCard(
          'Пропущено упражнений',
          _userStats?['skippedExercises']?.toString() ?? '0',
          Icons.skip_next,
          Colors.orange,
        ),
        _buildSummaryCard(
          'Процент выполнения',
          '${_userStats?['completionRate']?.toString() ?? '0'}%',
          Icons.percent,
          Colors.purple,
        ),
        _buildSummaryCard(
          'Среднее кол-во подходов',
          _userStats?['averageSetsPerTraining']?.toString() ?? '0',
          Icons.repeat,
          Colors.indigo,
        ),
        _buildSummaryCard(
          'Всего упражнений',
          _userStats?['totalExercises']?.toString() ?? '0',
          Icons.format_list_numbered,
          Colors.deepPurple,
        ),
        _buildSummaryCard(
          'Любимая группа',
          getMuscleGroupName(_userStats?['favoriteMuscleGroup']),
          Icons.star,
          Colors.amber,
        ),
      ],
  );
}

 Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(10), // Уменьшил отступы внутри карточки
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Важно: ограничиваем размер по содержимому
        children: [
          Icon(icon, color: color, size: 24), // Уменьшил иконку
          const SizedBox(height: 8), // Уменьшил отступ
          Flexible( // Добавил Flexible для текста
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12, // Уменьшил размер шрифта
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2, // Ограничил количество строк
              overflow: TextOverflow.ellipsis, // Добавил многоточие если не помещается
            ),
          ),
          const SizedBox(height: 8), // Уменьшил отступ
          Text(
            value,
            style: TextStyle(
              fontSize: 16, // Уменьшил размер шрифта
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildMuscleGroupChart() {
  if (_muscleGroupStats == null || _muscleGroupStats!.isEmpty) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center,
              size: 40,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Нет данных по группам мышц',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Выполните несколько тренировок, чтобы увидеть статистику',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  final data = _muscleGroupStats!;
  final total = data.fold<double>(0, (sum, item) => sum + (item['count'] as int).toDouble());

  final muscleGroupColors = {
    'Chest': Colors.redAccent,
    'Back': Colors.blueAccent,
    'Shoulders': Colors.greenAccent,
    'Arms': Colors.orangeAccent,
    'Legs': Colors.purpleAccent,
    'Abs': Colors.tealAccent,
  };

  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.symmetric(horizontal: 8.0),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // Центрируем всю колонку
        children: [ // Убрали crossAxisAlignment.start
          const Text(
            'Распределение по группам мышц',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sections: data.map((item) {
                  final muscleGroup = item['muscleGroup'] as String;
                  final percentage = (item['count'] as int) / total * 100;
                  return PieChartSectionData(
                    color: muscleGroupColors[muscleGroup] ?? Colors.grey,
                    value: item['count'].toDouble(),
                    title: '${percentage.toStringAsFixed(1)}%',
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center( // Явное центрирование контейнера с легендой
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center, // Центрирование внутри Wrap
              children: data.map((item) {
                final muscleGroup = item['muscleGroup'] as String;
                final color = muscleGroupColors[muscleGroup] ?? Colors.grey;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      getMuscleGroupName(muscleGroup),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ),
  );
}
}