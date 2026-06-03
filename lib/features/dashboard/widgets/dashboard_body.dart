import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/constants/language_options.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/utils/category_icon_mapper.dart';
import 'package:taxi_exam_app/core/widgets/adaptive_refresh_indicator.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'package:taxi_exam_app/features/bcd/bcd_category_hub_screen.dart';
import 'package:taxi_exam_app/features/bcd/bcd_text_utils.dart';
import 'package:taxi_exam_app/features/bcd/bcd_traffic_signs_screen.dart';
import 'package:taxi_exam_app/features/profile/stats_screen.dart';
import 'package:taxi_exam_app/features/tests/saved_questions_preview_screen.dart';
import 'package:translator/translator.dart';
import '../models/dashboard_stats.dart';
import '../models/exam_node.dart';
import '../models/subscribed_exam.dart';
import '../providers/dashboard_provider.dart';
import 'batch_row.dart';
import 'category_list_item.dart';
import 'exam_carousel_section.dart';
import 'exam_nav_helpers.dart';
import 'hero_section.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/features/smart_learning/screens/smart_learning_screen.dart';
import 'performance_overview_section.dart';
import 'weekly_streak_section.dart';

class DashboardBody extends StatefulWidget {
  const DashboardBody({
    super.key,
    required this.provider,
    required this.onSubscribe,
    required this.onRefresh,
  });

  final DashboardProvider provider;
  final VoidCallback onSubscribe;
  final Future<void> Function() onRefresh;

