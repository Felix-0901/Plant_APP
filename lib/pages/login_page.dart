import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../services/api_service.dart';
import '../utils/tools.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final res = await ApiService.login(
        email: _email.text.trim(),
        password: _password.text,
      );
      showSnack(context, res['message']?.toString() ?? '登入成功');
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('登入', style: AppText.title)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomTextField(
                    controller: _email,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: emailValidator,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _password,
                    label: '密碼',
                    obscureText: true,
                    validator: passwordValidator,
                  ),
                  const SizedBox(height: 20),
                  CustomButton(text: '登入', onPressed: _onLogin, loading: _loading),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/signup'),
                    child: const Text('還沒有帳號？去註冊'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
