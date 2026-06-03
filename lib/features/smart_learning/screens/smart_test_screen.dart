import 'dart:convert';
import 'dart:math' as math;
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final Future<Widget?> Function(bool hasPassed, Map<String, bool> finalResults)
      onComplete;

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

  // Session identity — used for attempt tracking
  late final String _testId;
  late final DateTime _startTime;
  late final TestAttemptSaveService _attemptSaveService;

  // Remaining question queue — front is always the current question.
  late final List<Question> _queue;

  // Session tracking
  final Map<String, int> _wrongCounts = {};
  final Set<String> _correctOnce = {};
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
    final isCorrect = _selection[0] == _current!.correctAnswer;
    if (!isCorrect) {
      final afterThis = (_wrongCounts[_current!.questionId] ?? 0) + 1;
      if (afterThis < 2) return false;
    }
    return _queue.length == 1;
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
    setState(() {
      _isChecked = true;
      if (isCorrect) {
        _progressDoneCount++;
        _consecutiveCorrect++;
      } else {
        _consecutiveCorrect = 0;
        // If this is the second wrong attempt it counts as done for progress.
        if ((_wrongCounts[id] ?? 0) >= 1) _progressDoneCount++;
      }
    });
    if (isCorrect) {
      if (_consecutiveCorrect >= 10) {
        // Milestone streak — celebratory triple pulse
        vibratePass();
      } else if (_consecutiveCorrect >= 5) {
        // Strong streak — heavy + medium double tap
        HapticFeedback.heavyImpact().then(
          (_) => Future.delayed(const Duration(milliseconds: 80),
              HapticFeedback.heavyImpact),
        );
      } else if (_consecutiveCorrect >= 3) {
        // Building streak — medium double tap
        HapticFeedback.mediumImpact().then(
          (_) => Future.delayed(const Duration(milliseconds: 70),
              HapticFeedback.mediumImpact),
        );
      } else {
        vibrateCorrectAnswer();
      }
    } else {
      vibrateWrongAnswer();
    }
  }

  // ── Queue advance ──────────────────────────────────────────────────────────

  Future<void> _advance() async {
    if (!_isAnswered || _current == null || _finishing) return;

    final q = _current!;
    final id = q.questionId;
    final wasCorrect = _selection[0] == q.correctAnswer;

    if (wasCorrect) {
      _correctOnce.add(id);
    } else {
      _wrongCounts[id] = (_wrongCounts[id] ?? 0) + 1;
      if (_wrongCounts[id]! >= 2) {
        vibrateFail();
      }
    }

    _queue.removeAt(0);

    if (!wasCorrect && _wrongCounts[id] == 1) {
      final len = _queue.length;
      final pos = len <= 1 ? len : 1 + _random.nextInt(len - 1);
      _queue.insert(pos, q);
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
      if (!hasPassed) vibrateFail();
      // Save completed attempt so it shows in the user's attempts list.
      _saveAttempt(status: 'completed', score: score, hasPassed: hasPassed)
          .ignore();
      final finalResults = {
        for (final q in widget.initialQuestions)
          q.questionId: _correctOnce.contains(q.questionId),
      };
      final nextScreen = await widget.onComplete(hasPassed, finalResults);
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
                  total: _total,
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
                        _NextButton(
                          enabled: _isAnswered && !_finishing,
                          label: _isChecked
                              ? (_isLastAction
                                  ? t.smart_result_continue
                                  : t.bcd_next)
                              : t.smart_check,
                          onPressed: _isChecked ? _advance : _onCheck,
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
  // The target progress ratio when burst fires — used to anchor particles.
  double _burstProgress = 0.0;

  // Fixed angles + distances for 7 particles so each burst looks consistent.
  static const _angles = [
    -math.pi / 2,       // top
    -math.pi / 4,       // top-right
    0.0,                // right
    math.pi / 4,        // bottom-right
    math.pi / 2,        // bottom
    -math.pi * 3 / 4,   // top-left
    math.pi * 3 / 4,    // bottom-left
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
      duration: const Duration(milliseconds: 1400),
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
      _progressCtrl.forward(from: 0);
      if (widget.consecutiveCorrect >= 3) {
        _fireBounceCtrl.forward(from: 0);
      }
      // Burst fires just as bar reaches its new position.
      _burstProgress = newProgress;
      Future.delayed(const Duration(milliseconds: 380), () {
        if (mounted) _burstCtrl.forward(from: 0);
      });
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
    // Widget height is just the bar — AppBar centers it naturally.
    // Label floats above via Clip.none; toolbarHeight gives it room.
    const totalH = 28.0;
    const barTop = (totalH - barHeight) / 2;
    const labelH = 14.0;
    final primary = Theme.of(context).colorScheme.primary;
    final trackColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.grey[300]!;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AnimatedBuilder(
        animation: Listenable.merge([_progressAnim, _burstCtrl, _labelCtrl, _shimmerCtrl, _fireBounceCtrl]),
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth;
              final fillWidth =
                  (_progressAnim.value * barWidth).clamp(0.0, barWidth);
              final burstX =
                  (_burstProgress * barWidth).clamp(0.0, barWidth);
              final burstT = _burstCtrl.value; // 0→1
              final burstActive = burstT > 0.0 && burstT < 1.0;
              const barCenterY = barTop + barHeight / 2;
              final fillColor = widget.consecutiveCorrect >= 3
                  ? const Color(0xFFFF9500)
                  : primary;
              // Bounce: scaleY spring — 1 → 1.35 → 0.9 → 1
              final bounceT = _fireBounceCtrl.value;
              final bounceScale = bounceT == 0.0
                  ? 1.0
                  : 1.0 +
                      0.35 *
                          math.sin(bounceT * math.pi) *
                          (1 - bounceT) *
                          (bounceT < 0.5 ? 1 : -0.6);
              final dropsActive = bounceT > 0.1 &&
                  bounceT < 0.7 &&
                  widget.consecutiveCorrect >= 3;
              final labelOpacity = _labelCtrl.value;
              final labelLeft = (fillWidth - 36).clamp(0.0, barWidth - 80.0);

              return SizedBox(
                height: totalH,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ── Streak label — floats above bar, within toolbarHeight
                    if (labelOpacity > 0 && widget.consecutiveCorrect >= 2)
                      Positioned(
                        top: -(labelH - 1),
                        left: labelLeft,
                        child: Opacity(
                          opacity: labelOpacity,
                          child: Text(
                            Translations.of(context)
                                .smart_in_a_row(n: widget.consecutiveCorrect),
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
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.diagonal3Values(
                              1.0, bounceScale, 1.0),
                          child: ClipRRect(
                          borderRadius: BorderRadius.circular(barHeight / 2),
                          child: SizedBox(
                            width: fillWidth,
                            height: barHeight,
                            child: Stack(
                              children: [
                                // Base fill — gold gradient on fire, solid otherwise
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: widget.consecutiveCorrect >= 3
                                          ? const LinearGradient(colors: [
                                              Color(0xFFFF9500),
                                              Color(0xFFFFCC00),
                                              Color(0xFFFF9500),
                                            ])
                                          : LinearGradient(
                                              colors: [primary, primary]),
                                    ),
                                  ),
                                ),
                                // Shimmer sweep — left to right when on fire
                                if (widget.consecutiveCorrect >= 3)
                                  Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment(
                                              -2.5 + _shimmerCtrl.value * 5, 0),
                                          end: Alignment(
                                              -1.0 + _shimmerCtrl.value * 5, 0),
                                          colors: [
                                            Colors.white.withValues(alpha: 0),
                                            Colors.white.withValues(alpha: 0.45),
                                            Colors.white.withValues(alpha: 0),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                // 3D highlight line
                                Positioned(
                                  top: 3,
                                  left: barHeight / 2,
                                  right: barHeight / 2,
                                  child: Container(
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? 0.12
                                            : 0.18,
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Fire drips below fill tip ──────────────────────────
                    if (dropsActive) ...List.generate(3, (i) {
                        final t = (bounceT - 0.1) / 0.6;
                        final offsets = [-6.0, 0.0, 6.0];
                        final delays = [0.0, 0.15, 0.08];
                        final dt = (t - delays[i]).clamp(0.0, 1.0);
                        final dropY = barTop + barHeight + dt * 10;
                        final dropOpacity = (1.0 - dt).clamp(0.0, 1.0);
                        final dropSize = 4.0 + i.toDouble();
                        return Positioned(
                          left: fillWidth - dropSize / 2 + offsets[i],
                          top: dropY,
                          child: Opacity(
                            opacity: dropOpacity,
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
                    if (burstActive) ...List.generate(_angles.length, (i) {
                        final ease = Curves.easeOut.transform(burstT);
                        final dist = ease * _maxDists[i];
                        // Size: 1→4px then back toward 0 at the end.
                        final sizeCurve = math.sin(burstT * math.pi);
                        final dotSize = 1.0 + 3.5 * sizeCurve;
                        final opacity = (1.0 - burstT).clamp(0.0, 1.0);
                        final cx =
                            burstX + dist * math.cos(_angles[i]) - dotSize / 2;
                        final cy = barCenterY +
                            dist * math.sin(_angles[i]) -
                            dotSize / 2;
                        return Positioned(
                          left: cx,
                          top: cy,
                          child: Opacity(
                            opacity: opacity,
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

// ── Next / Finish button ─────────────────────────────────────────────────────

class _NextButton extends StatelessWidget {
  final bool enabled;
  final String label;
  final VoidCallback onPressed;

  const _NextButton({
    required this.enabled,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: enabled ? onPressed : null,
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
