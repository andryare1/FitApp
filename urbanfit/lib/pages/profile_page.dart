import 'package:flutter/material.dart';
import 'package:urbanfit/pages/authorization/login_page.dart';
import 'package:urbanfit/services/auth_service.dart'; // Импортируем AuthService

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? username;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  // Получаем имя пользователя из SharedPreferences
  _getUserData() async {
    final storedUsername = await _authService.getUsername();
    setState(() {
      username = storedUsername; // Обновляем состояние с именем пользователя
    });
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Row(
        mainAxisAlignment: MainAxisAlignment.center, // Центрируем текст
        children: [
          Text('         Профиль', textAlign: TextAlign.center),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.exit_to_app),
          onPressed: () async {
            // Запрос на выход
            bool? exit = await _showExitDialog(context);
            if (exit == true) {
              // Очищаем токен
              await _authService.clearToken();
              // Перенаправляем на страницу входа
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            }
          },
        ),
      ],
    ),
      body: Center(
        child: username == null
            ? const CircularProgressIndicator() // Показываем индикатор загрузки, пока не получим имя
            : Text('Добро пожаловать, $username!'), // Отображаем имя пользователя
      ),
    );
  }

 Future<bool?> _showExitDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы действительно хотите выйти?'),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red), // Красный цвет кнопки
            onPressed: () {
              Navigator.of(context).pop(false); // Отмена
            },
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true); // Выйти
            },
            child: const Text('Выйти'),
          ),
        ],
      );
    },
  );
}
}
