import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class ApiService {
  static Uri _u(String path) => Uri.parse('${AppConfig.baseUrl}$path');

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      _u('/login'),
      body: {'email': email, 'password': password},
    );
    return _json(res);
  }

  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      _u('/signup'),
      body: {'name': name, 'email': email, 'password': password},
    );
    return _json(res);
  }

  // 範例：溫室資料
  static Future<Map<String, dynamic>> greenhouseStats() async {
    final res = await http.get(_u('/greenhouse/stats'));
    return _json(res);
  }

  static Map<String, dynamic> _json(http.Response res) {
    final body = res.body.isEmpty ? '{}' : res.body;
    final data = jsonDecode(body) as Map<String, dynamic>;
    // 開發期：把伺服器回應都印出來（你之前的偏好）
    // ignore: avoid_print
    print('[API ${res.request?.url}] ${res.statusCode} => $data');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(message: data['message']?.toString() ?? 'Request failed', code: res.statusCode);
    }
    return data;
  }
}

class ApiException implements Exception {
  final String message;
  final int code;
  ApiException({required this.message, required this.code});
  @override
  String toString() => 'ApiException($code): $message';
}
