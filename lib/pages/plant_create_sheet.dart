// lib/pages/plant_create_sheet.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/session.dart';
import '../utils/tools.dart';
import 'package:url_launcher/url_launcher.dart'; // ← 用於開啟外部連結

class PlantCreateSheet extends StatefulWidget {
  const PlantCreateSheet({super.key});

  @override
  State<PlantCreateSheet> createState() => _PlantCreateSheetState();
}

class _PlantCreateSheetState extends State<PlantCreateSheet> {
  final _form = GlobalKey<FormState>();
  final _variety = TextEditingController();
  final _name = TextEditingController();
  String _state = 'seedling'; // 預設值
  bool _loading = false;

  static final Uri _plantNetUrl =
      Uri.parse('https://identify.plantnet.org/zh-tw');

  @override
  void dispose() {
    _variety.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

    final email = Session.email ?? '';
    if (email.isEmpty) {
      await showAlert(context, 'Please sign in again.', title: 'No session');
      return;
    }

    setState(() => _loading = true);
    try {
      final today = ymd(DateTime.now()); // YYYYMMDD
      final data = await ApiService.createPlant(
        plantVariety: _variety.text.trim(),
        plantName: _name.text.trim(),
        plantState: _state,
        setupTime: today,
        email: email,
      );

      // ignore: avoid_print
      print('Create plant => $data');
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      await showAlert(context, e.toString(), title: 'Create Failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openPlantNet() async {
    final ok = await launchUrl(_plantNetUrl, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: bottomInset + 20),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Create Plant',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // Plant variety
                TextFormField(
                  controller: _variety,
                  decoration: const InputDecoration(
                    labelText: 'Plant variety',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Please enter variety' : null,
                ),

                // 與上方輸入框保留一點距離
                const SizedBox(height: 4),

                // 🔗 小小文字按鈕：右下角
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _openPlantNet,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Identify plant by photo',
                      style: TextStyle(
                        fontSize: 12, // 小字
                        color: Colors.blueGrey, // 淡灰藍色
                        decoration: TextDecoration.none, // ❌ 移除底線
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Plant name
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Plant name',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Please enter name' : null,
                ),
                const SizedBox(height: 16),

                // Plant state
                DropdownButtonFormField<String>(
                  value: _state,
                  onChanged: (v) => setState(() => _state = v ?? _state),
                  items: const [
                    DropdownMenuItem(value: 'seedling', child: Text('Seedling')),
                    DropdownMenuItem(value: 'growing', child: Text('Growing')),
                    DropdownMenuItem(value: 'stable', child: Text('Stable')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Plant state',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  ),
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                  dropdownColor: Colors.white,
                  isDense: true,
                ),
                const SizedBox(height: 20),

                // Submit
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Submit'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
