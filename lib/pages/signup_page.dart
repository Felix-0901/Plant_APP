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
  final _birthdayCtrl = TextEditingController(); // 顯示 YYYY-MM-DD
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  DateTime? _birthday; // 內部存日期

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
      await showAlert(context, '請選擇生日', title: '欄位未完成');
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await ApiService.signup(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        phone: _phone.text.trim(),
        birthday: _birthdayCtrl.text, // YYYY-MM-DD
      );
      // 成功：彈 OK 匡，按下後回登入頁
      await showAlert(context, res['message']?.toString() ?? 'Registration successful', title: '註冊成功');
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      // 失敗：顯示伺服器 message（有 OK 鈕）
      await showAlert(context, e.toString(), title: '註冊失敗');
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
                    controller: _phone,
                    label: '電話',
                    keyboardType: TextInputType.phone,
                    validator: (v) => requiredValidator(v, label: '電話'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _birthdayCtrl,
                    readOnly: true,
                    validator: (v) => requiredValidator(v, label: '生日'),
                    decoration: InputDecoration(
                      labelText: '生日（YYYY-MM-DD）',
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
                    label: '密碼',
                    obscureText: true,
                    validator: passwordValidator,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _confirm,
                    label: '確認密碼',
                    obscureText: true,
                    validator: (v) => confirmPasswordValidator(v, _password.text),
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
