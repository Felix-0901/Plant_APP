import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class ApiService {
  static Uri _u(String path) => Uri.parse('${AppConfig.baseUrl}$path');

  static Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
      };

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      _u('/login'),
      headers: _jsonHeaders,
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _json(res);
  }

  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String birthday, // YYYY-MM-DD
  }) async {
    final res = await http.post(
      _u('/register'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'birthday': birthday,
      }),
    );
    return _json(res);
  }

  static Map<String, dynamic> _json(http.Response res) {
    final body = res.body.isEmpty ? '{}' : res.body;
    final data = jsonDecode(body) as Map<String, dynamic>;
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
