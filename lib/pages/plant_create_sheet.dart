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
  String _state = 'Seedling'; // 預設
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

      // 依題意：成功不跳提示，直接關閉並回傳 true
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
    // 讓 BottomSheet 配合鍵盤高度
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 抬頭
                const Center(
                  child: Text(
                    'Create Plant',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 16),

                // Plant variety
                TextFormField(
                  controller: _variety,
                  decoration: const InputDecoration(labelText: 'Plant variety'),
                  validator: (v) => requiredValidator(v, label: 'Plant variety'),
                ),
                const SizedBox(height: 12),

                // Plant name
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Plant name'),
                  validator: (v) => requiredValidator(v, label: 'Plant name'),
                ),
                const SizedBox(height: 12),

                // Plant state (dropdown)
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Plant state', border: OutlineInputBorder()),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _state,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'Seedling', child: Text('Seedling')),
                        DropdownMenuItem(value: 'Growing', child: Text('Growing')),
                        DropdownMenuItem(value: 'Stable', child: Text('Stable')),
                      ],
                      onChanged: (v) => setState(() => _state = v ?? _state),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
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
