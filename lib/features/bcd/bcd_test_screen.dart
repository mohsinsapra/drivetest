import 'package:taxi_exam_app/core/widgets/app_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/widgets/app_back_button.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'package:taxi_exam_app/features/bcd/providers/bcd_provider.dart';
import 'package:taxi_exam_app/features/tests/test_screen.dart';

/// Thin loader: fetches BCD questions via [BcdProvider], then replaces
/// itself with the standard [Testscreen].
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
  final _provider = BcdProvider();

  @override
  void initState() {
    super.initState();
    _provider.addListener(_onStateChange);
    _provider.loadTestQuestions(widget.testId);
  }

  @override
  void dispose() {
    _provider.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (!mounted) return;
    if (_provider.testQuestionsError != null) {
      showAppSnackBar(
        Translations.of(context).bcd_failed_test_questions,
        type: SnackBarType.error,
      );
      Navigator.pop(context);
      return;
    }
    if (!_provider.testQuestionsLoading) {
      if (_provider.testQuestions.isEmpty) {
        showAppSnackBar(Translations.of(context).bcd_no_questions);
        Navigator.pop(context);
        return;
      }
      Navigator.pushReplacement(
        context,
        AppPageRoute(
          builder: (_) => Testscreen(
            questions: _provider.testQuestions,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(widget.testName), leading: const AppBackButton()),
      body: const Center(child: AppLoadingIndicator()),
    );
  }
}
