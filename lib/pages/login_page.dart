import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../services/api_service.dart';
import '../utils/tools.dart';
import '../utils/session.dart';
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
      final serverEmail = (res['email'] ?? _email.text.trim()).toString();
      await Session.setEmail(serverEmail);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      await showAlert(context, e.toString(), title: 'Login Failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Prompt dialog with TextField to input email
  Future<String?> _promptEmail() async {
    final controller = TextEditingController(text: _email.text.trim());
    String? errorText;

    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Forgot Password'),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  errorText: errorText,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final value = controller.text.trim();
                    final err = emailValidator(value);
                    if (err != null) {
                      setState(() => errorText = err);
                      return;
                    }
                    Navigator.of(ctx).pop(value);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    return result;
  }

  Future<void> _onForgotPassword() async {
    final email = await _promptEmail();
    if (email == null) return; // user cancelled

    try {
      final res = await ApiService.forgotPassword(email: email);
      await showAlert(
        context,
        res['message']?.toString() ?? 'A new password has been generated and sent to your email.',
        title: 'Password Reset',
      );
    } catch (e) {
      await showAlert(context, e.toString(), title: 'Reset Failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No AppBar
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
                  const Text(
                    'Login',
                    style: AppText.title,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  CustomTextField(
                    controller: _email,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: emailValidator,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _password,
                    label: 'Password',
                    obscureText: true,
                    validator: passwordValidator,
                  ),
                  const SizedBox(height: 20),
                  CustomButton(text: 'Sign In', onPressed: _onLogin, loading: _loading),
                  const SizedBox(height: 12),
                  // 🔄 調換順序：Forgot password? 在左，Sign up? 在右
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _onForgotPassword,
                        child: const Text('Forgot password?'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/signup'),
                        child: const Text('Sign up?'),
                      ),
                    ],
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
