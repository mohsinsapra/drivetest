import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/core/widgets/app_back_button.dart';
import 'package:taxi_exam_app/features/bcd/bcd_test_screen.dart';
import 'package:taxi_exam_app/features/smart_learning/screens/smart_session_screen.dart';
import 'package:taxi_exam_app/features/smart_learning/services/smart_progress_service.dart';
import 'package:taxi_exam_app/features/smart_learning/screens/smart_learning_screen.dart';

class SmartExamScreen extends StatefulWidget {
  final SmartExamEntry entry;

  const SmartExamScreen({super.key, required this.entry});

  @override
  State<SmartExamScreen> createState() => _SmartExamScreenState();
}

class _SmartExamScreenState extends State<SmartExamScreen> {
  final _svc = SmartProgressService();
  int _activeChunk = 0;
  int _weakCount = 0;
  int _masteredCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final total = widget.entry.chunkSizes.length;
    // Start all futures in parallel, then await each with a named variable.
    final activeChunkF = _svc.activeSmartIndex(widget.entry.testBcdId, total);
    final weakCountF = _svc.weakQuestionCount(widget.entry.testBcdId);
    final masteredCountF = _svc.masteredQuestionCount(widget.entry.testBcdId, widget.entry.chunkSizes);
    final activeChunk = await activeChunkF;
    final weakCount = await weakCountF;
    final masteredCount = await masteredCountF;
    if (mounted) {
      setState(() {
        _activeChunk = activeChunk;
        _weakCount = weakCount;
        _masteredCount = masteredCount;
        _loading = false;
      });
    }
  }

  Future<void> _startChunk(int chunkIndex) async {
    await Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => SmartSessionScreen(
          entry: widget.entry,
          chunkIndex: chunkIndex,
          isMistakesMode: false,
        ),
      ),
    );
    _load();
  }

  Future<void> _startMistakes() async {
    await Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => SmartSessionScreen(
          entry: widget.entry,
          chunkIndex: -1,
          isMistakesMode: true,
        ),
      ),
    );
    _load();
  }

  void _launchFullExam() {
    final e = widget.entry;
    final hasCompletedPreviousParts = _activeChunk >= e.chunkSizes.length;
    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => BCDTestScreen(
          testId: e.testBcdId,
          testName: e.testName,
          passScore: e.passScore,
          timeLimit: e.timeLimit,
          parentCategoryName: e.categoryName,
          parentCategoryBcdId: e.parentCategoryBcdId,
          isMockExamMode: true,
          maxWrongAnswers: hasCompletedPreviousParts ? null : 3,
          onGameOver: hasCompletedPreviousParts ? null : _onHeartsDepleted,
        ),
      ),
    );
  }

  void _onHeartsDepleted() {
    if (Navigator.canPop(context)) Navigator.pop(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showGameOverSheet();
    });
  }

  void _showGameOverSheet() {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          isDark ? cs.surfaceContainerHighest : theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.heart_broken_rounded,
                size: 36,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t.smart_hearts_game_over_title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              t.smart_hearts_game_over_body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  t.smart_hearts_keep_practising,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(
          widget.entry.testName,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                children: [
                  ...List.generate(widget.entry.chunkSizes.length, (i) {
                    final isPassed = i < _activeChunk;
                    final isActive = i == _activeChunk;
                    final isLocked = i > _activeChunk;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ChunkCard(
                        label: t.smart_chunk_n(n: i + 1),
                        questionCount: widget.entry.chunkSizes[i],
                        isPassed: isPassed,
                        isActive: isActive,
                        isLocked: isLocked,
                        onTap: !isLocked ? () => _startChunk(i) : null,
                      ),
                    );
                  }),
                  const SizedBox(height: 6),
                  if (_weakCount > 0) ...[
                    _TrainMistakesCard(
                        count: _weakCount, onTap: _startMistakes),
                    const SizedBox(height: 10),
                  ],
                  _FullExamCard(
                    onStart: _launchFullExam,
                    hasCompletedPreviousParts:
                        _activeChunk >= widget.entry.chunkSizes.length,
                    mastered: _masteredCount,
                    totalQuestions: widget.entry.questionCount,
                    weakCount: _weakCount,
                  ),
                ],
              ),
            ),
    );
  }
}

// ── Chunk card ──────────────────────────────────────────────────────────────

class _ChunkCard extends StatelessWidget {
  final String label;
  final int questionCount;
  final bool isPassed;
  final bool isActive;
  final bool isLocked;
  final VoidCallback? onTap;

  const _ChunkCard({
    required this.label,
    required this.questionCount,
    required this.isPassed,
    required this.isActive,
    required this.isLocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;
    final color = isPassed
        ? Colors.green.shade500
        : isActive
            ? cs.primary
            : cs.onSurface.withValues(alpha: 0.25);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isLocked ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? cs.primary.withValues(alpha: 0.4)
                  : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPassed
                      ? Icons.check_rounded
                      : isLocked
                          ? Icons.lock_outline_rounded
                          : Icons.play_arrow_rounded,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '${t.smart_questions_count(count: questionCount)} • ${t.smart_part_pass_requirement}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.55)),
                    ),
                  ],
                ),
              ),
              Text(
                isPassed
                    ? t.smart_chunk_passed
                    : isActive
                        ? t.smart_chunk_active
                        : t.smart_chunk_locked,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Train Mistakes card ──────────────────────────────────────────────────────

class _TrainMistakesCard extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _TrainMistakesCard({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.error.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: cs.error, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                t.smart_train_mistakes(count: count),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: cs.error, fontWeight: FontWeight.w600),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: cs.error.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

// ── Full Exam card ───────────────────────────────────────────────────────────

class _FullExamCard extends StatelessWidget {
  final VoidCallback onStart;
  final bool hasCompletedPreviousParts;
  final int mastered;
  final int totalQuestions;
  final int weakCount;

  const _FullExamCard({
    required this.onStart,
    required this.hasCompletedPreviousParts,
    required this.mastered,
    required this.totalQuestions,
    required this.weakCount,
  });

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: 1.0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.green.shade400.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.amber.shade600,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(t.smart_full_exam,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              hasCompletedPreviousParts
                  ? t.smart_full_exam_completed_parts
                  : t.smart_full_exam_early_attempt,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.55)),
            ),
            const SizedBox(height: 8),
            Text(
              hasCompletedPreviousParts
                  ? t.smart_full_exam_completed_rules
                  : t.smart_full_exam_early_rules,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.55), height: 1.4),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatChip(
                  icon: Icons.verified_rounded,
                  color: Colors.green.shade600,
                  label: t.smart_mastered_of(
                    mastered: mastered,
                    total: totalQuestions,
                  ),
                ),
                _StatChip(
                  icon: Icons.warning_amber_rounded,
                  color: cs.error,
                  label: t.smart_mistakes_to_review(count: weakCount),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onStart,
                child: Text(t.smart_attempt_final_exam),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _StatChip({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
