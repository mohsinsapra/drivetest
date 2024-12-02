import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';
import 'package:taxi_exam_app/core/widgets/explanation_widget.dart';
import 'package:taxi_exam_app/core/widgets/option_widget.dart';
import 'package:taxi_exam_app/core/widgets/question_widget.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:taxi_exam_app/features/tests/result_screen.dart';
import 'package:translator/translator.dart';

class Testscreen extends StatefulWidget {
  final List<Question> questions;
  final bool instantMarking;
  final String licenceId;
  final String categoryId;
  final int initialQuestionIndex;
  final Map<int, String>? userSelections;
  final bool isReviewMode; // New parameter

  const Testscreen({
    super.key,
    required this.questions,
    required this.instantMarking,
    required this.licenceId,
    required this.categoryId,
    this.initialQuestionIndex = 0,
    this.userSelections,
    this.isReviewMode = false, // Default to false
  });

  @override
  State<Testscreen> createState() => _TestscreenState();
}

class _TestscreenState extends State<Testscreen> {
  int currentQuestionIndex = 0;
  Map<int, String> userSelections = {};
  final ApiService _apiService = ApiService();

  // Add PageController
  late PageController _pageController;

  // Translation variables
  final translator = GoogleTranslator();
  bool isEnglish = true; // Track current language
  Map<int, String> translatedQuestions = {};
  Map<int, List<String>> translatedOptions = {};

  final _noScreenshot = NoScreenshot.instance;

  @override
  void initState() {
    super.initState();
    currentQuestionIndex = widget.initialQuestionIndex;
    userSelections = widget.userSelections ?? {};

    // Initialize PageController
    _pageController = PageController(initialPage: currentQuestionIndex);

    disableScreenshot();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      currentQuestionIndex = index;
    });
  }

  void _selectOption(String optionId, int index) {
    if (widget.isReviewMode) {
      // Do not allow selection in review mode
      return;
    }
    setState(() {
      userSelections[index] = optionId;
    });
  }

  void _nextQuestion() {
    if (currentQuestionIndex < widget.questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Show confirmation dialog
      _showFinishConfirmationDialog();
    }
  }

  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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
                _saveTestAttempt();

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

  void _saveTestAttempt() async {
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
    bool hasPassed = scorePercentage >= 70; // Adjust as needed

    // Create a TestAttempt object
    TestAttempt attempt = TestAttempt(
      testId: DateTime.now().millisecondsSinceEpoch.toString(), // Unique ID
      dateTime: DateTime.now(),
      userSelections: userSelections,
      score: scorePercentage,
      hasPassed: hasPassed,
      questions: widget.questions, // Save questions for detailed view
    );

    // Open a Hive box
    var box = await Hive.openBox<TestAttempt>('testAttempts');

    // Save the attempt
    await box.add(attempt);

    // Close the box (optional)
    await box.close();
  }

  Future<void> _translateQuestion(int index) async {
    final question = widget.questions[index];
    String targetLanguage = isEnglish ? 'en' : 'sv';

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Translate question text
      var translatedQuestion = await translator.translate(
        question.text,
        from: 'sv',
        to: targetLanguage,
      );

      // Translate options
      List<String> translatedOptionTexts = [];
      for (var option in question.options) {
        var translatedOption = await translator.translate(
          option.text,
          from: 'sv',
          to: targetLanguage,
        );
        translatedOptionTexts.add(translatedOption.text);
      }

      setState(() {
        translatedQuestions[index] = translatedQuestion.text;
        translatedOptions[index] = translatedOptionTexts;
        isEnglish = !isEnglish; // Toggle language state
      });
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Translation failed. Please try again.')),
      );
    } finally {
      // Dismiss loading indicator
      Navigator.of(context).pop();
    }
  }

  void disableScreenshot() async {
    await _noScreenshot.screenshotOff();
  }

  @override
  Widget build(BuildContext context) {
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
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemCount: widget.questions.length,
        itemBuilder: (context, index) {
          final question = widget.questions[index];

          // Sort options if necessary
          question.options
              .sort((a, b) => a.optionLabel.compareTo(b.optionLabel));

          // Get translated question text if available
          String questionText = translatedQuestions[index] ?? question.text;

          // Get translated options if available
          List<String> optionTexts = [];
          if (translatedOptions[index] != null) {
            optionTexts = translatedOptions[index]!;
          } else {
            optionTexts = question.options.map((e) => e.text).toList();
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Question Widget
                  QuestionWidget(
                    questionText: questionText,
                    question: question,
                    licenceId: widget.licenceId,
                    categoryId: widget.categoryId,
                    apiService: _apiService,
                  ),
                  const SizedBox(height: 16),
                  // Options
                  ...question.options.asMap().entries.map((entry) {
                    int optIndex = entry.key;
                    var option = entry.value;
                    String optionText = optionTexts[optIndex];

                    return OptionWidget(
                      optionText: optionText,
                      option: option,
                      question: question,
                      isSelected: userSelections[index] == option.optionLabel,
                      isInstantMarking: widget.instantMarking,
                      selectedOptionId: userSelections[index] ?? '',
                      onSelectOption: (optionId) =>
                          _selectOption(optionId, index),
                      licenceId: widget.licenceId,
                      categoryId: widget.categoryId,
                      apiService: _apiService,
                    );
                  }),
                  // Explanation
                  if (widget.instantMarking && userSelections[index] != null)
                    ExplanationWidget(
                      question: question,
                      licenceId: widget.licenceId,
                      categoryId: widget.categoryId,
                      apiService: _apiService,
                    ),
                ],
              ),
            ),
          );
        },
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
                onPressed: () {
                  _translateQuestion(currentQuestionIndex);
                },
                child: Text(!isEnglish ? 'SV' : 'EN'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Handle Save action
                },
                child: const Text('Save'),
              ),
              ElevatedButton(
                onPressed: _nextQuestion,
                child: Text(currentQuestionIndex == widget.questions.length - 1
                    ? 'Finish'
                    : 'Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
