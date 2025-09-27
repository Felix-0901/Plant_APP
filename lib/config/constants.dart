import 'package:flutter/material.dart';

class AppConfig {
  // 既有：auth
  static const String baseUrl = 'http://35.189.162.86/Max_plant/auth.php';
  // 新增：password reset
  static const String pswBaseUrl = 'http://35.189.162.86/Max_plant/psw_setting.php';
}

class AppText {
  static const title = TextStyle(fontSize: 28, fontWeight: FontWeight.bold);
}

class AppColors {
  static const primaryYellow = Color(0xFFFFD54F); // warm yellow
}
