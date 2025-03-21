import 'package:flutter/material.dart';
import 'package:urbanfit/pages/exercisesPage/exercises_page.dart';
import 'package:urbanfit/pages/main_page.dart';
import 'package:urbanfit/pages/profile_page.dart';
import 'package:urbanfit/pages/trainings_pade.dart';
import 'authorization/login_page.dart'; 

class HomePage extends StatefulWidget {
  final String? token;

  const HomePage({super.key, required this.token});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const MainPage(), // Главная страница
    const TrainingsPage(), // Тренировки
    const ExercisesPage(), // Упражнения
    const ProfilePage(), // Страница профиля
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.token == '' ? const LoginPage() : _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
          BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center), label: 'Тренировки'),
          BottomNavigationBarItem(
              icon: Icon(Icons.library_books), label: 'Упражнения'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle), label: 'Профиль'),
        ],
      ),
    );
  }
}
