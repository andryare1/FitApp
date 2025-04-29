import 'dart:async';
import 'package:flutter/material.dart';
import 'package:urbanfit/pages/authorizationPage/login_page.dart';
import 'package:urbanfit/services/auth_service.dart';

class EmailConfirmationPage extends StatefulWidget {
  final String userId;
  final String email;

  const EmailConfirmationPage({
    super.key,
    required this.userId,
    required this.email,
  });

  @override
  State<EmailConfirmationPage> createState() => _EmailConfirmationPageState();
}

class _EmailConfirmationPageState extends State<EmailConfirmationPage> {
  final AuthService _authService = AuthService();
  final List<TextEditingController> _codeControllers =
      List.generate(6, (_) => TextEditingController());

  bool _isSendingCode = false;
  bool _isVerifying = false;
  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsRemaining = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _resendCode() async {
    if (_secondsRemaining > 0 || _isSendingCode) return;

    setState(() => _isSendingCode = true);
    final error =
        await _authService.sendVerificationCode(widget.userId, widget.email);
    setState(() => _isSendingCode = false);

    if (error == null) {
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Код отправлен повторно")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка: $error")),
      );
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeControllers.map((c) => c.text).join();

    if (code.length != 6 || code.contains(RegExp(r'\D'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color.fromARGB(255, 200, 108, 108),
          content: Text("Введите корректный 6-значный код"),
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);
    final error = await _authService.verifyEmailCode(widget.userId, code);
    setState(() => _isVerifying = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color.fromARGB(255, 108, 200, 128),
          content: Text("Email успешно подтверждён!"),
        ),
      );
      await Future.delayed(
          const Duration(seconds: 1)); // небольшая пауза перед переходом
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color.fromARGB(255, 200, 108, 108),
          content: Text("Ошибка подтверждения: $error"),
        ),
      );
    }
  }

  Widget _buildCodeInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 40,
          child: TextField(
            controller: _codeControllers[index],
            keyboardType: TextInputType.number,
            maxLength: 1,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(counterText: ''),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                FocusScope.of(context).nextFocus();
              } else if (value.isEmpty && index > 0) {
                FocusScope.of(context).previousFocus();
              }
            },
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Подтверждение Email")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text("Введите код подтверждения",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text("Мы отправили код на ${widget.email}",
                textAlign: TextAlign.center),
            const SizedBox(height: 30),
            _buildCodeInput(),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isVerifying ? null : _verifyCode,
              child: _isVerifying
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text("Подтвердить"),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _secondsRemaining == 0 ? _resendCode : null,
              child: Text(_secondsRemaining == 0
                  ? "Отправить код повторно"
                  : "Отправить повторно через $_secondsRemaining сек."),
            ),
          ],
        ),
      ),
    );
  }
}
