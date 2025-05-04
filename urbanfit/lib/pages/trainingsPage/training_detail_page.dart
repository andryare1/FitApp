import 'package:flutter/material.dart';
import 'package:urbanfit/models/training.dart';
import 'package:urbanfit/models/training_exercise.dart';
import 'package:urbanfit/pages/trainingsPage/exerciseScreens/exercise_params_dialog.dart';
import 'package:urbanfit/pages/trainingsPage/exerciseScreens/muscle_group_selection_page.dart';
import 'package:urbanfit/pages/trainingsPage/startTrainingPage/training_start_page.dart';
import 'package:urbanfit/services/training_service.dart';

class TrainingDetailsPage extends StatefulWidget {
  final int trainingId;

  const TrainingDetailsPage({Key? key, required this.trainingId})
      : super(key: key);

  @override
  _TrainingDetailsPageState createState() => _TrainingDetailsPageState();
}

class _TrainingDetailsPageState extends State<TrainingDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _trainingService = TrainingService();
  late Future<Training> _trainingFuture;
  List<Map<String, dynamic>> _exercises = [];
  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _trainingFuture =
        _trainingService.getTrainingWithExercises(widget.trainingId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактирование'),
        actions: [
          IconButton(
            icon: _isSaving
                ? const CircularProgressIndicator()
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveTraining,
          ),
        ],
      ),
      body: FutureBuilder<Training>(
        future: _trainingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final training = snapshot.data!;

          if (!_isInitialized) {
            _nameController.text = training.name;
            _exercises = (training.exercises)
                .map((e) => {
                      'id': e.id,
                      'exerciseId': e.exerciseId,
                      'name': e.exerciseName,
                      'sets': e.sets,
                      'reps': e.reps,
                      'weight': e.weight,
                      'orderIndex': e.orderIndex,
                      'imageUrl': e.imageUrl ?? '',
                    })
                .toList();
            _isInitialized = true;
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Название тренировки',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите название тренировки';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(child: _buildExercisesList()),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить упражнение'),
                  onPressed: () => _navigateToExerciseGroups(context),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Начать тренировку'),
                    onPressed: () => _startTraining(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExercisesList() {
    if (_exercises.isEmpty) {
      return const Center(
          child: Text('Нет добавленных упражнений',
              style: TextStyle(color: Colors.grey)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Упражнения:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Expanded(
          child: ReorderableListView(
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _exercises.removeAt(oldIndex);
                _exercises.insert(newIndex, item);
                for (var i = 0; i < _exercises.length; i++) {
                  _exercises[i] = {..._exercises[i], 'orderIndex': i};
                }
              });
            },
            children: List.generate(_exercises.length, (index) {
              final exercise = _exercises[index];
              return _buildExerciseCard(exercise, index);
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise, int index) {
    return Dismissible(
      key: ValueKey(exercise['exerciseId']),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
            color: Colors.red, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete, color: Colors.white),
            SizedBox(width: 8),
            Text('Удалить',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      onDismissed: (_) {
        setState(() {
          _exercises
              .removeWhere((e) => e['exerciseId'] == exercise['exerciseId']);
        });
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              // Контейнер для изображения
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: exercise['imageUrl'] != null &&
                          exercise['imageUrl']!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(exercise['imageUrl']!),
                          fit: BoxFit.cover,
                          onError: (_, __) => const Icon(Icons
                              .error), // Обработчик ошибок загрузки изображения
                        )
                      : null,
                  color: Colors.grey[200],
                ),
                child: (exercise['imageUrl'] == null ||
                        exercise['imageUrl']!.isEmpty)
                    ? const Icon(Icons
                        .fitness_center) // Дефолтная иконка, если нет изображения
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exercise['name'] ?? 'Без названия',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                        '${exercise['sets']}x${exercise['reps']} ${exercise['weight']}кг',
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editExerciseParams(context, exercise),
              ),
              ReorderableDragStartListener(
                  index: index, child: const Icon(Icons.drag_handle)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToExerciseGroups(BuildContext context) async {
    final selectedExercises = await Navigator.push<List<Map<String, dynamic>>>(
      context,
      MaterialPageRoute(builder: (_) => MuscleGroupsSelectionPage()),
    );

    if (selectedExercises != null && selectedExercises.isNotEmpty) {
      setState(() {
        final newExercises = selectedExercises
            .where((ex) => !_exercises.any((e) => e['exerciseId'] == ex['id']))
            .map((e) => {
                  'exerciseId': e['id'],
                  'name': e['name'],
                  'sets': e['sets'] ?? 3,
                  'reps': e['reps'] ?? 10,
                  'weight': (e['weight'] as num?)?.toDouble() ?? 0.0,
                  'comment': e['comment'] ?? '',
                  'orderIndex': _exercises.length,
                  'imageUrl': e['imageUrl'] ?? '',
                })
            .toList();

        _exercises.addAll(newExercises);
      });
    }
  }

  Future<void> _editExerciseParams(
      BuildContext context, Map<String, dynamic> exercise) async {
    final updatedExercise = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ExerciseParamsDialog(exercise: exercise),
    );

    if (updatedExercise != null) {
      setState(() {
        final index = _exercises
            .indexWhere((e) => e['exerciseId'] == exercise['exerciseId']);
        if (index != -1) {
          _exercises[index] = {..._exercises[index], ...updatedExercise};
        }
      });
    }
  }

  Future<void> _saveTraining() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _trainingService.updateTraining(
        trainingId: widget.trainingId,
        name: _nameController.text,
        exercises: _exercises
            .map((e) => TrainingExercise(
                  id: e['id'] ?? 0,
                  exerciseId: e['exerciseId'] ?? 0,
                  exerciseName: e['name'] ?? '',
                  sets: e['sets'] ?? 3,
                  reps: e['reps'] ?? 10,
                  weight: e['weight']?.toDouble() ?? 0.0,
                  orderIndex: e['orderIndex'] ?? 0,
                  imageUrl: e['imageUrl'] ?? '',
                ))
            .toList(),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // void _startTraining(BuildContext context) {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => TrainingStartPage(
  //         trainingId: widget.trainingId,
  //         exercises: _exercises,
  //       ),
  //     ),
  //   );
  // }

  void _startTraining(BuildContext context) async {
    final training = await _trainingFuture;

    if (_hasChanges(training)) {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: const Row(
            children: [
              SizedBox(width: 8),
              Text('Вы внесли изменения'),
            ],
          ),
          content: const Text(
            'Сохранить и начать тренировку?',
            style: TextStyle(fontSize: 16),
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
              ),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Сохранить и начать'),
            ),
          ],
        ),
      );

      if (shouldSave == true) {
        await _saveTraining();
      } else {
        return;
      }
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingStartPage(
          trainingId: widget.trainingId,
          exercises: _exercises,
        ),
      ),
    );
  }

  bool _hasChanges(Training training) {
    if (_nameController.text != training.name) return true;
    final originalExercises = training.exercises;

    if (_exercises.length != originalExercises.length) return true;

    for (int i = 0; i < _exercises.length; i++) {
      final local = _exercises[i];
      final server = originalExercises.firstWhere(
          (e) => e.exerciseId == local['exerciseId'],
          orElse: () => TrainingExercise(
                id: -1,
                exerciseId: -1,
              ));

      if (local['sets'] != server.sets ||
          local['reps'] != server.reps ||
          local['weight'] != server.weight ||
          local['orderIndex'] != server.orderIndex ||
          local['name'] != server.exerciseName) {
        return true;
      }
    }

    return false;
  }
}
