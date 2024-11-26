// test_screen.dart
import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/core/widgets/explanation_widget.dart';
import 'package:taxi_exam_app/core/widgets/option_widget.dart';
import 'package:taxi_exam_app/core/widgets/question_widget.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:taxi_exam_app/features/tests/result_screen.dart';

class Testscreen extends StatefulWidget {
  final List<Question> questions;
  final bool instantMarking;
  final String licenceId;
  final String categoryId;
  final int initialQuestionIndex; // New parameter
  final Map<int, String>? userSelections; // New parameter

  const Testscreen({
    super.key,
    required this.questions,
    required this.instantMarking,
    required this.licenceId,
    required this.categoryId,
    this.initialQuestionIndex = 0,
    this.userSelections,
  });

  @override
  State<Testscreen> createState() => _TestscreenState();
}

class _TestscreenState extends State<Testscreen> {
  int currentQuestionIndex = 0;
  String selectedOptionId = '';
  bool showExplanation = false;
  final _noScreenshot = NoScreenshot.instance;
  final ApiService _apiService = ApiService();
  Map<int, String> userSelections = {};

  // Add ScrollController
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    currentQuestionIndex = widget.initialQuestionIndex;
    userSelections = widget.userSelections ?? {};
    selectedOptionId = userSelections[currentQuestionIndex] ?? '';
  }

  void _selectOption(String optionId) {
    // Capture the current scroll position
    final scrollPosition = _scrollController.position.pixels;

    setState(() {
      selectedOptionId = optionId;
      showExplanation = true;
      userSelections[currentQuestionIndex] = optionId; // Record selection
    });

    // Restore the scroll position after the frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(scrollPosition);
    });
  }

  void _nextQuestion() {
    if (currentQuestionIndex < widget.questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedOptionId = userSelections[currentQuestionIndex] ?? '';
        showExplanation = false;
      });
    } else {
      // Show confirmation dialog
      _showFinishConfirmationDialog();
    }
  }

  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
        selectedOptionId = userSelections[currentQuestionIndex] ?? '';
        showExplanation = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This is the first question!')),
      );
    }
  }

  void _showFinishConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap a button to dismiss
      builder: (BuildContext context) {
        int unansweredQuestions =
            widget.questions.length - userSelections.length;

        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Finish Test'),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss the dialog
                },
              ),
            ],
          ),
          content: Text(
            unansweredQuestions > 0
                ? 'You have $unansweredQuestions unanswered question(s). Do you still want to finish the test?'
                : 'Do you want to finish the test?',
          ),
          actions: [
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
            ElevatedButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
                _showResultDialog(); // Show pass/fail result
              },
            ),
          ],
        );
      },
    );
  }

  bool _calculateResult() {
    int correctAnswers = 0;

    for (int i = 0; i < widget.questions.length; i++) {
      final question = widget.questions[i];
      final selectedOptionLabel = userSelections[i];

      if (selectedOptionLabel != null &&
          selectedOptionLabel == question.correctAnswer) {
        correctAnswers++;
      }
    }

    double scorePercentage = (correctAnswers / widget.questions.length) * 100;
    return scorePercentage >= 70; // Assume passing score is 70%
  }

  void _showResultDialog() {
    bool hasPassed = _calculateResult();

    showDialog(
      context: context,
      barrierDismissible: false, // User must tap a button to dismiss
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(hasPassed ? 'Congratulations!' : 'Test Completed'),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss the dialog
                },
              ),
            ],
          ),
          content: Text(
            hasPassed
                ? 'You have passed the test.'
                : 'You did not pass the test.',
          ),
          actions: [
            TextButton(
              child: const Text('Go Back to Tests'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
                Navigator.of(context).pop(); // Go back to tests screen
              },
            ),
            ElevatedButton(
              child: const Text('See Results'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
                // Navigate to ResultScreen and remove previous routes
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResultScreen(
                      questions: widget.questions,
                      userSelections: userSelections,
                      licenceId: widget.licenceId,
                      categoryId: widget.categoryId,
                      hasPassed: hasPassed,
                    ),
                  ),
                  (Route<dynamic> route) => route.isFirst,
                );
              },
            ),
          ],
        );
      },
    );
  }

  void disableScreenshot() async {
    await _noScreenshot.screenshotOff();
    // debugPrint('Screenshot Off: $result');
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[currentQuestionIndex];
    // Clone the list to avoid mutating the original data
    bool isLastQuestion = currentQuestionIndex == widget.questions.length - 1;

// Sort options by 'option_label' or any other key
    question.options.sort((a, b) => a.optionLabel.compareTo(b.optionLabel));
    disableScreenshot();
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Question ${currentQuestionIndex + 1} of ${widget.questions.length}'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _showFinishConfirmationDialog,
            child: const Text('Finish'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          controller: _scrollController, // Add this line
          child: Column(
            children: [
              // Question Widget
              QuestionWidget(
                question: question,
                licenceId: widget.licenceId,
                categoryId: widget.categoryId,
                apiService: _apiService,
              ),
              const SizedBox(height: 16),
              // Options
              ...question.options.map((option) => OptionWidget(
                    option: option,
                    question: question,
                    isSelected: selectedOptionId == option.optionLabel,
                    isInstantMarking: widget.instantMarking,
                    selectedOptionId: selectedOptionId,
                    onSelectOption: _selectOption,
                    licenceId: widget.licenceId,
                    categoryId: widget.categoryId,
                    apiService: _apiService,
                  )),
              // Explanation

              Visibility(
                visible: showExplanation,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: ExplanationWidget(
                  question: question,
                  licenceId: widget.licenceId,
                  categoryId: widget.categoryId,
                  apiService: _apiService,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 32.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceEvenly, // Space buttons evenly
            children: [
              ElevatedButton(
                onPressed: _previousQuestion,
                child: const Text('Back'),
              ),
              ElevatedButton(
                onPressed: () {},
                child: const Text('EN/SV'),
              ),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Save'),
              ),
              ElevatedButton(
                onPressed: _nextQuestion,
                child: Text(isLastQuestion ? 'Finish' : 'Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
