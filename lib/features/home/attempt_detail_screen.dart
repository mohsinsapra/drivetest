import 'package:taxi_exam_app/core/utils/app_page_route.dart';
// attempt_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';
import 'package:taxi_exam_app/features/tests/test_screen.dart';

class AttemptDetailScreen extends StatelessWidget {
  final TestAttempt attempt;

  const AttemptDetailScreen({super.key, required this.attempt});

  @override
  Widget build(BuildContext context) {
    final a = attempt;
    final isPassed = a.hasPassed;
    final passColor = isPassed ? Colors.green.shade600 : Colors.red.shade500;
    final passBg = isPassed ? Colors.green.shade50 : Colors.red.shade50;
    final questions = a.questions;
    final hasQuestions = questions.isNotEmpty;
    final dt = a.dateTime;
    final dateStr =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final totalAnswered = a.userSelections.length;
    final correct = hasQuestions
        ? a.userSelections.entries.where((e) {
            final idx = e.key;
            if (idx < 0 || idx >= questions.length) return false;
            return e.value == questions[idx].correctAnswer;
          }).length
        : null;
    final duration =
        a.durationSeconds != null ? _formatDuration(a.durationSeconds!) : null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Attempt Details'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          // ── Score hero ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: passBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: passColor.withValues(alpha: 0.2), width: 1.5),
            ),
            child: Column(
              children: [
                Text(
                  '${a.score.toInt()}%',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: passColor,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: passColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPassed ? 'PASSED' : 'FAILED',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Meta info ──────────────────────────────────────────────────
          _InfoCard(children: [
            _InfoRow(
              icon: Icons.folder_outlined,
              label: 'Category',
              value: a.categoryName ?? '—',
              trailing: a.isBcd
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurple.shade400,
                        ),
                      ),
                    )
                  : null,
            ),
            if (a.licenceName?.isNotEmpty == true)
              _InfoRow(
                icon: Icons.card_membership_outlined,
                label: 'Licence',
                value: a.licenceName!,
              ),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Date',
              value: dateStr,
            ),
            if (duration != null)
              _InfoRow(
                icon: Icons.timer_outlined,
                label: 'Duration',
                value: duration,
              ),
            if (hasQuestions && correct != null)
              _InfoRow(
                icon: Icons.check_circle_outline,
                label: 'Correct',
                value: '$correct / ${questions.length}',
                valueColor: Colors.green.shade600,
              ),
            if (!hasQuestions)
              _InfoRow(
                icon: Icons.info_outline,
                label: 'Questions',
                value: '$totalAnswered answered',
              ),
          ]),
          const SizedBox(height: 20),

          // ── Question review (only if available) ───────────────────────
          if (hasQuestions) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Question Review',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            ...List.generate(questions.length, (index) {
              final question = questions[index];
              final userAnswer = a.userSelections[index];
              final isCorrect = userAnswer == question.correctAnswer;
              return _QuestionCard(
                index: index,
                question: question,
                userAnswer: userAnswer,
                isCorrect: isCorrect,
                onTap: () => Navigator.push(
                  context,
                  AppPageRoute(
                    builder: (_) => TestscreenWrapper(
                      questions: questions,
                      instantMarking: true,
                      licenceId: '',
                      categoryId: '',
                      initialQuestionIndex: index,
                      userSelections: a.userSelections,
                      isReviewMode: true,
                    ),
                  ),
                ),
              );
            }),
          ] else ...[
            _InfoCard(children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: Colors.grey.shade500),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Question-by-question review is only available for '
                        'tests taken in the current session.',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${s}s';
  }
}

// ── Supporting widgets ─────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? trailing;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: valueColor ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final dynamic question;
  final String? userAnswer;
  final bool isCorrect;
  final VoidCallback onTap;

  const _QuestionCard({
    required this.index,
    required this.question,
    required this.userAnswer,
    required this.isCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                    'Q${index + 1}: ${question.text}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  if (userAnswer != null)
                    Text(
                      'Your answer: $userAnswer',
                      style: TextStyle(fontSize: 12, color: color),
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
