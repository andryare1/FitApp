import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:urbanfit/pages/authorizationPage/login_page.dart';
import 'package:urbanfit/services/auth_service.dart';
import 'package:urbanfit/widgets/statistics_widget.dart';

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
  final token = await _authService.getToken();
  
  if (token == null) {
    print("Ошибка: токен не найден");
    if (mounted) {
      setState(() => _isLoading = false);
    }
    return;
  }

  setState(() => _isLoading = true);

  try {
    final storedUsername = await _authService.getUsername();
    final storedAvatarBytes = await _authService.getAvatarFromServer(token);

    if (mounted) {
      setState(() {
        username = storedUsername;
        avatarBytes = storedAvatarBytes;
      });
    }
  } catch (e) {
    print("Ошибка при загрузке данных пользователя: $e");
    if (mounted) {
      setState(() => avatarBytes = null);
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  // Загружает новое изображение и отправляет на сервер
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

  // Отправляет новый аватар на сервер
  Future<void> _uploadAvatar(File image) async {
    setState(() => _isLoading = true);

    try {
      final success = await _authService.uploadAvatar(image);
      if (success) {
        _loadUserData(); 
      } else {
        _showErrorDialog('Ошибка загрузки аватара. Попробуйте снова.');
      }
    } catch (e) {
      _showErrorDialog('Ошибка при загрузке аватара. Попробуйте позже.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Показывает диалог ошибки
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

  // Показывает диалог выхода
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

  // Показывает диалог выбора фото
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
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.pop(context);
                bool success = await _authService.deleteAvatar();

                if (success) {
                  setState(() {
                    avatarBytes = null;
                  });
                }
              },
              child: const Text("Удалить фото"),
            )
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
      title: const Text('Профиль'),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.exit_to_app),
          onPressed: _showExitDialog,
        ),
      ],
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Аватар с кнопкой редактирования
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                          child: avatarBytes != null
                              ? ClipOval(
                                  child: Image.memory(
                                    avatarBytes!,
                                    fit: BoxFit.cover,
                                    width: 96,
                                    height: 96,
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  size: 56,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                        ),
                        Positioned(
                          bottom: -4,
                          right: -4,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade300,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                width: 2,
                              ),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              iconSize: 16,
                              icon: const Icon(Icons.edit),
                              color: Colors.white,
                              onPressed: _showPhotoOptions,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Приветственное сообщение
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.deepPurple.shade100,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      username != null 
                          ? 'Добро пожаловать, $username!' 
                          : 'Добро пожаловать!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.deepPurple.shade800,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Заголовок статистики
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Center
                    (child: Text( 'Ваша статистика',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,)
                     
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Виджет статистики
                  const StatisticsWidget(),
                ],
              ),
            ),
          ),
  );
}
}
