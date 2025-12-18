// lib/utils/tools.dart
import 'package:flutter/material.dart';

// 一般提示
Future<void> showAlert(BuildContext context, String msg, {String title = 'Notice'}) async {
  return showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(msg),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
    ),
  );
}

// 確認對話框（OK / Cancel）
Future<bool> confirmDialog(
  BuildContext context, {
  String title = 'Confirm',
  required String message,
  String okText = 'OK',
  String cancelText = 'Cancel',
}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(cancelText)),
        TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(okText)),
      ],
    ),
  );
  return res == true;
}

// 公告內容對話框（內容可滾動）
Future<void> showAnnouncementDialog(
  BuildContext context, {
  required String title,
  required String date,
  required String content,
}) async {
  return showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(date, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 320, minWidth: 300),
        child: SingleChildScrollView(child: Text(content)),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
    ),
  );
}

void showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

// ---------- Validators ----------
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

// ---------- 日期工具 ----------
// YYYYMMDD (no separators)
String ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

DateTime todayDateOnly() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

// 將 'YYYYMMDD' 轉成 DateTime（失敗回 null）
DateTime? parseYmd(String? s) {
  if (s == null) return null;
  final t = s.trim();
  if (!RegExp(r'^\d{8}$').hasMatch(t)) return null;
  final y = int.tryParse(t.substring(0, 4));
  final m = int.tryParse(t.substring(4, 6));
  final d = int.tryParse(t.substring(6, 8));
  if (y == null || m == null || d == null) return null;
  try {
    return DateTime(y, m, d);
  } catch (_) {
    return null;
  }
}
