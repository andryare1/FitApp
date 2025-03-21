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
      final storedAvatarBytes =
          await _authService.getAvatarFromServer();

      if (mounted) {
        setState(() {
          username = storedUsername;
          avatarBytes = storedAvatarBytes; 
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => avatarBytes =
            Uint8List(0)); 
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
      body: Padding(
        padding: const EdgeInsets.all(1.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor: avatarBytes == null
                          ? Colors.grey[300]
                          : Colors.transparent,
                      child: avatarBytes != null
                          ? ClipOval(
                              child: Image.memory(
                                avatarBytes!,
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset('assets/error.png');
                                },
                              ),
                            )
                          : const Icon(Icons.person,
                              size: 60, color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: _showPhotoOptions,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Изменить фото'),
                  ),
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
