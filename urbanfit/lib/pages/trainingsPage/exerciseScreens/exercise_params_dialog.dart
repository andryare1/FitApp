import 'package:flutter/material.dart';

class ExerciseParamsDialog extends StatefulWidget {
  final Map<String, dynamic> exercise;

  const ExerciseParamsDialog({Key? key, required this.exercise}) : super(key: key);

  @override
  _ExerciseParamsDialogState createState() => _ExerciseParamsDialogState();
}

class _ExerciseParamsDialogState extends State<ExerciseParamsDialog> {
  late final TextEditingController _setsController;
  late final TextEditingController _repsController;
  late final TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _setsController = TextEditingController(text: (widget.exercise['sets'] ?? 3).toString());
    _repsController = TextEditingController(text: (widget.exercise['reps'] ?? 10).toString());
    _weightController = TextEditingController(text: (widget.exercise['weight'] ?? 0.0).toString());
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.exercise['name']),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _setsController,
              decoration: const InputDecoration(
                labelText: 'Подходы',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _repsController,
              decoration: const InputDecoration(
                labelText: 'Повторения',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Вес (кг)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: () {
            final updatedExercise = Map<String, dynamic>.from(widget.exercise)
              ..['sets'] = int.tryParse(_setsController.text) ?? 3
              ..['reps'] = int.tryParse(_repsController.text) ?? 10
              ..['weight'] = double.tryParse(_weightController.text) ?? 0.0;
            Navigator.pop(context, updatedExercise);
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}