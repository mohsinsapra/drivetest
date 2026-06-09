import 'dart:math';

import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/core/storage/app_storage.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/core/widgets/adaptive_refresh_indicator.dart';
import 'package:taxi_exam_app/core/widgets/app_back_button.dart';
import 'package:taxi_exam_app/core/widgets/app_button.dart';
import 'package:taxi_exam_app/core/widgets/app_loading_indicator.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'package:taxi_exam_app/features/bcd/providers/bcd_provider.dart';
import 'package:taxi_exam_app/features/tests/test_screen.dart';
import 'package:taxi_exam_app/features/smart_learning/screens/smart_learning_screen.dart';
import 'package:taxi_exam_app/features/smart_learning/screens/smart_result_screen.dart';
import 'package:taxi_exam_app/features/smart_learning/screens/smart_test_screen.dart';
import 'package:taxi_exam_app/features/smart_learning/services/smart_progress_service.dart';
import 'package:taxi_exam_app/features/smart_learning/utils/smart_utils.dart';

class SmartExamScreen extends StatefulWidget {
  final SmartExamEntry entry;

  const SmartExamScreen({super.key, required this.entry});

  @override
  State<SmartExamScreen> createState() => _SmartExamScreenState();
}

class _SmartExamScreenState extends State<SmartExamScreen> {
  final _svc = SmartProgressService();
  final _provider = BcdProvider();
  final _api = ApiService();
  int _activeChunk = 0;
  int _weakCount = 0;
  int _masteredCount = 0;
  Map<int, bool> _reviewPassedMap = {};
  bool _loading = true;
  // Key of the session being loaded ('chunk-N', 'review-N', 'mistakes').
  String? _loadingKey;