  @override
  State<DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<DashboardBody> {
  // Tracks which category IDs are expanded (3-layer exams).
  final Set<String> _expandedCategories = {};
  String? _lastExamId;

  // Cached sorted category list — rebuilt only when exam changes.
  List<CategoryStats>? _sortedCategories;
  List<CategoryStats>? _lastCategoryStats;

  // Checklist state
  final _api = ApiService();
  List<dynamic> _checklists = [];
  bool _checklistLoading = false;
  String? _checklistExamId;
  // Persists across exam switches — keyed by examId.
  final Map<String, List<dynamic>> _checklistCache = {};

  void _syncExam(ExamDashboardStats? stats) {
    final newId = stats?.exam.id;
    if (newId == _lastExamId) return;
    _lastExamId = newId;
    _expandedCategories.clear();
    _checklistExamId = null;
    _sortedCategories = null;
    _lastCategoryStats = null;
    final cats = stats?.categoryStats;
    if (cats != null && cats.isNotEmpty) {
      _expandedCategories.add(cats.first.node.id);
    }
    if (stats != null && stats.exam.isBcd && newId != null) {
      if (_checklistCache.containsKey(newId)) {
        // Serve from cache — no API call.
        _checklists = _checklistCache[newId]!;
        _checklistLoading = false;
      } else {
        _checklists = [];
        _checklistLoading = true;
        // For 3-layer exams, checklists live on subcategory nodes, not the top
        // level. Collect subcategory IDs from categoryStats; fall back to the
        // exam's own ID for 2-layer exams.
        final categoryIds =
            stats.exam.hasCategories && stats.categoryStats != null
                ? stats.categoryStats!.map((c) => c.node.id).toList()
                : <String>[newId];
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _fetchChecklists(newId, categoryIds);
        });
      }
    } else {
      _checklists = [];
      _checklistLoading = false;
    }
  }

  Future<void> _fetchChecklists(String examId, List<String> categoryIds) async {
    if (_checklistExamId == examId) return;
    _checklistExamId = examId;
    final ids = categoryIds.map(int.tryParse).whereType<int>().toList();
    if (ids.isEmpty) {
      setState(() => _checklistLoading = false);
      return;
    }
    try {
      final results = await Future.wait(
        ids.map(_api.fetchBCDChecklists),
      );
      if (mounted && _checklistExamId == examId) {
        final combined = results.expand((list) => list).toList();
        _checklistCache[examId] = combined;
        setState(() {
          _checklists = combined;
          _checklistLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _checklistLoading = false);
    }
  }

  bool get _isLoading =>
      widget.provider.switching ||
      (widget.provider.selectedStats == null &&
          (widget.provider.status == DashboardStatus.loading ||
              widget.provider.status == DashboardStatus.idle));

  @override
  Widget build(BuildContext context) {
    final stats = widget.provider.selectedStats;
    _syncExam(stats);
    final t = Translations.of(context);
    final showShimmer = _isLoading;

    return AdaptiveRefreshIndicator(
      onRefresh: widget.onRefresh,
      slivers: [
        SliverToBoxAdapter(child: HeroSection(stats: stats)),

        SliverToBoxAdapter(
          child: ExamCarouselSection(
            provider: widget.provider,
            onSubscribe: widget.onSubscribe,
          ),
        ),

        if (stats != null)
          SliverToBoxAdapter(
            child: RepaintBoundary(
              child: PerformanceOverviewSection(
                stats: stats,
                provider: widget.provider,
                isLoading: widget.provider.switching,
              ),
            ),
          )
        else if (showShimmer)
          SliverToBoxAdapter(
            child: _PerformanceShimmer(provider: widget.provider),
          ),

        // Checklist section — BCD exams only, collapsible
        if (stats != null &&
            stats.exam.isBcd &&
            (_checklistLoading || _checklists.isNotEmpty))
          SliverToBoxAdapter(
            child: _ChecklistSection(
              checklists: _checklists,
              loading: _checklistLoading,
            ),
          ),

        // Smart Learning entry point — above Focus Areas
        SliverToBoxAdapter(
          child: showShimmer
              ? const _SmartLearningShimmer()
              : _SmartLearningBanner(
                  examBcdId:
                      int.tryParse(widget.provider.selectedExam?.id ?? ''),
                ),
        ),

        if (stats != null || showShimmer)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
              child: Text(
                t.dash_focus_areas,
                style: GoogleFonts.lexend(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),

        // 3-layer exam: build category rows lazily as they scroll into view.
        if (stats != null &&
            stats.categoryStats != null &&
            !widget.provider.switching)
          _buildCategorySlivers(stats)
        else if (showShimmer ||
            (stats != null &&
                stats.categoryStats != null &&
                widget.provider.switching))
          _buildFocusAreasShimmer(),

        // 2-layer exam: potentially 670+ batches — build lazily via SliverList.
        if (stats != null &&
            stats.categoryStats == null &&
            !widget.provider.switching)
          ..._buildBatchSlivers(context, stats),

        if (stats != null || showShimmer) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
              child: Text(
                t.dash_weekly_streak,
                style: GoogleFonts.lexend(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          if (stats != null && !widget.provider.switching)
            SliverToBoxAdapter(
              child: RepaintBoundary(
                child: WeeklyStreakSection(streak: stats.streak),
              ),
            )
          else
            const SliverToBoxAdapter(child: _WeeklyStreakShimmer()),
        ],

        if (stats != null && stats.exam.isBcd)
          SliverToBoxAdapter(
            child: _QuickAccessSection(
              examBcdId: int.tryParse(stats.exam.id) ?? 0,
              examName: stats.exam.name,
            ),
          ),

        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.of(context).padding.bottom + 80,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySlivers(ExamDashboardStats stats) {
    final rawCats = stats.categoryStats!;
    if (!identical(_lastCategoryStats, rawCats)) {
      _lastCategoryStats = rawCats;
      DateTime? latestDate(CategoryStats cat) => cat.batchStats
          .map((b) => b.lastAttemptDate)
          .whereType<DateTime>()
          .fold<DateTime?>(
              null, (best, d) => best == null || d.isAfter(best) ? d : best);
      _sortedCategories = List.of(rawCats)
        ..sort((a, b) {
          final dateA = latestDate(a);
          final dateB = latestDate(b);
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateB.compareTo(dateA);
        });
    }
    final cats = _sortedCategories!;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.builder(
        itemCount: cats.length,
        itemBuilder: (ctx, i) {
          final cat = cats[i];
          return Padding(
            padding: EdgeInsets.only(bottom: i < cats.length - 1 ? 10 : 0),
            child: CategoryListItem(
              cat: cat,
              icon: categoryIcon(cat.node.name),
              isExpanded: _expandedCategories.contains(cat.node.id),
              onToggle: () => setState(() {
                if (_expandedCategories.contains(cat.node.id)) {
                  _expandedCategories.remove(cat.node.id);
                } else {
                  _expandedCategories.add(cat.node.id);
                }
              }),
              stats: stats,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFocusAreasShimmer() {
    return const _FocusAreasShimmer();
  }

  List<Widget> _buildBatchSlivers(
    BuildContext context,
    ExamDashboardStats stats,
  ) {
    final batches = stats.allBatchStats;
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.builder(
          itemCount: batches.length,
          itemBuilder: (ctx, i) {
            final batch = batches[i];
            return Padding(
              padding: EdgeInsets.only(bottom: i < batches.length - 1 ? 8 : 0),
              child: BatchRow(
                batch: batch,
                exam: stats.exam,
                batchAttempts: batch.sortedAttempts,
                onTap: stats.exam.isBcd
                    ? () => launchBatch(ctx, stats.exam, batch.node, null)
                    : null,
              ),
            );
          },
        ),
      ),
    ];
  }
}

// ─── Checklist section ────────────────────────────────────────────────────────

class _ChecklistSection extends StatefulWidget {
  const _ChecklistSection({
    required this.checklists,
    required this.loading,
  });

  final List<dynamic> checklists;
  final bool loading;

  @override
  State<_ChecklistSection> createState() => _ChecklistSectionState();
}

class _ChecklistSectionState extends State<_ChecklistSection> {
  String _langCode = 'SV';
  bool _translating = false;
  final Map<String, List<Map<String, String>>> _cache = {};
  final _translator = GoogleTranslator();

  List<Map<String, String>> get _effectiveItems {
    if (_cache.containsKey(_langCode)) return _cache[_langCode]!;
    return widget.checklists
        .map((item) => {
              'title': cleanBcdText(item['title']?.toString() ?? ''),
              'content':
                  cleanBcdMultilineText(item['content']?.toString() ?? ''),
            })
        .toList();
  }

  Future<void> _onLanguageSelected(String code) async {
    if (code == _langCode) return;
    if (code == 'SV' || _cache.containsKey(code)) {
      setState(() => _langCode = code);
      return;
    }
    setState(() {
      _langCode = code;
      _translating = true;
    });
    try {
      final toLang = code.toLowerCase();
      final items = widget.checklists;
      final titleFutures = items
          .map((item) => _translator.translate(
                cleanBcdText(item['title']?.toString() ?? ''),
                from: 'sv',
                to: toLang,
              ))
          .toList();
      final contentFutures = items
          .map((item) => _translator.translate(
                cleanBcdMultilineText(item['content']?.toString() ?? ''),
                from: 'sv',
                to: toLang,
              ))
          .toList();
      final titles = await Future.wait(titleFutures);
      final contents = await Future.wait(contentFutures);
      if (!mounted) return;
      _cache[code] = List.generate(
        items.length,
        (i) => {'title': titles[i].text, 'content': contents[i].text},
      );
      setState(() => _translating = false);
    } catch (_) {
      if (mounted) setState(() => _translating = false);
    }
  }

  String _flagFor(String code) {
    final entry = languageOptions.firstWhere(
      (l) => l['code'] == code,
      orElse: () => {},
    );
    final label = entry['label'];
    return label != null && label.isNotEmpty ? label.split(' ').first : '🌐';
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final items = _effectiveItems;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.bcd_hub_checklist,
                  style: GoogleFonts.lexend(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: _onLanguageSelected,
                itemBuilder: (_) => languageOptions
                    .map((l) => PopupMenuItem<String>(
                          value: l['code'],
                          child: Text(l['label']!),
                        ))
                    .toList(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: cs.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: _translating
                      ? SizedBox(
                          width: 36,
                          height: 18,
                          child: Center(
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.primary,
                              ),
                            ),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _flagFor(_langCode),
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            Icon(LucideIcons.languages,
                                size: 16, color: cs.primary),
                          ],
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.loading)
            _ChecklistShimmer()
          else if (items.length == 1)
            _ChecklistCard(
              title: items.first['title']!,
              content: items.first['content']!,
            )
          else
            DecoratedBox(
              decoration: BoxDecoration(
                color: isDark ? cs.surfaceContainerHighest : theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: cs.onSurface.withValues(alpha: 0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: items.asMap().entries.map((e) {
                    final isLast = e.key == items.length - 1;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ChecklistCard(
                          title: e.value['title']!,
                          content: e.value['content']!,
                          nested: true,
                        ),
                        if (!isLast)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: cs.onSurface.withValues(alpha: 0.07),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChecklistCard extends StatefulWidget {
  const _ChecklistCard({
    required this.title,
    required this.content,
    this.nested = false,
  });
  final String title;
  final String content;

  /// When true, renders without its own card decoration (for use inside a grouped container).
  final bool nested;

  @override
  State<_ChecklistCard> createState() => _ChecklistCardState();
}

class _ChecklistCardState extends State<_ChecklistCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _curved;
  bool _expanded = false;
  bool _hasBeenExpanded = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _curved = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _hasBeenExpanded = true;
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
    });
  }

  Widget _buildInner(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _toggle,
            splashColor: cs.primary.withValues(alpha: 0.08),
            highlightColor: cs.primary.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.clipboardCheck,
                        color: cs.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ClipRect(
          child: AnimatedBuilder(
            animation: _curved,
            builder: (ctx, child) {
              if (_ctrl.status == AnimationStatus.dismissed) {
                return const SizedBox.shrink();
              }
              return Align(
                alignment: Alignment.topCenter,
                heightFactor: _curved.value,
                child: child,
              );
            },
            child: _hasBeenExpanded
                ? Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.07),
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    child: Text(
                      widget.content,
                      style: GoogleFonts.lexend(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (widget.nested) return _buildInner(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHighest : theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _expanded
              ? cs.primary.withValues(alpha: 0.15)
              : cs.onSurface.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _buildInner(context),
      ),
    );
  }
}

class _ChecklistShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: List.generate(3, (i) {
        return Padding(
          padding: EdgeInsets.only(bottom: i < 2 ? 10 : 0),
          child: Shimmer.fromColors(
            baseColor: isDark
                ? cs.onSurface.withValues(alpha: 0.15)
                : cs.onSurface.withValues(alpha: 0.08),
            highlightColor: isDark
                ? cs.onSurface.withValues(alpha: 0.28)
                : cs.onSurface.withValues(alpha: 0.15),
            child: const _ChecklistCard(title: '', content: ''),
          ),
        );
      }),
    );
  }
}

// ─── Shimmer skeletons ────────────────────────────────────────────────────────

class _PerformanceShimmer extends StatelessWidget {
  const _PerformanceShimmer({required this.provider});

  final DashboardProvider provider;

  @override
  Widget build(BuildContext context) {
    return PerformanceOverviewSection(
      stats: _loadingDashboardStats(),
      provider: provider,
      isLoading: true,
    );
  }
}

ExamDashboardStats _loadingDashboardStats() {
  final exam = SubscribedExam(
    id: '__loading_exam__',
    name: 'Loading',
    hasCategories: true,
    nodes: const [],
    subscribedAt: DateTime(2024),
    isBcd: true,
  );

  List<BatchStats> batchesFor(String prefix, int count) => List.generate(
        count,
        (i) => BatchStats(
          node: ExamNode(
            id: '$prefix-batch-$i',
            name: 'Batch ${i + 1}',
            nodeTypeIndex: 1,
            parentId: prefix,
          ),
          attempts: 0,
          averageScore: 0,
          bestScore: 0,
          totalDurationSeconds: 0,
          avgDurationSeconds: 0,
          targetDurationSeconds: 0,
          lastAttemptDate: null,
          isCompleted: false,
        ),
      );

  final categories = [
    CategoryStats(
      node: const ExamNode(
        id: 'loading-cat-1',
        name: 'Category One',
        nodeTypeIndex: 0,
      ),
      batchStats: batchesFor('loading-cat-1', 12),
    ),
    CategoryStats(
      node: const ExamNode(
        id: 'loading-cat-2',
        name: 'Category Two',
        nodeTypeIndex: 0,
      ),
      batchStats: batchesFor('loading-cat-2', 8),
    ),
    CategoryStats(
      node: const ExamNode(
        id: 'loading-cat-3',
        name: 'Category Three',
        nodeTypeIndex: 0,
      ),
      batchStats: batchesFor('loading-cat-3', 10),
    ),
    CategoryStats(
      node: const ExamNode(
        id: 'loading-cat-4',
        name: 'Category Four',
        nodeTypeIndex: 0,
      ),
      batchStats: batchesFor('loading-cat-4', 6),
    ),
  ];

  final allBatches = categories.expand((c) => c.batchStats).toList();

  return ExamDashboardStats(
    exam: exam,
    categoryStats: categories,
    allBatchStats: allBatches,
    streak: _loadingStreak(),
  );
}

StreakSummary _loadingStreak() {
  return const StreakSummary(
    currentStreak: 0,
    bestStreak: 0,
    thisWeekActiveDays: [],
    weeklyGoal: 5,
    thisWeekActiveDayCount: 0,
  );
}

class _FocusAreasShimmer extends StatelessWidget {
  const _FocusAreasShimmer();

  @override
  Widget build(BuildContext context) {
    final stats = _loadingDashboardStats();
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.builder(
        itemCount: stats.categoryStats!.length,
        itemBuilder: (ctx, i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Shimmer.fromColors(
            baseColor: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.15)
                : Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.08),
            highlightColor: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.28)
                : Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.15),
            child: Container(
              height: 76,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeeklyStreakShimmer extends StatelessWidget {
  const _WeeklyStreakShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: isDark
          ? cs.onSurface.withValues(alpha: 0.15)
          : cs.onSurface.withValues(alpha: 0.08),
      highlightColor: isDark
          ? cs.onSurface.withValues(alpha: 0.28)
          : cs.onSurface.withValues(alpha: 0.15),
      child: WeeklyStreakSection(streak: _loadingStreak()),
    );
  }
}

class _SmartLearningShimmer extends StatelessWidget {
  const _SmartLearningShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: isDark
          ? cs.onSurface.withValues(alpha: 0.15)
          : cs.onSurface.withValues(alpha: 0.08),
      highlightColor: isDark
          ? cs.onSurface.withValues(alpha: 0.28)
          : cs.onSurface.withValues(alpha: 0.15),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        height: 68,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

// ─── Quick Access section ─────────────────────────────────────────────────────

class _QuickAccessSection extends StatefulWidget {
  final int examBcdId;
  final String examName;

  const _QuickAccessSection({
    required this.examBcdId,
    required this.examName,
  });

  @override
  State<_QuickAccessSection> createState() => _QuickAccessSectionState();
}

class _QuickAccessSectionState extends State<_QuickAccessSection> {
  final _api = ApiService();
  bool _savedLoading = false;

  Future<void> _openDocuments() {
    return Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => BCDDocumentsScreen(
          categoryBcdId: widget.examBcdId,
          categoryName: widget.examName,
        ),
      ),
    );
  }

  void _openTrafficSigns() {
    Navigator.push(
      context,
      AppPageRoute(builder: (_) => const BCDTrafficSignsScreen()),
    );
  }

  void _openStatistics() {
    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => StatsScreen(
          subtitle: widget.examName,
          licenceNameFilter: widget.examName,
        ),
      ),
    );
  }

  Future<void> _openSavedQuestions() async {
    if (_savedLoading) return;
    setState(() => _savedLoading = true);
    try {
      final questions = await _api.fetchSavedQuestionsResolved(
        scopeType: 'bcd',
        bcdCategoryId: widget.examBcdId,
      );
      if (!mounted) return;
      if (questions.isEmpty) {
        showAppSnackBar(Translations.of(context).bcd_no_saved_questions);
        return;
      }
      Navigator.push(
        context,
        AppPageRoute(
          builder: (_) => SavedQuestionsPreviewScreen(
            questions: questions,
            licenceId: '',
            categoryId: '',
            licenceName: widget.examName,
            categoryName: widget.examName,
            bcdCategoryId: widget.examBcdId,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        showAppSnackBar(
          Translations.of(context).bcd_failed_saved,
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _savedLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.dash_quick_access,
            style: GoogleFonts.lexend(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossCount = constraints.maxWidth < 320 ? 2 : 4;
              final aspectRatio = crossCount == 4 ? 0.85 : 1.6;
              return GridView.count(
                crossAxisCount: crossCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: aspectRatio,
                children: [
                  _QuickTile(
                    icon: LucideIcons.bookOpen,
                    label: t.bcd_hub_theory_docs.replaceAll('\n', ' '),
                    iconColor: cs.tertiary,
                    onTap: _openDocuments,
                  ),
                  _QuickTile(
                    icon: LucideIcons.alertTriangle,
                    label: t.bcd_hub_traffic_signs,
                    iconColor: cs.error,
                    onTap: _openTrafficSigns,
                  ),
                  _QuickTile(
                    icon: LucideIcons.barChart2,
                    label: t.bcd_hub_statistics,
                    iconColor: cs.primary,
                    onTap: _openStatistics,
                  ),
                  _QuickTile(
                    icon: LucideIcons.bookmark,
                    label: t.bcd_hub_saved_questions.replaceAll('\n', ' '),
                    iconColor: cs.secondary,
                    loading: _savedLoading,
                    onTap: _openSavedQuestions,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;
  final bool loading;

  const _QuickTile({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: iconColor.withValues(alpha: 0.08),
          highlightColor: iconColor.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: loading
                      ? Center(
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: iconColor,
                            ),
                          ),
                        )
                      : Icon(icon, color: iconColor, size: 17),
                ),
                const SizedBox(height: 7),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lexend(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                    height: 1.2,
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

class _SmartLearningBanner extends StatelessWidget {
  final int? examBcdId;

  const _SmartLearningBanner({this.examBcdId});

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        AppPageRoute(builder: (_) => SmartLearningScreen(examBcdId: examBcdId)),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cs.primary.withValues(alpha: 0.14),
              cs.primary.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.psychology_rounded, color: cs.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.smart_learning_title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold, color: cs.primary)),
                  const SizedBox(height: 2),
                  Text(t.smart_learning_subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.6))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: cs.primary.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
