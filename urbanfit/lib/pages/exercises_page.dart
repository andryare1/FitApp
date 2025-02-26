import 'package:flutter/material.dart';

class ExercisesPage extends StatelessWidget {
  const ExercisesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Center(
        child: Text('Упражнения'),
      )),
      body: const Center(
        child: Text(
          'Здесь будут отображаться упражнения!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