  int get _reviewCount => widget.entry.chunkSizes.length ~/ 2;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final total = widget.entry.chunkSizes.length;
    await _svc.syncChunksFromFullExamIfNeeded(widget.entry.testBcdId, total);
    // Start all futures in parallel, then await each with a named variable.
    final activeChunkF = _svc.activeSmartIndex(widget.entry.testBcdId, total);
    final weakCountF = _svc.weakQuestionCount(widget.entry.testBcdId);
    final masteredCountF = _svc.masteredQuestionCount(
        widget.entry.testBcdId, widget.entry.chunkSizes);
    final reviewMapF =
        _svc.reviewPassedMap(widget.entry.testBcdId, _reviewCount);
    final activeChunk = await activeChunkF;
    final weakCount = await weakCountF;
    final masteredCount = await masteredCountF;
    final reviewMap = await reviewMapF;
    if (mounted) {
      setState(() {
        _activeChunk = activeChunk;
        _weakCount = weakCount;
        _masteredCount = masteredCount;
        _reviewPassedMap = reviewMap;
        _loading = false;
      });
    }
  }

  Future<void> _startChunk(int chunkIndex) async {
    if (_loadingKey != null) return;
    setState(() => _loadingKey = 'chunk-$chunkIndex');
    try {
      final questions = await _fetchChunkQuestions(chunkIndex);
      if (!mounted || questions == null) return;
      await Navigator.push(
        context,
        AppPageRoute(
            builder: (_) => _buildChunkTestScreen(chunkIndex, questions)),
      );
    } finally {
      if (mounted) setState(() => _loadingKey = null);
    }
  }

  SmartTestScreen _buildChunkTestScreen(
      int chunkIndex, List<Question> questions) {
    final entry = widget.entry;
    final testBcdId = entry.testBcdId;
    return SmartTestScreen(
      initialQuestions: questions,
      passScorePercent: 70.0,
      testName: entry.testName,
      licenceId: '',
      categoryId: testBcdId.toString(),
      bcdCategoryId: entry.parentCategoryBcdId,
      bcdTestId: testBcdId,
      onComplete: (hasPassed, finalResults, wrongSelections) async {
        await _svc.recordSmartResult(testBcdId, chunkIndex, hasPassed);
        await _svc.recordSessionResults(testBcdId, finalResults);
        _load();
        _syncSmartData(testBcdId, false).ignore();
        final mastered =
            await _svc.masteredQuestionCount(testBcdId, entry.chunkSizes);
        return SmartResultScreen(
          entry: entry,
          chunkIndex: chunkIndex,
          isMistakesMode: false,
          isReviewMode: false,
          reviewIndex: 0,
          hasPassed: hasPassed,
          correct: finalResults.values.where((v) => v).length,
          total: finalResults.length,
          masteredCount: mastered,
          wrongQuestions: questions
              .where((q) => finalResults[q.questionId] == false)
              .toList(),
          wrongSelections: wrongSelections,
          onRetry: () async {
            final qs = await _fetchChunkQuestions(chunkIndex);
            if (qs == null) return null;
            return _buildChunkTestScreen(chunkIndex, qs);
          },
        );
      },
    );
  }

  Future<void> _startReview(int reviewIndex) async {
    if (_loadingKey != null) return;
    setState(() => _loadingKey = 'review-$reviewIndex');
    try {
      final questions = await _fetchReviewQuestions(reviewIndex);
      if (!mounted || questions == null) return;
      await Navigator.push(
        context,
        AppPageRoute(
            builder: (_) => _buildReviewTestScreen(reviewIndex, questions)),
      );
    } finally {
      if (mounted) setState(() => _loadingKey = null);
    }
  }

  SmartTestScreen _buildReviewTestScreen(
      int reviewIndex, List<Question> questions) {
    final entry = widget.entry;
    final testBcdId = entry.testBcdId;
    return SmartTestScreen(
      initialQuestions: questions,
      passScorePercent: 70.0,
      testName: entry.testName,
      licenceId: '',
      categoryId: testBcdId.toString(),
      bcdCategoryId: entry.parentCategoryBcdId,
      bcdTestId: testBcdId,
      onComplete: (hasPassed, finalResults, wrongSelections) async {
        await _svc.recordReviewResult(testBcdId, reviewIndex, hasPassed);
        await _svc.recordSessionResults(testBcdId, finalResults);
        _load();
        _syncSmartData(testBcdId, false).ignore();
        final mastered =
            await _svc.masteredQuestionCount(testBcdId, entry.chunkSizes);
        return SmartResultScreen(
          entry: entry,
          chunkIndex: -1,
          isMistakesMode: false,
          isReviewMode: true,
          reviewIndex: reviewIndex,
          hasPassed: hasPassed,
          correct: finalResults.values.where((v) => v).length,
          total: finalResults.length,
          masteredCount: mastered,
          wrongQuestions: questions
              .where((q) => finalResults[q.questionId] == false)
              .toList(),
          wrongSelections: wrongSelections,
          onRetry: () async {
            final qs = await _fetchReviewQuestions(reviewIndex);
            if (qs == null) return null;
            return _buildReviewTestScreen(reviewIndex, qs);
          },
        );
      },
    );
  }

  Future<void> _startMistakes() async {
    if (_loadingKey != null) return;
    setState(() => _loadingKey = 'mistakes');
    try {
      final questions = await _fetchMistakesQuestions();
      if (!mounted || questions == null) return;
      final entry = widget.entry;
      final testBcdId = entry.testBcdId;
      await Navigator.push(
        context,
        AppPageRoute(
          builder: (_) => SmartTestScreen(
            initialQuestions: questions,
            passScorePercent: 0.0,
            testName: entry.testName,
            licenceId: '',
            categoryId: testBcdId.toString(),
            bcdCategoryId: entry.parentCategoryBcdId,
            bcdTestId: testBcdId,
            onComplete: (hasPassed, finalResults, wrongSelections) async {
              await _svc.recordSessionResults(testBcdId, finalResults);
              _load();
              _syncSmartData(testBcdId, true).ignore();
              final mastered =
                  await _svc.masteredQuestionCount(testBcdId, entry.chunkSizes);
              return SmartResultScreen(
                entry: entry,
                chunkIndex: -1,
                isMistakesMode: true,
                isReviewMode: false,
                reviewIndex: 0,
                hasPassed: hasPassed,
                correct: finalResults.values.where((v) => v).length,
                total: finalResults.length,
                masteredCount: mastered,
                wrongQuestions: questions
                    .where((q) => finalResults[q.questionId] == false)
                    .toList(),
                wrongSelections: wrongSelections,
              );
            },
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingKey = null);
    }
  }

  // ── Question fetchers ────────────────────────────────────────────────────────

  Future<List<Question>?> _fetchChunkQuestions(int chunkIndex) async {
    try {
      final testBcdId = widget.entry.testBcdId;
      final sizes = SmartUtils.computeSmartSizes(widget.entry.questionCount);
      final safeIdx = chunkIndex.clamp(0, sizes.length - 1);
      final offset = SmartUtils.smartOffset(sizes, safeIdx);
      final limit = sizes[safeIdx];
      final base = await _provider.fetchChunkQuestions(testBcdId,
          limit: limit, offset: offset);
      final weakIds = await _svc.allWeakQuestionIds(testBcdId);
      final baseIds = base.map((q) => q.questionId).toSet();
      final cap = (limit * 0.3).floor();
      final injectIds =
          weakIds.where((id) => !baseIds.contains(id)).take(cap).toList();
      List<Question> questions;
      if (injectIds.isNotEmpty) {
        final injected =
            await _provider.fetchChunkQuestions(testBcdId, ids: injectIds);
        questions = [...base, ...injected]..shuffle(Random());
      } else {
        questions = base..shuffle(Random());
      }
      if (questions.isEmpty && mounted) {
        showAppSnackBar(Translations.of(context).bcd_no_questions);
        return null;
      }
      return questions;
    } catch (_) {
      if (mounted) {
        showAppSnackBar(Translations.of(context).bcd_failed_test_questions,
            type: SnackBarType.error);
      }
      return null;
    }
  }

  Future<List<Question>?> _fetchReviewQuestions(int reviewIndex) async {
    try {
      final testBcdId = widget.entry.testBcdId;
      final coveredChunks = 2 * (reviewIndex + 1);
      final sizes = widget.entry.chunkSizes.take(coveredChunks).toList();
      final totalCovered = sizes.fold(0, (a, b) => a + b);
      final reviewSize = widget.entry.chunkSizes[0].clamp(1, totalCovered);
      final all = await _provider.fetchChunkQuestions(testBcdId,
          limit: totalCovered, offset: 0);
      final questions = (all..shuffle(Random())).take(reviewSize).toList();
      if (questions.isEmpty && mounted) {
        showAppSnackBar(Translations.of(context).bcd_no_questions);
        return null;
      }
      return questions;
    } catch (_) {
      if (mounted) {
        showAppSnackBar(Translations.of(context).bcd_failed_test_questions,
            type: SnackBarType.error);
      }
      return null;
    }
  }

  Future<List<Question>?> _fetchMistakesQuestions() async {
    try {
      final testBcdId = widget.entry.testBcdId;
      final weakIds = await _svc.allWeakQuestionIds(testBcdId);
      if (weakIds.isEmpty) {
        if (mounted) {
          showAppSnackBar(Translations.of(context).bcd_no_questions);
        }
        return null;
      }
      final questions =
          await _provider.fetchChunkQuestions(testBcdId, ids: weakIds)
            ..shuffle(Random());
      if (questions.isEmpty && mounted) {
        showAppSnackBar(Translations.of(context).bcd_no_questions);
        return null;
      }
      return questions;
    } catch (_) {
      if (mounted) {
        showAppSnackBar(Translations.of(context).bcd_failed_test_questions,
            type: SnackBarType.error);
      }
      return null;
    }
  }

  Future<void> _syncSmartData(int testBcdId, bool isMistakes) async {
    try {
      if (!isMistakes) {
        final progressBox = await AppStorage.smartProgressBox();
        final chunks = progressBox.values
            .where((p) => p.testBcdId == testBcdId)
            .map((p) => {
                  'chunk_index': p.chunkIndex,
                  'is_passed': p.isPassed,
                  'completed_at': p.completedAt.toUtc().toIso8601String(),
                })
            .toList();
        if (chunks.isNotEmpty) {
          await _api.syncSmartProgress(testBcdId, chunks);
        }
      }
      final weakBox = await AppStorage.weakQuestionsBox();
      final weakQuestions = weakBox.values
          .where((wq) => wq.testBcdId == testBcdId)
          .map((wq) => {
                'question_id': wq.questionId,
                'wrong_count': wq.wrongCount,
                'correct_streak': wq.correctStreak,
                'last_seen': wq.lastSeen.toUtc().toIso8601String(),
              })
          .toList();
      await _api.syncWeakQuestions(testBcdId, weakQuestions);
    } catch (e) {
      debugPrint('[_syncSmartData] failed: $e');
    }
  }

  Future<List<Question>?> _fetchFullExamQuestions() async {
    try {
      return await _provider.fetchChunkQuestions(
        widget.entry.testBcdId,
        applyShufflePreference: true,
      );
    } catch (_) {
      if (mounted) {
        showAppSnackBar(Translations.of(context).bcd_failed_test_questions,
            type: SnackBarType.error);
      }
      return null;
    }
  }

  Future<void> _launchFullExam() async {
    if (_loadingKey != null) return;
    setState(() => _loadingKey = 'fullExam');
    try {
      final e = widget.entry;
      final hasCompletedPreviousParts = _activeChunk >= e.chunkSizes.length;
      final maxWrongAnswers = hasCompletedPreviousParts ? null : 3;

      final questions = await _fetchFullExamQuestions();
      if (!mounted || questions == null) return;
      if (questions.isEmpty) {
        showAppSnackBar(Translations.of(context).bcd_no_questions);
        return;
      }

      await Navigator.push(
        context,
        AppPageRoute(
          builder: (_) => Testscreen(
            questions: questions,
            instantMarking: maxWrongAnswers != null,
            licenceId: '',
            categoryId: e.testBcdId.toString(),
            licenceName: e.categoryName,
            categoryName: e.testName,
            bcdCategoryId: e.parentCategoryBcdId,
            bcdTestId: e.testBcdId,
            passScorePercent: e.passScore.toDouble(),
            isTimed: e.timeLimit > 0,
            timeLimitMinutes: e.timeLimit > 0 ? e.timeLimit : 10,
            isMockExamMode: true,
            maxWrongAnswers: maxWrongAnswers,
            onGameOver: hasCompletedPreviousParts ? null : _onHeartsDepleted,
          ),
        ),
      );
      _load();
    } finally {
      if (mounted) setState(() => _loadingKey = null);
    }
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
            AppFilledButton(
              label: t.smart_hearts_keep_practising,
              borderRadius: 14,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds part cards interleaved with review cards after every 2 parts.
  List<Widget> _buildChunksWithReviews(Translations t) {
    final chunks = widget.entry.chunkSizes;
    final items = <Widget>[];
    int reviewIdx = 0;

    for (int i = 0; i < chunks.length; i++) {
      final isPassed = i < _activeChunk;
      final isActive = i == _activeChunk;
      final isLocked = i > _activeChunk;

      items.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _ChunkCard(
          label: t.smart_chunk_n(n: i + 1),
          questionCount: chunks[i],
          isPassed: isPassed,
          isActive: isActive,
          isLocked: isLocked,
          isLoading: _loadingKey == 'chunk-$i',
          onTap: !isLocked ? () => _startChunk(i) : null,
        ),
      ));

      // Insert a review after every 2nd part.
      if ((i + 1) % 2 == 0 && reviewIdx < _reviewCount) {
        final rIdx = reviewIdx;
        final coveredChunks = i + 1;
        final isUnlocked = _activeChunk >= coveredChunks;
        final isReviewPassed = _reviewPassedMap[rIdx] ?? false;
        final totalCovered =
            chunks.take(coveredChunks).fold<int>(0, (a, b) => a + b);
        final reviewSize = chunks[0].clamp(1, totalCovered);

        items.add(Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ReviewCard(
            reviewNumber: rIdx + 1,
            questionCount: reviewSize,
            isPassed: isReviewPassed,
            isUnlocked: isUnlocked,
            isLoading: _loadingKey == 'review-$rIdx',
            onTap: isUnlocked ? () => _startReview(rIdx) : null,
          ),
        ));
        reviewIdx++;
      }
    }

    return items;
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
          ? const Center(child: AppLoadingIndicator())
          : AdaptiveRefreshIndicator(
              onRefresh: _load,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      ..._buildChunksWithReviews(t),
                      const SizedBox(height: 6),
                      if (_weakCount > 0) ...[
                        _TrainMistakesCard(
                          count: _weakCount,
                          isLoading: _loadingKey == 'mistakes',
                          onTap: _startMistakes,
                        ),
                        const SizedBox(height: 10),
                      ],
                      _FullExamCard(
                        onStart: _launchFullExam,
                        hasCompletedPreviousParts:
                            _activeChunk >= widget.entry.chunkSizes.length,
                        mastered: _masteredCount,
                        totalQuestions: widget.entry.questionCount,
                        weakCount: _weakCount,
                        isLoading: _loadingKey == 'fullExam',
                      ),
                    ]),
                  ),
                ),
              ],
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
  final bool isLoading;
  final VoidCallback? onTap;

  const _ChunkCard({
    required this.label,
    required this.questionCount,
    required this.isPassed,
    required this.isActive,
    required this.isLocked,
    this.isLoading = false,
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
                      '${t.smart_questions_count(count: questionCount)}  ${t.smart_part_pass_requirement}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.55)),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: AppLoadingIndicator(strokeWidth: 2, color: color),
                )
              else
                Text(
                  isPassed
                      ? t.smart_chunk_passed
                      : isActive
                          ? t.smart_chunk_active
                          : t.smart_chunk_locked,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: color, fontWeight: FontWeight.w600),
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
  final bool isLoading;
  final VoidCallback onTap;

  const _TrainMistakesCard({
    required this.count,
    required this.onTap,
    this.isLoading = false,
  });

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
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: cs.error, fontWeight: FontWeight.w600),
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: AppLoadingIndicator(strokeWidth: 2, color: cs.error),
              )
            else
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: cs.error.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

