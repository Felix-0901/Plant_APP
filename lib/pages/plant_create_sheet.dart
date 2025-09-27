// lib/pages/plant_create_sheet.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/session.dart';
import '../utils/tools.dart';

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

      // 成功：直接關閉並回傳 true
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
                const Text('Create Plant', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // Plant variety
                TextFormField(
                  controller: _variety,
                  decoration: const InputDecoration(
                    labelText: 'Plant variety',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter variety' : null,
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
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter name' : null,
                ),
                const SizedBox(height: 16),

                // Plant state (dropdown) —— 高度、寬度、文字顏色和 TextFormField 一致
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
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black, // ✅ 文字顏色和 TextFormField 一樣
                  ),
                  dropdownColor: Colors.white, // ✅ 下拉背景白色
                  isDense: true, // ✅ 保持標準高度
                ),
                const SizedBox(height: 20),

                // Submit
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
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
