import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/constants/language_options.dart';
import 'package:taxi_exam_app/core/models/image_viewer.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';
import 'package:taxi_exam_app/core/services/tts_service.dart';
import 'package:taxi_exam_app/core/widgets/explanation_widget.dart';
import 'package:taxi_exam_app/core/widgets/option_widget.dart';
import 'package:taxi_exam_app/core/widgets/question_widget.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:taxi_exam_app/core/widgets/tts_button.dart';
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

  final ttsService = TtsService();
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
    ttsService.flutterTts.stop(); // Stop TTS when disposing
    ttsService.ttsState = TtsState.stopped; // Reset TTS state
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      currentQuestionIndex = index;
    });
    ttsService.flutterTts.stop(); // Stop TTS when changing page
    ttsService.ttsState = TtsState.stopped; // Reset TTS state
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: GestureDetector(
          onTap: _showQuestionNavigationSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress bar
                Container(
                  width: 100,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor:
                        (currentQuestionIndex + 1) / widget.questions.length,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Question counter
                Text(
                  '${currentQuestionIndex + 1}/${widget.questions.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 4),
                // Dropdown indicator
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: Colors.grey[500],
                ),
              ],
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: PopupMenuButton<String>(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[200]!, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ttsService.getLanguageFlag(currentLanguageCode),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      LucideIcons.languages,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
              onSelected: (String value) async {
                String targetLang = value.toLowerCase();
                if (targetLang != currentLanguageCode.toLowerCase()) {
                  await _translateQuestion(currentQuestionIndex, targetLang);
                  setState(() {
                    currentLanguageCode = value;
                  });
                }
              },
              itemBuilder: (BuildContext context) => languageOptions
                  .map((lang) => PopupMenuItem<String>(
                        value: lang['code'],
                        child: Text(lang['label']!),
                      ))
                  .toList(),
            ),
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
          var questionUrl = _apiService.fetchImage(
            widget.licenceId,
            widget.categoryId,
            widget.questions[index].imageUrl,
          );
          // Sort options if necessary
          question.options
              .sort((a, b) => a.optionLabel.compareTo(b.optionLabel));

          // Get translated question text if available
          String questionText = question.text;

          // Get translated options if available
          List<String> optionTexts = [];
          optionTexts = question.options.map((e) => e.text).toList();

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question header

                  // Question text
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.3,
                        fontFamily: 'NudMoto',
                      ),
                      children: [
                        TextSpan(text: questionText),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: TtsButton(
                            textToSpeak: questionText,
                            languageCode: currentLanguageCode,
                            iconSize: 24, // adjust for visual balance
                            tooltip: 'Read aloud',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Question image (if available)
                  if (question.imageUrl.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GestureDetector(
                          onTap: () => showImageViewer(context, questionUrl),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.4,
                              maxWidth: MediaQuery.of(context).size.width * 0.9,
                            ),
                            child:
                                Image.network(questionUrl, fit: BoxFit.contain),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Options
                  ...question.options.asMap().entries.map((entry) {
                    int optIndex = entry.key;
                    var option = entry.value;
                    String optionText = optionTexts[optIndex];
                    bool isSelected =
                        userSelections[index] == option.optionLabel;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            _selectOption(option.optionLabel, index);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              // Determine background color and border for instant marking
                              color: widget.instantMarking &&
                                      userSelections[index] != null
                                  ? (isSelected
                                      ? (option.optionLabel ==
                                              question.correctAnswer
                                          ? Colors.green[100]
                                          : Colors.red[100])
                                      : (option.optionLabel ==
                                              question.correctAnswer
                                          ? Colors.green[200]
                                          : Colors.white))
                                  : (isSelected
                                      ? Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.1)
                                      : Colors.white),
                              border: Border.all(
                                color: widget.instantMarking &&
                                        userSelections[index] != null
                                    ? (option.optionLabel ==
                                            question.correctAnswer
                                        ? Colors.green[200]!
                                        : isSelected
                                            ? Colors.red[200]!
                                            : Colors.grey[200]!)
                                    : (isSelected
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey[300]!),
                                width: widget.instantMarking &&
                                        userSelections[index] != null
                                    ? (option.optionLabel ==
                                                question.correctAnswer ||
                                            isSelected
                                        ? 1.5
                                        : 0.5)
                                    : (isSelected ? 1 : 0.5),
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
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
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? Theme.of(context).primaryColor
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected
                                              ? Theme.of(context).primaryColor
                                              : Colors.grey[400]!,
                                          width: 2,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.circle,
                                              color: Colors.white,
                                              size: 12,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              optionText,
                                              softWrap: true,
                                              overflow: TextOverflow.visible,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                                color: isSelected
                                                    ? Theme.of(context)
                                                        .primaryColor
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          TtsButton(
                                            textToSpeak: optionText,
                                            languageCode: currentLanguageCode,
                                            iconSize: 20,
                                            tooltip: 'Read option aloud',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                // Option image (if available)
                                if (option.imageUrl != null &&
                                    option.imageUrl!.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(top: 12),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        option.imageUrl!,
                                        width: double.infinity,
                                        height: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            width: double.infinity,
                                            height: 120,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.image_not_supported,
                                                  size: 24,
                                                  color: Colors.grey[400],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Image not available',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Container(
                                            width: double.infinity,
                                            height: 120,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Center(
                                              child: SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  value: loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                      : null,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 24),

                  // Explanation (scrollable)
                  if (widget.instantMarking &&
                      userSelections[index] != null &&
                      question.answerExplanation.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            constraints: const BoxConstraints(),
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
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: currentQuestionIndex > 0 ? _previousQuestion : null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  side: BorderSide(
                    color: currentQuestionIndex > 0
                        ? Colors.grey[400]!
                        : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: currentQuestionIndex > 0
                        ? Colors.black87
                        : Colors.grey[400],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  currentQuestionIndex == widget.questions.length - 1
                      ? 'Finish'
                      : 'Next',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// Add this helper method for language flags

// Add this method to show the question navigation sheet
  void _showQuestionNavigationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Text(
                      'Questions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${currentQuestionIndex + 1} of ${widget.questions.length}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: widget.questions.length,
                  itemBuilder: (context, index) {
                    bool isAnswered = userSelections[index] != null;
                    bool isCurrent = index == currentQuestionIndex;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.1)
                                  : Colors.grey[50],
                              border: Border.all(
                                color: isCurrent
                                    ? Theme.of(context).primaryColor
                                    : Colors.transparent,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isAnswered
                                        ? Colors.green
                                        : isCurrent
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey[300],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: isAnswered
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 16,
                                          )
                                        : Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              color: isCurrent || isAnswered
                                                  ? Colors.white
                                                  : Colors.grey[600],
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Question ${index + 1}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: isCurrent
                                              ? Theme.of(context).primaryColor
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isAnswered
                                            ? 'Answered'
                                            : 'Not answered',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isAnswered
                                              ? Colors.green
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
