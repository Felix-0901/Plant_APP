import 'package:flutter/material.dart';

Future<void> showAlert(BuildContext context, String msg, {String title = '提示'}) async {
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

String? requiredValidator(String? v, {String label = '此欄位'}) {
  if (v == null || v.trim().isEmpty) return '$label 為必填';
  return null;
}

String? emailValidator(String? v) {
  if (v == null || v.trim().isEmpty) return 'Email 為必填';
  final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim());
  return ok ? null : 'Email 格式不正確';
}

String? passwordValidator(String? v) {
  if (v == null || v.length < 6) return '密碼至少 6 碼';
  return null;
}

String? confirmPasswordValidator(String? v, String original) {
  if (v == null || v.isEmpty) return '請再次輸入密碼';
  if (v != original) return '兩次密碼不一致';
  return null;
}

// 簡單把 DateTime 轉 YYYYMMDD
String ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
