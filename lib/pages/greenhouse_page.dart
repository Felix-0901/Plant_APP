import 'package:flutter/material.dart';
import '../config/constants.dart';

class GreenhousePage extends StatelessWidget {
  const GreenhousePage({super.key});

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
      appBar: AppBar(title: const Text('Greenhouse', style: AppText.title)),
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
                    const Text('Current Readings', style: AppText.title),
                    const SizedBox(height: 16),
                    _RowItem(label: 'Temperature (°C)', value: temp),
                    _RowItem(label: 'Humidity (%)', value: humi),
                    _RowItem(label: 'Light (lux)', value: light),
                    const SizedBox(height: 16),
                    const Text(
                      '(Demo data for now. API not connected.)',
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
