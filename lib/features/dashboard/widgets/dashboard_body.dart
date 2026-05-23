import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/utils/category_icon_mapper.dart';
import 'package:taxi_exam_app/core/widgets/adaptive_refresh_indicator.dart';
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

  void _syncExam(ExamDashboardStats? stats) {
    final newId = stats?.exam.id;
    if (newId == _lastExamId) return;
    _lastExamId = newId;
    _expandedCategories.clear();
    final cats = stats?.categoryStats;
    if (cats != null && cats.isNotEmpty) {
      _expandedCategories.add(cats.first.node.id);
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
