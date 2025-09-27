import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../services/api_service.dart';

class GreenhousePage extends StatelessWidget {
  const GreenhousePage({super.key});

  Future<Map<String, dynamic>> _load() => ApiService.greenhouseStats();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('溫室狀態', style: AppText.title)),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _load(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('載入失敗：${snap.error}'));
          }
          final data = snap.data ?? {};
          final temp = data['temperature']?.toString() ?? '--';
          final humi = data['humidity']?.toString() ?? '--';
          final light = data['light']?.toString() ?? '--';

          return Padding(
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
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
