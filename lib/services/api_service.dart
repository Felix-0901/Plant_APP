import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class ApiService {
  static Uri _u(String path) => Uri.parse('${AppConfig.baseUrl}$path');
  static Uri _psw(String path) => Uri.parse('${AppConfig.pswBaseUrl}$path');
  static Uri _hp(String path) => Uri.parse('${AppConfig.homepageBaseUrl}$path');
  static Uri _plant(String path) => Uri.parse('${AppConfig.plantBaseUrl}$path');

  static Map<String, String> get _jsonHeaders => {'Content-Type': 'application/json'};

  // ---------- Auth ----------
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
    required String birthday, // YYYYMMDD
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

  static Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    final res = await http.post(
      _psw('/found_psw'),
      headers: _jsonHeaders,
      body: jsonEncode({'email': email}),
    );
    return _json(res);
  }

  // ---------- Homepage ----------
  // 公告列表：POST /search_announcements（不需 body）
  static Future<List<Map<String, dynamic>>> searchAnnouncements() async {
    final res = await http.post(_hp('/search_announcements'), headers: _jsonHeaders, body: jsonEncode({}));
    final data = _jsonAny(res);
    if (data is Map<String, dynamic>) {
      final msg = data['message']?.toString();
      if (msg == 'No announcements') return [];
      final list = (data['results'] as List?) ?? const [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  // 植物資訊：POST /get_plant_info 需傳 email
  static Future<List<Map<String, dynamic>>> getPlantInfo({required String email}) async {
    final res = await http.post(
      _plant('/get_plant_info'),
      headers: _jsonHeaders,
      body: jsonEncode({'email': email}),
    );
    final data = _jsonAny(res);
    if (data is Map<String, dynamic>) {
      final list = (data['results'] as List?) ?? const [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    if (data is List) {
      // 後端若直接回陣列也能處理
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  // ---------- helpers ----------
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

  static dynamic _jsonAny(http.Response res) {
    final body = res.body.isEmpty ? 'null' : res.body;
    final data = jsonDecode(body);
    // ignore: avoid_print
    print('[API ${res.request?.url}] ${res.statusCode} => $data');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String msg = 'Request failed';
      if (data is Map<String, dynamic>) {
        msg = data['message']?.toString() ?? msg;
      }
      throw ApiException(message: msg, code: res.statusCode);
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
