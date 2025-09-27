// lib/pages/greenhouse_page.dart
import 'package:flutter/material.dart';
import '../config/constants.dart';
// 將來要連線時再打開：
// import '../services/api_service.dart';

class GreenhousePage extends StatelessWidget {
  const GreenhousePage({super.key});

  // 先用本地假資料；將來要連線時改用 ApiService.greenhouseStats()
  // Future<Map<String, dynamic>> _load() => ApiService.greenhouseStats();

  static const Map<String, dynamic> _demo = {
    'temperature': 24.8,
    'humidity': 62,
    'light': 8500,
  };

  @override
  Widget build(BuildContext context) {
    final data = _demo;
    final temp = data['temperature']?.toString() ?? '--';
    final humi = data['humidity']?.toString() ?? '--';
    final light = data['light']?.toString() ?? '--';

    return Scaffold(
      appBar: AppBar(title: const Text('溫室狀態', style: AppText.title)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('目前數值', style: AppText.title),
                    const SizedBox(height: 16),
                    _RowItem(label: '溫度 (°C)', value: temp),
                    _RowItem(label: '濕度 (%)', value: humi),
                    _RowItem(label: '光照 (lux)', value: light),
                    const SizedBox(height: 16),
                    const Text(
                      '（目前為示意數據，尚未串接 API）',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  final String label;
  final String value;
  const _RowItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Text(value, style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}
