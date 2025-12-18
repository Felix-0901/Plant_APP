// lib/pages/plant_page.dart
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/tools.dart';
import '../config/constants.dart';

class PlantPage extends StatefulWidget {
  final Map<String, dynamic> plant;
  final String email;

  const PlantPage({
    super.key,
    required this.plant,
    required this.email,
  });

  @override
  State<PlantPage> createState() => _PlantPageState();
}

class _PlantPageState extends State<PlantPage> {
  bool _initDialogShown = false;

  final TextEditingController _todayStateCtrl = TextEditingController();
  DateTime? _lastWateringDateTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _maybeForceInitialize();
    });
  }

  @override
  void dispose() {
    _todayStateCtrl.dispose();
    super.dispose();
  }

  // -----------------------------
  // Date helpers (same tolerant style)
  // -----------------------------
  DateTime? parseYmd(String? input) {
    if (input == null) return null;
    final s = input.trim();
    try {
      if (RegExp(r'^\d{8}$').hasMatch(s)) {
        final y = int.parse(s.substring(0, 4));
        final m = int.parse(s.substring(4, 6));
        final d = int.parse(s.substring(6, 8));
        return DateTime(y, m, d);
      }
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)) {
        return DateTime.parse(s);
      }
      if (RegExp(r'^\d{4}/\d{2}/\d{2}$').hasMatch(s)) {
        return DateTime.parse(s.replaceAll('/', '-'));
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  DateTime todayDateOnly() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _needsInitializationToday() {
    final initStr = (widget.plant['initialization'] ?? '').toString();
    final d = parseYmd(initStr);
    if (d == null) return true;
    final today = todayDateOnly();
    return DateTime(d.year, d.month, d.day) != today;
  }

  int _careDaysFromSetup() {
    final setupStr = (widget.plant['setup_time'] ?? '').toString();
    final setup = parseYmd(setupStr);
    if (setup == null) return 0;

    final today = todayDateOnly();
    final diff =
        today.difference(DateTime(setup.year, setup.month, setup.day)).inDays;
    final days = (diff < 0 ? 0 : diff) + 1;
    return days;
  }

  String _formatYmdHmsCompact(DateTime dt) {
    // YYYYMMDDhhmmss
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$y$m$d$hh$mm$ss';
  }

  Map<String, dynamic>? _taskMap() {
    final t = widget.plant['task'];
    if (t == null) return null;

    if (t is Map<String, dynamic>) return t;
    if (t is Map) return t.map((k, v) => MapEntry(k.toString(), v));

    // If server sometimes returns JSON string
    if (t is String) {
      final s = t.trim();
      if (s.startsWith('{') && s.endsWith('}')) {
        try {
          final decoded = ApiService.tryDecodeJson(s);
          if (decoded is Map) {
            return decoded.map((k, v) => MapEntry(k.toString(), v));
          }
        } catch (_) {}
      }
    }
    return null;
  }

  // -----------------------------
  // Initialization flow
  // -----------------------------
  Future<void> _maybeForceInitialize() async {
    if (_initDialogShown) return;

    if (_needsInitializationToday()) {
      _initDialogShown = true;

      final ok = await _showInitializeDialog();
      if (!mounted) return;

      // If user chooses back => return to greenhouse (no refresh)
      if (ok != true) {
        Navigator.of(context).pop(false);
      }
    }
  }

  Future<bool?> _showInitializeDialog() async {
    _todayStateCtrl.text = '';
    _lastWateringDateTime = null;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Initialization required'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'This plant has not been initialized today.\n'
                  'Please describe the current condition and select the last watering time.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _todayStateCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Current condition',
                    hintText: 'e.g., soil dry, leaves healthy, pests found...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                _LastWateringPicker(
                  value: _lastWateringDateTime,
                  onPick: (dt) => setState(() => _lastWateringDateTime = dt),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Back'),
            ),
            ElevatedButton(
              onPressed: () async {
                final todayState = _todayStateCtrl.text.trim();
                final lastDt = _lastWateringDateTime;

                if (todayState.isEmpty || lastDt == null) {
                  await showAlert(
                    context,
                    'Please fill in the condition and last watering time.',
                    title: 'Missing info',
                  );
                  return;
                }

                final uuid = (widget.plant['uuid'] ?? '').toString();
                final lastWateringTime = _formatYmdHmsCompact(lastDt);

                final ok = await ApiService.initializePlant(
                  uuid: uuid,
                  email: widget.email,
                  todayState: todayState,
                  lastWateringTime: lastWateringTime,
                );

                if (!mounted) return;

                if (ok) {
                  Navigator.of(ctx).pop(true);

                  // Screen dark + white spinner 5s
                  await _showBlockingSpinner5s();

                  if (!mounted) return;

                  // back to greenhouse => refresh
                  Navigator.of(context).pop(true);
                } else {
                  await showAlert(
                    context,
                    'Initialization failed. Please try again.',
                    title: 'Failed',
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showBlockingSpinner5s() async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    await Future.delayed(const Duration(seconds: 5));

    if (mounted) Navigator.of(context).pop();
  }

  // -----------------------------
  // UI
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    // According to your data:
    // plant_variety = Plant name
    // plant_name    = Plant nickname
    final plantName = (widget.plant['plant_variety'] ?? '').toString();
    final nickname = (widget.plant['plant_name'] ?? '').toString();
    final setupTime = (widget.plant['setup_time'] ?? '').toString();
    final initTime = (widget.plant['initialization'] ?? '').toString();
    final status = (widget.plant['plant_state'] ?? '').toString();
    final careDays = _careDaysFromSetup();
    final tasks = _taskMap();

    final caredToday = !_needsInitializationToday();
    final dotColor = caredToday ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          nickname.isEmpty ? 'Plant' : nickname,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 8),
                      decoration:
                          BoxDecoration(color: dotColor, shape: BoxShape.circle),
                    ),
                    Expanded(
                      child: Text(
                        plantName.isEmpty ? '-' : plantName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _InfoRow(label: 'Plant name', value: plantName),
                _InfoRow(label: 'Plant nickname', value: nickname),
                _InfoRow(label: 'Care start date', value: setupTime),
                _InfoRow(label: 'Care days', value: '$careDays days'),
                _InfoRow(label: 'Status', value: status),
                _InfoRow(label: 'Initialized', value: initTime),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tasks card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tasks',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepYellow,
                  ),
                ),
                const SizedBox(height: 10),
                if (tasks == null || tasks.isEmpty) ...[
                  const Text(
                    'No tasks yet.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ] else ...[
                  ...tasks.entries.map((e) {
                    final v = e.value;

                    bool done = false;
                    String content = '';

                    if (v is Map) {
                      done = (v['state'] == true);
                      content = (v['content'] ?? '').toString();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            done ? Icons.check_circle : Icons.radio_button_unchecked,
                            size: 18,
                            color: done ? Colors.green : Colors.black26,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              content.isEmpty ? e.key : content,
                              style: const TextStyle(fontSize: 14, color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LastWateringPicker extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime> onPick;

  const _LastWateringPicker({
    required this.value,
    required this.onPick,
  });

  Future<DateTime?> _pickDateTime(BuildContext context) async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: value != null
          ? TimeOfDay(hour: value!.hour, minute: value!.minute)
          : TimeOfDay.fromDateTime(now),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute, 0);
  }

  String _display(DateTime dt) {
    String two(int x) => x.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final dt = await _pickDateTime(context);
        if (dt != null) onPick(dt);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Last watering time',
          border: OutlineInputBorder(),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(value == null ? 'Tap to select' : _display(value!)),
            ),
            const Icon(Icons.calendar_today, size: 18),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            child: Text(value.isEmpty ? '-' : value),
          ),
        ],
      ),
    );
  }
}
