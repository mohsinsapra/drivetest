import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/providers/notification_provider.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/features/bcd/bcd_test_screen.dart';
import 'package:taxi_exam_app/features/notifications/notifications_screen.dart';
import '../models/dashboard_stats.dart';
import '../models/exam_node.dart';
import '../models/subscribed_exam.dart';
import '../providers/dashboard_provider.dart';
import 'widgets/batch_progress_card.dart';
import 'widgets/category_progress_card.dart';
import 'widgets/exam_overview_card.dart';
import 'widgets/section_header.dart';
import 'widgets/selected_exam_summary_card.dart';
import 'widgets/smart_insights_card.dart';
import 'widgets/exam_deadline_card.dart';
import 'widgets/weekly_streak_card.dart';

class ExamDashboardScreen extends StatefulWidget {
  const ExamDashboardScreen({super.key});

  @override
  State<ExamDashboardScreen> createState() => _ExamDashboardScreenState();
}

class _ExamDashboardScreenState extends State<ExamDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Defer init until the first frame so context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(Translations.of(context).dash_my_progress),
        actions: [
          // Subtle spinner while background API sync runs
          if (provider.syncing)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync_rounded),
              tooltip: Translations.of(context).dash_sync_from_server,
              onPressed: () => context.read<DashboardProvider>().syncNow(),
            ),
          // Notification bell with unread badge
          Consumer<NotificationProvider>(
            builder: (_, notifProvider, __) => Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded),
                  onPressed: () => Navigator.of(context).push(
                    AppPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  ),
                ),
                if (notifProvider.unreadCount > 0)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: switch (provider.status) {
        DashboardStatus.idle || DashboardStatus.loading =>
          const Center(child: CircularProgressIndicator()),
        DashboardStatus.error => _ErrorView(
            message: provider.error ?? Translations.of(context).dash_unknown_error,
            onRetry: () => context.read<DashboardProvider>().init(),
          ),
        DashboardStatus.loaded => RefreshIndicator(
            onRefresh: () =>
                context.read<DashboardProvider>().syncNow(),
            child: _DashboardBody(provider: provider),
          ),
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.provider});

  final DashboardProvider provider;

  @override
  Widget build(BuildContext context) {
    final stats = provider.selectedStats;
    final t = Translations.of(context);

    return CustomScrollView(
      slivers: [
        // ── 0. Exam deadline card ────────────────────────────────────────
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 8),
            child: ExamDeadlineCard(),
          ),
        ),

        // ── 1. Top exam overview ─────────────────────────────────────────
        SliverToBoxAdapter(
          child: SectionHeader(
            title: t.dash_my_exams,
            subtitle: t.dash_tap_to_dive,
          ),
        ),
        SliverToBoxAdapter(
          child: _ExamOverviewRow(provider: provider),
        ),

        // ── 2. Selected exam deep-dive ───────────────────────────────────
        if (stats != null) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SectionHeader(
                title: stats.exam.name,
                subtitle: t.dash_overview,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SelectedExamSummaryCard(
              stats: stats,
              onContinueTap: stats.continueNode == null
                  ? null
                  : () {
                      final batch = stats.continueNode!;
                      // Resolve category name for 3-layer exams
                      String? catName;
                      if (stats.exam.hasCategories) {
                        catName = stats.categoryStats
                            ?.where((c) => c.node.id == batch.node.parentId)
                            .map((c) => c.node.name)
                            .firstOrNull;
                      }
                      _launchBatch(context, stats.exam, batch.node, catName);
                    },
            ),
          ),

          // ── 3. Categories + batches ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: SectionHeader(
                title: stats.exam.hasCategories ? t.dash_categories_header : t.dash_batches_header,
                subtitle: stats.exam.hasCategories ? t.dash_expand_categories : null,
              ),
            ),
          ),

          if (stats.exam.hasCategories)
            _ThreeLayerContent(stats: stats)
          else
            _TwoLayerContent(stats: stats),

          // ── 4. Weekly Streak ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: SectionHeader(
                title: t.dash_weekly_streak,
                subtitle: t.dash_consistency_builds,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: WeeklyStreakCard(streak: stats.streak),
          ),

          // ── 5. Smart Insights ────────────────────────────────────────
          if (stats.totalAttempts > 0) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: SectionHeader(
                  title: t.dash_smart_insights,
                  subtitle: t.dash_based_on_attempts,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SmartInsightsCard(stats: stats),
            ),
          ],

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overview row (horizontal scroll)
// ─────────────────────────────────────────────────────────────────────────────

class _ExamOverviewRow extends StatelessWidget {
  const _ExamOverviewRow({required this.provider});

  final DashboardProvider provider;

