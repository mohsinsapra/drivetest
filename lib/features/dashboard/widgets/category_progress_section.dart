import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_exam_app/core/widgets/app_shimmer.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/utils/category_icon_mapper.dart';
import 'package:taxi_exam_app/features/bcd/bcd_text_utils.dart';
import '../models/dashboard_stats.dart';

/// Per-category progress breakdown — only for 3-layer (hasCategories) exams.
///
/// Shows each category with:
///   • Segmented batch dots (green=passed, amber=attempted, grey=untouched)
///   • Contextual status ("Needs practice", "Almost there!", "Complete ✓")
///   • Avg score with a warning indicator when below threshold
///   • Summary header: X/Y topics done · overall avg
class CategoryProgressSection extends StatelessWidget {
  const CategoryProgressSection({
    super.key,
    required this.stats,
    this.isLoading = false,
  });

  final ExamDashboardStats stats;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _Shimmer();

    final cats = stats.categoryStats;
    if (cats == null || cats.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final t = Translations.of(context);

    // Summary numbers
    final completedCats = cats
        .where(
            (c) => c.completedBatches == c.totalBatches && c.totalBatches > 0)
        .length;
    final touchedBatches =
        cats.expand((c) => c.batchStats).where((b) => b.attempts > 0);
    final overallAvg = touchedBatches.isEmpty
        ? 0.0
        : touchedBatches.map((b) => b.averageScore).reduce((a, b) => a + b) /
            touchedBatches.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHighest : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Summary header ──────────────────────────────────────────────
            _SummaryHeader(
              completedCats: completedCats,
              totalCats: cats.length,
              overallAvg: overallAvg,
              cs: cs,
            ),
            Divider(
                height: 1,
                thickness: 1,
                color: cs.onSurface.withValues(alpha: 0.07)),

            // ── Category rows ───────────────────────────────────────────────
            for (int i = 0; i < cats.length; i++) ...[
              _CategoryRow(cat: cats[i], t: t, cs: cs, theme: theme),
              if (i < cats.length - 1)
                Padding(
                  padding: const EdgeInsets.only(left: 52),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: cs.onSurface.withValues(alpha: 0.06),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Summary header ─────────────────────────────────────────────────────────────

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.completedCats,
    required this.totalCats,
    required this.overallAvg,
    required this.cs,
  });

  final int completedCats;
  final int totalCats;
  final double overallAvg;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final hasData = overallAvg > 0;
    final allDone = completedCats == totalCats;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allDone
                      ? t.dash_progress_all_done
                      : t.dash_progress_topics_done
                          .replaceAll('{done}', '$completedCats')
                          .replaceAll('{total}', '$totalCats'),
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: allDone
                        ? Colors.green.shade600
                        : cs.onSurface.withValues(alpha: 0.85),
                    height: 1.2,
                  ),
                ),
                if (!allDone) ...[
                  const SizedBox(height: 2),
                  Text(
                    hasData
                        ? t.dash_progress_avg_hint.replaceAll(
                            '{score}', overallAvg.toStringAsFixed(0))
                        : t.dash_progress_no_attempts,
                    style: GoogleFonts.lexend(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface.withValues(alpha: 0.45),
                      height: 1.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (allDone)
            Icon(Icons.emoji_events_rounded,
                size: 22, color: Colors.amber.shade600)
          else
            _RingProgress(
              value: completedCats / totalCats,
              hasData: hasData,
              cs: cs,
            ),
        ],
      ),
    );
  }
}

// Small circular progress ring for the summary header
class _RingProgress extends StatelessWidget {
  const _RingProgress({
    required this.value,
    required this.hasData,
    required this.cs,
  });

