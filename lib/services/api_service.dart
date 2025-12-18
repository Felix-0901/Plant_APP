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

  static Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json; charset=utf-8',
      };

  // ======================================================
  //                      Auth
  // ======================================================

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

  static Future<List<Map<String, dynamic>>> searchAnnouncements() async {
    final res = await http.post(
      _hp('/search_announcements'),
      headers: _jsonHeaders,
      body: jsonEncode({}),
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

  static Future<Map<String, dynamic>> createPlant({
    required String plantVariety,
    required String plantName,
    required String plantState,
    required String setupTime,
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

  // ✅ NEW: initialize plant (for tasks)
  // API: http://35.189.162.86/Max_plant/plant_setting.php/initialize_plant
  // body:
  //   uuid, email, today_state, last_watering_time (YYYYMMDDhhmmss)
  static Future<bool> initializePlant({
    required String uuid,
    required String email,
    required String todayState,
    required String lastWateringTime,
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

    if (res.statusCode < 200 || res.statusCode >= 300) return false;

    // If server returns non-JSON, still treat 200 as ok
    return true;
  }

  // ======================================================
  //                      Helpers
  // ======================================================

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

  // ✅ tiny helper for cases where task is a JSON string
  static dynamic tryDecodeJson(String s) {
    return jsonDecode(s);
  }
}

class ApiException implements Exception {
  final String message;
  final int code;
  ApiException({required this.message, required this.code});
  @override
  String toString() => 'ApiException($code): $message';
}
