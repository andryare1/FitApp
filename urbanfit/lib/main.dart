import 'package:flutter/material.dart';
import 'package:urbanfit/pages/authorizationPage/login_page.dart';
import 'package:urbanfit/pages/home_page.dart';
import 'package:urbanfit/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Получаем сохранённый токен из SharedPreferences
  String? token = await AuthService().getToken();

  runApp(MyApp(token: token));
}

class MyApp extends StatelessWidget {
  final String? token;

  const MyApp({super.key, this.token});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: token == null ? const LoginPage() : HomePage(token: token),
    );
  }
}
