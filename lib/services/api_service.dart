// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class ApiService {
  // ---------- Base URL builders ----------
  static Uri _u(String path) => Uri.parse('${AppConfig.baseUrl}$path');                // auth.php
  static Uri _psw(String path) => Uri.parse('${AppConfig.pswBaseUrl}$path');          // psw_setting.php
  static Uri _hp(String path) => Uri.parse('${AppConfig.homepageBaseUrl}$path');      // homepage_setting.php
  static Uri _plant(String path) => Uri.parse('${AppConfig.plantBaseUrl}$path');      // plant_setting.php

  // 重點：加上 charset，避免部分 PHP 環境解析問題
  static Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json; charset=utf-8',
      };

  // ======================================================
  //                      Auth
  // ======================================================

  /// 登入：POST /login
  /// 成功例：{ "message": "Login successful", "email": "xx@xx.com" }
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

  /// 註冊：POST /register
  /// 成功例：{ "message": "Registration successful" }
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

  /// 忘記密碼：POST /found_psw
  /// 成功例：{ "message": "A new password has been generated and sent to your email." }
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final res = await http.post(
      _psw('/found_psw'),
      headers: _jsonHeaders,
      body: jsonEncode({'email': email}),
    );
    return _json(res);
  }

  // ======================================================
  //                     Homepage
  // ======================================================

  /// 公告列表：POST /search_announcements（不需 body）
  /// 成功例：{ "message":"Search completed", "results":[{id,title,content,date}, ...] }
  /// 無公告：{ "message":"No announcements" }
  static Future<List<Map<String, dynamic>>> searchAnnouncements() async {
    final res = await http.post(
      _hp('/search_announcements'),
      headers: _jsonHeaders,
      body: jsonEncode({}), // 後端不需要，但維持 JSON
    );
    final data = _jsonAny(res);
    if (data is Map<String, dynamic>) {
      final msg = data['message']?.toString();
      if (msg == 'No announcements') return [];
      final list = (data['results'] as List?) ?? const [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  // ======================================================
  //                       Plant
  // ======================================================

  /// 取得使用者的植物資訊：POST /get_plant_info
  /// body: { "email": "..." }
  /// 成功例：{ "results":[{...}, ...] } 或直接回傳陣列
  /// 無資料：{ "message": "No plant data found" }
  static Future<List<Map<String, dynamic>>> getPlantInfo({
    required String email,
  }) async {
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
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  /// 建立植物（只用 JSON 送出，並完整印出請求/回應以便比對）
  /// 後端程式是：
  ///   $data = json_decode(file_get_contents('php://input'), true);
  ///   $plant_variety  = $data['plant_variety'] ?? '';
  ///   $plant_name     = $data['plant_name'] ?? '';
  ///   $plant_state    = $data['plant_state'] ?? '';
  ///   $setup_time     = $data['setup_time'] ?? '';
  ///   $email          = $data['email'] ?? '';
  static Future<Map<String, dynamic>> createPlant({
    required String plantVariety,
    required String plantName,
    required String plantState, // 建議小寫: seedling/growing/stable
    required String setupTime,  // YYYYMMDD
    required String email,
  }) async {
    // 標準化狀態（全小寫）
    final state = plantState.trim().toLowerCase();

    // 1) 準備 URL 與 JSON body
    final url = _plant('/create_plant');
    final payload = {
      'plant_variety': plantVariety.trim(),
      'plant_name': plantName.trim(),
      'plant_state': state,
      'setup_time': setupTime.trim(),
      'email': email.trim(),
    };

    // 2) 把「將要送出的東西」完整印出（方便和 Postman 一字不差比對）
    // ignore: avoid_print
    print('=== CREATE_PLANT REQUEST ===');
    // ignore: avoid_print
    print('URL: $url');
    // ignore: avoid_print
    print('Headers: ${{'Content-Type': 'application/json; charset=utf-8'}}');
    // ignore: avoid_print
    print('Body(JSON): ${jsonEncode(payload)}');

    // 3) 送出（只用 JSON；因為伺服器就是用 json_decode 讀取）
    final res = await http.post(
      url,
      headers: _jsonHeaders,
      body: jsonEncode(payload),
    );

    // 4) 原文回應＆狀態碼完整印出
    // ignore: avoid_print
    print('=== CREATE_PLANT RESPONSE ===');
    // ignore: avoid_print
    print('Status: ${res.statusCode}');
    // ignore: avoid_print
    print('RAW: ${res.body}');

    // 5) 解析（保持寬鬆，錯誤時帶原文訊息）
    dynamic data;
    try {
      data = res.body.isEmpty ? null : jsonDecode(res.body);
    } catch (_) {
      data = res.body; // 不是 JSON 就原文
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String msg = 'Request failed';
      if (data is Map<String, dynamic>) {
        msg = data['message']?.toString() ??
              data['error']?.toString() ??
              msg;
      } else if (data is String && data.isNotEmpty) {
        msg = data;
      }
      throw ApiException(message: msg, code: res.statusCode);
    }
    if (data is Map<String, dynamic>) return data;
    return {'message': 'OK', 'data': data};
  }

  // ======================================================
  //                      Helpers
  // ======================================================

  /// 嚴格 Map 輸出；非 2xx 丟 ApiException(message)
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

  /// 寬鬆任何型別輸出；非 2xx 丟 ApiException(message)
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
