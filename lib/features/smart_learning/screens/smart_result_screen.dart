import 'dart:async';

import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/core/services/analytics_service.dart';
import 'package:taxi_exam_app/core/services/activity_reminder_service.dart';
import 'package:taxi_exam_app/core/services/app_review_service.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/core/widgets/app_back_button.dart';
import 'package:taxi_exam_app/core/widgets/app_button.dart';
import 'package:taxi_exam_app/core/widgets/option_tile.dart';
import 'package:taxi_exam_app/features/smart_learning/screens/smart_learning_screen.dart';

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
  final bool isReviewMode;
  final int reviewIndex;
  final bool hasPassed;
  final int correct;
  final int total;
  final int masteredCount;

  /// Questions the user answered wrong in this session.
  final List<Question> wrongQuestions;

  /// Maps questionId → the wrong option label the user selected.
  final Map<String, String> wrongSelections;

  /// Called when the user taps Retry. Returns the SmartTestScreen to push,
  /// or null if the fetch failed (the callback handles showing the error).
  final Future<Widget?> Function()? onRetry;

  const SmartResultScreen({
    super.key,
    required this.entry,
    required this.chunkIndex,
    required this.isMistakesMode,
    this.isReviewMode = false,
    this.reviewIndex = 0,
    required this.hasPassed,
    required this.correct,
    required this.total,
    required this.masteredCount,
    this.wrongQuestions = const [],
    this.wrongSelections = const {},
    this.onRetry,
  });

  @override
  State<SmartResultScreen> createState() => _SmartResultScreenState();
}

class _SmartResultScreenState extends State<SmartResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scoreAnim;
  late final Animation<double> _masteryAnim;
  bool _retrying = false;

  double get _scorePercent =>
      widget.total == 0 ? 0 : widget.correct / widget.total;
  double get _masteryPercent => widget.entry.questionCount == 0
      ? 0
      : widget.masteredCount / widget.entry.questionCount;

  @override
  void initState() {
    super.initState();
    AnalyticsService().logSmartLearningCompleted();
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
        : widget.isReviewMode
            ? t.smart_review_n
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

          // ── Continue / Retry buttons ───────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  AppFilledButton(
                    label: t.smart_result_continue,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  if (!widget.hasPassed &&
                      !widget.isMistakesMode &&
                      widget.onRetry != null) ...[
                    const SizedBox(height: 12),
                    AppOutlinedButton(
                      label: t.smart_chunk_retry,
                      minimumWidth: 0,
                      loading: _retrying,
                      onPressed: _retrying
                          ? null
                          : () async {
                              setState(() => _retrying = true);
                              final screen = await widget.onRetry!();
                              if (!context.mounted) return;
                              setState(() => _retrying = false);
                              if (screen == null) return;
                              Navigator.of(context).pushReplacement(
                                AppPageRoute(builder: (_) => screen),
                              );
                            },
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Wrong question review list ─────────────────────────────────────
          if (widget.wrongQuestions.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Icon(Icons.cancel_outlined,
                        size: 18, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 8),
                    Text(
                      t.test_result_wrong_answers,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .error
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${widget.wrongQuestions.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final q = widget.wrongQuestions[index];
                    final wrongLabel = widget.wrongSelections[q.questionId];
                    return _WrongQuestionCard(
                      index: index,
                      question: q,
                      wrongLabel: wrongLabel,
                      onTap: () => _showAnswerReview(context, q, wrongLabel),
                    );
                  },
                  childCount: widget.wrongQuestions.length,
                ),
              ),
            ),
          ] else
            const SliverPadding(
              padding: EdgeInsets.only(bottom: 48),
              sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
        ],
      ),
    );
  }

  void _showAnswerReview(
      BuildContext context, Question question, String? wrongLabel) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AnswerReviewSheet(
        question: question,
        wrongLabel: wrongLabel ?? '',
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

// ── Wrong question card ───────────────────────────────────────────────────────

class _WrongQuestionCard extends StatelessWidget {
  final int index;
  final Question question;
  final String? wrongLabel;
  final VoidCallback onTap;

  const _WrongQuestionCard({
    required this.index,
    required this.question,
    required this.wrongLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    String? wrongText;
    String? correctText;
    if (wrongLabel != null && wrongLabel!.isNotEmpty) {
      try {
        wrongText = question.options
            .firstWhere((o) => o.optionLabel == wrongLabel)
            .text;
      } catch (_) {}
    }
    try {
      correctText = question.options
          .firstWhere((o) => o.optionLabel == question.correctAnswer)
          .text;
    } catch (_) {}

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHighest : theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: cs.error.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.error.withValues(alpha: 0.12),
                  ),
                  child: Center(
                    child: Icon(Icons.close, size: 13, color: cs.error),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    Option.stripHtml(question.text),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: cs.onSurface.withValues(alpha: 0.35)),
              ],
            ),
            if (wrongText != null || correctText != null) ...[
              const SizedBox(height: 10),
              if (wrongText != null)
                _AnswerRow(
                  label: wrongText,
                  isCorrect: false,
                ),
              if (correctText != null)
                _AnswerRow(
                  label: correctText,
                  isCorrect: true,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  final String label;
  final bool isCorrect;

  const _AnswerRow({required this.label, required this.isCorrect});

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? Colors.green.shade600 : Colors.red.shade600;
    final bg = isCorrect
        ? Colors.green.withValues(alpha: 0.08)
        : Colors.red.withValues(alpha: 0.08);
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              Option.stripHtml(label),
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Answer review bottom sheet ────────────────────────────────────────────────

class _AnswerReviewSheet extends StatelessWidget {
  final Question question;
  final String wrongLabel;

  const _AnswerReviewSheet({
    required this.question,
    required this.wrongLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final t = Translations.of(context);
    final mq = MediaQuery.of(context);

    return Container(
      decoration: BoxDecoration(
        color:
            isDark ? cs.surfaceContainerHighest : theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, mq.viewInsets.bottom + 32),
      constraints: BoxConstraints(
        maxHeight: mq.size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t.test_result_question_review,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            Option.stripHtml(question.text),
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: question.options.map((opt) {
                  final isWrong = opt.optionLabel == wrongLabel &&
                      wrongLabel.isNotEmpty &&
                      opt.optionLabel != question.correctAnswer;
                  final isCorrect = opt.optionLabel == question.correctAnswer;
                  return Option(
                    text: opt.text,
                    optionLabel: opt.optionLabel,
                    imageUrl: opt.imageUrl.isNotEmpty ? opt.imageUrl : null,
                    isSelected: isWrong,
                    showInstantMarking: true,
                    isCorrectAnswer: isCorrect,
                    onTap: () {},
                    explanation: isCorrect ? question.answerExplanation : null,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppFilledButton(
            label: t.smart_result_continue,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
