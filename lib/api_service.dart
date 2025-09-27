// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 建議: 可將 baseUrl 設為 static final 並集中管理
  static const String baseLoginUrl =
      'http://35.189.162.86/class_test/auth.php/login';
  static const String baseRegisterUrl =
      'http://35.189.162.86/class_test/auth.php/register';

  /// 共用的 JSON POST
  static Future<Map<String, dynamic>> _postJson(
    String url,
    Map<String, dynamic> body,
  ) async {
    final resp = await http.post(
      Uri.parse(url),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    // { "success": true, "message": "Login ok", "data": { ... } }
    // 嘗試解析 JSON；如果不是 JSON 就包裝為文字
    try {
      final data = jsonDecode(utf8.decode(resp.bodyBytes));
      if (data is Map<String, dynamic>) {
        return {
          'ok': resp.statusCode == 200,
          'status': resp.statusCode,
          'data': data,
          'raw': resp.body,
        };
      }
      return {
        'ok': resp.statusCode == 200,
        'status': resp.statusCode,
        'data': {'message': data.toString()},
        'raw': resp.body,
      };
    } catch (_) {
      return {
        'ok': resp.statusCode == 200,
        'status': resp.statusCode,
        'data': {'message': resp.body},
        'raw': resp.body,
      };
    }
  }

  /// 登入：email、password
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final payload = {
      'email': email,
      'password': password,
    };
    return _postJson(baseLoginUrl, payload);
  }

  /// 註冊：name、password、phone、birthday、email
  static Future<Map<String, dynamic>> register({
    required String name,
    required String password,
    required String phone,
    required String birthday, // 建議格式：YYYY-MM-DD
    required String email,
  }) async {
    final payload = {
      'name': name,
      'password': password,
      'phone': phone,
      'birthday': birthday,
      'email': email,
    };
    return _postJson(baseRegisterUrl, payload);
  }
}