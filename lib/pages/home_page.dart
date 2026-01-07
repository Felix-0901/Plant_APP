// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../services/api_service.dart';
import '../utils/session.dart';
import '../utils/tools.dart';
import '../widgets/custom_button.dart';
import '../utils/nav.dart';

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

      // DEBUG: 輸出今天日期
      debugPrint('🔍 DEBUG: today = $today');
      debugPrint('🔍 DEBUG: plants count = ${plants.length}');

      for (final p in plants) {
        final name = (p['plant_name'] ?? '').toString().trim();
        if (name.isEmpty) continue;

        final initStr = (p['initialization'] ?? '').toString();
        final initDate = parseYmd(initStr);

        // DEBUG: 輸出每個植物的資料
        debugPrint('🌱 Plant: $name');
        debugPrint('   - initialization raw: "$initStr"');
        debugPrint('   - initDate parsed: $initDate');

        // 無法解析日期 → 視為從未初始化 → 今天需要照顧
        if (initDate == null) {
          debugPrint('   → Added to notCared (null date)');
          notCared.add(name);
          continue;
        }

        final initOnly = DateTime(initDate.year, initDate.month, initDate.day);
        debugPrint('   - initOnly: $initOnly');

        // 今天已照顧 → 跳過
        if (initOnly == today) {
          debugPrint('   → Skipped (cared today)');
          continue;
        }

        // 今天沒照顧 → 加入 notCared (不管天數)
        debugPrint('   → Added to notCared (not cared today)');
        notCared.add(name);

        // 計算相差天數：超過 7 天 → 額外加入 tooLong
        final diffDays = today.difference(initOnly).inDays;
        debugPrint('   - diffDays: $diffDays');
        if (diffDays > 7) {
          debugPrint('   → Also added to tooLong');
          tooLong.add(name);
        }
      }

      debugPrint('📋 RESULT: notCared = $notCared');
      debugPrint('📋 RESULT: tooLong = $tooLong');

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景裝飾
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryYellow.withAlpha(77),
                    AppColors.primaryYellow.withAlpha(0),
                  ],
                ),
              ),
            ),
          ),

          // 主內容
          SafeArea(
            child: Column(
              children: [
                // 自訂 Header
                _buildHeader(),

                // 內容
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadAll,
                    color: AppColors.deepYellow,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      children: [
                        // 公告區
                        _buildAnnouncementsSection(),

                        const SizedBox(height: 20),

                        // 前往溫室按鈕
                        CustomButton(
                          text: 'View Greenhouse',
                          icon: Icons.park_outlined,
                          onPressed:
                              () => Navigator.pushNamed(context, '/greenhouse'),
                        ),

                        const SizedBox(height: 24),

                        // 植物照護區塊
                        _CareSection(
                          title: 'Not cared today',
                          icon: Icons.access_time_rounded,
                          iconColor: AppColors.warning,
                          bgColor: AppColors.warningLight,
                          names: _notCaredToday,
                        ),

                        const SizedBox(height: 16),

                        _CareSection(
                          title: 'Not cared for too long',
                          icon: Icons.warning_amber_rounded,
                          iconColor: AppColors.error,
                          bgColor: AppColors.errorLight,
                          names: _notCaredTooLong,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          // 登出按鈕
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppShadows.soft,
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, size: 22),
              onPressed: _onLogout,
              tooltip: 'Log out',
              color: AppColors.textSecondary,
            ),
          ),

          const Spacer(),

          // 標題
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.yellowGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Plant',
                style: AppText.title.copyWith(
                  fontSize: 24,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const Spacer(),

          // 佔位保持居中
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsSection() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.lightYellow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.campaign_rounded,
                    color: AppColors.deepYellow,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Announcements',
                  style: AppText.sectionTitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // 內容
          Expanded(
            child:
                _ann.isEmpty
                    ? Center(
                      child: Text(
                        _annLoaded ? 'No announcements' : 'Loading...',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                    : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      itemCount: _ann.length,
                      separatorBuilder:
                          (_, __) => const Divider(
                            height: 20,
                            color: AppColors.divider,
                          ),
                      itemBuilder: (context, i) {
                        final m = _ann[i];
                        final title = (m['title'] ?? '').toString();
                        final date = (m['date'] ?? '').toString();
                        final content = (m['content'] ?? '').toString();
                        return InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap:
                              () => showAnnouncementDialog(
                                context,
                                title: title,
                                date: date,
                                content: content,
                              ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        date,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textHint,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

/// 照護區塊
class _CareSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final List<String> names;

  const _CareSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.names,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: AppText.sectionTitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${names.length}',
                    style: TextStyle(
                      color: iconColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 內容
          if (names.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'All plants are well cared!',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: names.map((name) => _PlantChip(name: name)).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

/// 植物標籤
class _PlantChip extends StatelessWidget {
  final String name;
  const _PlantChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
