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
  final _phone = TextEditingController();
  final _birthdayCtrl = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  DateTime? _birthday;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _birthdayCtrl.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final today = DateTime.now();
    final initial = _birthday ?? DateTime(today.year - 18, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: today,
    );
    if (picked != null) {
      setState(() {
        _birthday = picked;
        _birthdayCtrl.text = ymd(picked);
      });
    }
  }

  Future<void> _onSignup() async {
    if (!_form.currentState!.validate()) return;
    if (_birthday == null) {
      await showAlert(context, 'Please select your birthday', title: 'Incomplete Form');
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await ApiService.signup(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        phone: _phone.text.trim(),
        birthday: _birthdayCtrl.text,
      );
      await showAlert(context, res['message']?.toString() ?? 'Registration successful',
          title: 'Sign Up Successful');
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      await showAlert(context, e.toString(), title: 'Sign Up Failed');
    } finally {
      if (mounted) setState(() => _loading = false);
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
                    'Sign Up',
                    style: AppText.title,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  CustomTextField(
                    controller: _name,
                    label: 'Full Name',
                    validator: (v) => requiredValidator(v, label: 'Full Name'),
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
                    controller: _phone,
                    label: 'Phone',
                    keyboardType: TextInputType.phone,
                    validator: (v) => requiredValidator(v, label: 'Phone'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _birthdayCtrl,
                    readOnly: true,
                    validator: (v) => requiredValidator(v, label: 'Birthday'),
                    decoration: InputDecoration(
                      labelText: 'Birthday (YYYYMMDD)',
                      suffixIcon: IconButton(
                        onPressed: _pickBirthday,
                        icon: const Icon(Icons.calendar_today),
                      ),
                    ),
                    onTap: _pickBirthday,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _password,
                    label: 'Password',
                    obscureText: true,
                    validator: passwordValidator,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _confirm,
                    label: 'Confirm Password',
                    obscureText: true,
                    validator: (v) => confirmPasswordValidator(v, _password.text),
                  ),
                  const SizedBox(height: 20),
                  CustomButton(text: 'Create Account', onPressed: _onSignup, loading: _loading),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: const Text('Already have an account? Sign in'),
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
