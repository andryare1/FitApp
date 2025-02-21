import 'package:flutter/material.dart';

class TrainingsPage extends StatelessWidget {
  const TrainingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Тренировки')),
      body: const Center(
        child: Text(
          'Здесь будут отображаться тренировки!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
