import 'package:cached_network_image/cached_network_image.dart';
import 'package:taxi_exam_app/core/widgets/app_button.dart';
import 'package:taxi_exam_app/core/widgets/app_loading_indicator.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/services/navigation_feedback.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/storage/app_storage.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';
import 'package:taxi_exam_app/core/services/saved_questions_service.dart';
import 'package:taxi_exam_app/core/services/tts_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:taxi_exam_app/core/widgets/navigation_controls.dart';
import 'package:taxi_exam_app/core/widgets/app_bottom_sheet.dart';
import 'package:taxi_exam_app/core/widgets/question_progress_header.dart';
import 'package:taxi_exam_app/core/widgets/test_dialogs.dart';
import 'package:taxi_exam_app/features/tests/test_attempt_save_service.dart';
import 'package:taxi_exam_app/features/tests/test_progress_guard.dart';
import 'package:taxi_exam_app/features/tests/widgets/question_chat_sheet.dart';
import 'package:taxi_exam_app/features/tests/widgets/language_grid.dart';
import 'package:taxi_exam_app/features/tests/widgets/question_navigation_grid.dart';
import 'package:taxi_exam_app/features/tests/widgets/question_page_item.dart';
import 'package:taxi_exam_app/features/tests/widgets/test_timer_chip.dart';
import 'package:taxi_exam_app/features/tests/widgets/tutorial_card.dart';
import 'package:taxi_exam_app/features/tests/widgets/tutorial_complete_overlay.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

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

  /// Called after the attempt is saved (chunk/smart-learning hook).
  /// Receives whether the attempt passed and a map of questionId → wasCorrect
  /// for every question (based on first and only selection — unanswered = false).
  final void Function(bool hasPassed, Map<String, bool> questionResults)?
      onComplete;

  /// When true, replaces the "Q X of N" progress header with a plain title.
  final bool hideProgress;

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
    this.onComplete,
    this.hideProgress = false,
  });

  @override
  State<Testscreen> createState() => _TestscreenState();
}

class _TestscreenState extends State<Testscreen> {
  int currentQuestionIndex = 0;
  Map<int, String> userSelections = {};
  final ApiService _apiService = ApiService();
  late final TestAttemptSaveService _attemptSaveService =
      TestAttemptSaveService(
    saveLocal: _persistAttemptLocal,
    syncRemote: _apiService.syncTestAttempt,
  );

  // Per-question AI chat sessions (keyed by question index).
  final Map<int, _AiSession> _aiSessions = {};

  bool _aiEnabled = false;

  // GlobalKeys for the translation tutorial.
  final _langMenuKey = GlobalKey<PopupMenuButtonState<String>>();
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
  late final ValueNotifier<int> _timerNotifier;

  // Mutable runtime toggles — initialised from widget params (settings)
  late bool _isTimed;
  late bool _instantMarking;
  bool _timerVisible = true;

  // Context captured inside CupertinoScaffold — needed for depth-effect sheets.
  BuildContext? _sheetContext;

  // Saved questions
  Set<String> _savedQuestionIds = {};

  // Test session identity
  late String _testId;
  late DateTime _startTime;

  // Snapshot of selections at load time — used to detect changes on resume
  late final Map<int, String> _initialSelections;
  late final int _initialQuestionIndex;

  final _noScreenshot = kIsWeb ? null : NoScreenshot.instance;

