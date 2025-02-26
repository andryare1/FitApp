import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:urbanfit/pages/authorization/login_page.dart';
import 'package:urbanfit/services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? username;
  Uint8List? avatarBytes;
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
  setState(() => _isLoading = true);

  try {
    final storedUsername = await _authService.getUsername();
    final storedAvatarBytes = await _authService.getAvatarFromServer(); // Берем URL с сервера

    setState(() {
      username = storedUsername;
      avatarBytes = storedAvatarBytes; // Устанавливаем аватар с сервера
    });
  } catch (e) {
    debugPrint('Ошибка загрузки данных: $e');
    setState(() => avatarBytes = null); // Если ошибка - показываем дефолтный аватар
  } finally {
    setState(() => _isLoading = false);
  }
}


  /// Загружает новое изображение и отправляет на сервер
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        await _uploadAvatar(File(pickedFile.path));
      }
    } catch (e) {
      debugPrint('Ошибка при выборе изображения: $e');
    }
  }

  /// Отправляет новый аватар на сервер
  Future<void> _uploadAvatar(File image) async {

    

    setState(() => _isLoading = true);

    try {
      final success = await _authService.uploadAvatar(image);
      if (success) {
        _loadUserData(); // Перезагружаем данные пользователя, чтобы обновить аватар
      } else {
        _showErrorDialog('Ошибка загрузки аватара. Попробуйте снова.');
      }
    } catch (e) {
      debugPrint('Ошибка загрузки аватара на сервер: $e');
      _showErrorDialog('Ошибка при загрузке аватара. Попробуйте позже.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Показывает диалог ошибки
  Future<void> _showErrorDialog(String message) async {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ошибка'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Показывает диалог выхода
  Future<void> _showExitDialog() async {
    final bool? exit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Выход'),
          content: const Text('Вы действительно хотите выйти?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Выйти'),
            ),
          ],
        );
      },
    );

    if (exit == true) {
      await _authService.clearToken();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  /// Показывает диалог выбора фото
  void _showPhotoOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: const Text('Выберите источник фото'),
          actions: <Widget>[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
              child: const Text('Сделать фото'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
              child: const Text('Выбрать из галереи'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        );
      },
    );
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Center(child: Text('Профиль')),
      actions: [
        IconButton(
          icon: const Icon(Icons.exit_to_app),
          onPressed: _showExitDialog,
        ),
      ],
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Индикатор загрузки
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.transparent,
                    child: avatarBytes != null
                        ? ClipOval(
                            child: Image.memory(
                              avatarBytes!,
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset('assets/error.png'); // Если ошибка
                              },
                            ),
                          )
                        : const Icon(Icons.person, size: 60), // Если нет аватарки
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _showPhotoOptions,
                  child: const Text('Изменить фото профиля'),
                ),
                const SizedBox(height: 20),
                Text(
                  username != null
                      ? 'Добро пожаловать, $username!'
                      : 'Загрузка...',
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
    ),
  );
}
}
