import 'dart:async';
import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/services/navigation_feedback.dart';
import 'package:hive/hive.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/constants/language_options.dart';
import 'package:taxi_exam_app/core/models/image_viewer.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';
import 'package:taxi_exam_app/core/services/saved_questions_service.dart';
import 'package:taxi_exam_app/core/services/tts_service.dart';
import 'package:taxi_exam_app/core/widgets/explanation_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:taxi_exam_app/core/widgets/navigation_controls.dart';
import 'package:taxi_exam_app/core/widgets/option_tile.dart';
import 'package:taxi_exam_app/core/widgets/question_progress_header.dart';
import 'package:taxi_exam_app/core/widgets/test_dialogs.dart';
import 'package:taxi_exam_app/core/widgets/tts_button.dart';

import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'package:taxi_exam_app/core/services/home_data_cache.dart';
import 'package:translator/translator.dart';

const _kTranslationTutorialKey = 'translation_tutorial_shown_v1';

/// Thin alias kept for call-site compatibility after adding the tutorial.
typedef TestscreenWrapper = Testscreen;

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

  // GlobalKeys for the translation tutorial.
  final _langMenuKey = GlobalKey<PopupMenuButtonState<String>>();
  final _langButtonKey = GlobalKey();
  final _peekAreaKey = GlobalKey();

  // True while phase-1 of the tutorial is active (waiting for language pick).
  bool _tutorialPhase1Active = false;

  // Overlay shown while dropdown is open, prompting language selection (phase 1b).
  OverlayEntry? _langPickOverlay;

  // Overlay shown during phase-2 (gesture-transparent instruction card).
  OverlayEntry? _phase2Overlay;

  final ttsService = TtsService();
  late PageController _pageController;

  // Translation variables
  final translator = GoogleTranslator();
  bool isEnglish = true;
  Map<int, String> translatedQuestions = {};
  Map<int, List<String>> translatedOptions = {};
  Map<String, List<Question>> translatedQuestionsWithOptions = {};
  String currentLanguageCode = 'SV';
  String? _previousLanguageCode;

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

    if (!widget.isReviewMode) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _checkAndShowTutorial());
    }
  }

  Future<void> _checkAndShowTutorial() async {
    if (!kDebugMode) {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kTranslationTutorialKey) == true) return;
      await prefs.setBool(_kTranslationTutorialKey, true);
    }
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    _showTutorialPhase1();
  }

  TutorialCoachMark? _phase1Coach;
  // Fine-grained tutorial state for phases 2 and 3.
  bool _tutorialPhase2Active = false; // "press & hold" card visible
  bool _tutorialPhase2bActive =
      false; // user is holding — "now release" card visible
  bool _tutorialPhase3aActive = false; // "swipe left" card visible
  bool _tutorialPhase3bActive = false; // "now swipe right" card visible

  void _showTutorialPhase1() {
    setState(() => _tutorialPhase1Active = true);
    final t = Translations.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    _phase1Coach = TutorialCoachMark(
      targets: [
        TargetFocus(
          identify: 'lang_button',
          keyTarget: _langButtonKey,
          shape: ShapeLightFocus.RRect,
          radius: 20,
          enableTargetTab: true,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (_, __) => _TutorialCard(
                icon: LucideIcons.languages,
                title: t.tut_step1_title,
                body: t.tut_step1_body,
                primaryColor: primary,
              ),
            ),
          ],
        ),
      ],
      colorShadow: Colors.black87,
      paddingFocus: 8,
      opacityShadow: 0.85,
      hideSkip: false,
      textSkip: t.intro_skip,
      // Dismiss overlay on tap so dropdown can open immediately after.
      onClickTarget: (_) {
        _phase1Coach?.finish();
        Future.delayed(const Duration(milliseconds: 150), () {
          _langMenuKey.currentState?.showButtonMenu();
          _showLangPickHint();
        });
      },
      onSkip: () {
        _dismissLangPickHint();
        setState(() => _tutorialPhase1Active = false);
        return true;
      },
    );

    _phase1Coach!.show(context: context);
  }

  // Phase 1b — hint card shown while the dropdown is open.
  void _showLangPickHint() {
    if (!mounted) return;
    _dismissLangPickHint();
    final t = Translations.of(context);
    final theme = Theme.of(context);
    _langPickOverlay = OverlayEntry(
      builder: (_) => Positioned(
        left: 16,
        right: 16,
        bottom: 120,
        child: Material(
          color: Colors.transparent,
          child: IgnorePointer(
            child: _TutorialCard(
              icon: Icons.translate,
              title: t.tut_step1b_title,
              body: t.tut_step1b_body,
              primaryColor: theme.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_langPickOverlay!);
  }

  void _dismissLangPickHint() {
    _langPickOverlay?.remove();
    _langPickOverlay = null;
  }

  // ── Tutorial overlay helpers ──────────────────────────────────────────────

  void _dismissPhase2Overlay() {
    _phase2Overlay?.remove();
    _phase2Overlay = null;
  }

  void _replaceOverlay(OverlayEntry entry) {
    _dismissPhase2Overlay();
    _phase2Overlay = entry;
    Overlay.of(context).insert(entry);
  }

  // Phase 2a — "Press & hold to peek original".
  void _showTutorialPhase2() {
    if (!mounted) return;
    setState(() {
      _tutorialPhase2Active = true;
      _tutorialPhase2bActive = false;
    });
    final t = Translations.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    _replaceOverlay(OverlayEntry(
      builder: (_) => Positioned(
        left: 16,
        right: 16,
        bottom: 120,
        child: Material(
          color: Colors.transparent,
          child: IgnorePointer(
            child: _TutorialCard(
              icon: Icons.touch_app_outlined,
              title: t.tut_step2a_title,
              body: t.tut_step2a_body,
              primaryColor: primary,
            ),
          ),
        ),
      ),
    ));
  }

  // Phase 2b — shown while user is holding: "Now release to go back".
  void _showReleaseHint() {
    if (!mounted) return;
    setState(() {
      _tutorialPhase2bActive = true;
    });
    final t = Translations.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    _replaceOverlay(OverlayEntry(
      builder: (_) => Positioned(
        left: 16,
        right: 16,
        bottom: 120,
        child: Material(
          color: Colors.transparent,
          child: IgnorePointer(
            child: _TutorialCard(
              icon: Icons.pan_tool_outlined,
              title: t.tut_step2b_title,
              body: t.tut_step2b_body,
              primaryColor: primary,
            ),
          ),
        ),
      ),
    ));
  }

  // Phase 3a — "Swipe left to go to the next question".
  void _showTutorialPhase3a() {
    if (!mounted) return;
    setState(() {
      _tutorialPhase3aActive = true;
      _tutorialPhase2Active = false;
      _tutorialPhase2bActive = false;
    });
    final t = Translations.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    _replaceOverlay(OverlayEntry(
      builder: (_) => Positioned(
        left: 16,
        right: 16,
        bottom: 120,
        child: Material(
          color: Colors.transparent,
          child: IgnorePointer(
            child: _TutorialCard(
              icon: Icons.swipe_left_outlined,
              title: t.tut_step3a_title,
              body: t.tut_step3a_body,
              primaryColor: primary,
            ),
          ),
        ),
      ),
    ));
  }

  // Phase 3b — "Now swipe right to come back".
  void _showTutorialPhase3b() {
    if (!mounted) return;
    setState(() {
      _tutorialPhase3aActive = false;
      _tutorialPhase3bActive = true;
    });
    final t = Translations.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    _replaceOverlay(OverlayEntry(
      builder: (_) => Positioned(
        left: 16,
        right: 16,
        bottom: 120,
        child: Material(
          color: Colors.transparent,
          child: IgnorePointer(
            child: _TutorialCard(
              icon: Icons.swipe_right_outlined,
              title: t.tut_step3b_title,
              body: t.tut_step3b_body,
              primaryColor: primary,
            ),
          ),
        ),
      ),
    ));
  }

  void _dismissTutorial({bool celebrate = false}) {
    _dismissPhase2Overlay();
    setState(() {
      _tutorialPhase1Active = false;
      _tutorialPhase2Active = false;
      _tutorialPhase2bActive = false;
      _tutorialPhase3aActive = false;
      _tutorialPhase3bActive = false;
    });
    if (celebrate && mounted) _showTutorialComplete();
  }

  void _showTutorialComplete() {
    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (_) => Material(
        color: Colors.transparent,
        child: _TutorialCompleteOverlay(
          onDone: () => entry?.remove(),
        ),
      ),
    );
    Overlay.of(context).insert(entry);
    vibratePass();
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
    final passed = _calculateResult();
    if (passed) {
      vibratePass();
    } else {
      vibrateFail();
    }
    showResultDialog(
      context: context,
      hasPassed: passed,
      score: _computeScorePercent(),
      passScorePercent: widget.passScorePercent,
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

  Widget _buildImageTile(BuildContext context, double s, String url) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GestureDetector(
          onTap: () => showImageViewer(context, url),
          child: Image.network(url, fit: BoxFit.cover),
        ),
      ),
    );
  }

  List<Widget> _buildQuestionImages(
    BuildContext context,
    double s,
    MediaQueryData mq,
    List<String> urls,
  ) {
    if (urls.isEmpty) return [];

    if (urls.length > 2) {
      return [
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 8 * s,
          mainAxisSpacing: 8 * s,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children:
              urls.map((url) => _buildImageTile(context, s, url)).toList(),
        ),
        SizedBox(height: 12 * s),
      ];
    }

    return [
      ...urls.map(
        (url) => Container(
          margin: EdgeInsets.only(bottom: 12 * s),
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
              onTap: () => showImageViewer(context, url),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: mq.size.height * 0.32,
                  maxWidth: mq.size.width * 0.9,
                ),
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      ),
      SizedBox(height: 8 * s),
    ];
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pageController.dispose();
    ttsService.flutterTts.stop();
    ttsService.ttsState = TtsState.stopped;
    _dismissLangPickHint();
    _dismissPhase2Overlay();
    super.dispose();
  }

  void _onPageChanged(int index) {
    final prevIndex = currentQuestionIndex;
    setState(() {
      currentQuestionIndex = index;
    });
    ttsService.flutterTts.stop();
    ttsService.ttsState = TtsState.stopped;
    if (_tutorialPhase3aActive && index > prevIndex) {
      // Swiped left — show "now swipe right" card.
      Future.delayed(const Duration(milliseconds: 300), _showTutorialPhase3b);
    } else if (_tutorialPhase3bActive && index < prevIndex) {
      // Swiped right — tutorial complete, celebrate.
      _dismissTutorial(celebrate: true);
    }
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
    if (_instantMarking && optionId != widget.questions[index].correctAnswer) {
      vibrateWrongAnswer();
    } else {
      playNavigationFeedback();
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
          final passed = _calculateResult();
          if (passed) {
            vibratePass();
          } else {
            vibrateFail();
          }
          showResultDialog(
            context: context,
            hasPassed: passed,
            score: _computeScorePercent(),
            passScorePercent: widget.passScorePercent,
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
    return _computeScorePercent() >= widget.passScorePercent;
  }

  double _computeScorePercent() {
    if (widget.questions.isEmpty) return 0;
    int correctAnswers = 0;
    for (int i = 0; i < widget.questions.length; i++) {
      final sel = userSelections[i];
      if (sel != null && sel == widget.questions[i].correctAnswer) {
        correctAnswers++;
      }
    }
    return (correctAnswers / widget.questions.length) * 100;
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
    HomeDataCache.invalidate(); // force home to re-sync on next visit
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
    _dismissLangPickHint();
    ttsService.flutterTts.stop();
    ttsService.ttsState = TtsState.stopped;

    final targetLang = value.toLowerCase();
    if (targetLang == currentLanguageCode.toLowerCase()) return;
    HapticFeedback.selectionClick();

    final previousCode = currentLanguageCode;

    if (targetLang == 'sv') {
      if (mounted) {
        setState(() {
          _previousLanguageCode = previousCode;
          currentLanguageCode = value;
          isEnglish = false;
        });
      }
      return;
    }

    await _translateQuestion(currentQuestionIndex, targetLang);
    if (mounted) {
      setState(() {
        _previousLanguageCode = previousCode;
        currentLanguageCode = value;
      });
      // Phase 1 of the tutorial just completed — user picked a language.
      // Show phase 2 after a short delay so the translation appears first.
      if (_tutorialPhase1Active) {
        setState(() => _tutorialPhase1Active = false);
        await Future.delayed(const Duration(milliseconds: 500));
        _showTutorialPhase2();
      }
    }
  }

  Future<void> _revertToPreviousLanguage() async {
    if (_previousLanguageCode == null) return;
    await _onLanguageSelected(_previousLanguageCode!);
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
            icon: Icon(Icons.arrow_back,
                color: Theme.of(context).colorScheme.onSurface),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _remainingSeconds <= 60 && _timerVisible
                            ? Colors.red.withValues(alpha: 0.12)
                            : Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _remainingSeconds <= 60 && _timerVisible
                              ? Colors.red
                              : Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _timerVisible
                                ? Icons.timer
                                : Icons.timer_off_outlined,
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
                key: _langButtonKey,
                margin: const EdgeInsets.only(right: 8),
                child: PopupMenuButton<String>(
                  key: _langMenuKey,
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
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.4),
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
              icon: Icon(Icons.more_vert,
                  color: Theme.of(context).colorScheme.onSurface),
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
                    child: Divider(
                        color: Theme.of(context).dividerColor, height: 1),
                  ),
                if (!widget.isReviewMode)
                  PopupMenuItem<String>(
                    value: 'toggle_timer',
                    child: Row(
                      children: [
                        Icon(
                            _isTimed
                                ? Icons.timer_off_outlined
                                : Icons.timer_outlined,
                            size: 18),
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
                        Icon(
                            _instantMarking
                                ? Icons.rule_outlined
                                : Icons.rule_outlined,
                            size: 18),
                        const SizedBox(width: 8),
                        Text(_instantMarking
                            ? 'Turn off instant marking'
                            : 'Turn on instant marking'),
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
                    child: Divider(
                        color: Theme.of(context).dividerColor, height: 1),
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

            return GestureDetector(
              onLongPress: () {
                _revertToPreviousLanguage();
                // Tutorial: user started holding — update card to "now release".
                if (_tutorialPhase2Active && !_tutorialPhase2bActive) {
                  _showReleaseHint();
                }
              },
              onLongPressUp: () {
                _revertToPreviousLanguage();
                // Tutorial: user released — advance to "swipe left" step.
                if (_tutorialPhase2bActive) {
                  Future.delayed(
                    const Duration(milliseconds: 600),
                    _showTutorialPhase3a,
                  );
                }
              },
              child: Padding(
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

                      // Question images — use multi-image list if available,
                      // fall back to legacy imageUrl for backward compatibility.
                      ..._buildQuestionImages(
                        context,
                        s,
                        mq,
                        question.images.isNotEmpty
                            ? question.images
                            : (question.imageUrl.isNotEmpty
                                ? [questionUrl]
                                : []),
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
                          showInstantMarking:
                              _instantMarking && userSelections[index] != null,
                          isCorrectAnswer:
                              option.optionLabel == question.correctAnswer,
                          onTap: () => _selectOption(option.optionLabel, index),
                          languageCode: currentLanguageCode,
                          scale: s,
                        );
                      }),

                      // Peek-area anchor — only on the first question so the
                      // tutorial key is stable and in the widget tree.
                      if (index == 0)
                        SizedBox(key: _peekAreaKey, height: 12 * s)
                      else
                        SizedBox(height: 12 * s),

                      // Bookmark button
                      if (!widget.isReviewMode &&
                          widget.questions[index].questionId.isNotEmpty)
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () async {
                              HapticFeedback.lightImpact();
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
                                      color: _savedQuestionIds.contains(widget
                                              .questions[index].questionId)
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
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
                            border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.3),
                                width: 1),
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
              ),
            );
          },
        ), // PageView
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
                if (passed) {
                  vibratePass();
                } else {
                  vibrateFail();
                }
                showResultDialog(
                  context: context,
                  hasPassed: passed,
                  score: _computeScorePercent(),
                  passScorePercent: widget.passScorePercent,
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
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.1)
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.04),
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
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.2),
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
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
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

