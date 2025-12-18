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

  /// 建立植物
  static Future<Map<String, dynamic>> createPlant({
    required String plantVariety,
    required String plantName,
    required String plantState, // seedling/growing/stable
    required String setupTime,  // YYYYMMDD
    required String email,
  }) async {
    final state = plantState.trim().toLowerCase();

    final url = _plant('/create_plant');
    final payload = {
      'plant_variety': plantVariety.trim(),
      'plant_name': plantName.trim(),
      'plant_state': state,
      'setup_time': setupTime.trim(),
      'email': email.trim(),
    };

    // ignore: avoid_print
    print('=== CREATE_PLANT REQUEST ===');
    // ignore: avoid_print
    print('URL: $url');
    // ignore: avoid_print
    print('Headers: ${{'Content-Type': 'application/json; charset=utf-8'}}');
    // ignore: avoid_print
    print('Body(JSON): ${jsonEncode(payload)}');

    final res = await http.post(
      url,
      headers: _jsonHeaders,
      body: jsonEncode(payload),
    );

    // ignore: avoid_print
    print('=== CREATE_PLANT RESPONSE ===');
    // ignore: avoid_print
    print('Status: ${res.statusCode}');
    // ignore: avoid_print
    print('RAW: ${res.body}');

    dynamic data;
    try {
      data = res.body.isEmpty ? null : jsonDecode(res.body);
    } catch (_) {
      data = res.body;
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String msg = 'Request failed';
      if (data is Map<String, dynamic>) {
        msg = data['message']?.toString() ?? data['error']?.toString() ?? msg;
      } else if (data is String && data.isNotEmpty) {
        msg = data;
      }
      throw ApiException(message: msg, code: res.statusCode);
    }
    if (data is Map<String, dynamic>) return data;
    return {'message': 'OK', 'data': data};
  }

  /// 初始化植物（拿任務）
  static Future<bool> initializePlant({
    required String uuid,
    required String email,
    required String todayState,
    required String lastWateringTime, // YYYYMMDDhhmmss
  }) async {
    final url = _plant('/initialize_plant');
    final payload = {
      'uuid': uuid,
      'email': email,
      'today_state': todayState,
      'last_watering_time': lastWateringTime,
    };

    // ignore: avoid_print
    print('=== INITIALIZE_PLANT REQUEST ===');
    // ignore: avoid_print
    print('URL: $url');
    // ignore: avoid_print
    print('Body(JSON): ${jsonEncode(payload)}');

    final res = await http.post(
      url,
      headers: _jsonHeaders,
      body: jsonEncode(payload),
    );

    // ignore: avoid_print
    print('=== INITIALIZE_PLANT RESPONSE ===');
    // ignore: avoid_print
    print('Status: ${res.statusCode}');
    // ignore: avoid_print
    print('RAW: ${res.body}');

    return res.statusCode >= 200 && res.statusCode < 300;
  }

  /// ✅ NEW: 更新任務狀態（整包 task 送回去）
  /// API: /update_plant_task
  /// body: { uuid, email, task: { task_1: {...}, ... } }
  static Future<bool> updatePlantTask({
    required String uuid,
    required String email,
    required Map<String, dynamic> task,
  }) async {
    final url = _plant('/update_plant_task');

    // ✅ 後端多半期待 $task 是字串，所以這裡送 JSON 字串
    final payload = {
      'uuid': uuid,
      'email': email,
      'task': jsonEncode(task),
    };

    // ignore: avoid_print
    print('=== UPDATE_PLANT_TASK REQUEST ===');
    // ignore: avoid_print
    print('URL: $url');
    // ignore: avoid_print
    print('Body(JSON): ${jsonEncode(payload)}');

    final res = await http.post(
      url,
      headers: _jsonHeaders,
      body: jsonEncode(payload),
    );

    // ignore: avoid_print
    print('=== UPDATE_PLANT_TASK RESPONSE ===');
    // ignore: avoid_print
    print('Status: ${res.statusCode}');
    // ignore: avoid_print
    print('RAW: ${res.body}');

    if (res.statusCode < 200 || res.statusCode >= 300) return false;

    // ✅ 有些後端即使失敗也回 200，所以額外看 message
    try {
      final data = jsonDecode(res.body);
      if (data is Map && data['message'] != null) {
        final msg = data['message'].toString().toLowerCase();
        if (msg.contains('fail') || msg.contains('error')) return false;
      }
    } catch (_) {}

    return true;
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
      throw ApiException(
        message: data['message']?.toString() ?? 'Request failed',
        code: res.statusCode,
      );
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

  /// ✅ tiny helper (PlantPage may need when task returned as JSON string)
  static dynamic tryDecodeJson(String s) => jsonDecode(s);
}

class ApiException implements Exception {
  final String message;
  final int code;
  ApiException({required this.message, required this.code});
  @override
  String toString() => 'ApiException($code): $message';
}
