// lib/pages/greenhouse_page.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/session.dart';
import '../utils/tools.dart';

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

  // 今日是否已初始化（true = 綠點 / 已照顧）
  bool _caredToday(String? initYmd) {
    final d = parseYmd(initYmd);
    if (d == null) return false;
    final today = todayDateOnly();
    final only = DateTime(d.year, d.month, d.day);
    return only == today;
  }

  // 照顧天數 = today - setup_time（無法解析回 '-'）
  String _careDays(String? setupYmd) {
    final setup = parseYmd(setupYmd);
    if (setup == null) return '-';
    final today = todayDateOnly();
    final days = today.difference(DateTime(setup.year, setup.month, setup.day)).inDays;
    final safe = days < 0 ? 0 : days; // 避免負數
    return '$safe days';
    // 若你想包含「當天算第 1 天」，可改： return '${safe + 1} days';
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
                ? const _EmptyState() // ✅ 空狀態置中且可下拉刷新
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    itemCount: _plants.length,
                    itemBuilder: (context, i) {
                      final p = _plants[i];

                      final name = (p['plant_name'] ?? '').toString();
                      final variety = (p['plant_variety'] ?? '').toString();
                      final state = (p['plant_state'] ?? '').toString();
                      final setupTime = (p['setup_time'] ?? '').toString(); // YYYYMMDD
                      final init = (p['initialization'] ?? '').toString();   // YYYYMMDD

                      final cared = _caredToday(init);        // 今日是否已初始化
                      final daysText = _careDays(setupTime);  // 照顧天數

                      return _PlantCard(
                        name: name,
                        variety: variety,
                        state: state,
                        caredToday: cared,
                        daysText: daysText,
                        onTap: () {
                          // 預留：之後點擊有功能再補
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
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    // 用 LayoutBuilder + SingleChildScrollView + ConstrainedBox
    // 讓內容置中，同時保留下拉刷新手勢
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
  final String daysText; // "12 days" or "-"
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
                // 第一行：紅/綠點 + 名稱（最大黑字） + 右側天數
                Row(
                  children: [
                    // 左側紅/綠點
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    // 名稱（展開並截斷）
                    Expanded(
                      child: Text(
                        name.isEmpty ? '-' : name,
                        style: const TextStyle(
                          fontSize: 20, // 名稱最大
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 右側：照顧天數
                    Text(
                      daysText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
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