  final double value;
  final bool hasData;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: 3.5,
            backgroundColor: cs.onSurface.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(
              hasData ? cs.primary : cs.onSurface.withValues(alpha: 0.2),
            ),
            strokeCap: StrokeCap.round,
          ),
          Text(
            '${(value * 100).round()}%',
            style: GoogleFonts.lexend(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withValues(alpha: 0.7),
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category row ───────────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.cat,
    required this.t,
    required this.cs,
    required this.theme,
  });

  final CategoryStats cat;
  final Translations t;
  final ColorScheme cs;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final completed = cat.completedBatches;
    final total = cat.totalBatches;
    final touched = cat.touchedBatches;
    final avg = cat.averageScore;
    final isComplete = completed == total && total > 0;
    final notStarted = touched == 0;
    final almostDone =
        !isComplete && total > 0 && (total - completed) <= 2 && touched > 0;
    final lowScore = touched > 0 && avg < 70;

    final String statusText;
    final Color statusColor;

    if (isComplete) {
      statusText = t.dash_cat_complete;
      statusColor = Colors.green.shade600;
    } else if (notStarted) {
      statusText = t.dash_cat_not_started;
      statusColor = cs.onSurface.withValues(alpha: 0.3);
    } else if (almostDone) {
      statusText =
          t.dash_cat_almost_done.replaceAll('{n}', '${total - completed}');
      statusColor = cs.primary;
    } else if (lowScore) {
      statusText = t.dash_cat_needs_practice;
      statusColor = Colors.orange.shade500;
    } else {
      statusText = t.dash_cat_in_progress
          .replaceAll('{done}', '$completed')
          .replaceAll('{total}', '$total');
      statusColor = cs.primary;
    }

    final name =
        formatNodeName(stripAppSuffix(cat.node.name), t.node_group_prefix);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isComplete
                  ? Colors.green.shade500.withValues(alpha: 0.12)
                  : notStarted
                      ? cs.onSurface.withValues(alpha: 0.06)
                      : cs.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              categoryIcon(cat.node.name),
              size: 14,
              color: isComplete
                  ? Colors.green.shade600
                  : notStarted
                      ? cs.onSurface.withValues(alpha: 0.3)
                      : cs.primary,
            ),
          ),
          const SizedBox(width: 10),
          // Text + segments
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface
                              .withValues(alpha: notStarted ? 0.45 : 0.88),
                          height: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!notStarted && !isComplete) ...[
                      const SizedBox(width: 6),
                      Text(
                        '$completed/$total',
                        style: GoogleFonts.lexend(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                    if (isComplete) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.check_circle_rounded,
                          size: 14, color: Colors.green.shade500),
                    ],
                    if (lowScore && !isComplete) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.warning_amber_rounded,
                          size: 13, color: Colors.orange.shade400),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                // Segmented batch dots
                _BatchDots(
                    batches: cat.batchStats, cs: cs, isComplete: isComplete),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      statusText,
                      style: GoogleFonts.lexend(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                        height: 1.2,
                      ),
                    ),
                    if (!notStarted && !isComplete) ...[
                      Text(
                        '  •  ${t.dash_avg_score_label.replaceAll('{score}', avg.toStringAsFixed(0))}',
                        style: GoogleFonts.lexend(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface.withValues(alpha: 0.38),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Segmented batch dots ───────────────────────────────────────────────────────

class _BatchDots extends StatelessWidget {
  const _BatchDots({
    required this.batches,
    required this.cs,
    required this.isComplete,
  });

  final List<BatchStats> batches;
  final ColorScheme cs;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    // Cap visual dots at 20 to avoid overflow
    final displayed = batches.take(20).toList();
    return Wrap(
      spacing: 3,
      runSpacing: 3,
      children: displayed.map((b) {
        final Color dotColor;
        if (b.isCompleted) {
          dotColor = Colors.green.shade500;
        } else if (b.attempts > 0) {
          dotColor = b.averageScore >= 70
              ? cs.primary.withValues(alpha: 0.6)
              : Colors.orange.shade400;
        } else {
          dotColor = cs.onSurface.withValues(alpha: 0.15);
        }
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        );
      }).toList(),
    );
  }
}

// ── Shimmer ────────────────────────────────────────────────────────────────────

class _Shimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: AppShimmer(
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
