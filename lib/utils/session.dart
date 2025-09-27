import 'package:shared_preferences/shared_preferences.dart';

class Session {
  static const _kEmailKey = 'user_email';
  static String? _email;
  static bool _ready = false;

  static String? get email => _email;
  static bool get isReady => _ready;

  /// Load from SharedPreferences
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _email = prefs.getString(_kEmailKey);
    _ready = true;
  }

  /// Save to memory + SharedPreferences
  static Future<void> setEmail(String email) async {
    _email = email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kEmailKey, email);
  }

  /// Clear login state
  static Future<void> clear() async {
    _email = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kEmailKey);
  }
}
