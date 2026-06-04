import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';
import 'package:taxi_exam_app/core/services/home_data_cache.dart';
import 'package:taxi_exam_app/core/storage/app_storage.dart';
import 'package:taxi_exam_app/features/tests/test_attempt_save_service.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/core/services/language_preference_service.dart';
import 'package:taxi_exam_app/core/services/navigation_feedback.dart';
import 'package:taxi_exam_app/core/services/sound_service.dart';
import 'package:taxi_exam_app/core/services/tts_service.dart';
import 'package:taxi_exam_app/core/widgets/app_bottom_sheet.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'package:taxi_exam_app/features/tests/widgets/language_grid.dart';
import 'package:taxi_exam_app/features/tests/widgets/question_chat_sheet.dart';
import 'package:taxi_exam_app/features/tests/widgets/question_page_item.dart';
import 'package:translator/translator.dart';

/// Chunk-session test screen with built-in re-ask logic.
///
/// Wrong on first attempt → re-inserted at a random later position.
/// Wrong on second attempt → retired (not re-asked again).
/// Session ends when the queue is empty; [onComplete] is called with the
/// final pass/fail and a per-question correct map.
class SmartTestScreen extends StatefulWidget {
  final List<Question> initialQuestions;
  final double passScorePercent;
  final String testName;
  final String licenceId;
  final String categoryId;
  final int? bcdCategoryId;
  final int? bcdTestId;

  /// Called when the session ends.
  /// Return a [Widget] to push-replace to it, or null to simply pop.
  /// [wrongSelections] maps questionId → the last wrong option label selected.
  final Future<Widget?> Function(
    bool hasPassed,
    Map<String, bool> finalResults,
    Map<String, String> wrongSelections,
  ) onComplete;

  const SmartTestScreen({
    super.key,
    required this.initialQuestions,
    required this.onComplete,
    this.passScorePercent = 70.0,
    this.testName = '',
    this.licenceId = '',
    this.categoryId = '',
    this.bcdCategoryId,
    this.bcdTestId,
  });

  @override
  State<SmartTestScreen> createState() => _SmartTestScreenState();
}

class _SmartTestScreenState extends State<SmartTestScreen> {
  final _api = ApiService();
  final _tts = TtsService();
  final _random = Random();
  final _noScreenshot = kIsWeb ? null : NoScreenshot.instance;

  // Session identity — used for attempt tracking
  late final String _testId;
  late final DateTime _startTime;
  late final TestAttemptSaveService _attemptSaveService;

  // Remaining question queue — front is always the current question.
  late final List<Question> _queue;

  // Session tracking
  final Map<String, int> _wrongCounts = {};
  final Set<String> _correctOnce = {};
  // Questions answered correctly once but awaiting a confirmation re-ask.
  final Set<String> _needsConfirmation = {};
  // Questions whose progress step has already been counted (at most once each).
  final Set<String> _progressCounted = {};
  // Last wrong option label selected per question (for result-screen review).
  final Map<String, String> _lastWrongSelections = {};
  // Drives the visual progress bar — updated immediately on Check.
  int _progressDoneCount = 0;
  int _consecutiveCorrect = 0;
  bool _hideStreakLabel = false;

  // Current question UI state (QuestionPageItem uses index 0 as the slot key).
  final Map<int, String> _selection = {};
  bool _isAnswered = false;
  bool _isChecked = false;
  int _pageKey = 0;

  // Language & AI (mirrors test_screen pattern)
  String _langCode = 'SV';
  bool _aiEnabled = false;
  final Map<String, List<ChatMessage>> _aiSessions = {};

  // Context captured inside CupertinoScaffold — required for depth-effect sheets.
  BuildContext? _sheetContext;

  bool _finishing = false;

  // Translation
  final _translator = GoogleTranslator();
  final Map<String, List<Question>> _translatedQuestions = {};
  String? _previousLangCode;

