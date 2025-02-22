import 'dart:io'; 
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:urbanfit/pages/authorization/login_page.dart';
import 'package:urbanfit/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart'; // Для получения директории

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? username;
  XFile? _avatarImage;
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _getUserData();
    _loadAvatarImage();
  }

  // Получаем имя пользователя из SharedPreferences
  _getUserData() async {
    final storedUsername = await _authService.getUsername();
    setState(() {
      username = storedUsername;
    });
  }

  // Метод для загрузки аватарки из локального хранилища
  _loadAvatarImage() async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = await _authService.getAvatarPath(); // Предположим, что этот метод извлекает путь из SharedPreferences.
    
    if (filePath != null) {
      final file = File(filePath);
      if (file.existsSync()) {
        setState(() {
          _avatarImage = XFile(filePath);
        });
      }
    }
  }

  // Метод для выбора изображения из галереи
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _saveAvatarImage(pickedFile);
    }
  }

  // Метод для снятия фотографии с камеры
  Future<void> _takePhoto() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      _saveAvatarImage(pickedFile);
    }
  }

  // Метод для сохранения фото в локальное хранилище
  Future<void> _saveAvatarImage(XFile image) async {
    final directory = await getApplicationDocumentsDirectory();
    final name = DateTime.now().millisecondsSinceEpoch.toString(); // Генерируем уникальное имя для файла
    final file = File('${directory.path}/$name.png');
    await file.writeAsBytes(await image.readAsBytes());
    await _authService.saveAvatarPath(file.path); // Сохраняем путь в SharedPreferences или в другом месте.
    
    setState(() {
      _avatarImage = image;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('      Профиль'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              bool? exit = await _showExitDialog(context);
              if (exit == true) {
                await _authService.clearToken();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Отображаем аватарку или иконку по умолчанию
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _avatarImage == null
                    ? const AssetImage('assets/default_avatar.png')
                    : FileImage(File(_avatarImage!.path)) as ImageProvider,
                child: _avatarImage == null
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            // Кнопка для изменения аватарки
            ElevatedButton(
              onPressed: _showPhotoOptions,
              child: const Text('Изменить фото профиля'),
            ),
            const SizedBox(height: 20),
            // Отображаем имя пользователя
            username == null
                ? const CircularProgressIndicator()
                : Text('Добро пожаловать, $username!', style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  // Диалоговое окно для подтверждения выхода
  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Выход'),
          content: const Text('Вы действительно хотите выйти?'),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Выйти'),
            ),
          ],
        );
      },
    );
  }

  // Метод для отображения диалога с выбором источника фото
  void _showPhotoOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Выберите источник фото'),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
                _takePhoto();
              },
              child: const Text('Сделать фото'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
                _pickImage();
              },
              child: const Text('Выбрать из галереи'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context); // Закрытие диалога без действий
              },
              isDestructiveAction: true,
              child: const Text('Отмена'),
            ),
          ],
        );
      },
    );
  }
}