  @override
  void reassemble() {
    super.reassemble();
    if (kDebugMode && !widget.isReviewMode) {
      _dismissTutorial();
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _checkAndShowTutorial());
    }
  }

  @override
  void initState() {
    super.initState();
    currentQuestionIndex = widget.initialQuestionIndex;
    userSelections = Map<int, String>.from(widget.userSelections ?? {});
    _initialSelections = Map<int, String>.from(userSelections);
    _initialQuestionIndex = currentQuestionIndex;
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
    _timerNotifier = ValueNotifier(_remainingSeconds);

    // Sort options once here so itemBuilder never mutates on every render.
    for (final q in widget.questions) {
      q.options.sort((a, b) => a.optionLabel.compareTo(b.optionLabel));
    }

    _savedQuestionIds =
        Set<String>.from(widget.initiallySavedQuestionIds ?? {});

    _loadSavedQuestionIds();
    _loadAiEnabled();
    // Pre-open the Hive box so saves never hang waiting for it to open
    AppStorage.testAttemptsBox();
    if (!widget.isReviewMode) _applyShuffleIfEnabled();

    if (!widget.isReviewMode) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _checkAndShowTutorial());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadImagesForQuestion(currentQuestionIndex);
      _preloadImagesForQuestion(currentQuestionIndex + 1);
      _preloadImagesForQuestion(currentQuestionIndex + 2);
    });
  }

  Future<void> _applyShuffleIfEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    if ((prefs.getBool('shuffleOnDevice') ?? true) && mounted) {
      widget.questions.shuffle(Random());
      setState(() {});
    }
  }

  Future<void> _checkAndShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    if (!kDebugMode && prefs.getBool(_kTranslationTutorialKey) == true) return;
    if (!kDebugMode) await prefs.setBool(_kTranslationTutorialKey, true);
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    _showTutorialPhase1();
  }

  TutorialCoachMark? _phase1Coach;
  // Fine-grained tutorial state for phase 2.
  bool _tutorialPhase2Active = false; // "press & hold" card visible
  bool _tutorialPhase2bActive =
      false; // user is holding — "now release" card visible

  void _showTutorialPhase1() {
    setState(() => _tutorialPhase1Active = true);
    final t = Translations.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    _phase1Coach = TutorialCoachMark(
      targets: [
        TargetFocus(
          identify: 'lang_button',
          keyTarget: _langMenuKey,
          shape: ShapeLightFocus.RRect,
          radius: 20,
          enableTargetTab: true,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (_, __) => TutorialCard(
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
    final primary = Theme.of(context).colorScheme.primary;
    _langPickOverlay = OverlayEntry(
      builder: (_) => Positioned(
        left: 16,
        right: 16,
        bottom: 120,
        child: Material(
          color: Colors.transparent,
          child: IgnorePointer(
            child: TutorialCard(
              icon: Icons.translate,
              title: t.tut_step1b_title,
              body: t.tut_step1b_body,
              primaryColor: primary,
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
    _replaceOverlay(_buildTutorialOverlay(
      icon: Icons.touch_app_outlined,
      title: t.tut_step2a_title,
      body: t.tut_step2a_body,
      primary: primary,
    ));
  }

  // Phase 2b — shown while user is holding: "Now release to go back".
  void _showReleaseHint() {
    if (!mounted) return;
    setState(() => _tutorialPhase2bActive = true);
    final t = Translations.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    _replaceOverlay(_buildTutorialOverlay(
      icon: Icons.pan_tool_outlined,
      title: t.tut_step2b_title,
      body: t.tut_step2b_body,
      primary: primary,
    ));
  }

  OverlayEntry _buildTutorialOverlay({
    required IconData icon,
    required String title,
    required String body,
    required Color primary,
  }) {
    return OverlayEntry(
      builder: (_) => Positioned(
        left: 16,
        right: 16,
        bottom: 120,
        child: Material(
          color: Colors.transparent,
          child: IgnorePointer(
            child: TutorialCard(
              icon: icon,
              title: title,
              body: body,
              primaryColor: primary,
            ),
          ),
        ),
      ),
    );
  }

  void _dismissTutorial({bool celebrate = false}) {
    _dismissPhase2Overlay();
    setState(() {
      _tutorialPhase1Active = false;
      _tutorialPhase2Active = false;
      _tutorialPhase2bActive = false;
    });
    if (celebrate && mounted) _showTutorialComplete();
  }

  void _showTutorialComplete() {
    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (_) => Material(
        color: Colors.transparent,
        child: TutorialCompleteOverlay(
          onDone: () => entry?.remove(),
        ),
      ),
    );
    Overlay.of(context).insert(entry);
    vibratePass();
  }

  Future<void> _loadAiEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(AppStorage.kUserJson);
    if (stored == null) return;
    try {
      final map = jsonDecode(stored) as Map<String, dynamic>;
      final enabled = map['ai_enabled'] == true;
      if (mounted && enabled != _aiEnabled) {
        setState(() => _aiEnabled = enabled);
      }
    } catch (_) {}
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

  void _preloadImagesForQuestion(int index) {
    if (!mounted) return;
    if (index < 0 || index >= widget.questions.length) return;
    final q = widget.questions[index];

    final urls = <String>[
      if (q.images.isNotEmpty)
        ...q.images
      else if (q.imageUrl.isNotEmpty)
        _apiService.fetchImage(widget.licenceId, widget.categoryId, q.imageUrl),
      for (final tab in q.tabs) ...tab.images,
      for (final opt in q.options)
        if (opt.imageUrl.isNotEmpty) opt.imageUrl,
    ];

    for (final url in urls) {
      if (url.isEmpty) continue;
      precacheImage(CachedNetworkImageProvider(url), context);
    }
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      // Update notifier only — avoids rebuilding the entire Testscreen every second.
      _timerNotifier.value = --_remainingSeconds;
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _onTimerExpired();
      }
    });
  }

  Future<void> _onTimerExpired() async {
    showAppSnackBar(Translations.of(context).test_time_up_submitting);
    final saveResult = await _saveTestAttempt();
    if (!mounted) return;
    if (!saveResult.backendSynced) {
      showAppSnackBar(Translations.of(context).test_save_backend_failed);
    }
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

  void _openAiChat(
    BuildContext context,
    int index, {
    String? displayText,
    String? prompt,
  }) {
    final session = _aiSessions[index];
    CupertinoScaffold.showCupertinoModalBottomSheet<void>(
      context: context,
      builder: (_) => QuestionChatSheet(
        question: widget.questions[index],
        existingMessages: session?.messages ?? [],
        initialDisplayText: displayText,
        initialPrompt: prompt,
        categoryName: widget.categoryName,
        licenceName: widget.licenceName,
        onFirstMessageSent: () {
          // Mark session as started immediately so buttons switch to "Continue chat"
          // while the sheet is still open — no need to wait for it to close.
          if (mounted) {
            setState(() => _aiSessions[index] ??= const _AiSession._pending());
          }
        },
        onSaveSession: (msgs) {
          // Defer setState — onSaveSession is called from dispose() while
          // the widget tree is locked; scheduling for the next frame is safe.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _aiSessions[index] = _AiSession(msgs));
            }
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _timerNotifier.dispose();
    _pageController.dispose();
    _phase1Coach?.finish();
    ttsService.flutterTts.stop();
    ttsService.ttsState = TtsState.stopped;
    _dismissLangPickHint();
    _dismissPhase2Overlay();
    _aiSessions.clear(); // Fresh AI context on next test attempt
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      currentQuestionIndex = index;
    });
    ttsService.flutterTts.stop();
    ttsService.ttsState = TtsState.stopped;
    _preloadImagesForQuestion(index + 1);
    _preloadImagesForQuestion(index + 2);
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
    if (_instantMarking) {
      if (optionId == widget.questions[index].correctAnswer) {
        vibrateCorrectAnswer();
      } else {
        vibrateWrongAnswer();
      }
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
        onConfirm: () async {
          await _saveTestAttempt();
          if (!mounted) return;
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
      showAppSnackBar(Translations.of(context).test_first_question);
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

  Future<TestAttemptSaveResult> _saveTestAttempt() async {
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

    final result = await _attemptSaveService.save(attempt);
    HomeDataCache.invalidate(); // force home to re-sync on next visit

    if (widget.onComplete != null) {
      final qResults = <String, bool>{};
      for (int i = 0; i < widget.questions.length; i++) {
        final sel = userSelections[i];
        qResults[widget.questions[i].questionId] =
            sel != null && sel == widget.questions[i].correctAnswer;
      }
      widget.onComplete!(hasPassed, qResults);
    }

    return result;
  }

  Future<TestAttemptSaveResult> _savePausedTest() async {
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

    final result = await _attemptSaveService.save(attempt);
    HomeDataCache.invalidate();
    return result;
  }

  Future<void> _persistAttemptLocal(TestAttempt attempt) async {
    final box = await AppStorage.testAttemptsBox();
    await box.put(
      attempt.testId,
      attempt,
    ); // put by testId overwrites any paused version
  }

  bool get _hasChanges {
    return hasResumableProgressChanges(
      initialSelections: _initialSelections,
      currentSelections: userSelections,
      initialQuestionIndex: _initialQuestionIndex,
      currentQuestionIndex: currentQuestionIndex,
    );
  }

  Future<void> _showExitDialog() async {
    final t = Translations.of(context);
    // Resumed test with no answer changes — nothing new to save, just exit
    if (widget.resumeTestId != null && !_hasChanges) {
      Navigator.of(context).pop();
      return;
    }
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        title: Text(t.test_exit_title),
        content: Text(t.test_exit_save_prompt),
        actions: [
          AppFilledButton(
            label: t.btn_save_and_exit,
            onPressed: () => Navigator.pop(ctx, 'save'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AppTextButton(
                  label: t.btn_keep_going,
                  onPressed: () => Navigator.pop(ctx, 'cancel'),
                ),
              ),
              Expanded(
                child: AppTextButton(
                  label: t.btn_exit,
                  foregroundColor: Theme.of(ctx).colorScheme.error,
                  onPressed: () => Navigator.pop(ctx, 'exit'),
                ),
              ),
            ],
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
        builder: (_) => const Center(child: AppLoadingIndicator()),
      );
      try {
        final saveResult =
            await _savePausedTest().timeout(const Duration(seconds: 5));
        if (!mounted) return;
        Navigator.of(context).pop(); // close loading
        if (saveResult.fullySynced) {
          Navigator.of(context).pop(); // close test screen
        } else {
          showAppSnackBar(t.test_save_backend_failed);
        }
      } catch (e) {
        debugPrint('Save failed: $e');
        if (mounted) {
          Navigator.of(context).pop(); // close loading
          showAppSnackBar(t.test_save_backend_failed);
        }
      }
    } else if (result == 'exit') {
      Navigator.of(context).pop();
    }
  }

  Future<void> _showLanguageSheet() async {
    final t = Translations.of(context);
    final langNotifier = ValueNotifier<String>(currentLanguageCode);
    final wasInTutorial = _tutorialPhase1Active;

    // Dismiss the popup-open hint before the sheet slides in.
    _dismissLangPickHint();

    await CupertinoScaffold.showCupertinoModalBottomSheet<void>(
      context: _sheetContext ?? context,
      builder: (ctx) => AppBottomSheetContainer(
        title: t.test_question_language_title,
        subtitle: t.test_question_language_subtitle,
        heightFactor: 0.8,
        hint: wasInTutorial ? _buildSheetTutorialHint(t) : null,
        child: LanguageGrid(
          selectedLanguage: langNotifier,
          onSelected: (code) async {
            await _onLanguageSelected(code);
            langNotifier.value = code;
          },
        ),
      ),
    );

    // Sheet was dismissed — if tutorial was active and a non-SV language
    // was selected, advance to the press-and-hold phase.
    if (wasInTutorial && mounted && currentLanguageCode.toLowerCase() != 'sv') {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) _showTutorialPhase2();
    }
  }

  Widget _buildSheetTutorialHint(Translations t) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.translate_rounded, size: 18, color: primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              t.tut_step1_grid_hint,
              style: TextStyle(
                fontSize: 13,
                color: primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFeedbackDialog() async {
    final t = Translations.of(context);
    final q = widget.questions[currentQuestionIndex];
    if (q.questionId.isEmpty) {
      showAppSnackBar(t.test_feedback_unavailable);
      return;
    }
    final controller = TextEditingController();
    String feedbackType = 'question_issue';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(t.test_feedback_title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: feedbackType,
                decoration: InputDecoration(labelText: t.test_feedback_type),
                items: [
                  DropdownMenuItem(
                      value: 'question_issue',
                      child: Text(t.test_feedback_question_issue)),
                  DropdownMenuItem(
                      value: 'wrong_answer',
                      child: Text(t.test_feedback_wrong_answer)),
                  DropdownMenuItem(
                      value: 'typo', child: Text(t.test_feedback_typo)),
                  DropdownMenuItem(
                      value: 'image_issue',
                      child: Text(t.test_feedback_image_issue)),
                  DropdownMenuItem(
                    value: 'other',
                    child: Text(t.test_feedback_other),
                  ),
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
                decoration: InputDecoration(
                  hintText: t.test_feedback_hint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            AppTextButton(
              label: t.cancel,
              onPressed: () => Navigator.pop(ctx),
            ),
            AppFilledButton(
              label: t.btn_submit,
              onPressed: () => Navigator.pop(ctx, {
                'text': controller.text.trim(),
                'type': feedbackType,
              }),
            ),
          ],
        ),
      ),
    );
    controller.dispose();

    final text = (result?['text'] ?? '').trim();
    final type = (result?['type'] ?? 'question_issue').trim();
    if (!mounted || text.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: AppLoadingIndicator()),
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
    showAppSnackBar(ok ? t.test_feedback_submitted : t.test_feedback_failed);
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
      if (mounted) {
        showAppSnackBar(Translations.of(context).test_translation_failed);
      }
    }
  }

  Future<void> _onLanguageSelected(String value) async {
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
      if (_tutorialPhase1Active) {
        setState(() => _tutorialPhase1Active = false);
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
      child: CupertinoScaffold(
        body: Builder(builder: (innerCtx) {
          _sheetContext = innerCtx;
          return Scaffold(
            appBar: AppBar(
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.close,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () {
                  if (widget.isReviewMode) {
                    Navigator.of(context).pop();
                  } else {
                    _showExitDialog();
                  }
                },
              ),
              title: widget.hideProgress
                  ? Text(widget.categoryName.isNotEmpty
                      ? widget.categoryName
                      : Translations.of(context).test_questions_title)
                  : QuestionProgressHeader(
                      currentIndex: currentQuestionIndex,
                      total: widget.questions.length,
                      onTap: _showQuestionNavigationSheet,
                    ),
              centerTitle: false,
              titleSpacing: 0,
              actions: [
                // Timer display — ValueListenableBuilder isolates rebuilds to this
                // widget only; the rest of the screen is unaffected by each tick.
                if (_isTimed && !widget.isReviewMode)
                  TestTimerChip(
                    timerNotifier: _timerNotifier,
                    visible: _timerVisible,
                    onToggle: () =>
                        setState(() => _timerVisible = !_timerVisible),
                  ),
                PopupMenuButton<String>(
                  key: _langMenuKey,
                  icon: Icon(Icons.more_vert,
                      color: Theme.of(context).colorScheme.onSurface),
                  onSelected: (value) {
                    if (value == 'language') {
                      _showLanguageSheet();
                    } else if (value == 'feedback') {
                      _showFeedbackDialog();
                    } else if (value == 'toggle_timer') {
                      setState(() {
                        _isTimed = !_isTimed;
                        if (_isTimed) {
                          if (_remainingSeconds <= 0) {
                            _remainingSeconds = widget.timeLimitMinutes * 60;
                            _timerNotifier.value = _remainingSeconds;
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
                    PopupMenuItem<String>(
                      value: 'language',
                      child: Row(
                        children: [
                          Text(
                            ttsService.getLanguageFlag(currentLanguageCode),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(t.test_question_language_menu),
                          const Spacer(),
                          Icon(Icons.chevron_right,
                              size: 16, color: Colors.grey[500]),
                        ],
                      ),
                    ),
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
                            Text(_isTimed
                                ? t.test_turn_off_timer
                                : t.test_turn_on_timer),
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
                                ? t.test_turn_off_instant_marking
                                : t.test_turn_on_instant_marking),
                            const Spacer(),
                            if (_instantMarking)
                              const Icon(Icons.check, size: 16),
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
                    PopupMenuItem<String>(
                      value: 'feedback',
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 18),
                          const SizedBox(width: 8),
                          Text(t.test_feedback_title),
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
                final questionUrl = _apiService.fetchImage(
                  widget.licenceId,
                  widget.categoryId,
                  widget.questions[index].imageUrl,
                );
                final uiLang = LocaleSettings.currentLocale == AppLocale.sv
                    ? 'Swedish'
                    : 'English';
                return QuestionPageItem(
                  index: index,
                  question: question,
                  legacyImageUrl: questionUrl,
                  userSelections: userSelections,
                  isReviewMode: widget.isReviewMode,
                  instantMarking: _instantMarking,
                  savedQuestionIds: _savedQuestionIds,
                  aiEnabled: _aiEnabled,
                  hasAiSession: _aiSessions.containsKey(index),
                  currentLanguageCode: currentLanguageCode,
                  scale: s,
                  peekAreaKey: index == 0 ? _peekAreaKey : null,
                  onOptionTap: (optionLabel) =>
                      _selectOption(optionLabel, index),
                  onLongPress: () {
                    _revertToPreviousLanguage();
                    if (_tutorialPhase2Active && !_tutorialPhase2bActive) {
                      _showReleaseHint();
                    }
                  },
                  onLongPressUp: () {
                    _revertToPreviousLanguage();
                    if (_tutorialPhase2bActive) {
                      Future.delayed(
                        const Duration(milliseconds: 600),
                        () => _dismissTutorial(celebrate: true),
                      );
                    }
                  },
                  onAiContinue: () => _openAiChat(context, index),
                  onAiHint: () => _openAiChat(
                    context,
                    index,
                    displayText: t.ai_hint_button,
                    prompt:
                        'Give me a short hint that helps me figure out the answer without telling me directly. You MUST reply in $uiLang only.',
                  ),
                  onAiUnderstand: () => _openAiChat(
                    context,
                    index,
                    displayText: t.ai_understand_button,
                    prompt:
                        'Help me understand this question. Explain the concept it is testing and why the correct answer is right. You MUST reply in $uiLang only.',
                  ),
                  onToggleSave: (qId, questionText) async {
                    final isSaved =
                        await SavedQuestionsService.toggleSavedScoped(
                      qId,
                      questionText: questionText,
                      licenceId: widget.licenceId,
                      categoryId: widget.categoryId,
                      bcdCategoryId: widget.bcdCategoryId,
                    );
                    final ids = await SavedQuestionsService.getSavedIdsScoped(
                      licenceId: widget.licenceId,
                      categoryId: widget.categoryId,
                      bcdCategoryId: widget.bcdCategoryId,
                    );
                    if (mounted) {
                      setState(() => _savedQuestionIds = ids);
                      showAppSnackBar(isSaved
                          ? t.test_question_saved
                          : t.test_question_removed);
                    }
                  },
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
                  unansweredCount:
                      widget.questions.length - userSelections.length,
                  onCancel: () {}, // nothing extra on “No”
                  onConfirm: () async {
                    final saveResult = await _saveTestAttempt();
                    if (!mounted) return;
                    if (!saveResult.backendSynced) {
                      showAppSnackBar(t.test_save_backend_failed);
                    }
                    final passed = _calculateResult();
                    if (passed) {
                      vibratePass();
                    } else {
                      vibrateFail();
                    }
                    showResultDialog(
                      context: this.context,
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
          ); // Scaffold
        }), // Builder
      ), // CupertinoScaffold
    ); // PopScope
  } // build

// Add this helper method for language flags

// Add this method to show the question navigation sheet
  void _showQuestionNavigationSheet() {
    final progressText = t.test_question_progress
        .replaceAll('{current}', '${currentQuestionIndex + 1}')
        .replaceAll('{total}', '${widget.questions.length}');
    CupertinoScaffold.showCupertinoModalBottomSheet<void>(
      context: _sheetContext ?? context,
      builder: (ctx) => AppBottomSheetContainer(
        title: t.test_questions_title,
        subtitle: progressText,
        heightFactor: 0.8,
        child: QuestionNavigationGrid(
          questionCount: widget.questions.length,
          userSelections: userSelections,
          currentIndex: currentQuestionIndex,
          onTap: (index) {
            Navigator.pop(ctx);
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
        ),
      ),
    );
  }
}

class _AiSession {
  final List<ChatMessage> messages;
  const _AiSession(this.messages);
  // Placeholder set immediately on first message — history arrives on sheet close.
  const _AiSession._pending() : messages = const [];
}
