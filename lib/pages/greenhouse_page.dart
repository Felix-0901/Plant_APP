// lib/pages/greenhouse_page.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/session.dart';
import '../utils/tools.dart';
import '../config/constants.dart';
import 'plant_create_sheet.dart';

class GreenhousePage extends StatefulWidget {
  const GreenhousePage({super.key});

  @override
  State<GreenhousePage> createState() => _GreenhousePageState();
}

class _GreenhousePageState extends State<GreenhousePage> {
  List<Map<String, dynamic>> _plants = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  Future<void> _loadPlants() async {
    try {
      final email = Session.email;
      if (email == null || email.isEmpty) {
        setState(() {
          _plants = [];
          _loaded = true;
        });
        return;
      }
      final res = await ApiService.getPlantInfo(email: email);
      setState(() {
        _plants = res;
        _loaded = true;
      });
    } catch (e) {
      setState(() => _loaded = true);
      await showAlert(context, e.toString(), title: 'Greenhouse Error');
    }
  }

  // ✅ 寬鬆解析：支援 YYYYMMDD / YYYY-MM-DD / YYYY/MM/DD
  DateTime? parseYmd(String? input) {
    if (input == null) return null;
    final s = input.trim();
    try {
      if (RegExp(r'^\d{8}$').hasMatch(s)) {
        // YYYYMMDD
        final y = int.parse(s.substring(0, 4));
        final m = int.parse(s.substring(4, 6));
        final d = int.parse(s.substring(6, 8));
        return DateTime(y, m, d);
      }
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)) {
        // YYYY-MM-DD
        return DateTime.parse(s);
      }
      if (RegExp(r'^\d{4}/\d{2}/\d{2}$').hasMatch(s)) {
        // YYYY/MM/DD -> 轉成 - 再 parse
        return DateTime.parse(s.replaceAll('/', '-'));
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  // ✅ 今天的「日期」（去除時分秒）
  DateTime todayDateOnly() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // 今日是否已初始化（true = 綠點 / 已照顧）
  bool _caredToday(String? initDateStr) {
    final d = parseYmd(initDateStr);
    if (d == null) return false;
    final today = todayDateOnly();
    return DateTime(d.year, d.month, d.day) == today;
  }

  // 照顧天數 = (today - setup_time).inDays + 1（今天建立即顯示 1）
  String _careDays(String? setupDateStr) {
    final setup = parseYmd(setupDateStr);
    if (setup == null) return '-';
    final today = todayDateOnly();
    final diff = today.difference(DateTime(setup.year, setup.month, setup.day)).inDays;
    final days = (diff < 0 ? 0 : diff) + 1;
    return '$days days';
  }

  Future<void> _openCreate() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const PlantCreateSheet(),
    );

    if (created == true) {
      await _loadPlants();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar：白底、無陰影、標題 Greenhouse（黑字粗體）
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Greenhouse',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPlants,
        child: _loaded
            ? (_plants.isEmpty
                ? const _EmptyState() // 置中顯示「No plants」
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    itemCount: _plants.length,
                    itemBuilder: (context, i) {
                      final p = _plants[i];

                      final name = (p['plant_name'] ?? '').toString();
                      final variety = (p['plant_variety'] ?? '').toString();
                      final state = (p['plant_state'] ?? '').toString();
                      final setupTime = (p['setup_time'] ?? '').toString();        // 可能是 YYYY-MM-DD
                      final init = (p['initialization'] ?? '').toString();         // 也一併用寬鬆解析

                      final cared = _caredToday(init);
                      final daysText = _careDays(setupTime);

                      return _PlantCard(
                        name: name,
                        variety: variety,
                        state: state,
                        caredToday: cared,
                        daysText: daysText,
                        onTap: () {
                          // 預留：之後點擊卡片的功能
                        },
                      );
                    },
                  ))
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: const [
                  SizedBox(height: 160),
                  Center(child: CircularProgressIndicator()),
                  SizedBox(height: 160),
                ],
              ),
      ),

      // 右下角：新增植物
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    // 置中顯示 + 保留下拉刷新
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: const Center(
              child: Text(
                'No plants',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlantCard extends StatelessWidget {
  final String name;
  final String variety;
  final String state;
  final bool caredToday; // true=綠點、false=紅點
  final String daysText; // "N days" or "-"
  final VoidCallback? onTap;

  const _PlantCard({
    required this.name,
    required this.variety,
    required this.state,
    required this.caredToday,
    required this.daysText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = caredToday ? Colors.green : Colors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 第一行：紅/綠點 + 名稱（最大黑字） + 右側天數（黃色）
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                    ),
                    Expanded(
                      child: Text(
                        name.isEmpty ? '-' : name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      daysText,
                      style: const TextStyle(
                        fontSize: 20, // ✅ 和名稱一樣大
                        fontWeight: FontWeight.bold, // ✅ 粗體
                        color: AppColors.deepYellow
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 第二行：品種 + 狀態（灰色小字，左到右）
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        variety.isEmpty ? '-' : variety,
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.isEmpty ? '-' : state,
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
