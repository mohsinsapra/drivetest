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

  Map<String, List<Question>> translatedQuestionsWithOptions = {};

  String currentLanguageCode = 'SV';

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

  Future<List<Question>> translateQuestionsOnce(
    List<Question> questions, {
    required String fromLang,
    required String toLang,
    required GoogleTranslator translator,
  }) async {
    // 1 ─ Gather all strings that need translation (order matters!)
    final List<String> buffer = [];
    for (final q in questions) {
      buffer.add(q.text);
      buffer.addAll(q.options.map((o) => o.text));
    }

    // 2 ─ Kick off *one* asynchronous batch of requests.
    //     Each element in `results` keeps the same index it had in `buffer`.
    final results = await Future.wait(
      buffer
          .map((txt) => translator.translate(txt, from: fromLang, to: toLang)),
    ); // ← single await point :contentReference[oaicite:0]{index=0}

    // 3 ─ Walk through the original structure and replace the texts.
    var idx = 0;
    return questions.map((q) {
      final translatedQuestionText = results[idx++].text;

      final translatedOptions = q.options.map((o) {
        final translatedOptText = results[idx++].text;
        return o.copyWith(text: translatedOptText);
        // …or Option(optionLabel: o.optionLabel, text: translatedOptText, imageUrl: o.imageUrl);
      }).toList();

      return q.copyWith(
          text: translatedQuestionText, options: translatedOptions);
      // …or Question(text: translatedQuestionText, imageUrl: q.imageUrl, …);
    }).toList();
  }

  Future<void> _translateQuestion(int index, String targetLang) async {
    if (translatedQuestionsWithOptions.containsKey(targetLang)) {
      // If already translated, just use the cached translation
      final translated = translatedQuestionsWithOptions[targetLang]!;
      translatedQuestions[index] = translated[index].text;
      translatedOptions[index] =
          translated[index].options.map((option) => option.text).toList();

      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final translated = await translateQuestionsOnce(
        widget.questions,
        fromLang: 'sv',
        toLang: targetLang,
        translator: translator,
      );

      translatedQuestionsWithOptions[targetLang] = translated;

      setState(() {
        isEnglish = targetLang == 'en';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Translation failed. Please try again.')),
      );
    } finally {
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
          final translatedList =
              translatedQuestionsWithOptions[currentLanguageCode.toLowerCase()];
          final question =
              (translatedList != null && translatedList.length > index)
                  ? translatedList[index]
                  : widget.questions[index];

          // Sort options if necessary
          question.options
              .sort((a, b) => a.optionLabel.compareTo(b.optionLabel));

          // Get translated question text if available
          String questionText = question.text;

          // Get translated options if available
          List<String> optionTexts = [];

          optionTexts = question.options.map((e) => e.text).toList();

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
              DropdownButton<String>(
                value:
                    currentLanguageCode, // ✅ reflect actual selected language
                underline: const SizedBox(),
                items: [
                  {'code': 'SV', 'label': '🇸🇪'}, // Swedish (official)
                  {
                    'code': 'EN',
                    'label': '🇬🇧'
                  }, // English (widely used as second language)
                  {'code': 'AR', 'label': '🇸🇦'}, // Arabic
                  {'code': 'SO', 'label': '🇸🇴'}, // Somali
                  {'code': 'FA', 'label': '🇮🇷'}, // Persian (Farsi)
                  {'code': 'UR', 'label': '🇵🇰'}, // Urdu
                  {
                    'code': 'FI',
                    'label': '🇫🇮'
                  }, // Finnish (official minority)
                  {'code': 'KU', 'label': '🇹🇷'}, // Kurdish (Kurmanji/Sorani)
                  {'code': 'RU', 'label': '🇷🇺'}, // Russian
                  {'code': 'TI', 'label': '🇪🇷'}, // Tigrinya
                  {'code': 'DA', 'label': '🇩🇰'}, // Danish
                  {'code': 'NO', 'label': '🇳🇴'}, // Norwegian
                  {'code': 'PL', 'label': '🇵🇱'}, // Polish
                  {'code': 'TR', 'label': '🇹🇷'}, // Turkish
                ]
                    .map((lang) => DropdownMenuItem<String>(
                          value: lang['code'],
                          child: Text(
                            lang['label']!,
                            style: const TextStyle(fontSize: 35),
                          ),
                        ))
                    .toList(),
                onChanged: (String? value) async {
                  if (value == null) return;

                  String targetLang = value.toLowerCase();
                  // Optional condition if you want to skip already active languages
                  if (targetLang != currentLanguageCode.toLowerCase()) {
                    await _translateQuestion(currentQuestionIndex, targetLang);
                    setState(() {
                      currentLanguageCode = value; // ✅ update selected language
                    });
                  }
                },
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
