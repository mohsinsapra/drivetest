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
  bool _fullUnlocked = false;
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
    final fullUnlockedF = _svc.isFullExamUnlocked(widget.entry.testBcdId, total);
    final masteredCountF = _svc.masteredQuestionCount(widget.entry.testBcdId, widget.entry.chunkSizes);
    final activeChunk = await activeChunkF;
    final weakCount = await weakCountF;
    final fullUnlocked = await fullUnlockedF;
    final masteredCount = await masteredCountF;
    if (mounted) {
      setState(() {
        _activeChunk = activeChunk;
        _weakCount = weakCount;
        _fullUnlocked = fullUnlocked;
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

  void _launchFullExam({required bool timed}) {
    final e = widget.entry;
    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => BCDTestScreen(
          testId: e.testBcdId,
          testName: e.testName,
          passScore: e.passScore,
          timeLimit: timed ? e.timeLimit : 0,
          parentCategoryName: e.categoryName,
          parentCategoryBcdId: e.parentCategoryBcdId,
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
                  _MasteryProgressCard(
                    mastered: _masteredCount,
                    total: widget.entry.questionCount,
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(widget.entry.chunkSizes.length, (i) {
                    final isPassed = i < _activeChunk;
                    final isActive = i == _activeChunk;
                    final isLocked = i > _activeChunk;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ChunkCard(
                        label: t.smart_chunk_n(n: i + 1),
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
                    unlocked: _fullUnlocked,
                    onPractice: _fullUnlocked
                        ? () => _launchFullExam(timed: false)
                        : null,
                    onTimed: _fullUnlocked
                        ? () => _launchFullExam(timed: true)
                        : null,
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
  final bool isPassed;
  final bool isActive;
  final bool isLocked;
  final VoidCallback? onTap;

  const _ChunkCard({
    required this.label,
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
  final bool unlocked;
  final VoidCallback? onPractice;
  final VoidCallback? onTimed;

  const _FullExamCard({
    required this.unlocked,
    this.onPractice,
    this.onTimed,
  });

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: unlocked ? 1.0 : 0.45,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked
                ? Colors.green.shade400.withValues(alpha: 0.4)
                : cs.outlineVariant,
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
                  unlocked
                      ? Icons.emoji_events_rounded
                      : Icons.lock_outline_rounded,
                  color: unlocked
                      ? Colors.amber.shade600
                      : cs.onSurface.withValues(alpha: 0.3),
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
              unlocked ? t.smart_full_exam_ready : t.smart_full_exam_locked,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.55)),
            ),
            if (unlocked) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onPractice,
                      child: Text(t.smart_practice_mode),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: onTimed,
                      child: Text(t.smart_timed_mode),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Mastery progress card ────────────────────────────────────────────────────

class _MasteryProgressCard extends StatelessWidget {
  final int mastered;
  final int total;

  const _MasteryProgressCard({required this.mastered, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final t = Translations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final progress = total == 0 ? 0.0 : (mastered / total).clamp(0.0, 1.0);
    final percent = (progress * 100).round();
    const passThreshold = 0.70;
    final passed = progress >= passThreshold;
    final barColor = passed ? Colors.green.shade500 : cs.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHighest : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: passed
              ? Colors.green.shade400.withValues(alpha: 0.4)
              : cs.onSurface.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
                passed ? Icons.verified_rounded : Icons.trending_up_rounded,
                size: 18,
                color: passed ? Colors.green.shade500 : cs.primary,
              ),
              const SizedBox(width: 8),
              Text(
                t.smart_progress_title,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                t.smart_mastered_of(mastered: mastered, total: total),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (_, constraints) {
            final barWidth = constraints.maxWidth;
            final markerX = barWidth * passThreshold;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress == 0 ? 0.0 : progress.clamp(0.04, 1.0),
                    minHeight: 10,
                    backgroundColor: cs.onSurface.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
                // 70% threshold marker
                Positioned(
                  left: markerX - 1,
                  top: -3,
                  bottom: -3,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$percent%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: passed ? Colors.green.shade600 : cs.primary,
                ),
              ),
              const Spacer(),
              Text(
                passed
                    ? t.smart_progress_ready_full_exam
                    : t.smart_progress_required_to_pass,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
