import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:taxi_exam_app/core/widgets/app_lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/core/utils/calculate_stats.dart';
import 'package:taxi_exam_app/core/widgets/attempt_spark_widget.dart';
import 'package:taxi_exam_app/core/widgets/category_pie_chart_widget.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'package:taxi_exam_app/features/home/attempt_detail_screen.dart';
import 'package:taxi_exam_app/features/tests/test_screen.dart';
import 'package:taxi_exam_app/main_screen.dart';

// ─── Constants ───────────────────────────────────────────────────────────────

// Background and card colours are theme-aware (see build methods)
const _kHeroStart = Color(0xFF1A1040);
const _kHeroEnd = Color(0xFF3D2C8D);

// ─── HomeScreen ──────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  List<TestAttempt> _previousAttempts = [];
  List<TestAttempt> _pausedAttempts = [];
  Map<String, dynamic> _stats = {};
  int selectedTabIndex = 0;
  bool _isLoading = true;
  late final VoidCallback _tabListener;
  MainScreenProvider? _mainScreenProvider;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  List<String> get licenceNames =>
      _stats['licenceWithCategories']?.keys.toList() ?? [];

  String get selectedLicence {
    if (licenceNames.isEmpty) return '';
    final idx = selectedTabIndex.clamp(0, licenceNames.length - 1);
    return licenceNames[idx];
  }

  static String _effectiveLicence(TestAttempt a) =>
      (a.licenceName?.isNotEmpty == true)
          ? a.licenceName!
          : (a.isBcd ? 'Category' : 'Unknown');

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _loadPreviousAttempts();
    _tabListener = () {
      if (_mainScreenProvider?.currentIndex == 0 && mounted) {
        _loadPreviousAttempts();
      }
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mainScreenProvider =
          Provider.of<MainScreenProvider>(context, listen: false);
      _mainScreenProvider!.addListener(_tabListener);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _mainScreenProvider?.removeListener(_tabListener);
    super.dispose();
  }

  void _loadPreviousAttempts() async {
    try {
      final box = await Hive.openBox<TestAttempt>('testAttempts');
      _refreshFromBox(box);
      _syncFromBackend(box);
    } catch (e) {
      debugPrint('HomeScreen: error loading attempts: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _refreshFromBox(Box<TestAttempt> box) {
    if (!mounted) return;
    final all = box.values.toList().cast<TestAttempt>();
    setState(() {
      _pausedAttempts = all.where((a) => a.isPaused).toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
      _previousAttempts = all.where((a) => a.isCompleted).toList();
      _stats = calculateStats(_previousAttempts);
      _isLoading = false;
    });
    _fadeController.forward(from: 0);
  }

  Future<void> _syncFromBackend(Box<TestAttempt> box) async {
    final apiService = ApiService();
    final remoteList = await apiService.fetchTestAttempts();
    bool changed = false;
    for (final data in remoteList) {
      final id = data['attempt_id'] as String? ?? '';
      if (id.isEmpty || box.containsKey(id)) continue;
      List<Question> questions = const [];
      if ((data['status'] as String? ?? '') == 'paused') {
        questions = await apiService.fetchQuestionsForAttempt(id);
      }
      final attempt =
          apiService.testAttemptFromJson(data, questions: questions);
      if (attempt != null) {
        await box.put(id, attempt);
        changed = true;
      }
    }
    if (changed) _refreshFromBox(box);
  }

  Future<void> _deleteAllTests() async {
    final box = await Hive.openBox<TestAttempt>('testAttempts');
    await box.clear();
    setState(() {
      _previousAttempts.clear();
      _pausedAttempts.clear();
    });
    showAppSnackBar('All tests have been deleted.');
    ApiService().deleteAllTestAttempts();
  }

  void _confirmDeletePausedTest(TestAttempt attempt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Progress'),
        content: const Text('Are you sure you want to delete this saved test?'),
        actions: [
          TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop()),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
            onPressed: () async {
              Navigator.of(ctx).pop();
              setState(() => _pausedAttempts
                  .removeWhere((a) => a.testId == attempt.testId));
              final box = await Hive.openBox<TestAttempt>('testAttempts');
              await box.delete(attempt.testId);
              ApiService().deleteTestAttempt(attempt.testId);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAllTests() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Tests'),
        content:
            const Text('Are you sure you want to delete all test attempts?'),
        actions: [
          TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop()),
          ElevatedButton(
            child: const Text('Delete'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteAllTests();
            },
          ),
        ],
      ),
    );
  }

  Map<String, int> getDailyAttemptCounts(List<TestAttempt> attempts) {
    final now = DateTime.now();
    final Map<String, int> result = {};
    for (int i = 6; i >= 0; i--) {
      final date =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final key = "${date.day}/${date.month}";
      result[key] = attempts
          .where((a) =>
              a.dateTime.year == date.year &&
              a.dateTime.month == date.month &&
              a.dateTime.day == date.day)
          .length;
    }
    return result;
  }

  Map<String, int> getMonthlyAttemptCounts(List<TestAttempt> attempts) {
    final now = DateTime.now();
    final Map<String, int> result = {};
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final key = "${date.month}/${date.year}";
      result[key] = attempts
          .where((a) =>
              a.dateTime.year == date.year && a.dateTime.month == date.month)
          .length;
    }
    return result;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = Translations.of(context);
    final hasData = _previousAttempts.isNotEmpty;
    final passed = _previousAttempts.where((a) => a.hasPassed).length;
    final failed = _previousAttempts.length - passed;
    final avgScore = (_stats['averageScore'] as num?)?.toDouble() ?? 0.0;
    final licenceWithCategories = Map<String, Map<String, int>>.from(
        _stats['licenceWithCategories'] ?? {});
    final licenceNames = licenceWithCategories.keys.toList();
    final selectedAttempts = _previousAttempts
        .where((a) => _effectiveLicence(a) == selectedLicence)
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    final dailyCounts = getDailyAttemptCounts(selectedAttempts);
    final monthlyCounts = getMonthlyAttemptCounts(selectedAttempts);

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
                    .animate(CurvedAnimation(
                        parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        child: _isLoading
            ? _buildSkeleton() // show shimmer immediately, no translation needed
            : SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: CustomScrollView(
                    slivers: [
                      // Header
                      SliverToBoxAdapter(child: _buildHeader()),

                      if (hasData) ...[
                        // Hero card
                        SliverToBoxAdapter(
                            child: _buildHeroCard(avgScore, passed, failed)),
                        // Quick stats
                        SliverToBoxAdapter(
                            child: _buildQuickStats(passed, failed)),
                        // In progress
                        if (_pausedAttempts.isNotEmpty)
                          SliverToBoxAdapter(child: _buildInProgressSection(t)),
                        // Licence tabs
                        if (licenceNames.length > 1)
                          SliverToBoxAdapter(
                              child: _buildLicenceTabs(licenceNames)),
                        // Charts
                        SliverToBoxAdapter(
                            child: _buildChartsSection(
                                dailyCounts, monthlyCounts, t)),
                        // Pie chart
                        if (licenceWithCategories[selectedLicence] != null)
                          SliverToBoxAdapter(
                              child: _buildPieSection(
                                  licenceWithCategories[selectedLicence]!, t)),
                        // Activity header
                        SliverToBoxAdapter(
                            child: _buildSectionHeader(t.home_recent_activity,
                                '${selectedAttempts.length} ${t.home_attempts}')),
                        // Activity list
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _StaggeredItem(
                              index: index,
                              child:
                                  _buildActivityItem(selectedAttempts[index]),
                            ),
                            childCount: selectedAttempts.length,
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 110)),
                      ] else if (_pausedAttempts.isNotEmpty) ...[
                        SliverToBoxAdapter(child: _buildInProgressSection(t)),
                        const SliverToBoxAdapter(child: SizedBox(height: 110)),
                      ] else ...[
                        SliverFillRemaining(child: _buildEmptyState(t)),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ── Section widgets ────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final t = Translations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.home_dashboard,
                    style:
                        TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                Text(t.home_my_progress,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.notifications_none_rounded,
                color: Colors.grey.shade700),
            onPressed: () {},
          ),
          if (_previousAttempts.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline_rounded,
                  color: Colors.grey.shade700),
              onPressed: _confirmDeleteAllTests,
            ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(double avgScore, int passed, int failed) {
    return _StaggeredItem(
      index: 0,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kHeroStart, _kHeroEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _kHeroEnd.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(Translations.of(context).home_overall_score,
                    style:
                        const TextStyle(color: Colors.white60, fontSize: 13)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_previousAttempts.length} ${Translations.of(context).home_tests}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: avgScore),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Text(
                '${v.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
            ),
            const SizedBox(height: 14),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: avgScore / 100),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: v,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(Colors.orange),
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _HeroStat(
                    value: passed.toString(),
                    label: Translations.of(context).home_passed,
                    color: Colors.greenAccent.shade400),
                const SizedBox(width: 28),
                _HeroStat(
                    value: failed.toString(),
                    label: Translations.of(context).home_failed,
                    color: Colors.red.shade200),
                const SizedBox(width: 28),
                _HeroStat(
                    value: _previousAttempts.length.toString(),
                    label: Translations.of(context).home_total,
                    color: Colors.white70),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(int passed, int failed) {
    return _StaggeredItem(
      index: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          children: [
            Expanded(
                child: _QuickStatCard(
              icon: Icons.check_circle_outline_rounded,
              value: passed.toString(),
              label: Translations.of(context).home_passed,
              iconColor: Colors.green.shade500,
              bgColor: Colors.green.withValues(alpha: 0.12),
            )),
            const SizedBox(width: 12),
            Expanded(
                child: _QuickStatCard(
              icon: Icons.cancel_outlined,
              value: failed.toString(),
              label: Translations.of(context).home_failed,
              iconColor: Colors.red.shade400,
              bgColor: Colors.red.withValues(alpha: 0.12),
            )),
            const SizedBox(width: 12),
            Expanded(
                child: _QuickStatCard(
              icon: Icons.pause_circle_outline_rounded,
              value: _pausedAttempts.length.toString(),
              label: Translations.of(context).home_paused,
              iconColor: Colors.orange.shade500,
              bgColor: Colors.orange.withValues(alpha: 0.12),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildInProgressSection(Translations t) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = _pausedAttempts.length == 1
        ? screenWidth - 40
        : (screenWidth * 0.82).clamp(0.0, 340.0);

    return _StaggeredItem(
      index: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              t.home_in_progress, '${_pausedAttempts.length} ${t.home_active}'),
          SizedBox(
            height: 190,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _pausedAttempts.length,
              itemBuilder: (context, index) => _InProgressCard(
                cardWidth: cardWidth,
                attempt: _pausedAttempts[index],
                onResume: () async {
                  final a = _pausedAttempts[index];
                  await Navigator.push(
                    context,
                    AppPageRoute(
                      builder: (_) => Testscreen(
                        questions: a.questions,
                        instantMarking: true,
                        licenceId: a.licenceId ?? '',
                        categoryId: a.categoryId ?? '',
                        licenceName: a.licenceName ?? '',
                        categoryName: a.categoryName ?? '',
                        initialQuestionIndex: a.currentQuestionIndex,
                        userSelections: a.userSelections,
                        resumeTestId: a.testId,
                        bcdCategoryId: a.bcdCategoryId,
                      ),
                    ),
                  );
                  _loadPreviousAttempts();
                },
                onDelete: () =>
                    _confirmDeletePausedTest(_pausedAttempts[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenceTabs(List<String> names) {
    return _StaggeredItem(
      index: 3,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: names.asMap().entries.map((e) {
            final isActive = selectedTabIndex == e.key;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => selectedTabIndex = e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Theme.of(context).colorScheme.surface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : [],
                  ),
                  child: Text(
                    e.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive ? Theme.of(context).colorScheme.onSurface : Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildChartsSection(
      Map<String, int> daily, Map<String, int> monthly, Translations t) {
    return _StaggeredItem(
      index: 4,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          children: [
            Expanded(
              child: _ChartCard(
                label: t.home_this_week,
                child: AttemptCountLineGraph(
                    data: daily, lineColor: Colors.deepPurple, height: 110),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ChartCard(
                label: t.home_this_month,
                child: AttemptCountLineGraph(
                    data: monthly, lineColor: Colors.orange, height: 110),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieSection(Map<String, int> data, Translations t) {
    return _StaggeredItem(
      index: 5,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.home_by_category,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 8),
              CategoryPieChart(data: data),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          Text(subtitle,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(TestAttempt attempt) {
    final isPassed = attempt.hasPassed;
    final color = isPassed ? Colors.green.shade500 : Colors.red.shade400;
    final bgColor = isPassed ? Colors.green.withValues(alpha: 0.12) : Colors.red.withValues(alpha: 0.12);
    final dt = attempt.dateTime;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        AppPageRoute(
            builder: (_) => AttemptDetailScreen(attempt: attempt)),
      ),
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(
                isPassed ? Icons.check_rounded : Icons.close_rounded,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          attempt.categoryName ?? 'Unknown',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (attempt.isBcd) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Category',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.deepPurple.shade300,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${dt.day}/${dt.month}/${dt.year}  ·  ${_effectiveLicence(attempt)}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${attempt.score.toInt()}%',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  isPassed ? 'Passed' : 'Failed',
                  style: TextStyle(fontSize: 11, color: color),
                ),
              ],
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Translations t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 200,
              child: AppLottie(
                asset: 'animations/no_attempts.json',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            Text(t.home_no_attempts,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              t.home_no_attempts_sub,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kHeroEnd,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () =>
                  Provider.of<MainScreenProvider>(context, listen: false)
                      .setIndex(1),
              child: Text(t.home_take_quiz,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade50,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(children: [
                  _sBox(140, 40, 8),
                  const Spacer(),
                  _sBox(40, 40, 20),
                ]),
                const SizedBox(height: 20),
                // Hero card
                _sBox(double.infinity, 190, 24),
                const SizedBox(height: 16),
                // Quick stats
                Row(children: [
                  Expanded(child: _sBox(double.infinity, 90, 16)),
                  const SizedBox(width: 12),
                  Expanded(child: _sBox(double.infinity, 90, 16)),
                  const SizedBox(width: 12),
                  Expanded(child: _sBox(double.infinity, 90, 16)),
                ]),
                const SizedBox(height: 24),
                // Charts
                Row(children: [
                  Expanded(child: _sBox(double.infinity, 110, 16)),
                  const SizedBox(width: 12),
                  Expanded(child: _sBox(double.infinity, 110, 16)),
                ]),
                const SizedBox(height: 24),
                // Activity items
                for (int i = 0; i < 4; i++) ...[
                  _sBox(double.infinity, 64, 0),
                  const Divider(height: 1),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sBox(double w, double h, double r) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r),
        ),
      );
}

// ─── Staggered item ──────────────────────────────────────────────────────────

class _StaggeredItem extends StatefulWidget {
  final Widget child;
  final int index;
  const _StaggeredItem({required this.child, required this.index});

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _scale = Tween<double>(begin: 0.96, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    Future.delayed(Duration(milliseconds: widget.index * 65), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _slide,
          child: ScaleTransition(scale: _scale, child: widget.child),
        ),
      );
}

// ─── Hero stat chip ──────────────────────────────────────────────────────────

class _HeroStat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _HeroStat(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      );
}

// ─── Quick stat card ─────────────────────────────────────────────────────────

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color iconColor, bgColor;
  const _QuickStatCard(
      {required this.icon,
      required this.value,
      required this.label,
      required this.iconColor,
      required this.bgColor});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: bgColor, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(height: 10),
            Text(value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
      );
}

// ─── Chart card wrapper ───────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final String label;
  final Widget child;
  const _ChartCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600)),
            child,
          ],
        ),
      );
}

// ─── In-progress horizontal card ─────────────────────────────────────────────

class _InProgressCard extends StatefulWidget {
  final TestAttempt attempt;
  final VoidCallback onResume;
  final VoidCallback onDelete;
  final double cardWidth;
  const _InProgressCard(
      {required this.attempt,
      required this.onResume,
      required this.onDelete,
      required this.cardWidth});

  @override
  State<_InProgressCard> createState() => _InProgressCardState();
}

class _InProgressCardState extends State<_InProgressCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.attempt;
    final answered = a.userSelections.length;
    final total = a.questions.length;
    final progress = total > 0 ? answered / total : 0.0;

    return Container(
      width: widget.cardWidth,
      margin: const EdgeInsets.only(right: 12, bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
              color: Colors.orange.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FadeTransition(
                opacity: Tween<double>(begin: 0.5, end: 1.0).animate(
                    CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pause_circle_outline,
                          size: 11, color: Colors.orange.shade700),
                      const SizedBox(width: 3),
                      Text(Translations.of(context).home_paused,
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              if (a.isBcd) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Category',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.deepPurple.shade300,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              const Spacer(),
              GestureDetector(
                onTap: widget.onDelete,
                child: Icon(Icons.close, size: 15, color: Colors.grey.shade400),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            a.categoryName ?? 'Unknown',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            'Q${a.currentQuestionIndex + 1} of $total',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 4,
                backgroundColor: Theme.of(context).dividerColor,
                color: Colors.orange,
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: a.questions.isNotEmpty ? widget.onResume : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: a.questions.isNotEmpty
                    ? Colors.orange
                    : Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    a.questions.isNotEmpty
                        ? Translations.of(context).home_resume
                        : 'Unavailable',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