  @override
  Widget build(BuildContext context) {
    final exams = provider.exams;
    final selectedId = provider.selectedExam?.id;

    return SizedBox(
      height: 170,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: exams.length,
        itemBuilder: (context, i) {
          final exam = exams[i];
          final progress = provider.overviewProgress[exam.id] ?? 0;

          // Derive continue label from selected stats if this exam is selected
          String? continueLabel;
          if (exam.id == selectedId && provider.selectedStats != null) {
            final next = provider.selectedStats!.continueNode;
            if (next != null) {
              continueLabel = Translations.of(context)
                  .dash_continue_label
                  .replaceAll('{name}', next.node.name);
            }
          }

          return ExamOverviewCard(
            exam: exam,
            progressPercent: progress,
            isSelected: exam.id == selectedId,
            continueLabel: continueLabel,
            onTap: () => context.read<DashboardProvider>().selectExam(exam),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Test launcher
// ─────────────────────────────────────────────────────────────────────────────

/// Navigates to [BCDTestScreen] for BCD batch nodes. No-op for non-BCD.
void _launchBatch(
  BuildContext context,
  SubscribedExam exam,
  ExamNode batchNode,
  String? categoryName,
) {
  if (!exam.isBcd) return;

  // Derive the direct-parent bcd_id that BCDTestScreen expects
  final parentBcdId = int.tryParse(batchNode.parentId ?? exam.id) ?? 0;
  final parentName = categoryName ?? exam.name;

  Navigator.push(
    context,
    AppPageRoute(
      builder: (_) => BCDTestScreen(
        testId: int.tryParse(batchNode.id) ?? 0,
        testName: batchNode.name,
        passScore: batchNode.passScore,
        timeLimit: batchNode.targetDurationSeconds ~/ 60,
        parentCategoryName: parentName,
        parentCategoryBcdId: parentBcdId,
      ),
    ),
  ).then((_) {
    // Refresh stats after the user returns from the test
    if (context.mounted) context.read<DashboardProvider>().refresh();
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// 3-layer content: expandable categories → batches
// ─────────────────────────────────────────────────────────────────────────────

class _ThreeLayerContent extends StatefulWidget {
  const _ThreeLayerContent({required this.stats});
  final ExamDashboardStats stats;

  @override
  State<_ThreeLayerContent> createState() => _ThreeLayerContentState();
}

class _ThreeLayerContentState extends State<_ThreeLayerContent> {
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    // Auto-expand first category
    final cats = widget.stats.categoryStats;
    if (cats != null && cats.isNotEmpty) {
      _expanded.add(cats.first.node.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = widget.stats.categoryStats ?? [];

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final catStat = cats[index];
          final isExpanded = _expanded.contains(catStat.node.id);

          return _CategorySection(
            catStat: catStat,
            isExpanded: isExpanded,
            exam: widget.stats.exam,
            onToggle: () => setState(() {
              if (isExpanded) {
                _expanded.remove(catStat.node.id);
              } else {
                _expanded.add(catStat.node.id);
              }
            }),
          );
        },
        childCount: cats.length,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Collapsible category section
// ─────────────────────────────────────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.catStat,
    required this.isExpanded,
    required this.exam,
    required this.onToggle,
  });

  final CategoryStats catStat;
  final bool isExpanded;
  final SubscribedExam exam;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            // Category header — tappable to expand/collapse
            CategoryProgressCard(
              stats: catStat,
              nested: true,
              showChevron: true,
              isExpanded: isExpanded,
              onTap: onToggle,
            ),

            // Animated batch list
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Column(
                      children: [
                        Divider(
                          height: 1,
                          indent: 14,
                          endIndent: 14,
                          color: cs.onSurface.withOpacity(0.08),
                        ),
                        ...catStat.batchStats.asMap().entries.map((entry) {
                          final i = entry.key;
                          final batchStat = entry.value;
                          final isLast = i == catStat.batchStats.length - 1;
                          return Column(
                            children: [
                              BatchProgressCard(
                                stats: batchStat,
                                nested: true,
                                onTap: exam.isBcd
                                    ? () => _launchBatch(
                                          context,
                                          exam,
                                          batchStat.node,
                                          catStat.node.name,
                                        )
                                    : null,
                              ),
                              if (!isLast)
                                Divider(
                                  height: 1,
                                  indent: 36,
                                  endIndent: 14,
                                  color: cs.onSurface.withOpacity(0.05),
                                ),
                            ],
                          );
                        }),
                        const SizedBox(height: 4),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2-layer content: batches directly, no category wrapper
// ─────────────────────────────────────────────────────────────────────────────

class _TwoLayerContent extends StatelessWidget {
  const _TwoLayerContent({required this.stats});
  final ExamDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final batchStat = stats.allBatchStats[index];
          return BatchProgressCard(
            stats: batchStat,
            onTap: stats.exam.isBcd
                ? () => _launchBatch(context, stats.exam, batchStat.node, null)
                : null,
          );
        },
        childCount: stats.allBatchStats.length,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error view
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(Translations.of(context).dash_retry),
            ),
          ],
        ),
      ),
    );
  }
}
