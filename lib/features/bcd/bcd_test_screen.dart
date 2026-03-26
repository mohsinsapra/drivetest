import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/models/option.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'package:taxi_exam_app/features/tests/test_screen.dart';

import 'bcd_text_utils.dart';

final _api = ApiService();

/// Thin loader: fetches BCD questions, converts to [Question]/[Option],
/// then replaces itself with the standard [Testscreen].
class BCDTestScreen extends StatefulWidget {
  final int testId;
  final String testName;
  final int passScore;
  final int timeLimit; // minutes; 0 = untimed
  final String parentCategoryName;
  final int? parentCategoryBcdId;

  const BCDTestScreen({
    super.key,
    required this.testId,
    required this.testName,
    required this.passScore,
    required this.timeLimit,
    this.parentCategoryName = '',
    this.parentCategoryBcdId,
  });

  @override
  State<BCDTestScreen> createState() => _BCDTestScreenState();
}

class _BCDTestScreenState extends State<BCDTestScreen> {
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await _api.fetchBCDTestQuestions(widget.testId);
      final questions = raw.map(_toQuestion).toList();

      if (!mounted) return;

      if (questions.isEmpty) {
        showAppSnackBar('No questions found for this test.');
        Navigator.pop(context);
        return;
      }

      // Replace this loader screen with Testscreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => Testscreen(
            questions: questions,
            instantMarking: true,
            licenceId: '',
            categoryId: widget.testId.toString(),
            licenceName: widget.parentCategoryName,
            categoryName: widget.testName,
            bcdCategoryId: widget.parentCategoryBcdId,
            bcdTestId: widget.testId,
            passScorePercent: widget.passScore.toDouble(),
            isTimed: widget.timeLimit > 0,
            timeLimitMinutes: widget.timeLimit > 0 ? widget.timeLimit : 10,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar('Failed to load test questions.');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.testName)),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

/// Convert a single BCD question JSON map to a [Question].
Question _toQuestion(dynamic raw) {
  final q = raw as Map<String, dynamic>;
  final answers = (q['bcd_answers'] as List<dynamic>?) ?? [];

  final options = answers.map((a) {
    final ans = a as Map<String, dynamic>;
    return Option(
      optionLabel: ans['label']?.toString() ?? '',
      text: cleanBcdText(ans['content']?.toString() ?? ''),
      imageUrl: '',
    );
  }).toList();

  // Build full URL for question image if present
  final rawImagePath = q['image_url']?.toString() ?? '';
  final imageUrl =
      rawImagePath.isNotEmpty ? _api.bcdMediaUrl(rawImagePath) : '';

  return Question(
    questionId: q['bcd_id']?.toString() ?? '',
    text: cleanBcdText(q['content']?.toString() ?? ''),
    imageUrl: imageUrl,
    correctAnswer: q['correct_answer']?.toString() ?? '',
    answerExplanation: cleanBcdText(q['explanation']?.toString() ?? ''),
    options: options,
  );
}
