import 'package:flutter/material.dart';

Future<void> showAlert(BuildContext context, String msg, {String title = 'Notice'}) async {
  return showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(msg),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
      ],
    ),
  );
}

void showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

String? requiredValidator(String? v, {String label = 'This field'}) {
  if (v == null || v.trim().isEmpty) return '$label is required';
  return null;
}

String? emailValidator(String? v) {
  if (v == null || v.trim().isEmpty) return 'Email is required';
  final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim());
  return ok ? null : 'Invalid email format';
}

String? passwordValidator(String? v) {
  if (v == null || v.length < 6) return 'Password must be at least 6 characters';
  return null;
}

String? confirmPasswordValidator(String? v, String original) {
  if (v == null || v.isEmpty) return 'Please confirm your password';
  if (v != original) return 'Passwords do not match';
  return null;
}

// YYYYMMDD (no separators)
String ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
