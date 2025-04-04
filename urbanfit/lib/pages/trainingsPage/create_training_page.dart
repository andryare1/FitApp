import 'package:flutter/material.dart';
import 'package:urbanfit/models/training_exercise.dart';
import 'package:urbanfit/pages/trainingsPage/exerciseScreens/exercise_params_dialog.dart';
import 'package:urbanfit/pages/trainingsPage/exerciseScreens/muscle_group_selection_page.dart';
import 'package:urbanfit/services/training_service.dart';

class CreateTrainingPage extends StatefulWidget {
  const CreateTrainingPage({Key? key}) : super(key: key);

  @override
  _CreateTrainingPageState createState() => _CreateTrainingPageState();
}

class _CreateTrainingPageState extends State<CreateTrainingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _trainingService = TrainingService();
  final _selectedExercises = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Новая тренировка'),
        actions: [
          IconButton(
            icon: _isSaving
                ? const CircularProgressIndicator()
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveTraining,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
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
              const SizedBox(height: 20),
              Expanded(child: _buildExercisesList()),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Добавить упражнение'),
                onPressed: () => _navigateToExerciseGroups(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExercisesList() {
    if (_selectedExercises.isEmpty) {
      return const Center(
        child: Text(
          'Нет добавленных упражнений',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Добавленные упражнения:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ReorderableListView.builder(
            itemCount: _selectedExercises.length,
            itemBuilder: (context, index) {
              final exercise = _selectedExercises[index];
              return _buildExerciseCard(exercise, index);
            },
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;

                final item = _selectedExercises.removeAt(oldIndex);
                _selectedExercises.insert(newIndex, item);

                for (var i = 0; i < _selectedExercises.length; i++) {
                  _selectedExercises[i]['orderIndex'] = i;
                }
              });
            },
          ),
        ),
      ],
    );
  }

Widget _buildExerciseCard(Map<String, dynamic> exercise, int index) {
  return Dismissible(
    key: ValueKey(exercise['id']),
    direction: DismissDirection.endToStart,
    background: Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'Удалить',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
    onDismissed: (direction) {
      _removeExercise(exercise);
    },
    child: Card(
      key: ValueKey(exercise['id']),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            // Изображение упражнения
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(exercise['imageUrl']),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {
                    // Обработка ошибки загрузки изображения
                  },
                ),
              ),
              child: exercise['imageUrl'] == null || exercise['imageUrl'].isEmpty
                  ? const Icon(Icons.fitness_center)
                  : null,
            ),
            const SizedBox(width: 12),
            // Название и параметры упражнения
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${exercise['sets']}x${exercise['reps']} ${exercise['weight']}кг',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            // Кнопки управления
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editExerciseParams(context, exercise),
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  Future<void> _navigateToExerciseGroups(BuildContext context) async {
    final selectedExercises = await Navigator.push<List<Map<String, dynamic>>>(
      context,
      MaterialPageRoute(
        builder: (context) => MuscleGroupsSelectionPage(),
      ),
    );

    if (selectedExercises != null && selectedExercises.isNotEmpty) {
      setState(() {
        final newExercises = selectedExercises
            .where(
              (ex) => !_selectedExercises.any((e) => e['id'] == ex['id']),
            )
            .toList();

        _selectedExercises.addAll(newExercises.map((e) => {
              ...e,
              'sets': 3,
              'reps': 10,
              'weight': 0.0,
            }));
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
        final index =
            _selectedExercises.indexWhere((e) => e['id'] == exercise['id']);
        if (index != -1) {
          _selectedExercises[index] = updatedExercise;
        }
      });
    }
  }

  void _removeExercise(Map<String, dynamic> exercise) {
    setState(() {
      _selectedExercises.removeWhere((e) => e['id'] == exercise['id']);
    });
  }

  Future<void> _saveTraining() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте хотя бы одно упражнение')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final exercises = _selectedExercises
          .map((e) => TrainingExercise(
                id: 0,
                exerciseId: e['id'],
                exerciseName: e['name'],
                sets: e['sets'] ?? 3,
                reps: e['reps'] ?? 10,
                weight: (e['weight'] as num?)?.toDouble() ?? 0.0,
                orderIndex: _selectedExercises.indexOf(e), // Сохраняем порядок
                comment: e['comment'],
              ))
          .toList();

      await _trainingService.createTrainingWithExercises(
        name: _nameController.text,
        exercises: exercises,
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
}
