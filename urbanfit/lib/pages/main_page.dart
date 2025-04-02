import 'package:flutter/material.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
   return Scaffold(
      appBar: AppBar(
          title: const Center(
        child: Text('Главная'),
      )),
      body: const Center(
        child: Text(
          'Здесь будет отображаться главная!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
