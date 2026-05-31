import 'dart:math';

import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/core/widgets/app_back_button.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'package:taxi_exam_app/features/bcd/providers/bcd_provider.dart';
import 'package:taxi_exam_app/features/smart_learning/screens/smart_result_screen.dart';
import 'package:taxi_exam_app/features/smart_learning/services/smart_progress_service.dart';
import 'package:taxi_exam_app/features/smart_learning/screens/smart_learning_screen.dart';
import 'package:taxi_exam_app/features/smart_learning/screens/smart_test_screen.dart';

/// Loads all weak questions across every exam in a category and launches a
/// [SmartTestScreen] session. Uses the same 2-correct graduation mechanic.
class SmartCategoryMistakesScreen extends StatefulWidget {
  final String categoryName;
  final List<SmartExamEntry> entries;

  const SmartCategoryMistakesScreen({
    super.key,
    required this.categoryName,
    required this.entries,
  });

  @override
  State<SmartCategoryMistakesScreen> createState() => _SmartCategoryMistakesScreenState();
}

class _SmartCategoryMistakesScreenState extends State<SmartCategoryMistakesScreen> {
  final _provider = BcdProvider();
  final _svc = SmartProgressService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // 1. Get weak question IDs grouped by test.
    final testIds = widget.entries.map((e) => e.testBcdId).toList();
    final weakByTest = await _svc.weakQuestionIdsByTest(testIds);

    if (!mounted) return;
    final t = Translations.of(context);

    if (weakByTest.isEmpty) {
      showAppSnackBar(t.smart_mistakes_none_category);
      Navigator.pop(context);
      return;
    }

    // 2. Fetch questions for each test that has weak entries.
    final allQuestions = <Question>[];
    // Track which testBcdId owns each questionId for post-session recording.
    final questionTestMap = <String, int>{};

    for (final entry in weakByTest.entries) {
      final testId = entry.key;
      final ids = entry.value;
      try {
        final questions =
            await _provider.fetchChunkQuestions(testId, ids: ids);
        for (final q in questions) {
          questionTestMap[q.questionId] = testId;
        }
        allQuestions.addAll(questions);
      } catch (_) {
        // Skip tests that fail to load — continue with others.
      }
    }

    if (!mounted) return;

    if (allQuestions.isEmpty) {
      showAppSnackBar(t.smart_mistakes_load_failed);
      Navigator.pop(context);
      return;
    }

    allQuestions.shuffle(Random());

    Navigator.pushReplacement(
      context,
      AppPageRoute(
        builder: (_) => SmartTestScreen(
          initialQuestions: allQuestions,
          passScorePercent: 0.0, // mistakes mode — no pass threshold
          testName: widget.categoryName,
          licenceId: '',
          categoryId: '',
          onComplete: (hasPassed, finalResults) async {
            // Group results by testBcdId and record each separately.
            final resultsByTest = <int, Map<String, bool>>{};
            for (final e in finalResults.entries) {
              final testId = questionTestMap[e.key];
              if (testId == null) continue;
              resultsByTest.putIfAbsent(testId, () => {})[e.key] = e.value;
            }
            for (final e in resultsByTest.entries) {
              await _svc.recordSessionResults(e.key, e.value);
            }

            // Find the entry with the most questions for the result screen context.
            final primaryEntry = widget.entries.reduce((a, b) =>
                a.questionCount >= b.questionCount ? a : b);
            final mastered = await _svc.masteredQuestionCount(
                primaryEntry.testBcdId, primaryEntry.chunkSizes);
            final correct = finalResults.values.where((v) => v).length;

            return SmartResultScreen(
              entry: primaryEntry,
              chunkIndex: -1,
              isMistakesMode: true,
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

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: AppBackButton(onPressed: () => Navigator.pop(context)),
        title: Text(t.smart_mistakes_title),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
