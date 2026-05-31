import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/core/services/navigation_feedback.dart';
import 'package:taxi_exam_app/core/services/tts_service.dart';
import 'package:taxi_exam_app/core/storage/app_storage.dart';
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

  // Remaining question queue — front is always the current question.
  late final List<Question> _queue;

  // Session tracking
  final Map<String, int> _wrongCounts = {};
  final Set<String> _correctOnce = {};
  int _doneCount = 0;

  // Current question UI state (QuestionPageItem uses index 0 as the slot key).
  final Map<int, String> _selection = {};
  bool _isAnswered = false;
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

  @override
  void initState() {
    super.initState();
    _queue = List<Question>.from(widget.initialQuestions);
    _loadAiEnabled();
  }

  @override
  void dispose() {
    _tts.flutterTts.stop();
    super.dispose();
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

  // ── Translation ────────────────────────────────────────────────────────────

  Future<void> _translateToLanguage(String targetLang) async {
    if (_translatedQuestions.containsKey(targetLang)) return;
    try {
      final List<String> texts = [];
      for (final q in widget.initialQuestions) {
        texts.add(q.text);
        texts.addAll(q.options.map((o) => o.text));
      }
      final results = await Future.wait(
        texts.map((s) => _translator.translate(s, from: 'sv', to: targetLang)),
      );
      var idx = 0;
      final translated = <Question>[];
      for (final q in widget.initialQuestions) {
        final tText = results[idx++].text;
        final tOpts = q.options
            .map((o) => o.copyWith(text: results[idx++].text))
            .toList();
        translated.add(q.copyWith(text: tText, options: tOpts));
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
    final targetLang = code.toLowerCase();
    if (targetLang == _langCode.toLowerCase()) return;
    HapticFeedback.selectionClick();
    if (targetLang == 'sv') {
      if (mounted) setState(() => _langCode = code.toUpperCase());
      return;
    }
    await _translateToLanguage(targetLang);
    if (mounted) setState(() => _langCode = code.toUpperCase());
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
    if (!_isAnswered || _current == null) return false;
    final isCorrect = _selection[0] == _current!.correctAnswer;
    if (!isCorrect) {
      final afterThis = (_wrongCounts[_current!.questionId] ?? 0) + 1;
      if (afterThis < 2) return false;
    }
    return _queue.length == 1;
  }

  // ── Option selection ───────────────────────────────────────────────────────

  void _onOptionTap(String optionLabel) {
    if (_isAnswered) return;
    setState(() {
      _selection[0] = optionLabel;
      _isAnswered = true;
    });
    if (optionLabel == _current!.correctAnswer) {
      vibrateCorrectAnswer();
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
      _doneCount++;
    } else {
      _wrongCounts[id] = (_wrongCounts[id] ?? 0) + 1;
      if (_wrongCounts[id]! >= 2) _doneCount++;
    }

    _queue.removeAt(0);

    if (!wasCorrect && _wrongCounts[id] == 1) {
      final len = _queue.length;
      final pos = len <= 1 ? len : 1 + _random.nextInt(len - 1);
      _queue.insert(pos, q);
    }

    if (_queue.isEmpty) {
      setState(() => _finishing = true);
      final correctCount = widget.initialQuestions
          .where((q) => _correctOnce.contains(q.questionId))
          .length;
      final hasPassed = _total > 0 &&
          (correctCount / _total * 100) >= widget.passScorePercent;
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
      _pageKey++;
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
    return shouldExit ?? false;
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
        title: _PillProgressBar(done: _doneCount, total: _total),
        centerTitle: false,
        titleSpacing: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert,
                color: Theme.of(context).colorScheme.onSurface),
            onSelected: (value) {
              if (value == 'language') _showLanguageSheet();
            },
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                value: 'language',
                child: Row(
                  children: [
                    Text(_tts.getLanguageFlag(_langCode),
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(t.test_question_language_menu),
                    const Spacer(),
                    Icon(Icons.chevron_right,
                        size: 16,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: q == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    layoutBuilder: (currentChild, previousChildren) => Stack(
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
                        instantMarking: true,
                        savedQuestionIds: const {},
                        aiEnabled: _aiEnabled,
                        hasAiSession:
                            id != null && _aiSessions.containsKey(id),
                        currentLanguageCode: _langCode,
                        scale: 1.0,
                        onOptionTap: _onOptionTap,
                        onLongPress: () {},
                        onLongPressUp: () {},
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
                _NextButton(
                  enabled: _isAnswered && !_finishing,
                  label:
                      _isLastAction ? t.smart_result_continue : t.bcd_next,
                  onPressed: _advance,
                ),
              ],
            ),
        )); // PopScope + Scaffold
      }), // Builder
    ); // CupertinoScaffold
  }
}

// ── Pill-shaped progress bar (matches QuestionProgressHeader style) ───────────

class _PillProgressBar extends StatelessWidget {
  final int done;
  final int total;

  const _PillProgressBar({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final value = total <= 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    final visibleValue = value == 0 ? 0.0 : value.clamp(0.04, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    if (isIOS) {
      // iOS: thin, clean UIProgressView-style bar
      return Container(
        margin: const EdgeInsets.only(right: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: visibleValue,
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.grey.shade200,
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    // Android / Web: pill container
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: LinearProgressIndicator(
        value: visibleValue,
        minHeight: 10,
        borderRadius: BorderRadius.circular(10),
        backgroundColor:
            isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey[300],
        color: Theme.of(context).primaryColor,
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
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
