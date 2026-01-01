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
  bool _busy = false;

  late Map<String, dynamic> _plant; // ✅ current plant data (will refresh from server)

  final TextEditingController _todayStateCtrl = TextEditingController();
  DateTime? _lastWateringDateTime;

  @override
  void initState() {
    super.initState();
    _plant = Map<String, dynamic>.from(widget.plant);

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

  String get _uuid => (_plant['uuid'] ?? '').toString();



  bool _needsInitializationToday() {
    final initStr = (_plant['initialization'] ?? '').toString();
    final d = parseYmd(initStr);
    if (d == null) return true;
    final today = todayDateOnly();
    return DateTime(d.year, d.month, d.day) != today;
  }

  int _careDaysFromSetup() {
    final setupStr = (_plant['setup_time'] ?? '').toString();
    final setup = parseYmd(setupStr);
    if (setup == null) return 0;

    final today = todayDateOnly();
    final diff =
        today.difference(DateTime(setup.year, setup.month, setup.day)).inDays;
    return (diff < 0 ? 0 : diff) + 1;
  }

  String _formatYmdHmsCompact(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$y$m$d$hh$mm$ss';
  }

  // -----------------------------
  // Task parsing (robust)
  // -----------------------------
  Map<String, dynamic>? _taskMap() {
    final t = _plant['task'];
    if (t == null) return null;

    if (t is Map<String, dynamic>) return t;
    if (t is Map) return t.map((k, v) => MapEntry(k.toString(), v));

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

  bool _taskDone(dynamic v) {
    if (v is Map) {
      final s = v['state'];
      return s == true || s?.toString().toLowerCase() == 'true';
    }
    return false;
  }

  String _taskContent(dynamic v, String fallbackKey) {
    if (v is Map) {
      final c = v['content']?.toString() ?? '';
      return c.isEmpty ? fallbackKey : c;
    }
    return fallbackKey;
  }

  // -----------------------------
  // Refresh plant from server (fetch all -> find by uuid)
  // -----------------------------
  Future<void> _refreshPlantFromServer() async {
    final plants = await ApiService.getPlantInfo(email: widget.email);

    Map<String, dynamic>? found;
    for (final p in plants) {
      if ((p['uuid'] ?? '').toString() == _uuid) {
        found = p;
        break;
      }
    }

    if (found == null) {
      await showAlert(context, 'Plant not found after refresh.', title: 'Error');
      return;
    }

    if (!mounted) return;
    setState(() {
      _plant = Map<String, dynamic>.from(found!);
    });
  }

  // -----------------------------
  // Busy overlay
  // -----------------------------
  Future<T?> _runBusy<T>(Future<T?> Function() job) async {
    if (_busy) return null;
    setState(() => _busy = true);
    try {
      return await job();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // -----------------------------
  // Initialization flow (same as before)
  // -----------------------------
  Future<void> _maybeForceInitialize() async {
    if (_initDialogShown) return;

    if (_needsInitializationToday()) {
      _initDialogShown = true;

      final ok = await _showInitializeDialog();
      if (!mounted) return;

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

                final lastWateringTime = _formatYmdHmsCompact(lastDt);

                final ok = await _runBusy<bool>(() async {
                  return await ApiService.initializePlant(
                    uuid: _uuid,
                    email: widget.email,
                    todayState: todayState,
                    lastWateringTime: lastWateringTime,
                  );
                });

                if (!mounted) return;

                if (ok == true) {
                  Navigator.of(ctx).pop(true);

                  // 5 seconds overlay spinner (as your spec)
                  await _showBlockingSpinner5s();

                  if (!mounted) return;

                  // refresh plant data in this page
                  await _runBusy<void>(() async {
                    await _refreshPlantFromServer();
                    return null;
                  });
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
  // ✅ NEW: Task completion flow
  // -----------------------------
  Future<void> _completeTask(String taskKey) async {
    final tasks = _taskMap();
    if (tasks == null || tasks.isEmpty) {
      await showAlert(context, 'No tasks available.', title: 'Tasks');
      return;
    }

    final raw = tasks[taskKey];
    if (raw is! Map) return;

    final alreadyDone = _taskDone(raw);
    if (alreadyDone) {
      await showAlert(context, 'This task is already completed.', title: 'Tasks');
      return;
    }

    // ✅ 1) 先建立 updated task（只改被點的那個 state=true）
    final updated = <String, dynamic>{};
    for (final entry in tasks.entries) {
      final k = entry.key;
      final v = entry.value;

      if (v is Map) {
        final vv = Map<String, dynamic>.from(
          v.map((kk, vv) => MapEntry(kk.toString(), vv)),
        );
        if (k == taskKey) vv['state'] = true;
        updated[k] = vv;
      } else {
        updated[k] = v;
      }
    }

    // ✅ 2) 先讓 UI 立刻變完成（本地先改）
    setState(() {
      _plant['task'] = updated;
    });

    await _runBusy<void>(() async {
      // ✅ 3) 上傳
      final ok = await ApiService.updatePlantTask(
        uuid: _uuid,
        email: widget.email,
        task: updated,
      );

      if (!ok) {
        // ❗失敗就回復 UI（再拉一次伺服器狀態最保險）
        await _refreshPlantFromServer();
        await showAlert(context, 'Failed to update task.', title: 'Tasks');
        return null;
      }

      // ✅ 4) 成功後：再跟伺服器要所有植物資料 → 找 uuid → 更新此頁
      await _refreshPlantFromServer();
      return null;
    });
  }


  // -----------------------------
  // UI
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    final plantName = (_plant['plant_variety'] ?? '').toString();
    final nickname = (_plant['plant_name'] ?? '').toString();
    final setupTime = (_plant['setup_time'] ?? '').toString();
    final initTime = (_plant['initialization'] ?? '').toString();
    final status = (_plant['plant_state'] ?? '').toString();
    final careDays = _careDaysFromSetup();
    final tasks = _taskMap();

    final caredToday = !_needsInitializationToday();
    final dotColor = caredToday ? Colors.green : Colors.red;

    return Stack(
      children: [
        Scaffold(
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
                        final key = e.key;
                        final v = e.value;

                        final done = _taskDone(v);
                        final content = _taskContent(v, key);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: done ? null : () => _completeTask(key),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 10,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      done
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      size: 18,
                                      color: done ? Colors.green : Colors.black26,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        content,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: done ? Colors.black38 : Colors.black,
                                          decoration: done
                                              ? TextDecoration.lineThrough
                                              : TextDecoration.none,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (!done)
                                      const Icon(
                                        Icons.chevron_right,
                                        size: 18,
                                        color: Colors.black26,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // ✅ Busy overlay (during update task / refresh)
        if (_busy)
          Positioned.fill(
            child: Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
      ],
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
