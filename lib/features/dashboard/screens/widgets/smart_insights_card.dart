import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import '../../models/dashboard_stats.dart';

class SmartInsightsCard extends StatelessWidget {
  const SmartInsightsCard({super.key, required this.stats});

  final ExamDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final t = Translations.of(context);

    final strongest = stats.strongestBatch;
    final weakest = stats.weakestBatch;
    final continueNode = stats.continueNode;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          if (strongest != null)
            _InsightTile(
              icon: Icons.emoji_events_rounded,
              iconColor: Colors.amber,
              title: t.dash_insight_strongest,
              subtitle: t.dash_insight_area_detail
                  .replaceAll('{name}', strongest.node.name)
                  .replaceAll(
                      '{score}', strongest.averageScore.toStringAsFixed(0)),
              isFirst: true,
            ),
          if (weakest != null)
            _InsightTile(
              icon: Icons.trending_down_rounded,
              iconColor: Colors.orange,
              title: t.dash_insight_weakest,
              subtitle: t.dash_insight_area_detail
                  .replaceAll('{name}', weakest.node.name)
                  .replaceAll(
                      '{score}', weakest.averageScore.toStringAsFixed(0)),
            ),
          if (continueNode != null)
            _InsightTile(
              icon: Icons.arrow_forward_ios_rounded,
              iconColor: cs.primary,
              title: t.dash_insight_focus,
              subtitle: t.dash_insight_focus_detail
                  .replaceAll('{name}', continueNode.node.name),
            ),
          _InsightTile(
            icon: Icons.lightbulb_outline_rounded,
            iconColor: Colors.green,
            title: t.dash_insight_continue_learning,
            subtitle: _continueLearningText(t),
            isLast: true,
          ),
        ],
      ),
    );
  }

  String _continueLearningText(Translations t) {
    final progress = stats.overallProgressPercent;
    if (progress == 0) {
      return t.dash_insight_start.replaceAll('{name}', stats.exam.name);
    }
    if (progress >= 100) {
      return t.dash_insight_all_done;
    }
    final done = stats.completedBatchCount;
    final total = stats.totalBatchCount;
    return t.dash_insight_progress
        .replaceAll('{done}', '$done')
        .replaceAll('{total}', '$total')
        .replaceAll('{pct}', progress.toStringAsFixed(0));
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.isFirst = false,
    this.isLast = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha: 0.55),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 62,
            color: cs.onSurface.withValues(alpha: 0.06),
          ),
      ],
    );
  }
}
