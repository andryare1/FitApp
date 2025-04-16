import 'dart:async';
import 'package:flutter/material.dart';
import 'package:urbanfit/pages/trainingsPage/startTrainingPage/training_result_page.dart';
import 'package:urbanfit/services/auth_service.dart';
import 'package:urbanfit/services/exercise_service.dart';

class TrainingStartPage extends StatefulWidget {
  final int trainingId;
  final List<Map<String, dynamic>> exercises;

  const TrainingStartPage({
    Key? key,
    required this.trainingId,
    required this.exercises,
  }) : super(key: key);

  @override
  _TrainingStartPageState createState() => _TrainingStartPageState();
}

class _TrainingStartPageState extends State<TrainingStartPage> {
  late List<Map<String, dynamic>> _exercises;
  late int _currentExerciseIndex;
  late int _currentSet;
  bool _isTimerRunning = false;
  late Timer _timer;
  int _elapsedTime = 0;
  int _totalSets = 0;
  int _completedSets = 0;
  String _muscleGroup = '';
  final _authService = AuthService();
  final _exerciseService = ExerciseService();
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  late int _currentProgressId;
  int? _sessionId; // ID сессии тренировки

  final List<Map<String, dynamic>> _exerciseStats = [];

  @override
  void initState() {
    super.initState();
    _exercises = List.from(widget.exercises);
    _currentExerciseIndex = 0;
    _currentSet = 1;
    _totalSets = _exercises[_currentExerciseIndex]['sets'];
    _createTrainingSession(); // создаем сессию
    _loadMuscleGroup();
    _startTimer();
  }