  @override
  void initState() {
    super.initState();
    _testId = DateTime.now().millisecondsSinceEpoch.toString();
    _startTime = DateTime.now();
    _attemptSaveService = TestAttemptSaveService(
      saveLocal: _persistAttemptLocal,
      syncRemote: _api.syncTestAttempt,
    );
    _queue = List<Question>.from(widget.initialQuestions);
    _noScreenshot?.screenshotOff();
    _loadAiEnabled();
    _preFetchPreferredLanguage();
    // Pre-open Hive box so saves don't hang.
    AppStorage.testAttemptsBox();
    // Mark as started immediately so even app-kill is recorded.
    _saveAttempt(status: 'started', score: 0, hasPassed: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadQueueImages(0);
      _preloadQueueImages(1);
      _preloadQueueImages(2);
    });
  }

  @override
  void dispose() {
    _tts.flutterTts.stop();
    super.dispose();
  }

  Future<void> _persistAttemptLocal(TestAttempt attempt) async {
    final box = await AppStorage.testAttemptsBox();
    await box.put(attempt.testId, attempt);
  }

  Future<void> _saveAttempt({
    required String status,
    required double score,
    required bool hasPassed,
  }) async {
    final attempt = TestAttempt(
      testId: _testId,
      dateTime: _startTime,
      userSelections: {},
      score: score,
      hasPassed: hasPassed,
      questions: widget.initialQuestions,
      licenceName: '',
      categoryName: widget.testName,
      status: status,
      currentQuestionIndex: 0,
      licenceId: widget.licenceId,
      categoryId: widget.categoryId,
      durationSeconds: DateTime.now().difference(_startTime).inSeconds,
      bcdCategoryId: widget.bcdCategoryId,
    );
    await _attemptSaveService.save(attempt);
    HomeDataCache.invalidate();
  }

  Future<void> _loadAiEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(AppStorage.kUserJson);
    if (stored == null) return;
    try {
      final map = jsonDecode(stored) as Map<String, dynamic>;
      if (mounted) setState(() => _aiEnabled = map['ai_enabled'] == true);
    } catch (_) {}
  }

  Future<void> _preFetchPreferredLanguage() async {
    final lang = await LanguagePreferenceService.getMostUsed();
    if (lang == null || lang.toLowerCase() == 'sv') return;
    await _translateToLanguage(lang.toLowerCase());
    if (mounted && _previousLangCode == null) {
      setState(() => _previousLangCode = lang.toUpperCase());
    }
  }

  // ── Image preloading ───────────────────────────────────────────────────────

  void _preloadQueueImages(int queueIndex) {
    if (!mounted) return;
    if (queueIndex < 0 || queueIndex >= _queue.length) return;
    final q = _queue[queueIndex];

    final urls = <String>[
      if (q.images.isNotEmpty)
        ...q.images
      else if (q.imageUrl.isNotEmpty)
        _api.fetchImage(widget.licenceId, widget.categoryId, q.imageUrl),
      for (final tab in q.tabs) ...tab.images,
      for (final opt in q.options)
        if (opt.imageUrl.isNotEmpty) opt.imageUrl,
    ];

    for (final url in urls) {
      if (url.isEmpty) continue;
      precacheImage(CachedNetworkImageProvider(url), context);
    }
  }

  // ── Translation ────────────────────────────────────────────────────────────

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

  String _stripHtml(String s) {
    s = s.replaceAll(RegExp(r'<[^>]+>'), ' ');
    const entities = {
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

  Future<String> _safeTranslate(String text, String toLang) async {
    try {
      final result = await _translator.translate(text, from: 'sv', to: toLang);
      return result.text;
    } catch (_) {
      return text;
    }
  }

  Future<void> _translateToLanguage(String targetLang) async {
    if (_translatedQuestions.containsKey(targetLang)) return;
    try {
      final List<String> mainBuffer = [];
      for (final q in widget.initialQuestions) {
        mainBuffer.add(q.text);
        mainBuffer.addAll(q.options.map((o) => o.text));
      }
      final mainResults = await Future.wait(
        mainBuffer
            .map((s) => _translator.translate(s, from: 'sv', to: targetLang)),
      );
      var idx = 0;
      final partial = <Question>[];
      for (final q in widget.initialQuestions) {
        final tText = mainResults[idx++].text;
        final tOpts = q.options
            .map((o) => o.copyWith(text: mainResults[idx++].text))
            .toList();
        partial.add(q.copyWith(text: tText, options: tOpts));
      }

      final expFutures = widget.initialQuestions.map((q) {
        final t = _stripHtml(q.answerExplanation);
        if (!_isTranslatableText(t)) return Future<String?>.value(null);
        return _safeTranslate(t, targetLang).then<String?>((v) => v);
      }).toList();
      final expResults = await Future.wait(expFutures);

      final translated = <Question>[];
      for (var i = 0; i < partial.length; i++) {
        final exp = expResults[i];
        translated.add(exp != null
            ? partial[i].copyWith(answerExplanation: exp)
            : partial[i]);
      }
      _translatedQuestions[targetLang] = translated;
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        showAppSnackBar(Translations.of(context).test_translation_failed);
      }
    }
  }

  Future<void> _onLanguageSelected(String code) async {
    _tts.flutterTts.stop();
    final targetLang = code.toLowerCase();
    if (targetLang == _langCode.toLowerCase()) return;
    HapticFeedback.selectionClick();
    final previousCode = _langCode;
    if (targetLang == 'sv') {
      if (mounted) {
        setState(() {
          _previousLangCode = previousCode;
          _langCode = code.toUpperCase();
        });
      }
      return;
    }
    LanguagePreferenceService.record(code).ignore();
    await _translateToLanguage(targetLang);
    if (mounted) {
      setState(() {
        _previousLangCode = previousCode;
        _langCode = code.toUpperCase();
      });
    }
  }

  Future<void> _revertToPreviousLanguage() async {
    if (_previousLangCode == null) return;
    await _onLanguageSelected(_previousLangCode!);
  }

  // Returns the current question with translations applied if a non-SV language is active.
  Question? get _displayQuestion {
    final q = _current;
    if (q == null) return null;
    final lang = _langCode.toLowerCase();
    if (lang == 'sv') return q;
    final list = _translatedQuestions[lang];
    if (list == null) return q;
    final i =
        widget.initialQuestions.indexWhere((x) => x.questionId == q.questionId);
    if (i < 0 || i >= list.length) return q;
    return list[i];
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Question? get _current => _queue.isNotEmpty ? _queue.first : null;
  int get _total => widget.initialQuestions.length;

  String get _uiLang =>
      LocaleSettings.currentLocale == AppLocale.sv ? 'Swedish' : 'English';

  bool get _isLastAction {
    if (!_isChecked || _current == null) return false;
    final id = _current!.questionId;
    final isCorrect = _selection[0] == _current!.correctAnswer;
    if (!isCorrect) {
      final afterThis = (_wrongCounts[id] ?? 0) + 1;
      if (afterThis < 2) return false;
    } else {
      // First correct will be re-inserted for confirmation — not the last action.
      if (!_needsConfirmation.contains(id)) return false;
    }
    return _queue.length == 1;
  }

  String get _correctAnswerText {
    final q = _displayQuestion;
    if (q == null) return '';
    try {
      return q.options.firstWhere((o) => o.optionLabel == q.correctAnswer).text;
    } catch (_) {
      return q.correctAnswer;
    }
  }

  // ── Option selection ───────────────────────────────────────────────────────

  void _onOptionTap(String optionLabel) {
    if (_isChecked) return;
    setState(() {
      _selection[0] = optionLabel;
      _isAnswered = true;
    });
  }

  void _onCheck() {
    if (!_isAnswered || _isChecked) return;
    final id = _current!.questionId;
    final isCorrect = _selection[0] == _current!.correctAnswer;
    final prevConsecutive = _consecutiveCorrect;
    setState(() {
      _isChecked = true;
      if (isCorrect) {
        _progressDoneCount++;
        _progressCounted.add(id); // guard wrong-retire from double-counting
        _consecutiveCorrect++;
      } else {
        _consecutiveCorrect = 0;
        _lastWrongSelections[id] = _selection[0] ?? '';
        // 2nd wrong attempt → retired; count if progress not already counted
        // via a prior correct answer on this question.
        if ((_wrongCounts[id] ?? 0) >= 1 && !_progressCounted.contains(id)) {
          _progressDoneCount++;
          _progressCounted.add(id);
        }
      }
    });
    if (isCorrect) {
      if (_consecutiveCorrect >= 3) {
        SoundService.instance.consecutiveCorrect().ignore();
      } else {
        SoundService.instance.correctAnswer().ignore();
      }
      if (_consecutiveCorrect >= 10) {
        // Milestone streak — celebratory triple pulse
        vibratePass();
      } else if (_consecutiveCorrect >= 5) {
        // Strong streak — heavy + medium double tap
        HapticFeedback.heavyImpact().then(
          (_) => Future.delayed(
              const Duration(milliseconds: 80), HapticFeedback.heavyImpact),
        );
      } else if (_consecutiveCorrect >= 3) {
        // Building streak — medium double tap
        HapticFeedback.mediumImpact().then(
          (_) => Future.delayed(
              const Duration(milliseconds: 70), HapticFeedback.mediumImpact),
        );
      } else {
        vibrateCorrectAnswer();
      }
    } else {
      if (prevConsecutive >= 3) {
        SoundService.instance.consecutiveCorrectBroken().ignore();
      } else {
        SoundService.instance.incorrectAnswer().ignore();
      }
      vibrateWrongAnswer();
    }
  }

  // ── Queue advance ──────────────────────────────────────────────────────────

  Future<void> _advance() async {
    if (!_isAnswered || _current == null || _finishing) return;

    final q = _current!;
    final id = q.questionId;
    final wasCorrect = _selection[0] == q.correctAnswer;
    final wasConfirmation = _needsConfirmation.contains(id);

    if (wasCorrect) {
      if (wasConfirmation) {
        // Second correct — confirmed mastery.
        _needsConfirmation.remove(id);
        _correctOnce.add(id);
      } else {
        // First correct — queue a confirmation re-ask.
        _needsConfirmation.add(id);
      }
    } else {
      _needsConfirmation.remove(id);
      _wrongCounts[id] = (_wrongCounts[id] ?? 0) + 1;
      if (_wrongCounts[id]! >= 2) {
        vibrateFail();
      }
    }

    _queue.removeAt(0);

    if (!wasCorrect && _wrongCounts[id] == 1) {
      // First wrong — re-insert at a random position.
      final len = _queue.length;
      final pos = len <= 1 ? len : 1 + _random.nextInt(len - 1);
      _queue.insert(pos, q);
    } else if (wasCorrect && !wasConfirmation) {
      // First correct — re-insert for confirmation at a random later position.
      final len = _queue.length;
      if (len == 0) {
        _queue.add(q);
      } else {
        final pos = len <= 1 ? len : 1 + _random.nextInt(len - 1);
        _queue.insert(pos, q);
      }
    }

    _preloadQueueImages(1);
    _preloadQueueImages(2);

    if (_queue.isEmpty) {
      setState(() => _finishing = true);
      final correctCount = widget.initialQuestions
          .where((q) => _correctOnce.contains(q.questionId))
          .length;
      final score = _total > 0 ? (correctCount / _total * 100) : 0.0;
      final hasPassed = score >= widget.passScorePercent;
      if (hasPassed) {
        SoundService.instance.passExam().ignore();
      } else {
        SoundService.instance.failExam().ignore();
        vibrateFail();
      }
      // Save completed attempt so it shows in the user's attempts list.
      _saveAttempt(status: 'completed', score: score, hasPassed: hasPassed)
          .ignore();
      final finalResults = {
        for (final q in widget.initialQuestions)
          q.questionId: _correctOnce.contains(q.questionId),
      };
      final wrongSelections = {
        for (final q in widget.initialQuestions)
          if (!_correctOnce.contains(q.questionId) &&
              _lastWrongSelections.containsKey(q.questionId))
            q.questionId: _lastWrongSelections[q.questionId]!,
      };
      final nextScreen =
          await widget.onComplete(hasPassed, finalResults, wrongSelections);
      if (mounted) {
        if (nextScreen != null) {
          Navigator.pushReplacement(
            context,
            AppPageRoute(builder: (_) => nextScreen),
          );
        } else {
          Navigator.pop(context);
        }
      }
      return;
    }

    setState(() {
      _selection.clear();
      _isAnswered = false;
      _isChecked = false;
      _pageKey++;
      _hideStreakLabel = true;
    });
    // Reset flag after the label has animated out so next streak shows fresh.
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _hideStreakLabel = false);
    });
  }

  // ── Language sheet ─────────────────────────────────────────────────────────

  Future<void> _showLanguageSheet() async {
    final t = Translations.of(context);
    final langNotifier = ValueNotifier<String>(_langCode);
    await CupertinoScaffold.showCupertinoModalBottomSheet<void>(
      context: _sheetContext ?? context,
      builder: (_) => AppBottomSheetContainer(
        title: t.test_question_language_title,
        subtitle: t.test_question_language_subtitle,
        heightFactor: 0.8,
        child: LanguageGrid(
          selectedLanguage: langNotifier,
          onSelected: (code) async {
            await _onLanguageSelected(code);
            langNotifier.value = code;
          },
        ),
      ),
    );
  }

  // ── AI chat ────────────────────────────────────────────────────────────────

  void _openAiChat({String? displayText, String? prompt}) {
    final q = _current;
    if (q == null) return;
    final id = q.questionId;

    CupertinoScaffold.showCupertinoModalBottomSheet<void>(
      context: _sheetContext ?? context,
      builder: (_) => QuestionChatSheet(
        question: q,
        existingMessages: _aiSessions[id] ?? [],
        initialDisplayText: displayText,
        initialPrompt: prompt,
        categoryName: widget.testName,
        licenceName: '',
        onFirstMessageSent: () {
          if (mounted) setState(() => _aiSessions.putIfAbsent(id, () => []));
        },
        onSaveSession: (msgs) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _aiSessions[id] = msgs);
          });
        },
      ),
    );
  }

  Future<bool> _confirmExitSession() async {
    if (_finishing) return true;
    final t = Translations.of(context);
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.smart_exit_title),
        content: Text(t.smart_exit_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(t.btn_exit),
          ),
        ],
      ),
    );
    final confirmed = shouldExit ?? false;
    if (confirmed) vibrateFail();
    return confirmed;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final q = _displayQuestion;
    final id = _current?.questionId;

    return CupertinoScaffold(
      body: Builder(builder: (innerCtx) {
        _sheetContext = innerCtx;
        return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) async {
              if (didPop) return;
              final nav = Navigator.of(innerCtx);
              final shouldExit = await _confirmExitSession();
              if (!mounted || !shouldExit) return;
              nav.pop();
            },
            child: Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: AppBar(
                leading: IconButton(
                  icon: Icon(Icons.close,
                      color: Theme.of(context).colorScheme.onSurface),
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    final shouldExit = await _confirmExitSession();
                    if (!mounted || !shouldExit) return;
                    nav.pop();
                  },
                ),
                title: _SmartProgressBar(
                  doneCount: _progressDoneCount,
                  total: _total * 2,
                  consecutiveCorrect: _consecutiveCorrect,
                  hideLabel: _hideStreakLabel,
                ),
                centerTitle: false,
                titleSpacing: 4,
                leadingWidth: 44,
                toolbarHeight: 64,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                elevation: 2,
                shadowColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.08),
                actions: [
                  _LanguageChip(
                    flag: _tts.getLanguageFlag(_langCode),
                    langCode: _langCode,
                    onTap: _showLanguageSheet,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              body: q == null
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onLongPress: _revertToPreviousLanguage,
                            onLongPressUp: _revertToPreviousLanguage,
                            behavior: HitTestBehavior.opaque,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, anim) {
                                final isIncoming =
                                    child.key == ValueKey(_pageKey);
                                final slide = Tween<Offset>(
                                  begin: Offset(isIncoming ? 1.0 : -1.0, 0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: anim,
                                  curve: Curves.easeInOut,
                                ));
                                return SlideTransition(
                                    position: slide, child: child);
                              },
                              layoutBuilder: (currentChild, previousChildren) =>
                                  Stack(
                                alignment: Alignment.topCenter,
                                children: [
                                  ...previousChildren,
                                  if (currentChild != null) currentChild,
                                ],
                              ),
                              child: KeyedSubtree(
                                key: ValueKey(_pageKey),
                                child: QuestionPageItem(
                                  index: 0,
                                  question: q,
                                  legacyImageUrl: _api.fetchImage(
                                    widget.licenceId,
                                    widget.categoryId,
                                    q.imageUrl,
                                  ),
                                  userSelections: _selection,
                                  isReviewMode: false,
                                  instantMarking: _isChecked,
                                  savedQuestionIds: const {},
                                  aiEnabled: _aiEnabled,
                                  hasAiSession:
                                      id != null && _aiSessions.containsKey(id),
                                  currentLanguageCode: _langCode,
                                  scale: 1.0,
                                  onOptionTap: _onOptionTap,
                                  onLongPress: _revertToPreviousLanguage,
                                  onLongPressUp: _revertToPreviousLanguage,
                                  onAiContinue: _openAiChat,
                                  onAiHint: () => _openAiChat(
                                    displayText: t.ai_hint_button,
                                    prompt:
                                        'Give me a short hint that helps me figure out the answer without telling me directly. You MUST reply in $_uiLang only.',
                                  ),
                                  onAiUnderstand: () => _openAiChat(
                                    displayText: t.ai_understand_button,
                                    prompt:
                                        'Help me understand this question. Explain the concept it is testing and why the correct answer is right. You MUST reply in $_uiLang only.',
                                  ),
                                  onToggleSave: (_, __) {},
                                ),
                              ),
                            ),
                          ),
                        ),
                        _FeedbackFooter(
                          isAnswered: _isAnswered,
                          isChecked: _isChecked,
                          isCorrect: _isChecked &&
                              _current != null &&
                              _selection[0] == _current!.correctAnswer,
                          isLastAction: _isLastAction,
                          isFinishing: _finishing,
                          correctAnswerText: _correctAnswerText,
                          onCheck: _onCheck,
                          onAdvance: _advance,
                        ),
                      ],
                    ),
            )); // PopScope + Scaffold
      }), // Builder
    ); // CupertinoScaffold
  }
}

