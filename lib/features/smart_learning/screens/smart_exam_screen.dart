import 'dart:math';

import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/services/analytics_service.dart';
import 'package:taxi_exam_app/features/payment/single_product_paywall.dart';
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

  late bool _subscribed = widget.entry.categorySubscribed;

  bool get _locked =>
      widget.entry.subscriptionProduct != null &&
      !_subscribed &&
      !widget.entry.isTestFree;

  /// Returns true when the action should be blocked (locked and not purchased).
  /// If the user buys during the paywall, unlocks in place and returns false so
  /// the caller proceeds with the originally requested action.
  Future<bool> _gateBlocked() async {
    if (!_locked) return false;
    AnalyticsService().logPaywallShown(
      source: 'smart_learning',
      productId: (widget.entry.subscriptionProduct?['id'] as num?)?.toInt(),
    );
    final purchased = await showSingleProductPaywall(
      context,
      subscriptionProduct: widget.entry.subscriptionProduct,
      title: widget.entry.categoryName,
    );
    if (!mounted) return true;
    if (purchased) {
      setState(() => _subscribed = true);
      return false;
    }
    return true;
  }

  int get _reviewCount => widget.entry.chunkSizes.length ~/ 2;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final total = widget.entry.chunkSizes.length;
    await _svc.syncChunksFromFullExamIfNeeded(
        widget.entry.testBcdId, total, widget.entry.questionCount);
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
    if (await _gateBlocked()) return;
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
    if (await _gateBlocked()) return;
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
    if (await _gateBlocked()) return;
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
    if (await _gateBlocked()) return;
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

  /// Builds the journey: part and review nodes on a winding trail ending at
  /// the Full Exam boss node, followed by the optional Train Mistakes card
  /// and the Full Exam info card.
  List<Widget> _buildJourney(Translations t) {
    final cs = Theme.of(context).colorScheme;
    final chunks = widget.entry.chunkSizes;
    final allPartsDone = _activeChunk >= chunks.length;
    const reviewColor = Color(0xFF7C3AED);

    final steps = <_JourneyStep>[];
    int reviewIdx = 0;

    for (int i = 0; i < chunks.length; i++) {
      final isPassed = i < _activeChunk;
      final isActive = i == _activeChunk;

      steps.add(_JourneyStep(
        label: t.smart_chunk_n(n: i + 1),
        sublabel: t.smart_questions_count(count: chunks[i]),
        icon: isPassed
            ? Icons.star_rounded
            : isActive
                ? Icons.play_arrow_rounded
                : Icons.lock_rounded,
        state: isPassed
            ? _NodeState.passed
            : isActive
                ? _NodeState.active
                : _NodeState.locked,
        activeColor: cs.primary,
        loading: _loadingKey == 'chunk-$i',
        showBubble: isActive,
        onTap: !(i > _activeChunk) ? () => _startChunk(i) : null,
      ));

      // Insert a review after every 2nd part.
      if ((i + 1) % 2 == 0 && reviewIdx < _reviewCount) {
        final rIdx = reviewIdx;
        final isUnlocked = _activeChunk >= i + 1;
        final isReviewPassed = _reviewPassedMap[rIdx] ?? false;
        final totalCovered = chunks.take(i + 1).fold<int>(0, (a, b) => a + b);
        final reviewSize = chunks[0].clamp(1, totalCovered);

        steps.add(_JourneyStep(
          label: t.smart_review_n,
          sublabel: t.smart_review_subtitle(count: reviewSize),
          icon: isReviewPassed ? Icons.check_rounded : Icons.refresh_rounded,
          state: isReviewPassed
              ? _NodeState.passed
              : isUnlocked
                  ? _NodeState.active
                  : _NodeState.locked,
          activeColor: reviewColor,
          loading: _loadingKey == 'review-$rIdx',
          onTap: isUnlocked ? () => _startReview(rIdx) : null,
        ));
        reviewIdx++;
      }
    }

    // Full Exam: the boss node at the end of the trail. Always tappable
    // (early attempts allowed, with the 3-mistake limit).
    steps.add(_JourneyStep(
      label: t.smart_full_exam,
      icon: Icons.emoji_events_rounded,
      state: allPartsDone ? _NodeState.active : _NodeState.locked,
      activeColor: Colors.amber.shade600,
      isBoss: true,
      loading: _loadingKey == 'fullExam',
      showBubble: allPartsDone,
      onTap: _launchFullExam,
    ));

    return [
      _JourneyPath(steps: steps, bubbleText: t.smart_chunk_active),
      const SizedBox(height: 20),
      if (_weakCount > 0)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _TrainMistakesCard(
            count: _weakCount,
            isLoading: _loadingKey == 'mistakes',
            onTap: _startMistakes,
          ),
        ),
      _FullExamCard(
        onStart: _launchFullExam,
        hasCompletedPreviousParts: allPartsDone,
        mastered: _masteredCount,
        totalQuestions: widget.entry.questionCount,
        weakCount: _weakCount,
        isLoading: _loadingKey == 'fullExam',
      ),
    ];
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
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(_buildJourney(t)),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Journey path ────────────────────────────────────────────────────────────

enum _NodeState { passed, active, locked }

/// One stop on the journey trail.
class _JourneyStep {
  final String label;
  final String? sublabel;
  final IconData icon;
  final _NodeState state;
  final Color activeColor;
  final bool isBoss;
  final bool loading;
  final bool showBubble;
  final VoidCallback? onTap;