  Future<void> _createTrainingSession() async {
    final token = await _authService.getToken();
    if (token == null) return;

    try {
      final sessionId =
          await _exerciseService.startTrainingSession(widget.trainingId, token);
      if (!mounted) return;
      setState(() {
        _sessionId = sessionId;
      });
      _startExerciseProgress(); // начинаем первый прогресс только после создания сессии
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось создать сессию тренировки')),
      );
    }
  }

  Future<void> _loadMuscleGroup() async {
    final token = await _authService.getToken();
    if (token == null) return;
    final exerciseId = _exercises[_currentExerciseIndex]['exerciseId'];
    final muscleGroupRaw =
        await _exerciseService.getMuscleGroupByExerciseId(exerciseId, token);
    if (!mounted) return;
    setState(() {
      _muscleGroup = getMuscleGroupName(muscleGroupRaw);
    });
  }

  Future<void> _startExerciseProgress() async {
    final token = await _authService.getToken();
    if (token == null || _sessionId == null) {
      return;
    }

    final exerciseId = _exercises[_currentExerciseIndex]['exerciseId'];
    final setsPlanned = _exercises[_currentExerciseIndex]['sets'];

    try {
      final progressId = await _exerciseService.startExerciseProgress(
        widget.trainingId,
        exerciseId,
        setsPlanned,
        token,
        sessionId: _sessionId!,
      );
      if (!mounted) return;
      setState(() {
        _currentProgressId = progressId;
      });
    } catch (e) {
      // Логирование ошибок
      print("Error occurred while starting exercise progress: $e");
    }
  }

  Future<void> _completeExercise({bool skipped = false}) async {
    final token = await _authService.getToken();
    if (token == null || _sessionId == null) return;
    await _exerciseService.completeExerciseProgress(
      _currentProgressId,
      _completedSets,
      skipped,
      token,
      sessionId: _sessionId!,
    );
  }

  void _startTimer() {
    _isTimerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedTime++);
    });
  }

  void _pauseTimer() {
    _timer.cancel();
    setState(() => _isTimerRunning = false);
  }

  void _resumeTimer() {
    _startTimer();
  }

  void _nextSet() {
    if (_currentSet < _totalSets) {
      setState(() => _currentSet++);
    } else {
      _nextExercise();
    }
  }

  void _skipSet() {
    _nextSet();
  }

  void _nextExercise({bool skipped = false}) async {
    await _completeExercise(skipped: skipped);
    _exerciseStats.add({
      'name': _exercises[_currentExerciseIndex]['name'],
      'sets': _totalSets,
      'completed': _completedSets,
      'skipped': skipped,
      'imageUrl': _exercises[_currentExerciseIndex]['imageUrl'],
    });
    if (_currentExerciseIndex < _exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _currentSet = 1;
        _completedSets = 0;
        _totalSets = _exercises[_currentExerciseIndex]['sets'];
      });
      _loadMuscleGroup();
      _startExerciseProgress();
      _weightController.clear();
      _repsController.clear();
    } else {
      _finishTraining();
    }
  }

  void _addSetData() {
    if (_weightController.text.isEmpty || _repsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите вес и повторения')),
      );
      return;
    }

     if (double.tryParse(_weightController.text) == null ||
        int.tryParse(_repsController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите корректные значения')),
      );
      return;
    }
    
    setState(() {
      _completedSets++;
      _weightController.clear();
      _repsController.clear();
    });
    _nextSet();
  }

  void _finishTraining() async {
    // Останавливаем таймер
    _timer.cancel();

    // Отправляем запрос на сервер для завершения тренировки и обновления процента
    final token = await _authService.getToken();
    if (token == null || _sessionId == null) return;

    try {
      // Вызов эндпоинта для завершения тренировки
      final response = await _exerciseService.completeTraining(
        widget.trainingId,
        token,
        sessionId: _sessionId!,
      );

      // Проверка успешного ответа от сервера
      if (response['completionPercentage'] != null) {
        // Перенаправляем на страницу результатов с данными тренировки
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TrainingResultPage(
              elapsedTime: _elapsedTime,
              stats: _exerciseStats,
              completionPercentage: response['completionPercentage'],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при завершении тренировки')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при завершении тренировки')),
      );
    }
  }

  String getMuscleGroupName(dynamic muscleGroup) {
    switch (muscleGroup) {
      case 0:
      case 'Chest':
        return 'Грудь';
      case 1:
      case 'Back':
        return 'Спина';
      case 2:
      case 'Shoulders':
        return 'Плечи';
      case 3:
      case 'Arms':
        return 'Руки';
      case 4:
      case 'Legs':
        return 'Ноги';
      case 5:
      case 'Abs':
        return 'Пресс';
      default:
        return 'Неизвестно';
    }
  }

  String _formatTime(int seconds) {
    final d = Duration(seconds: seconds);
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}$m:$s';
  }

  @override
  void dispose() {
    _timer.cancel();
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercise = _exercises[_currentExerciseIndex];
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${_currentExerciseIndex + 1}/${_exercises.length} $_muscleGroup'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
                child: Text(
              _formatTime(_elapsedTime),
              style: const TextStyle(fontWeight: FontWeight.bold),
            )),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _isTimerRunning ? _pauseTimer() : _resumeTimer();
        },
        child: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text('Видео упражнения')),
            ),
            const SizedBox(height: 16),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0,
                end: (_currentExerciseIndex + (_currentSet - 1) / _totalSets) /
                    _exercises.length,
              ),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Упражнение: ${exercise['name']}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('Сеты: $_currentSet/$_totalSets'),
            const SizedBox(height: 16),

            // Вес и повторения в одну строку
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    enabled: _isTimerRunning,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      labelText: 'Вес (кг)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _repsController,
                    enabled: _isTimerRunning,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      labelText: 'Повторения',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Кнопка +
                SizedBox(
                  height: 56,
                  width: 56,
                  child: ElevatedButton(
                    onPressed: _isTimerRunning ? _addSetData : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 83, 174, 86),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: EdgeInsets.zero, // Убираем внутренние отступы
                      alignment: Alignment.center, // Центрируем контент
                      minimumSize: const Size(56, 56), // Четко задаем размер
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size:
                          24, // Можно уменьшить или увеличить при необходимости
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Пропустить подход и упражнение
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isTimerRunning ? _skipSet : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Пропустить подход'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isTimerRunning
                        ? () => _nextExercise(skipped: true)
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Пропустить упражнение'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
