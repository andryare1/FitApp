import 'dart:async';
import 'package:flutter/material.dart';
import 'package:urbanfit/pages/trainingsPage/startTrainingPage/training_result_page.dart';
import 'package:urbanfit/services/auth_service.dart';
import 'package:urbanfit/services/exercise_service.dart';
import 'package:urbanfit/services/session_service.dart';
import 'package:video_player/video_player.dart';

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
  final _sessionService = SessionService();
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  late int _currentProgressId;
  int? _sessionId; // ID сессии тренировки

  bool _isVideoInitialized = false;
  bool _hasError = false;
  Timer? _loadTimeoutTimer;
  late VideoPlayerController _videoController;

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
  
  Future<void> _initializeVideo() async {
    final videoUrl = _exercises[_currentExerciseIndex]['videoUrl']?.toString();

    if (videoUrl == null || videoUrl.isEmpty) {
      if (mounted) setState (() => _hasError = true);
      return;
    }
_startTimeoutTimer();
    try {
_videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))..addListener(_videoListener);
await _videoController.initialize();
 _cancelTimer();
    _videoController.setLooping(true);
    _videoController.play();

    if (mounted) setState(() => _isVideoInitialized = true);
  } catch (e) {
    debugPrint('Error initializing video: $e');
    _cancelTimer();
    if (mounted) setState(() => _hasError = true);
    await _videoController.dispose();
    }
  }
  void _videoListener() {
    if (_videoController.value.hasError && mounted) {
      setState(() => _hasError = true);
      _cancelTimer();
    }
  }

   void _startTimeoutTimer() {
    _loadTimeoutTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_isVideoInitialized && !_hasError) {
        setState(() => _hasError = true);
      }
    });
  }

  void _cancelTimer() {
    _loadTimeoutTimer?.cancel();
    _loadTimeoutTimer = null;
  }
  Future<void> _createTrainingSession() async {
    final token = await _authService.getToken();
    if (token == null) return;

    try {
      final sessionId =
          await _sessionService.startTrainingSession(widget.trainingId, token);
      if (!mounted) return;
      setState(() {
        _sessionId = sessionId;
      });
      _startExerciseProgress();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось создать сессию тренировки')),
      );
    }
  }

  Future<bool> _onWillPop() async {
    // Показать диалог перед выходом
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Выход из тренировки'),
          content: const Text(
              'При выходе прогресс будет утерян. Вы уверены, что хотите выйти?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Отменить выход
              },
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                // Удаление данных сессии из базы данных
                await _sessionService.deleteTrainingSession(_sessionId!);
                Navigator.of(context).pop(true); // Подтвердить выход
              },
              child: const Text('Выйти'),
            ),
          ],
        );
      },
    );

    // Возвращаем true или false в зависимости от того, подтвердил ли пользователь выход
    return shouldExit ?? false;
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
      final response = await _sessionService.completeTraining(
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
    _videoController.removeListener(_videoListener);
    _videoController.dispose();
    _cancelTimer();
    _timer.cancel();
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercise = _exercises[_currentExerciseIndex];
    return WillPopScope(
      onWillPop: _onWillPop, // Использование уже существующего метода
      child: GestureDetector(
        onTap: () {
          // Скрыть клавиатуру при касании вне поля ввода
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(            
                    borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(aspectRatio: 16/9, child: _buildVideoWidget(),),
                ),
                const SizedBox(height: 16),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                      begin: 0,
                      end: (_currentExerciseIndex +
                              (_currentSet - 1) / _totalSets) /
                          _exercises.length),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, child) {
                    return LinearProgressIndicator(value: value);
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Упражнение: ${exercise['name']}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
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
                          backgroundColor:
                              const Color.fromARGB(255, 83, 174, 86),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding:
                              EdgeInsets.zero, // Убираем внутренние отступы
                          alignment: Alignment.center, // Центрируем контент
                          minimumSize:
                              const Size(56, 56), // Четко задаем размер
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
                        child: const Text('Пропустить подход',
                            style: TextStyle(fontSize: 12)),
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
                        child: const Text(
                          'Пропустить упражнение',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


   Widget _buildVideoWidget() {
  if (_hasError) return _buildErrorPlaceholder();
  if (!_isVideoInitialized) return _buildLoadingIndicator();

  return AspectRatio(
    aspectRatio: _videoController.value.aspectRatio,
    child: VideoPlayer(_videoController),
  );
}

  Widget _buildLoadingIndicator() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              'Видео недоступно',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _retryVideoLoading,
              child: const Text('Попробовать снова'),
            ),
          ],
        ),
      ),
    );
  }

    void _retryVideoLoading() {
    if (mounted) {
      setState(() {
        _hasError = false;
        _isVideoInitialized = false;
      });
      _initializeVideo();
    }
  }
}
