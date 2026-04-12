import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/constants/language_options.dart';
import 'package:taxi_exam_app/core/models/image_viewer.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';
import 'package:taxi_exam_app/core/services/saved_questions_service.dart';
import 'package:taxi_exam_app/core/services/tts_service.dart';
import 'package:taxi_exam_app/core/widgets/explanation_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:taxi_exam_app/core/widgets/navigation_controls.dart';
import 'package:taxi_exam_app/core/widgets/option_tile.dart';
import 'package:taxi_exam_app/core/widgets/question_progress_header.dart';
import 'package:taxi_exam_app/core/widgets/test_dialogs.dart';
import 'package:taxi_exam_app/core/widgets/tts_button.dart';

import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'package:translator/translator.dart';

class Testscreen extends StatefulWidget {
  final List<Question> questions;
  final bool instantMarking;
  final String licenceId;
  final String categoryId;
  final String licenceName;
  final String categoryName;
  final int initialQuestionIndex;
  final Map<int, String>? userSelections;
  final bool isReviewMode;
  final bool isTimed;
  final int timeLimitMinutes;
  final double passScorePercent;
  final String? resumeTestId;
  final int? bcdTestId;
  final Set<String>? initiallySavedQuestionIds;

  /// BCD parent-category ID — only set for BCD tests; null for legacy tests.
  final int? bcdCategoryId;

  const Testscreen({
    super.key,
    required this.questions,
    required this.instantMarking,
    required this.licenceId,
    required this.categoryId,
    this.licenceName = '',
    this.categoryName = '',
    this.initialQuestionIndex = 0,
    this.userSelections,
    this.isReviewMode = false,
    this.isTimed = false,
    this.timeLimitMinutes = 10,
    this.passScorePercent = 70,
    this.resumeTestId,
    this.bcdCategoryId,
    this.bcdTestId,
    this.initiallySavedQuestionIds,
  });

  @override
  State<Testscreen> createState() => _TestscreenState();
}

class _TestscreenState extends State<Testscreen> {
  int currentQuestionIndex = 0;
  Map<int, String> userSelections = {};
  final ApiService _apiService = ApiService();

  final ttsService = TtsService();
  late PageController _pageController;

  // Translation variables
  final translator = GoogleTranslator();
  bool isEnglish = true;
  Map<int, String> translatedQuestions = {};
  Map<int, List<String>> translatedOptions = {};
  Map<String, List<Question>> translatedQuestionsWithOptions = {};
  String currentLanguageCode = 'SV';

  // Timer
  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  // Mutable runtime toggles — initialised from widget params (settings)
  late bool _isTimed;
  late bool _instantMarking;
  bool _timerVisible = true;

  // Saved questions
  Set<String> _savedQuestionIds = {};

  // Test session identity
  late String _testId;
  late DateTime _startTime;

  // Snapshot of selections at load time — used to detect changes on resume
  late final Map<int, String> _initialSelections;

  final _noScreenshot = kIsWeb ? null : NoScreenshot.instance;

  @override
  void initState() {
    super.initState();
    currentQuestionIndex = widget.initialQuestionIndex;
    userSelections = Map<int, String>.from(widget.userSelections ?? {});
    _initialSelections = Map<int, String>.from(userSelections);
    _pageController = PageController(initialPage: currentQuestionIndex);
    _testId =
        widget.resumeTestId ?? DateTime.now().millisecondsSinceEpoch.toString();
    _startTime = DateTime.now();
    disableScreenshot();

    _isTimed = widget.isTimed;
    _instantMarking = widget.instantMarking;

    if (_isTimed && !widget.isReviewMode) {
      _remainingSeconds = widget.timeLimitMinutes * 60;
      _startTimer();
    }

    _savedQuestionIds =
        Set<String>.from(widget.initiallySavedQuestionIds ?? {});

    _loadSavedQuestionIds();
    // Pre-open the Hive box so saves never hang waiting for it to open
    Hive.openBox<TestAttempt>('testAttempts');
  }

