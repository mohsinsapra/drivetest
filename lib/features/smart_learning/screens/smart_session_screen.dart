import 'dart:math';

import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/core/storage/app_storage.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/core/widgets/app_back_button.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'package:taxi_exam_app/features/bcd/providers/bcd_provider.dart';
import 'package:taxi_exam_app/features/smart_learning/screens/smart_result_screen.dart';
import 'package:taxi_exam_app/features/smart_learning/services/smart_progress_service.dart';
import 'package:taxi_exam_app/features/smart_learning/screens/smart_learning_screen.dart';
import 'package:taxi_exam_app/features/smart_learning/screens/smart_test_screen.dart';
import 'package:taxi_exam_app/features/smart_learning/utils/smart_utils.dart';

/// Thin loader for Smart Learning chunk sessions.
///
/// Fetches only the questions needed for this chunk (or this mistakes session)
/// using limit/offset pagination, then hands off to [SmartTestScreen].
class SmartSessionScreen extends StatefulWidget {
  final SmartExamEntry entry;
  final int chunkIndex; // -1 for Train Mistakes mode
  final bool isMistakesMode;
  final VoidCallback? onProgressSaved;

  const SmartSessionScreen({
    super.key,
    required this.entry,
    required this.chunkIndex,
    required this.isMistakesMode,
    this.onProgressSaved,
  });

  @override
  State<SmartSessionScreen> createState() => _SmartSessionScreenState();
}

class _SmartSessionScreenState extends State<SmartSessionScreen> {
  final _provider = BcdProvider();
  final _svc = SmartProgressService();
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final testBcdId = widget.entry.testBcdId;
    List<Question> questions;

    try {
      if (widget.isMistakesMode) {
        // Fetch only the user's weak questions by ID.
        final weakIds = await _svc.allWeakQuestionIds(testBcdId);
        if (weakIds.isEmpty) {
          if (mounted) {
            showAppSnackBar(Translations.of(context).bcd_no_questions);
            Navigator.pop(context);
          }
          return;
        }
        questions = await _provider.fetchChunkQuestions(testBcdId, ids: weakIds)
          ..shuffle(Random());
      } else {
        // Compute the offset and limit for this chunk from the known question count.
        final sizes = SmartUtils.computeSmartSizes(widget.entry.questionCount);
        final safeIdx = widget.chunkIndex.clamp(0, sizes.length - 1);
        final offset = SmartUtils.smartOffset(sizes, safeIdx);
        final limit = sizes[safeIdx];
        final base = await _provider.fetchChunkQuestions(
          testBcdId,
          limit: limit,
          offset: offset,
        );

        // Inject up to 30% weak questions (deduped against the base slice).
        final weakIds = await _svc.allWeakQuestionIds(testBcdId);
        final baseIds = base.map((q) => q.questionId).toSet();
        final cap = (limit * 0.3).floor();
        final injectIds =
            weakIds.where((id) => !baseIds.contains(id)).take(cap).toList();

        if (injectIds.isNotEmpty) {
          final injected =
              await _provider.fetchChunkQuestions(testBcdId, ids: injectIds);
          questions = [...base, ...injected]..shuffle(Random());
        } else {
          questions = base..shuffle(Random());
        }
      }
    } catch (_) {
      if (mounted) {
        showAppSnackBar(Translations.of(context).bcd_failed_test_questions,
            type: SnackBarType.error);
        Navigator.pop(context);
      }
      return;
    }

    if (!mounted) return;

    if (questions.isEmpty) {
      showAppSnackBar(Translations.of(context).bcd_no_questions);
      Navigator.pop(context);
      return;
    }

    final chunkIdx = widget.chunkIndex;
    final isMistakes = widget.isMistakesMode;

    Navigator.pushReplacement(
      context,
      AppPageRoute(
        builder: (_) => SmartTestScreen(
          initialQuestions: questions,
          passScorePercent: isMistakes ? 0.0 : 70.0,
          testName: widget.entry.testName,
          licenceId: '',
          categoryId: testBcdId.toString(),
          bcdCategoryId: widget.entry.parentCategoryBcdId,
          bcdTestId: testBcdId,
          onComplete: (hasPassed, finalResults) async {
            if (!isMistakes) {
              await _svc.recordSmartResult(testBcdId, chunkIdx, hasPassed);
            }
            await _svc.recordSessionResults(testBcdId, finalResults);
            widget.onProgressSaved?.call();
            // Fire-and-forget: sync smart progress + weak questions to backend.
            _syncSmartData(testBcdId, isMistakes).ignore();
            final mastered = await _svc.masteredQuestionCount(
                testBcdId, widget.entry.chunkSizes);
            final correct = finalResults.values.where((v) => v).length;
            return SmartResultScreen(
              entry: widget.entry,
              chunkIndex: chunkIdx,
              isMistakesMode: isMistakes,
              hasPassed: hasPassed,
              correct: correct,
              total: finalResults.length,
              masteredCount: mastered,
            );
          },
        ),
      ),
    );
  }

  Future<void> _syncSmartData(int testBcdId, bool isMistakes) async {
    try {
      // Sync chunk pass/fail progress (skip for mistakes-only sessions).
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
      // Sync full weak question pool (always — mistakes session also modifies it).
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

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: AppBackButton(onPressed: () => Navigator.pop(context)),
        title: Text(
          widget.isMistakesMode
              ? t.smart_mistakes_title
              : t.smart_chunk_n(n: widget.chunkIndex + 1),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
