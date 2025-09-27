import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../services/api_service.dart';
import '../utils/tools.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _onSignup() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final res = await ApiService.signup(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      );
      showSnack(context, res['message']?.toString() ?? '註冊成功');
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('註冊', style: AppText.title)),
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
                    controller: _name,
                    label: '姓名',
                    validator: (v) => requiredValidator(v, label: '姓名'),
                  ),
                  const SizedBox(height: 12),
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
                  CustomButton(text: '建立帳號', onPressed: _onSignup, loading: _loading),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: const Text('已經有帳號？去登入'),
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
