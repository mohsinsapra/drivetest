import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/features/tests/test_screen.dart';

class ResultScreen extends StatefulWidget {
  final List<Question> questions;
  final Map<int, String> userSelections;
  final String licenceId;
  final String categoryId;
  final bool hasPassed;
  final double passScorePercent;

  const ResultScreen({
    super.key,
    required this.questions,
    required this.userSelections,
    required this.licenceId,
    required this.categoryId,
    required this.hasPassed,
    this.passScorePercent = 70,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _progressAnim;
  late final int _correct;
  late final double _scorePercent;

  @override
  void initState() {
    super.initState();
    int c = 0;
    for (int i = 0; i < widget.questions.length; i++) {
      final sel = widget.userSelections[i];
      if (sel != null && sel == widget.questions[i].correctAnswer) c++;
    }
    _correct = c;
    _scorePercent =
        widget.questions.isEmpty ? 0 : (c / widget.questions.length) * 100;

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnim = Tween<double>(begin: 0, end: _scorePercent / 100).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final isPassed = widget.hasPassed;
    final primaryColor =
        isPassed ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final unanswered = widget.questions.length - widget.userSelections.length;
    final wrong = widget.questions.length - _correct - unanswered;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Text(isPassed
            ? t.test_result_screen_passed_title
            : t.test_result_screen_failed_title),
        elevation: 0,
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _ScoreHeader(
              isPassed: isPassed,
              primaryColor: primaryColor,
              progressAnim: _progressAnim,
              scorePercent: _scorePercent,
              correct: _correct,
              wrong: wrong,
              unanswered: unanswered,
              total: widget.questions.length,
              passScorePercent: widget.passScorePercent,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _StatsCard(
                scorePercent: _scorePercent,
                passScorePercent: widget.passScorePercent,
                correct: _correct,
                wrong: wrong,
                unanswered: unanswered,
                total: widget.questions.length,
                isPassed: isPassed,
                primaryColor: primaryColor,
              ),
            ),
          ),
          if (widget.questions.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              sliver: SliverToBoxAdapter(
                child: Text(
                  t.test_result_question_review,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final q = widget.questions[index];
                    final sel = widget.userSelections[index];
                    final isCorrect = sel == q.correctAnswer;
                    return _QuestionReviewCard(
                      index: index,
                      question: q,
                      userAnswer: sel,
                      isCorrect: isCorrect,
                      onTap: () => Navigator.push(
                        context,
                        AppPageRoute(
                          builder: (_) => TestscreenWrapper(
                            questions: widget.questions,
                            instantMarking: true,
                            licenceId: widget.licenceId,
                            categoryId: widget.categoryId,
                            initialQuestionIndex: index,
                            userSelections: widget.userSelections,
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: widget.questions.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Score header ───────────────────────────────────────────────────────────────

class _ScoreHeader extends StatelessWidget {
  final bool isPassed;
  final Color primaryColor;
  final Animation<double> progressAnim;
  final double scorePercent;
  final int correct;
  final int wrong;
  final int unanswered;
  final int total;
  final double passScorePercent;

  const _ScoreHeader({
    required this.isPassed,
    required this.primaryColor,
    required this.progressAnim,
    required this.scorePercent,
    required this.correct,
    required this.wrong,
    required this.unanswered,
    required this.total,
    required this.passScorePercent,
  });

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: progressAnim,
            builder: (context, _) => SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progressAnim.value,
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
                          '${(progressAnim.value * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 36,
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
              isPassed
                  ? t.test_result_passed_badge
                  : t.test_result_failed_badge,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isPassed
                ? t.test_result_passed_message
                : t.test_result_need_to_pass
                    .replaceAll('{score}', '${passScorePercent.toInt()}'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
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
                  label: t.test_result_skipped,
                  value: '$unanswered',
                  icon: Icons.remove_circle_outline_rounded,
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

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

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
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats card ────────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final double scorePercent;
  final double passScorePercent;
  final int correct;
  final int wrong;
  final int unanswered;
  final int total;
  final bool isPassed;
  final Color primaryColor;

  const _StatsCard({
    required this.scorePercent,
    required this.passScorePercent,
    required this.correct,
    required this.wrong,
    required this.unanswered,
    required this.total,
    required this.isPassed,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;
    final gap = scorePercent - passScorePercent;
    final gapLabel = gap >= 0
        ? t.test_result_above_pass_mark
            .replaceAll('{gap}', '+${gap.toStringAsFixed(1)}')
        : t.test_result_below_pass_mark
            .replaceAll('{gap}', gap.toStringAsFixed(1));
    final gapColor = gap >= 0 ? Colors.green.shade600 : Colors.red.shade500;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.test_result_your_results,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 14),

          // Score vs pass mark bar
          _ScoreBarRow(
            label: t.test_result_your_score,
            value: scorePercent,
            max: 100,
            color: primaryColor,
            valueLabel: '${scorePercent.toStringAsFixed(1)}%',
          ),
          const SizedBox(height: 10),
          _ScoreBarRow(
            label: t.test_result_pass_mark,
            value: passScorePercent,
            max: 100,
            color: Colors.grey.shade400,
            valueLabel: '${passScorePercent.toInt()}%',
          ),

          const SizedBox(height: 14),

          // Gap label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: gapColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  gap >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: gapColor,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  gapLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: gapColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Divider(color: cs.outlineVariant, height: 1),
          const SizedBox(height: 14),

          // Breakdown rows
          _BreakdownRow(
            label: t.test_result_correct_answers,
            value: '$correct / $total',
            valueColor: Colors.green.shade600,
            icon: Icons.check_circle_outline_rounded,
            iconColor: Colors.green.shade500,
          ),
          const SizedBox(height: 10),
          _BreakdownRow(
            label: t.test_result_wrong_answers,
            value: '$wrong / $total',
            valueColor: Colors.red.shade500,
            icon: Icons.cancel_outlined,
            iconColor: Colors.red.shade400,
          ),
          if (unanswered > 0) ...[
            const SizedBox(height: 10),
            _BreakdownRow(
              label: t.test_result_skipped,
              value: '$unanswered / $total',
              valueColor: Colors.grey.shade500,
              icon: Icons.remove_circle_outline_rounded,
              iconColor: Colors.grey.shade400,
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreBarRow extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final Color color;
  final String valueLabel;

  const _ScoreBarRow({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    required this.valueLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6)),
              ),
            ),
            Text(
              valueLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (value / max).clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final IconData icon;
  final Color iconColor;

  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 17, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

// ── Question review card ───────────────────────────────────────────────────────

class _QuestionReviewCard extends StatelessWidget {
  final int index;
  final Question question;
  final String? userAnswer;
  final bool isCorrect;
  final VoidCallback onTap;

  const _QuestionReviewCard({
    required this.index,
    required this.question,
    required this.userAnswer,
    required this.isCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final color = isCorrect ? Colors.green.shade500 : Colors.red.shade400;
    final bgColor = isCorrect ? Colors.green.shade50 : Colors.red.shade50;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(
                isCorrect ? Icons.check_rounded : Icons.close_rounded,
                color: color,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.test_result_question_row
                        .replaceAll('{n}', '${index + 1}')
                        .replaceAll('{text}', question.text),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  userAnswer != null
                      ? Text(
                          t.test_result_your_answer
                              .replaceAll('{answer}', userAnswer!),
                          style: TextStyle(fontSize: 12, color: color),
                        )
                      : Text(
                          t.test_not_answered,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                        ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade300, size: 18),
          ],
        ),
      ),
    );
  }
}