  Future<void> _loadSavedQuestionIds() async {
    final localIds = await SavedQuestionsService.getSavedIdsScoped(
      licenceId: widget.licenceId,
      categoryId: widget.categoryId,
      bcdCategoryId: widget.bcdCategoryId,
    );
    if (mounted) setState(() => _savedQuestionIds = localIds);

    final remoteIds = await SavedQuestionsService.refreshFromBackend(
      licenceId: widget.licenceId,
      categoryId: widget.categoryId,
      bcdCategoryId: widget.bcdCategoryId,
    );
    if (mounted) setState(() => _savedQuestionIds = remoteIds);
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _remainingSeconds--);
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _onTimerExpired();
      }
    });
  }

  void _onTimerExpired() {
    showAppSnackBar('Time is up! Submitting your test.');
    _saveTestAttempt();
    showResultDialog(
      context: context,
      hasPassed: _calculateResult(),
      questions: widget.questions,
      userSelections: userSelections,
      licenceId: widget.licenceId,
      categoryId: widget.categoryId,
    );
  }

  String get _timerDisplay {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pageController.dispose();
    ttsService.flutterTts.stop();
    ttsService.ttsState = TtsState.stopped;
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
    // Prevent re-selection if already answered in instant marking mode
    if (_instantMarking && userSelections[index] != null) {
      return;
    }
    setState(() {
      userSelections[index] = optionId;
    });
  }

  void _nextQuestion() async {
    if (currentQuestionIndex < widget.questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Show confirmation dialog
      await showFinishConfirmationDialog(
        context: context,
        unansweredCount: widget.questions.length - userSelections.length,
        onCancel: () {}, // nothing extra to do
        onConfirm: () {
          _saveTestAttempt();
          showResultDialog(
            context: context,
            hasPassed: _calculateResult(),
            questions: widget.questions,
            userSelections: userSelections,
            licenceId: widget.licenceId,
            categoryId: widget.categoryId,
          );
        },
      );
    }
  }

  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      showAppSnackBar('This is the first question!');
    }
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
    return scorePercentage >= widget.passScorePercent;
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
    bool hasPassed = scorePercentage >= widget.passScorePercent;

    final attempt = TestAttempt(
      testId: _testId,
      dateTime: _startTime,
      userSelections: userSelections,
      score: scorePercentage,
      hasPassed: hasPassed,
      questions: widget.questions,
      licenceName: widget.licenceName,
      categoryName: widget.categoryName,
      status: 'completed',
      currentQuestionIndex: 0,
      licenceId: widget.licenceId,
      categoryId: widget.categoryId,
      durationSeconds: DateTime.now().difference(_startTime).inSeconds,
      bcdCategoryId: widget.bcdCategoryId,
    );

    final box = Hive.isBoxOpen('testAttempts')
        ? Hive.box<TestAttempt>('testAttempts')
        : await Hive.openBox<TestAttempt>('testAttempts');
    await box.put(
        _testId, attempt); // put by testId overwrites any paused version
    _apiService.syncTestAttempt(attempt); // best-effort backend sync
  }

  Future<void> _savePausedTest() async {
    final attempt = TestAttempt(
      testId: _testId,
      dateTime: _startTime,
      userSelections: Map<int, String>.from(userSelections),
      score: 0,
      hasPassed: false,
      questions: widget.questions,
      licenceName: widget.licenceName,
      categoryName: widget.categoryName,
      status: 'paused',
      currentQuestionIndex: currentQuestionIndex,
      licenceId: widget.licenceId,
      categoryId: widget.categoryId,
      durationSeconds: DateTime.now().difference(_startTime).inSeconds,
      bcdCategoryId: widget.bcdCategoryId,
    );

    // Use already-open box if available to avoid potential deadlock
    final box = Hive.isBoxOpen('testAttempts')
        ? Hive.box<TestAttempt>('testAttempts')
        : await Hive.openBox<TestAttempt>('testAttempts');

    await box.put(_testId, attempt);
    _apiService.syncTestAttempt(attempt); // best-effort backend sync
  }

  bool get _hasChanges {
    if (userSelections.length != _initialSelections.length) return true;
    for (final entry in userSelections.entries) {
      if (_initialSelections[entry.key] != entry.value) return true;
    }
    return false;
  }

  Future<void> _showExitDialog() async {
    // Resumed test with no answer changes — nothing new to save, just exit
    if (widget.resumeTestId != null && !_hasChanges) {
      Navigator.of(context).pop();
      return;
    }
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Test'),
        content: const Text('Would you like to save your progress?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Keep Going'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'exit'),
            child: const Text('Exit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'save'),
            child: const Text('Save & Exit'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (result == 'save') {
      // Show saving indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      try {
        await _savePausedTest().timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('Save failed: $e');
      } finally {
        if (mounted) Navigator.of(context).pop(); // close loading
        if (mounted) Navigator.of(context).pop(); // close test screen
      }
    } else if (result == 'exit') {
      Navigator.of(context).pop();
    }
  }

  Future<void> _showFeedbackDialog() async {
    final q = widget.questions[currentQuestionIndex];
    if (q.questionId.isEmpty) {
      showAppSnackBar('Feedback is unavailable for this question.');
      return;
    }
    final controller = TextEditingController();
    String feedbackType = 'question_issue';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Feedback'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: feedbackType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(
                      value: 'question_issue', child: Text('Question issue')),
                  DropdownMenuItem(
                      value: 'wrong_answer', child: Text('Wrong answer')),
                  DropdownMenuItem(
                      value: 'typo', child: Text('Typo/text issue')),
                  DropdownMenuItem(
                      value: 'image_issue', child: Text('Image issue')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setDialogState(() => feedbackType = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Tell us what is wrong with this question...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, {
                'text': controller.text.trim(),
                'type': feedbackType,
              }),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );

    final text = (result?['text'] ?? '').trim();
    final type = (result?['type'] ?? 'question_issue').trim();
    if (!mounted || text.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final isBcd = widget.bcdCategoryId != null;
    final ok = await _apiService.submitQuestionFeedback(
      questionId: q.questionId,
      questionText: q.text,
      feedbackText: text,
      scopeType: isBcd ? 'bcd' : 'legacy',
      feedbackType: type,
      licenceId: widget.licenceId,
      categoryId: widget.categoryId,
      bcdCategoryId: widget.bcdCategoryId,
      bcdTestId: widget.bcdTestId,
      licenceName: widget.licenceName,
      categoryName: widget.categoryName,
    );

    if (!mounted) return;
    Navigator.of(context).pop();
    showAppSnackBar(ok
        ? 'Thanks! Your feedback was submitted.'
        : 'Could not submit feedback. Please try again.');
  }

  /// Returns true if [s] is translatable text (not an image URL/path).
  bool _isTranslatableText(String s) {
    if (s.isEmpty) return false;
    if (s.startsWith('http://') || s.startsWith('https://')) return false;
    if (!s.contains(' ') &&
        RegExp(r'\.(png|jpg|jpeg|gif|webp)$', caseSensitive: false)
            .hasMatch(s)) {
      return false;
    }
    return true;
  }

  /// Strip HTML tags and decode common entities for clean translation input.
  String _stripHtml(String s) {
    s = s.replaceAll(RegExp(r'<[^>]+>'), ' ');
    const entities = {
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&#39;': "'",
      '&nbsp;': ' ',
      '&auml;': 'ä',
      '&Auml;': 'Ä',
      '&ouml;': 'ö',
      '&Ouml;': 'Ö',
      '&aring;': 'å',
      '&Aring;': 'Å',
    };
    for (final e in entities.entries) {
      s = s.replaceAll(e.key, e.value);
    }
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Translate a single string, returning the original on error.
  Future<String> _safeTranslate(String text, String fromLang, String toLang,
      GoogleTranslator translator) async {
    try {
      final result =
          await translator.translate(text, from: fromLang, to: toLang);
      return result.text;
    } catch (_) {
      return text;
    }
  }

  Future<List<Question>> translateQuestionsOnce(
    List<Question> questions, {
    required String fromLang,
    required String toLang,
    required GoogleTranslator translator,
  }) async {
    // 1 ─ Build main buffer (question text + options only)
    final List<String> mainBuffer = [];
    for (final q in questions) {
      mainBuffer.add(q.text);
      mainBuffer.addAll(q.options.map((o) => o.text));
    }

    // 2 ─ Translate main buffer in one batch (throws on failure)
    final mainResults = await Future.wait(
      mainBuffer
          .map((txt) => translator.translate(txt, from: fromLang, to: toLang)),
    );

    // 3 ─ Reassemble question text + options
    var idx = 0;
    final partialTranslated = <Question>[];
    for (final q in questions) {
      final translatedText = mainResults[idx++].text;
      final translatedOptions = q.options.map((o) {
        return o.copyWith(text: mainResults[idx++].text);
      }).toList();
      partialTranslated
          .add(q.copyWith(text: translatedText, options: translatedOptions));
    }

    // 4 ─ Translate explanations separately — each one with its own error handling
    //     so a bad explanation cannot break the whole translation batch.
    final List<String?> expTexts = questions.map((q) {
      final t = _stripHtml(q.answerExplanation);
      return _isTranslatableText(t) ? t : null;
    }).toList();

    final expFutures = expTexts.map((t) {
      if (t == null) return Future<String?>.value(null);
      return _safeTranslate(t, fromLang, toLang, translator)
          .then<String?>((v) => v);
    }).toList();

    final expResults = await Future.wait(expFutures);

    // 5 ─ Final assembly
    final translated = <Question>[];
    for (var i = 0; i < partialTranslated.length; i++) {
      final translatedExp = expResults[i];
      translated.add(translatedExp != null
          ? partialTranslated[i].copyWith(answerExplanation: translatedExp)
          : partialTranslated[i]);
    }
    return translated;
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
      showAppSnackBar('Translation failed. Please try again.');
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _onLanguageSelected(String value) async {
    ttsService.flutterTts.stop();
    ttsService.ttsState = TtsState.stopped;

    final targetLang = value.toLowerCase();
    if (targetLang == currentLanguageCode.toLowerCase()) return;

    if (targetLang == 'sv') {
      if (mounted) {
        setState(() {
          currentLanguageCode = value;
          isEnglish = false;
        });
      }
      return;
    }

    await _translateQuestion(currentQuestionIndex, targetLang);
    if (mounted) {
      setState(() {
        currentLanguageCode = value;
      });
    }
  }

  void disableScreenshot() async {
    await _noScreenshot?.screenshotOff();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isSmallScreen = mq.size.width < 390;
    // Scale factor: 1.0 on standard screens (≥ 812 pt tall), shrinks on shorter ones
    final s = (mq.size.height / 812.0).clamp(0.72, 1.0);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (widget.isReviewMode) {
          Navigator.of(context).pop();
          return;
        }
        _showExitDialog();
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () {
              if (widget.isReviewMode) {
                Navigator.of(context).pop();
              } else {
                _showExitDialog();
              }
            },
          ),
          title: QuestionProgressHeader(
            currentIndex: currentQuestionIndex,
            total: widget.questions.length,
            onTap: _showQuestionNavigationSheet,
          ),
          centerTitle: true,
          actions: [
            // Timer display
            if (_isTimed && !widget.isReviewMode)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Center(
                  child: GestureDetector(
                    onTap: () => setState(() => _timerVisible = !_timerVisible),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _remainingSeconds <= 60 && _timerVisible
                            ? Colors.red.withValues(alpha: 0.12)
                            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _remainingSeconds <= 60 && _timerVisible
                              ? Colors.red
                              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _timerVisible ? Icons.timer : Icons.timer_off_outlined,
                            size: 14,
                            color: _remainingSeconds <= 60 && _timerVisible
                                ? Colors.red
                                : Theme.of(context).colorScheme.primary,
                          ),
                          if (_timerVisible) ...[
                            const SizedBox(width: 4),
                            Text(
                              _timerDisplay,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _remainingSeconds <= 60
                                    ? Colors.red
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (!isSmallScreen)
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: PopupMenuButton<String>(
                  onSelected: _onLanguageSelected,
                  itemBuilder: (BuildContext context) => languageOptions
                      .map((lang) => PopupMenuItem<String>(
                            value: lang['code'],
                            child: Text(lang['label']!),
                          ))
                      .toList(),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                        width: 1,
                      ),
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
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onSurface),
              onSelected: (value) {
                if (value == 'lang_en') {
                  _onLanguageSelected('EN');
                } else if (value == 'lang_sv') {
                  _onLanguageSelected('SV');
                } else if (value == 'feedback') {
                  _showFeedbackDialog();
                } else if (value == 'toggle_timer') {
                  setState(() {
                    _isTimed = !_isTimed;
                    if (_isTimed) {
                      if (_remainingSeconds <= 0) {
                        _remainingSeconds = widget.timeLimitMinutes * 60;
                      }
                      _startTimer();
                    } else {
                      _countdownTimer?.cancel();
                    }
                  });
                } else if (value == 'toggle_instant') {
                  setState(() => _instantMarking = !_instantMarking);
                }
              },
              itemBuilder: (context) => [
                if (isSmallScreen)
                  PopupMenuItem<String>(
                    value: 'lang_en',
                    child: Row(
                      children: [
                        const Text('🇬🇧 English'),
                        const Spacer(),
                        if (currentLanguageCode.toLowerCase() == 'en')
                          const Icon(Icons.check, size: 16),
                      ],
                    ),
                  ),
                if (isSmallScreen)
                  PopupMenuItem<String>(
                    value: 'lang_sv',
                    child: Row(
                      children: [
                        const Text('🇸🇪 Svenska'),
                        const Spacer(),
                        if (currentLanguageCode.toLowerCase() == 'sv')
                          const Icon(Icons.check, size: 16),
                      ],
                    ),
                  ),
                if (isSmallScreen)
                  PopupMenuItem<String>(
                    enabled: false,
                    height: 1,
                    padding: EdgeInsets.zero,
                    child: Divider(color: Theme.of(context).dividerColor, height: 1),
                  ),
                if (!widget.isReviewMode)
                  PopupMenuItem<String>(
                    value: 'toggle_timer',
                    child: Row(
                      children: [
                        Icon(_isTimed ? Icons.timer_off_outlined : Icons.timer_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(_isTimed ? 'Turn off timer' : 'Turn on timer'),
                        const Spacer(),
                        if (_isTimed) const Icon(Icons.check, size: 16),
                      ],
                    ),
                  ),
                if (!widget.isReviewMode)
                  PopupMenuItem<String>(
                    value: 'toggle_instant',
                    child: Row(
                      children: [
                        Icon(_instantMarking ? Icons.rule_outlined : Icons.rule_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(_instantMarking ? 'Turn off instant marking' : 'Turn on instant marking'),
                        const Spacer(),
                        if (_instantMarking) const Icon(Icons.check, size: 16),
                      ],
                    ),
                  ),
                if (!widget.isReviewMode)
                  PopupMenuItem<String>(
                    enabled: false,
                    height: 1,
                    padding: EdgeInsets.zero,
                    child: Divider(color: Theme.of(context).dividerColor, height: 1),
                  ),
                const PopupMenuItem<String>(
                  value: 'feedback',
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, size: 18),
                      SizedBox(width: 8),
                      Text('Feedback'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: PageView.builder(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          itemCount: widget.questions.length,
          itemBuilder: (context, index) {
            final translatedList = translatedQuestionsWithOptions[
                currentLanguageCode.toLowerCase()];
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
              padding: EdgeInsets.all(20.0 * s),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question text
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 22 * s,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.3,
                        ),
                        children: [
                          TextSpan(text: questionText),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: TtsButton(
                              textToSpeak: questionText,
                              languageCode: currentLanguageCode,
                              iconSize: 22 * s,
                              tooltip: 'Read aloud',
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 14 * s),

                    // Question image (if available)
                    if (question.imageUrl.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(bottom: 20 * s),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.1),
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
                                maxHeight: mq.size.height * 0.32,
                                maxWidth: mq.size.width * 0.9,
                              ),
                              child: Image.network(questionUrl,
                                  fit: BoxFit.contain),
                            ),
                          ),
                        ),
                      ),

                    SizedBox(height: 12 * s),

                    // Options
                    ...question.options.asMap().entries.map((entry) {
                      int optIndex = entry.key;
                      var option = entry.value;
                      String optionText = optionTexts[optIndex];
                      bool isSelected =
                          userSelections[index] == option.optionLabel;

                      return Option(
                        text: optionText,
                        optionLabel: option.optionLabel,
                        imageUrl: option.imageUrl,
                        isSelected: isSelected,
                        showInstantMarking: _instantMarking &&
                            userSelections[index] != null,
                        isCorrectAnswer:
                            option.optionLabel == question.correctAnswer,
                        onTap: () => _selectOption(option.optionLabel, index),
                        languageCode: currentLanguageCode,
                        scale: s,
                      );
                    }),

                    SizedBox(height: 12 * s),

                    // Bookmark button
                    if (!widget.isReviewMode &&
                        widget.questions[index].questionId.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () async {
                            final qId = widget.questions[index].questionId;
                            final isSaved =
                                await SavedQuestionsService.toggleSavedScoped(
                              qId,
                              questionText: widget.questions[index].text,
                              licenceId: widget.licenceId,
                              categoryId: widget.categoryId,
                              bcdCategoryId: widget.bcdCategoryId,
                            );
                            final ids =
                                await SavedQuestionsService.getSavedIdsScoped(
                              licenceId: widget.licenceId,
                              categoryId: widget.categoryId,
                              bcdCategoryId: widget.bcdCategoryId,
                            );
                            if (mounted) {
                              setState(() => _savedQuestionIds = ids);
                              showAppSnackBar(isSaved
                                  ? 'Question saved'
                                  : 'Question removed from saved');
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _savedQuestionIds.contains(
                                          widget.questions[index].questionId)
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  color: _savedQuestionIds.contains(
                                          widget.questions[index].questionId)
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey[600],
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _savedQuestionIds.contains(
                                          widget.questions[index].questionId)
                                      ? 'Saved'
                                      : 'Save question',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _savedQuestionIds.contains(
                                            widget.questions[index].questionId)
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    SizedBox(height: 8 * s),

                    // Explanation (scrollable)
                    if (_instantMarking &&
                        userSelections[index] != null &&
                        question.answerExplanation.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(bottom: 16 * s),
                        padding: EdgeInsets.all(16 * s),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 1),
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
        bottomNavigationBar: NavigationControls(
          atFirst: currentQuestionIndex == 0,
          atLast: currentQuestionIndex == widget.questions.length - 1,
          onBack: _previousQuestion,
          // Decide at runtime whether we go to the next page or open the dialogs.
          onNextOrFinish: () {
            if (currentQuestionIndex < widget.questions.length - 1) {
              _nextQuestion();
              return;
            }

            // Last question → show the confirmation dialog
            showFinishConfirmationDialog(
              context: context,
              unansweredCount: widget.questions.length - userSelections.length,
              onCancel: () {}, // nothing extra on “No”
              onConfirm: () {
                _saveTestAttempt(); // store Hive record
                final passed = _calculateResult();

                // After saving, show the pass/fail dialog
                showResultDialog(
                  context: context,
                  hasPassed: passed,
                  questions: widget.questions,
                  userSelections: userSelections,
                  licenceId: widget.licenceId,
                  categoryId: widget.categoryId,
                );
              },
            );
          },
        ),
      ), // Scaffold
    ); // PopScope
  } // build

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
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.only(
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
                  color: Theme.of(context).dividerColor,
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
                                      .colorScheme.primary
                                      .withValues(alpha: 0.1)
                                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
                              border: Border.all(
                                color: isCurrent
                                    ? Theme.of(context).colorScheme.primary
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
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
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
                                              ? Theme.of(context).colorScheme.primary
                                              : Theme.of(context).colorScheme.onSurface,
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