// ── Review card ─────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final int reviewNumber;
  final int questionCount;
  final bool isPassed;
  final bool isUnlocked;
  final bool isLoading;
  final VoidCallback? onTap;

  const _ReviewCard({
    required this.reviewNumber,
    required this.questionCount,
    required this.isPassed,
    required this.isUnlocked,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;
    const reviewColor = Color(0xFF7C3AED); // violet — distinct from parts
    final color = isUnlocked
        ? (isPassed ? Colors.green.shade500 : reviewColor)
        : cs.onSurface.withValues(alpha: 0.25);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isUnlocked ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isUnlocked && !isPassed
                  ? reviewColor.withValues(alpha: 0.4)
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
                      : isUnlocked
                          ? Icons.refresh_rounded
                          : Icons.lock_outline_rounded,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.smart_review_n,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.smart_review_subtitle(count: questionCount),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.55)),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: AppLoadingIndicator(strokeWidth: 2, color: color),
                )
              else
                Text(
                  isPassed
                      ? t.smart_chunk_passed
                      : isUnlocked
                          ? t.smart_chunk_active
                          : t.smart_chunk_locked,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: color, fontWeight: FontWeight.w600),
                ),
            ],
          ),
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
  final bool isLoading;

  const _FullExamCard({
    required this.onStart,
    required this.hasCompletedPreviousParts,
    required this.mastered,
    required this.totalQuestions,
    required this.weakCount,
    this.isLoading = false,
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
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurface.withValues(alpha: 0.55)),
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
            AppFilledButton(
              label: t.smart_attempt_final_exam,
              onPressed: isLoading ? null : onStart,
              loading: isLoading,
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
