import 'dart:async';

import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/services/activity_reminder_service.dart';
import 'package:taxi_exam_app/core/services/app_review_service.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/core/widgets/app_back_button.dart';
import 'package:taxi_exam_app/features/smart_learning/screens/smart_learning_screen.dart';
import 'package:taxi_exam_app/features/smart_learning/screens/smart_session_screen.dart';

/// Post-chunk result screen shown after a Smart Learning session ends.
///
/// Displays:
///  - Animated score circle (correct / total for this session)
///  - Pass / fail status for the chunk
///  - Overall exam mastery progress with 70% threshold marker
///  - Contextual insight: how many questions until 70%, or "all mastered"
///  - Continue button (pops back to SmartExamScreen)
class SmartResultScreen extends StatefulWidget {
  final SmartExamEntry entry;
  final int chunkIndex; // -1 = mistakes mode
  final bool isMistakesMode;
  final bool hasPassed;
  final int correct;
  final int total;
  final int masteredCount;

  const SmartResultScreen({
    super.key,
    required this.entry,
    required this.chunkIndex,
    required this.isMistakesMode,
    required this.hasPassed,
    required this.correct,
    required this.total,
    required this.masteredCount,
  });

  @override
  State<SmartResultScreen> createState() => _SmartResultScreenState();
}

class _SmartResultScreenState extends State<SmartResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scoreAnim;
  late final Animation<double> _masteryAnim;

  double get _scorePercent =>
      widget.total == 0 ? 0 : widget.correct / widget.total;
  double get _masteryPercent => widget.entry.questionCount == 0
      ? 0
      : widget.masteredCount / widget.entry.questionCount;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _scoreAnim = Tween<double>(begin: 0, end: _scorePercent)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _masteryAnim = Tween<double>(begin: 0, end: _masteryPercent)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
    unawaited(AppReviewService.instance
        .maybeRequestAfterSmartSession(hasPassed: widget.hasPassed));
    unawaited(ActivityReminderService.schedule(
      examTitle: widget.entry.testName,
      payloadJson:
          ActivityReminderService.buildSmartPayload(widget.entry.testBcdId),
      locale: LocaleSettings.currentLocale.flutterLocale.languageCode,
    ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final t = Translations.of(context);

    final headerColor =
        widget.hasPassed ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    final totalQ = widget.entry.questionCount;
    final needed = (totalQ * 0.70).ceil();
    final remaining = (needed - widget.masteredCount).clamp(0, totalQ);
    final masteryPassed = widget.masteredCount >= needed;

    String insightText;
    IconData insightIcon;
    Color insightColor;
    if (masteryPassed) {
      insightText = t.smart_progress_ready_full_exam;
      insightIcon = Icons.emoji_events_rounded;
      insightColor = Colors.green.shade600;
    } else if (widget.masteredCount == 0) {
      insightText = t.smart_result_unlock_needed(count: needed);
      insightIcon = Icons.flag_rounded;
      insightColor = cs.primary;
    } else {
      final questionLabel = remaining == 1
          ? t.smart_category_question
          : t.smart_category_questions;
      insightText = t.smart_result_unlock_remaining(
        count: remaining,
        questionLabel: questionLabel,
      );
      insightIcon = Icons.trending_up_rounded;
      insightColor = cs.primary;
    }

    final chunkLabel = widget.isMistakesMode
        ? t.smart_mistakes_title
        : t.smart_chunk_n(n: widget.chunkIndex + 1);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: AppBackButton(onPressed: () => Navigator.of(context).pop()),
        backgroundColor: headerColor,
        foregroundColor: Colors.white,
        title: Text(chunkLabel,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // ── Score header ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ScoreHeader(
              hasPassed: widget.hasPassed,
              headerColor: headerColor,
              scoreAnim: _scoreAnim,
              correct: widget.correct,
              wrong: widget.total - widget.correct,
              total: widget.total,
            ),
          ),

          // ── Mastery progress card ──────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: _masteryAnim,
                builder: (_, __) => _MasteryCard(
                  mastered: widget.masteredCount,
                  total: totalQ,
                  masteryProgress: _masteryAnim.value,
                  masteryPassed: masteryPassed,
                  insightText: insightText,
                  insightIcon: insightIcon,
                  insightColor: insightColor,
                ),
              ),
            ),
          ),

          // ── Continue button ────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(t.smart_result_continue,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  if (!widget.hasPassed && !widget.isMistakesMode) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pushReplacement(
                          AppPageRoute(
                            builder: (_) => SmartSessionScreen(
                              entry: widget.entry,
                              chunkIndex: widget.chunkIndex,
                              isMistakesMode: false,
                            ),
                          ),
                        ),
                        child: Text(t.smart_chunk_retry,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Score header ─────────────────────────────────────────────────────────────

class _ScoreHeader extends StatelessWidget {
  final bool hasPassed;
  final Color headerColor;
  final Animation<double> scoreAnim;
  final int correct;
  final int wrong;
  final int total;

  const _ScoreHeader({
    required this.hasPassed,
    required this.headerColor,
    required this.scoreAnim,
    required this.correct,
    required this.wrong,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: scoreAnim,
            builder: (_, __) => SizedBox(
              width: 130,
              height: 130,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: scoreAnim.value,
                    strokeWidth: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(scoreAnim.value * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t.test_result_score_label,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            ),
            child: Text(
              hasPassed
                  ? t.smart_result_part_passed_caps
                  : t.smart_result_try_again_caps,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: t.test_result_correct,
                  value: '$correct',
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatChip(
                  label: t.test_result_wrong,
                  value: '$wrong',
                  icon: Icons.cancel_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatChip(
                  label: t.home_total,
                  value: '$total',
                  icon: Icons.list_alt_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatChip(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}

// ── Mastery card ─────────────────────────────────────────────────────────────

class _MasteryCard extends StatelessWidget {
  final int mastered;
  final int total;
  final double masteryProgress;
  final bool masteryPassed;
  final String insightText;
  final IconData insightIcon;
  final Color insightColor;

  const _MasteryCard({
    required this.mastered,
    required this.total,
    required this.masteryProgress,
    required this.masteryPassed,
    required this.insightText,
    required this.insightIcon,
    required this.insightColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final t = Translations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final barColor = masteryPassed ? Colors.green.shade500 : cs.primary;
    const passThreshold = 0.70;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHighest : theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: masteryPassed
              ? Colors.green.shade400.withValues(alpha: 0.4)
              : cs.onSurface.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_graph_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(t.smart_result_overall_mastery,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('$mastered / $total',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurface.withValues(alpha: 0.55))),
            ],
          ),
          const SizedBox(height: 14),

          // Mastery bar with 70% threshold marker
          LayoutBuilder(builder: (_, constraints) {
            final markerX = constraints.maxWidth * passThreshold;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: masteryProgress == 0
                        ? 0.0
                        : masteryProgress.clamp(0.04, 1.0),
                    minHeight: 12,
                    backgroundColor: cs.onSurface.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
                Positioned(
                  left: markerX - 1,
                  top: -4,
                  bottom: -4,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${(masteryProgress * 100).round()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: masteryPassed ? Colors.green.shade600 : cs.primary,
                ),
              ),
              const Spacer(),
              Text(t.smart_result_threshold,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurface.withValues(alpha: 0.45))),
            ],
          ),

          const SizedBox(height: 14),
          Divider(color: cs.outlineVariant, height: 1),
          const SizedBox(height: 14),

          // Insight row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(insightIcon, size: 18, color: insightColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  insightText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.75),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
