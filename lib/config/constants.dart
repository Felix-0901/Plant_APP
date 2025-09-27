import 'package:flutter/material.dart';

class AppConfig {
  // Auth / Password
  static const String baseUrl = 'http://35.189.162.86/Max_plant/auth.php';
  static const String pswBaseUrl = 'http://35.189.162.86/Max_plant/psw_setting.php';

  // NEW: Home / Plant
  static const String homepageBaseUrl = 'http://35.189.162.86/Max_plant/homepage_setting.php';
  static const String plantBaseUrl = 'http://35.189.162.86/Max_plant/plant_setting.php';
}

class AppText {
  static const title = TextStyle(fontSize: 28, fontWeight: FontWeight.bold);
}

class AppColors {
  static const primaryYellow = Color(0xFFFFD54F); // 溫和黃
  static const deepYellow = Color(0xFFFBC02D);    // 深黃
}
