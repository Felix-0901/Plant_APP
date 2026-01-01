// lib/pages/greenhouse_page.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/session.dart';
import '../utils/tools.dart';
import '../config/constants.dart';
import 'plant_create_sheet.dart';
import 'plant_page.dart'; // ✅ NEW

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



  bool _caredToday(String? initDateStr) {
    final d = parseYmd(initDateStr);
    if (d == null) return false;
    final today = todayDateOnly();
    return DateTime(d.year, d.month, d.day) == today;
  }

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
                ? const _EmptyState()
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    itemCount: _plants.length,
                    itemBuilder: (context, i) {
                      final p = _plants[i];

                      final name = (p['plant_name'] ?? '').toString();
                      final variety = (p['plant_variety'] ?? '').toString();
                      final state = (p['plant_state'] ?? '').toString();
                      final setupTime = (p['setup_time'] ?? '').toString();
                      final init = (p['initialization'] ?? '').toString();

                      final cared = _caredToday(init);
                      final daysText = _careDays(setupTime);

                      return _PlantCard(
                        name: name,
                        variety: variety,
                        state: state,
                        caredToday: cared,
                        daysText: daysText,
                        onTap: () async {
                          final email = Session.email;
                          if (email == null || email.isEmpty) {
                            await showAlert(context, 'Please login again.', title: 'Session');
                            return;
                          }

                          final shouldRefresh = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlantPage(
                                plant: p,
                                email: email,
                              ),
                            ),
                          );

                          if (shouldRefresh == true) {
                            await _loadPlants();
                          }
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
  final bool caredToday;
  final String daysText;
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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepYellow,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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