// ── Language chip (AppBar action) ────────────────────────────────────────────

class _LanguageChip extends StatelessWidget {
  final String flag;
  final String langCode;
  final VoidCallback onTap;

  const _LanguageChip({
    required this.flag,
    required this.langCode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              langCode,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Smart streak progress bar ────────────────────────────────────────────────

class _SmartProgressBar extends StatefulWidget {
  final int doneCount;
  final int total;
  final int consecutiveCorrect;
  final bool hideLabel;

  const _SmartProgressBar({
    required this.doneCount,
    required this.total,
    required this.consecutiveCorrect,
    this.hideLabel = false,
  });

  @override
  State<_SmartProgressBar> createState() => _SmartProgressBarState();
}

class _SmartProgressBarState extends State<_SmartProgressBar>
    with TickerProviderStateMixin {
  late final AnimationController _progressCtrl;
  late final AnimationController _burstCtrl;
  late final AnimationController _labelCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _fireBounceCtrl;
  late Animation<double> _progressAnim;
  double _lastProgress = 0.0;
  double _burstProgress = 0.0;

  // Cancellable timers — prevents stacked delayed calls when user taps fast.
  Timer? _burstTimer;
  Timer? _bounceTimer;

  static const _angles = [
    -math.pi / 2,
    -math.pi / 4,
    0.0,
    math.pi / 4,
    math.pi / 2,
    -math.pi * 3 / 4,
    math.pi * 3 / 4,
  ];
  static const _maxDists = [13.0, 10.0, 8.0, 11.0, 9.0, 10.0, 12.0];

  @override
  void initState() {
    super.initState();
    _lastProgress = _calcProgress();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _burstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _labelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    _fireBounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _progressAnim = Tween<double>(begin: _lastProgress, end: _lastProgress)
        .animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_SmartProgressBar old) {
    super.didUpdateWidget(old);

    if (widget.hideLabel && !old.hideLabel) {
      _labelCtrl.reverse();
    }

    if (widget.consecutiveCorrect >= 3 && old.consecutiveCorrect < 3) {
      _shimmerCtrl.repeat();
    } else if (widget.consecutiveCorrect < 3 && old.consecutiveCorrect >= 3) {
      _shimmerCtrl.stop();
      _shimmerCtrl.reset();
    }

    final newProgress = _calcProgress();
    if (newProgress != _lastProgress) {
      _progressAnim = Tween<double>(
        begin: _progressAnim.value,
        end: newProgress,
      ).animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut));
      _lastProgress = newProgress;
      _burstProgress = newProgress;
      _progressCtrl.forward(from: 0);

      // Cancel any pending timers from rapid taps before scheduling new ones.
      _burstTimer?.cancel();
      _bounceTimer?.cancel();

      _burstTimer = Timer(const Duration(milliseconds: 380), () {
        if (mounted) _burstCtrl.forward(from: 0);
      });

      if (widget.consecutiveCorrect >= 3) {
        _bounceTimer = Timer(const Duration(milliseconds: 450), () {
          if (mounted) _fireBounceCtrl.forward(from: 0);
        });
      }

      if (widget.consecutiveCorrect >= 2) {
        _labelCtrl.forward(from: 0);
      } else {
        _labelCtrl.reverse();
      }
    }
  }

  double _calcProgress() {
    if (widget.total <= 0) return 0.0;
    return (widget.doneCount / widget.total).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _burstTimer?.cancel();
    _bounceTimer?.cancel();
    _progressCtrl.dispose();
    _burstCtrl.dispose();
    _labelCtrl.dispose();
    _shimmerCtrl.dispose();
    _fireBounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const barHeight = 16.0;
    const totalH = 28.0;
    const barTop = (totalH - barHeight) / 2;
    const labelH = 14.0;
    const barCenterY = barTop + barHeight / 2;

    // Cache theme values — these don't change per animation frame.
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final trackColor =
        isDark ? Colors.white.withValues(alpha: 0.18) : Colors.grey[300]!;
    final highlightAlpha = isDark ? 0.12 : 0.18;
    final onFire = widget.consecutiveCorrect >= 3;
    final fillColor = onFire ? const Color(0xFFFF9500) : primary;
    final streakLabel = widget.consecutiveCorrect >= 2
        ? Translations.of(context).smart_in_a_row(n: widget.consecutiveCorrect)
        : null;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth;
          final burstX = (_burstProgress * barWidth).clamp(0.0, barWidth);

          return AnimatedBuilder(
            animation: Listenable.merge([
              _progressAnim,
              _burstCtrl,
              _labelCtrl,
              _shimmerCtrl,
              _fireBounceCtrl,
            ]),
            builder: (context, _) {
              final fillWidth =
                  (_progressAnim.value * barWidth).clamp(0.0, barWidth);
              final burstT = _burstCtrl.value;
              final burstActive = burstT > 0.0 && burstT < 1.0;
              final bounceT = _fireBounceCtrl.value;
              // bounceScale: 1 → 1.35 → 0.9 → 1 spring feel.
              final bounceScale = 1.0 +
                  0.35 *
                      math.sin(bounceT * math.pi) *
                      (1 - bounceT) *
                      (bounceT < 0.5 ? 1 : -0.6);
              final dropsActive = onFire && bounceT > 0.1 && bounceT < 0.7;
              final labelOpacity = _labelCtrl.value;
              final labelLeft = (fillWidth - 36).clamp(0.0, barWidth - 80.0);

              return SizedBox(
                height: totalH,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ── Streak label ───────────────────────────────────────
                    if (labelOpacity > 0 && streakLabel != null)
                      Positioned(
                        top: -(labelH - 1),
                        left: labelLeft,
                        child: Opacity(
                          opacity: labelOpacity,
                          child: Text(
                            streakLabel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: fillColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),

                    // ── Track ──────────────────────────────────────────────
                    Positioned(
                      top: barTop,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: trackColor,
                          borderRadius: BorderRadius.circular(barHeight / 2),
                        ),
                      ),
                    ),

                    // ── Fill ───────────────────────────────────────────────
                    if (fillWidth > 0)
                      Positioned(
                        top: barTop,
                        left: 0,
                        // Anchor bounce scale to the center of the fill bar.
                        child: Transform(
                          alignment: Alignment(
                            (fillWidth / 2 / barWidth) * 2 - 1,
                            0,
                          ),
                          transform:
                              Matrix4.diagonal3Values(1.0, bounceScale, 1.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(barHeight / 2),
                            child: SizedBox(
                              width: fillWidth,
                              height: barHeight,
                              child: Stack(
                                children: [
                                  // Solid base fill
                                  Positioned.fill(
                                    child: ColoredBox(color: fillColor),
                                  ),
                                  // 3D highlight line
                                  Positioned(
                                    top: 3,
                                    left: barHeight / 2,
                                    right: barHeight / 2,
                                    child: Container(
                                      height: 3,
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: highlightAlpha),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                  // Shimmer sweep — only when on fire
                                  if (onFire)
                                    Positioned.fill(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment(
                                                -2.5 + _shimmerCtrl.value * 5,
                                                0),
                                            end: Alignment(
                                                -1.0 + _shimmerCtrl.value * 5,
                                                0),
                                            colors: [
                                              Colors.white.withValues(alpha: 0),
                                              Colors.white
                                                  .withValues(alpha: 0.45),
                                              Colors.white.withValues(alpha: 0),
                                            ],
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

                    // ── Fire drips ─────────────────────────────────────────
                    if (dropsActive)
                      ...List.generate(3, (i) {
                        const offsets = [-6.0, 0.0, 6.0];
                        const delays = [0.0, 0.15, 0.08];
                        final t = (bounceT - 0.1) / 0.6;
                        final dt = (t - delays[i]).clamp(0.0, 1.0);
                        final dropSize = 4.0 + i.toDouble();
                        return Positioned(
                          left: burstX - dropSize / 2 + offsets[i],
                          top: barTop + barHeight + dt * 10,
                          child: Opacity(
                            opacity: (1.0 - dt).clamp(0.0, 1.0),
                            child: Container(
                              width: dropSize,
                              height: dropSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: fillColor,
                              ),
                            ),
                          ),
                        );
                      }),

                    // ── Burst particles ────────────────────────────────────
                    if (burstActive)
                      ...List.generate(_angles.length, (i) {
                        final ease = Curves.easeOut.transform(burstT);
                        final dist = ease * _maxDists[i];
                        final dotSize = 1.0 + 3.5 * math.sin(burstT * math.pi);
                        return Positioned(
                          left: burstX +
                              dist * math.cos(_angles[i]) -
                              dotSize / 2,
                          top: barCenterY +
                              dist * math.sin(_angles[i]) -
                              dotSize / 2,
                          child: Opacity(
                            opacity: (1.0 - burstT).clamp(0.0, 1.0),
                            child: Container(
                              width: dotSize,
                              height: dotSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: fillColor,
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Duolingo-style feedback footer ───────────────────────────────────────────

class _FeedbackFooter extends StatefulWidget {
  final bool isAnswered;
  final bool isChecked;
  final bool isCorrect;
  final bool isLastAction;
  final bool isFinishing;
  final String correctAnswerText;
  final VoidCallback onCheck;
  final VoidCallback onAdvance;

  const _FeedbackFooter({
    required this.isAnswered,
    required this.isChecked,
    required this.isCorrect,
    required this.isLastAction,
    required this.isFinishing,
    required this.correctAnswerText,
    required this.onCheck,
    required this.onAdvance,
  });

  @override
  State<_FeedbackFooter> createState() => _FeedbackFooterState();
}

class _FeedbackFooterState extends State<_FeedbackFooter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _slide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    if (widget.isChecked) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant _FeedbackFooter old) {
    super.didUpdateWidget(old);
    if (widget.isChecked && !old.isChecked) {
      _ctrl.forward(from: 0);
    } else if (!widget.isChecked && old.isChecked) {
      _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCorrect = widget.isCorrect;

    final bgColor = isCorrect
        ? (isDark ? const Color(0xFF1B3A28) : const Color(0xFFD7F5E0))
        : (isDark ? const Color(0xFF3A1B1B) : const Color(0xFFFFE8E8));

    final fgColor =
        isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F);

    final btnColor = widget.isChecked
        ? (isCorrect ? const Color(0xFF388E3C) : const Color(0xFFD32F2F))
        : Theme.of(context).colorScheme.primary;

    final title =
        isCorrect ? t.smart_feedback_correct : t.smart_feedback_incorrect;

    final actionLabel = widget.isChecked
        ? (widget.isLastAction
            ? t.smart_result_continue
            : (isCorrect ? t.bcd_next : t.smart_hearts_guide_got_it))
        : t.smart_check;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Feedback strip — slides up from below, sits above the button ──
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: widget.isChecked
              ? ClipRect(
                  child: SlideTransition(
                    position: _slide,
                    child: Container(
                      width: double.infinity,
                      color: bgColor,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _FeedbackIcon(isCorrect: isCorrect),
                              const SizedBox(width: 8),
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: fgColor,
                                ),
                              ),
                            ],
                          ),
                          if (!isCorrect &&
                              widget.correctAnswerText.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              t.smart_feedback_correct_answer,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: fgColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.correctAnswerText,
                              style: TextStyle(
                                fontSize: 14,
                                color: fgColor.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        // ── Button — always present, color animates on check ──────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          color: widget.isChecked ? bgColor : Colors.transparent,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: AnimatedTheme(
                  duration: const Duration(milliseconds: 250),
                  data: Theme.of(context).copyWith(
                    filledButtonTheme: FilledButtonThemeData(
                      style: FilledButton.styleFrom(backgroundColor: btnColor),
                    ),
                  ),
                  child: FilledButton(
                    onPressed: widget.isFinishing
                        ? null
                        : (widget.isChecked
                            ? widget.onAdvance
                            : (widget.isAnswered ? widget.onCheck : null)),
                    child: Text(
                      actionLabel.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ), // AnimatedContainer
      ],
    );
  }
}

// ── Feedback icon — diamond for correct, circle-X for incorrect ───────────────
// Mirrors the option tile's indicator shape for visual consistency.

// ── Feedback icon — uses the exact same colors as the option tile indicators ──

class _FeedbackIcon extends StatelessWidget {
  final bool isCorrect;

  const _FeedbackIcon({required this.isCorrect});

  @override
  Widget build(BuildContext context) {
    if (isCorrect) {
      return Transform.rotate(
        angle: 0.7853981634, // 45°
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: Colors.green, // matches option_tile.dart correct indicator
            borderRadius: BorderRadius.circular(5),
          ),
          child: Center(
            child: Transform.rotate(
              angle: -0.7853981634,
              child: const Icon(Icons.check, size: 15, color: Colors.white),
            ),
          ),
        ),
      );
    }
    return Container(
      width: 26,
      height: 26,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.red, // matches option_tile.dart wrong indicator
      ),
      child: const Center(
        child: Icon(Icons.close, size: 15, color: Colors.white),
      ),
    );
  }
}