class _TutorialCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color? primaryColor;

  const _TutorialCard({
    required this.icon,
    required this.title,
    required this.body,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = primaryColor ?? cs.primary;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = (screenWidth - 32).clamp(0.0, 420.0);

    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        body,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.88),
                          height: 1.4,
                          decoration: TextDecoration.none,
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
  }
}

// ── Tutorial completion overlay ───────────────────────────────────────────────

class _TutorialCompleteOverlay extends StatefulWidget {
  final VoidCallback onDone;
  const _TutorialCompleteOverlay({required this.onDone});

  @override
  State<_TutorialCompleteOverlay> createState() =>
      _TutorialCompleteOverlayState();
}

class _TutorialCompleteOverlayState extends State<_TutorialCompleteOverlay>
    with SingleTickerProviderStateMixin {
  // Single controller: sheet slides up first (0→0.3), then content staggers (0.3→1.0).
  late final AnimationController _ctrl;

  late final Animation<Offset> _sheetSlide;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconFade;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _bodyFade;
  late final Animation<Offset> _bodySlide;
  late final Animation<double> _subtitleFade;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _buttonFade;
  late final Animation<Offset> _buttonSlide;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    Animation<double> curved(double begin, double end, Curve curve) =>
        CurvedAnimation(
            parent: _ctrl, curve: Interval(begin, end, curve: curve));

    const upStart = Offset(0, 0.18);

    _sheetSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0, 0.28, curve: Curves.easeOutCubic)));

    _iconFade = curved(0.22, 0.40, Curves.easeOut);
    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.22, 0.45, curve: Curves.elasticOut)));

    _titleFade = curved(0.40, 0.55, Curves.easeOut);
    _titleSlide = Tween<Offset>(begin: upStart, end: Offset.zero).animate(
        CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.40, 0.55, curve: Curves.easeOutCubic)));

    _bodyFade = curved(0.52, 0.67, Curves.easeOut);
    _bodySlide = Tween<Offset>(begin: upStart, end: Offset.zero).animate(
        CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.52, 0.67, curve: Curves.easeOutCubic)));

    _subtitleFade = curved(0.63, 0.78, Curves.easeOut);
    _subtitleSlide = Tween<Offset>(begin: upStart, end: Offset.zero).animate(
        CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.63, 0.78, curve: Curves.easeOutCubic)));

    _buttonFade = curved(0.78, 1.0, Curves.easeOut);
    _buttonSlide = Tween<Offset>(begin: upStart, end: Offset.zero).animate(
        CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.78, 1.0, curve: Curves.easeOutCubic)));

    _ctrl.forward();
  }

  void _dismiss() {
    _ctrl.reverse().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _staggered({
    required Animation<double> fade,
    required Animation<Offset> slide,
    required Widget child,
  }) {
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Translations.of(context);
    final hPad = (MediaQuery.of(context).size.width * 0.07).clamp(20.0, 52.0);

    return SlideTransition(
      position: _sheetSlide,
      child: Container(
        color: cs.surface,
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon
                  FadeTransition(
                    opacity: _iconFade,
                    child: ScaleTransition(
                      scale: _iconScale,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.primary.withValues(alpha: 0.1),
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 80,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title
                  _staggered(
                    fade: _titleFade,
                    slide: _titleSlide,
                    child: Text(
                      t.tut_complete_title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Body
                  _staggered(
                    fade: _bodyFade,
                    slide: _bodySlide,
                    child: Text(
                      t.tut_complete_body,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: cs.onSurface.withValues(alpha: 0.6),
                        height: 1.6,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Subtitle
                  _staggered(
                    fade: _subtitleFade,
                    slide: _subtitleSlide,
                    child: Text(
                      t.tut_complete_subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha: 0.85),
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Button
                  _staggered(
                    fade: _buttonFade,
                    slide: _buttonSlide,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _dismiss,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          t.tut_start_practicing,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
