// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/session.dart';
import '../utils/tools.dart';
import '../widgets/custom_button.dart';
import '../utils/nav.dart'; // for shared routeObserver

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with RouteAware, WidgetsBindingObserver {
  // 公告
  List<Map<String, dynamic>> _ann = [];
  bool _annLoaded = false;

  // 植物分組
  List<String> _notCaredToday = [];
  List<String> _notCaredTooLong = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadAll();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadAll();
    }
  }

  Future<void> _loadAll() async {
    // 1) 抓公告
    try {
      final anns = await ApiService.searchAnnouncements();
      setState(() {
        _ann = anns;
        _annLoaded = true;
      });
    } catch (e) {
      await showAlert(context, e.toString(), title: 'Announcements Error');
      setState(() => _annLoaded = true);
    }

    // 2) 抓植物資料
    try {
      final email = Session.email;
      if (email == null || email.isEmpty) return;

      final plants = await ApiService.getPlantInfo(email: email);

      final today = todayDateOnly();
      final List<String> notCared = [];
      final List<String> tooLong = [];

      for (final p in plants) {
        final name = (p['plant_name'] ?? '').toString().trim();
        if (name.isEmpty) continue;

        final initStr = (p['initialization'] ?? '').toString();
        final initDate = parseYmd(initStr);

        if (initDate == null) {
          tooLong.add(name);
          continue;
        }

        final initOnly = DateTime(initDate.year, initDate.month, initDate.day);
        if (initOnly == today) continue;

        final diffDays = today.difference(initOnly).inDays;
        if (diffDays > 7) {
          tooLong.add(name);
        } else if (diffDays >= 1) {
          notCared.add(name);
        }
      }

      setState(() {
        _notCaredToday = notCared;
        _notCaredTooLong = tooLong;
      });
    } catch (e) {
      await showAlert(context, e.toString(), title: 'Plant Info Error');
    }
  }

  Future<void> _onLogout() async {
    final ok = await confirmDialog(
      context,
      title: 'Log out',
      message: 'Are you sure you want to log out?',
      okText: 'OK',
      cancelText: 'Cancel',
    );
    if (!ok) return;

    await Session.clear();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  bool _onAnnouncementsScroll(ScrollNotification n) => false;
  bool _onBottomListScroll(ScrollNotification n) => false;



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.black),
          onPressed: _onLogout,
          tooltip: 'Log out',
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Plant',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          // 公告區
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child: _ann.isEmpty
                    ? Center(
                        child: Text(
                          _annLoaded ? 'No announcements' : 'Loading...',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: _onAnnouncementsScroll,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _ann.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 16),
                          itemBuilder: (context, i) {
                            final m = _ann[i];
                            final title = (m['title'] ?? '').toString();
                            final date = (m['date'] ?? '').toString();
                            final content = (m['content'] ?? '').toString();
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  date,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black54),
                                ),
                              ),
                              onTap: () => showAnnouncementDialog(
                                context,
                                title: title,
                                date: date,
                                content: content,
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 24),
          ),

          // 前往溫室按鈕
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: CustomButton(
                text: 'View Greenhouse',
                onPressed: () => Navigator.pushNamed(context, '/greenhouse'),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 下半部：整體可捲動
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAll,
              child: NotificationListener<ScrollNotification>(
                onNotification: _onBottomListScroll,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: _AutoHeightSection(
                        title: 'Not cared today',
                        names: _notCaredToday,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: _AutoHeightSection(
                        title: 'Not cared for too long',
                        names: _notCaredTooLong,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 自動高度區塊（不可內捲動）
class _AutoHeightSection extends StatelessWidget {
  final String title;
  final List<String> names;

  const _AutoHeightSection({
    required this.title,
    required this.names,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            if (names.isEmpty)
              const Text('None', style: TextStyle(color: Colors.black54))
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < names.length; i++) ...[
                    _PlantTile(name: names[i]),
                    if (i != names.length - 1) const SizedBox(height: 8),
                  ]
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// 單一植物子區塊
class _PlantTile extends StatelessWidget {
  final String name;
  const _PlantTile({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // 撐滿寬度
      alignment: Alignment.centerLeft, // 靠左
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      constraints: const BoxConstraints(minHeight: 50), // 比較高
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        name,
        textAlign: TextAlign.left,
        style: const TextStyle(color: Colors.black),
      ),
    );
  }
}
