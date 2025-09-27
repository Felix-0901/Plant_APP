import 'package:flutter/material.dart';

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