  const _JourneyStep({
    required this.label,
    this.sublabel,
    required this.icon,
    required this.state,
    required this.activeColor,
    this.isBoss = false,
    this.loading = false,
    this.showBubble = false,
    this.onTap,
  });
}

/// A straight vertical timeline list: game-style nodes down the left,
/// connected by the trail (solid green behind the user, dotted grey ahead),
/// with the step's title and details to the right. The current step carries
/// a "you are here" pill.
class _JourneyPath extends StatelessWidget {
  final List<_JourneyStep> steps;
  final String bubbleText;

  const _JourneyPath({required this.steps, required this.bubbleText});

  static const double _rowHeight = 88;
  static const double _gutterWidth = 84;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final h = steps.length * _rowHeight;
    final centers = [
      for (int i = 0; i < steps.length; i++)
        Offset(_gutterWidth / 2, i * _rowHeight + _rowHeight / 2),
    ];

    return SizedBox(
      height: h,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(_gutterWidth, h),
            painter: _TrailPainter(
              centers: centers,
              segmentDone: [
                for (int i = 0; i < steps.length - 1; i++)
                  steps[i].state == _NodeState.passed,
              ],
              doneColor: Colors.green.shade500,
              pendingColor: cs.onSurface.withValues(alpha: 0.15),
            ),
          ),
          Column(
            children: [
              for (final step in steps)
                SizedBox(height: _rowHeight, child: _buildStep(context, step)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, _JourneyStep step) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final doneColor = Colors.green.shade500;
    final labelColor = switch (step.state) {
      _NodeState.passed => doneColor,
      _NodeState.active => step.activeColor,
      _NodeState.locked => cs.onSurface.withValues(alpha: 0.4),
    };

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: step.onTap,
      child: Row(
        children: [
          SizedBox(
            width: _gutterWidth,
            child: Center(child: _JourneyNode(step: step)),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  step.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: labelColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (step.sublabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    step.sublabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (step.showBubble)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _HereBubble(text: bubbleText, color: step.activeColor),
            ),
        ],
      ),
    );
  }
}

/// A chunky game-style circle with a hard bottom shadow for a 3D pressed
/// look. Passed = green check, active = colored with a soft outer ring,
/// locked = greyed. The boss (Full Exam) node is slightly larger.
class _JourneyNode extends StatelessWidget {
  final _JourneyStep step;

  const _JourneyNode({required this.step});

  Color _depth(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - 0.14).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final doneColor = Colors.green.shade500;
    final isActive = step.state == _NodeState.active;
    final isLocked = step.state == _NodeState.locked;

    final fill = switch (step.state) {
      _NodeState.passed => doneColor,
      _NodeState.active => step.activeColor,
      // Solid locked grey (blended, so the hard depth shadow works).
      _NodeState.locked =>
        Color.alphaBlend(cs.onSurface.withValues(alpha: 0.12), cs.surface),
    };
    final contentColor =
        isLocked ? cs.onSurface.withValues(alpha: 0.35) : Colors.white;
    final size = step.isBoss ? 68.0 : (isActive ? 62.0 : 56.0);

    final circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        boxShadow: [
          BoxShadow(color: _depth(fill), offset: const Offset(0, 4)),
        ],
      ),
      alignment: Alignment.center,
      child: step.loading
          ? SizedBox(
              width: 22,
              height: 22,
              child: AppLoadingIndicator(strokeWidth: 2.5, color: contentColor),
            )
          : Icon(step.icon, color: contentColor, size: step.isBoss ? 32 : 26),
    );

    if (!isActive) return circle;
    // Soft halo ring around the current step.
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: step.activeColor.withValues(alpha: 0.35),
          width: 3,
        ),
      ),
      child: circle,
    );
  }
}

/// Small "you are here" pill shown on the active row.
class _HereBubble extends StatelessWidget {
  final String text;
  final Color color;

  const _HereBubble({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

/// Paints the trail between node centers as smooth S-curves: solid green for
/// completed stretches, dashed grey ahead.
class _TrailPainter extends CustomPainter {
  final List<Offset> centers;
  final List<bool> segmentDone;
  final Color doneColor;
  final Color pendingColor;

  const _TrailPainter({
    required this.centers,
    required this.segmentDone,
    required this.doneColor,
    required this.pendingColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < centers.length - 1; i++) {
      final p0 = centers[i];
      final p1 = centers[i + 1];
      final midY = (p0.dy + p1.dy) / 2;
      final path = Path()
        ..moveTo(p0.dx, p0.dy)
        ..cubicTo(p0.dx, midY, p1.dx, midY, p1.dx, p1.dy);

      final done = segmentDone[i];
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = done ? 5.0 : 4.5
        ..color = done ? doneColor : pendingColor;

      if (done) {
        canvas.drawPath(path, paint);
      } else {
        _drawDashed(canvas, path, paint);
      }
    }
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    const dash = 1.0, gap = 12.0;
    for (final metric in path.computeMetrics()) {
      double d = 6;
      while (d < metric.length) {
        canvas.drawPath(
            metric.extractPath(d, min(d + dash, metric.length)), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.centers != centers ||
      old.segmentDone != segmentDone ||
      old.doneColor != doneColor ||
      old.pendingColor != pendingColor;
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
