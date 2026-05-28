import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/constants/app_text_styles.dart';
import 'package:taxi_exam_app/core/constants/language_options.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/utils/category_icon_mapper.dart';
import 'package:taxi_exam_app/core/widgets/adaptive_refresh_indicator.dart';
import 'package:taxi_exam_app/features/bcd/bcd_text_utils.dart';
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
            child: PerformanceOverviewSection(
              stats: stats,
              provider: widget.provider,
              isLoading: widget.provider.switching,
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

        if (stats != null)
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
          )
        else if (showShimmer)
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
              child: WeeklyStreakSection(streak: stats.streak),
            )
          else
            const SliverToBoxAdapter(child: _WeeklyStreakShimmer()),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildCategorySlivers(ExamDashboardStats stats) {
    DateTime? latestDate(CategoryStats cat) => cat.batchStats
        .map((b) => b.lastAttemptDate)
        .whereType<DateTime>()
        .fold<DateTime?>(
            null, (best, d) => best == null || d.isAfter(best) ? d : best);

    final cats = List.of(stats.categoryStats!)
      ..sort((a, b) {
        final dateA = latestDate(a);
        final dateB = latestDate(b);
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateB.compareTo(dateA);
      });
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
              color: categoryColor(cat.node.name),
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
    final cs = Theme.of(context).colorScheme;
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
          else
            Column(
              children: items
                  .asMap()
                  .entries
                  .map(
                    (e) => Padding(
                      padding: EdgeInsets.only(
                          bottom: e.key < items.length - 1 ? 10 : 0),
                      child: _ChecklistCard(
                        title: e.value['title']!,
                        content: e.value['content']!,
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _ChecklistCard extends StatefulWidget {
  const _ChecklistCard({required this.title, required this.content});
  final String title;
  final String content;

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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: _expanded ? cs.surfaceContainerLow : theme.cardColor,
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
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
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
                              color: cs.onSurface.withValues(alpha: 0.07),
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        width: double.infinity,
                        child: Text(
                          widget.content,
                          style:
                              AppTextStyles.bodyMedium().copyWith(height: 1.5),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
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
                ? cs.onSurface.withValues(alpha: 0.12)
                : cs.onSurface.withValues(alpha: 0.08),
            highlightColor: isDark
                ? cs.onSurface.withValues(alpha: 0.06)
                : cs.onSurface.withValues(alpha: 0.03),
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
                    .withValues(alpha: 0.12)
                : Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.08),
            highlightColor: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.06)
                : Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.03),
            child: CategoryListItem(
              cat: stats.categoryStats![i],
              icon: categoryIcon(stats.categoryStats![i].node.name),
              color: categoryColor(stats.categoryStats![i].node.name),
              isExpanded: false,
              onToggle: () {},
              stats: stats,
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
          ? cs.onSurface.withValues(alpha: 0.12)
          : cs.onSurface.withValues(alpha: 0.08),
      highlightColor: isDark
          ? cs.onSurface.withValues(alpha: 0.06)
          : cs.onSurface.withValues(alpha: 0.03),
      child: WeeklyStreakSection(streak: _loadingStreak()),
    );
  }
}
