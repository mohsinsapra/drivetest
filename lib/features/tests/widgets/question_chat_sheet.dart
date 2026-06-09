import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/widgets/app_loading_indicator.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/models/chat_message.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/core/services/ai_chat_service.dart';
import 'package:taxi_exam_app/core/widgets/ai_action_button.dart';

export 'package:taxi_exam_app/core/models/chat_message.dart' show ChatMessage;

enum _SuggestionType { hint, understand }

class QuestionChatSheet extends StatefulWidget {
  final Question question;

  /// Messages to restore when resuming a previous session.
  final List<ChatMessage> existingMessages;

  /// Display text shown in the user bubble (e.g. the button label).
  final String? initialDisplayText;

  /// Actual prompt sent to the AI — may differ from display text.
  final String? initialPrompt;

  /// Called when the sheet closes so the caller can persist the history.
  final void Function(List<ChatMessage> messages) onSaveSession;

  /// Called as soon as the first user message is sent — before the sheet closes.
  final VoidCallback? onFirstMessageSent;

  final String categoryName;
  final String licenceName;

  const QuestionChatSheet({
    super.key,
    required this.question,
    required this.onSaveSession,
    this.existingMessages = const [],
    this.initialDisplayText,
    this.initialPrompt,
    this.onFirstMessageSent,
    this.categoryName = '',
    this.licenceName = '',
  });

  @override
  State<QuestionChatSheet> createState() => _QuestionChatSheetState();
}

class _QuestionChatSheetState extends State<QuestionChatSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late final List<ChatMessage> _messages;
  AiChatService? _aiService;
  bool _initializing = true;
  bool _isSending = false;
  bool _firstMessageFired = false;
  static const Duration _kMinAssistantResponseDelay =
      Duration(milliseconds: 1500);

  // Typewriter animation state
  Timer? _typewriterTimer;
  static const int _kCharsPerTick = 4; // chars revealed per 16ms frame
  // Debounce scroll so we don't animate on every token.
  Timer? _scrollDebounce;
  // Suggestion chips shown above input — removed one-by-one as they're used.
  final Set<_SuggestionType> _availableSuggestions = {
    _SuggestionType.hint,
    _SuggestionType.understand,
  };

  @override
  void initState() {
    super.initState();
    _messages = List.of(widget.existingMessages);

    // Remove suggestions already used in restored session history
    for (final msg in _messages) {
      if (!msg.isUser) continue;
      final text = msg.text.toLowerCase();
      if (text.contains('hint') || text.contains('ledtråd')) {
        _availableSuggestions.remove(_SuggestionType.hint);
      }
      if (text.contains('understand') || text.contains('förstå')) {
        _availableSuggestions.remove(_SuggestionType.understand);
      }
    }

    if (widget.initialDisplayText != null) {
      final display = widget.initialDisplayText!.toLowerCase();
      if (display.contains('hint') || display.contains('ledtråd')) {
        _availableSuggestions.remove(_SuggestionType.hint);
      } else if (display.contains('understand') || display.contains('förstå')) {
        _availableSuggestions.remove(_SuggestionType.understand);
      }
    }

    _initService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_messages.isEmpty) {
      setState(() {
        _messages.add(ChatMessage(
          text: Translations.of(context).ai_greeting_full,
          isUser: false,
        ));
      });
    }
  }

  Future<void> _initService() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('language') ?? 'sv';
    final language = langCode == 'en' ? 'English' : 'Swedish';

    _aiService = AiChatService(
      questionId: widget.question.questionId,
      language: language,
    );

    if (!mounted) return;
    setState(() => _initializing = false);

    if (widget.initialPrompt != null) {
      await _sendText(
        display: widget.initialDisplayText ?? widget.initialPrompt!,
        prompt: widget.initialPrompt!,
      );
    }
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _scrollDebounce?.cancel();
    widget.onSaveSession(List.of(_messages));
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await _sendText(display: text, prompt: text);
  }

  void _useSuggestion(_SuggestionType type) {
    final t = Translations.of(context);
    final uiLang =
        LocaleSettings.currentLocale == AppLocale.sv ? 'Swedish' : 'English';
    final String display;
    final String prompt;
    if (type == _SuggestionType.hint) {
      display = t.ai_hint_button;
      prompt =
          'Give me a short hint that helps me figure out the answer without telling me directly. You MUST reply in $uiLang only.';
    } else {
      display = t.ai_understand_button;
      prompt =
          'Help me understand this question. Explain the concept it is testing and why the correct answer is right. You MUST reply in $uiLang only.';
    }
    setState(() => _availableSuggestions.remove(type));
    _sendText(display: display, prompt: prompt);
  }

  Future<void> _sendText({
    required String display,
    required String prompt,
  }) async {
    if (_aiService == null || _isSending) return;

    if (!_firstMessageFired) {
      _firstMessageFired = true;
      widget.onFirstMessageSent?.call();
    }

    final t = Translations.of(context);
    setState(() {
      _messages.add(ChatMessage(text: display, isUser: true));
      _messages.add(const ChatMessage(text: '', isUser: false)); // typing dots
      _isSending = true;
    });
    _scrollToBottom();

    String fullText;
    final responseWatch = Stopwatch()..start();
    try {
      fullText = await _aiService!.sendMessage(prompt, _messages);
      if (fullText.isEmpty) fullText = t.ai_error;
      responseWatch.stop();
      final remainingDelay =
          _kMinAssistantResponseDelay - responseWatch.elapsed;
      if (remainingDelay > Duration.zero) {
        await Future<void>.delayed(remainingDelay);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.last = ChatMessage(text: t.ai_error, isUser: false);
        _isSending = false;
      });
      return;
    }

    if (!mounted) return;

    // Typewriter: reveal fullText character by character
    int revealed = 0;
    _typewriterTimer?.cancel();
    _typewriterTimer =
        Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      revealed = min(revealed + _kCharsPerTick, fullText.length);
      final partial = fullText.substring(0, revealed);
      setState(() {
        _messages.last = ChatMessage(text: partial, isUser: false);
      });
      _scrollToBottom();
      if (revealed >= fullText.length) {
        timer.cancel();
        if (mounted) setState(() => _isSending = false);
      }
    });
  }

  void _scrollToBottom() {
    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(const Duration(milliseconds: 80), () {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final inputDisabled = _initializing || _isSending;

    final topPadding = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height - topPadding - 56,
      child: Material(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: theme.dividerColor, width: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: cs.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    t.ai_assistant,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      t.dash_smart_new.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.keyboard_arrow_down,
                        color: cs.onSurfaceVariant),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: t.ai_close,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // ── Messages ─────────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                itemCount: _messages.length,
                itemBuilder: (_, i) {
                  final msg = _messages[i];
                  final isTyping =
                      !msg.isUser && msg.text.isEmpty && _isSending;
                  return _Bubble(message: msg, isTyping: isTyping);
                },
              ),
            ),

            // ── Suggestion chips ─────────────────────────────────────────
            if (_availableSuggestions.isNotEmpty && !_isSending)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      if (_availableSuggestions.contains(_SuggestionType.hint))
                        AiActionButton(
                          label: t.ai_hint_button,
                          icon: Icons.lightbulb_outline,
                          onPressed: () => _useSuggestion(_SuggestionType.hint),
                        ),
                      if (_availableSuggestions
                          .contains(_SuggestionType.understand))
                        AiActionButton(
                          label: t.ai_understand_button,
                          icon: Icons.auto_awesome,
                          onPressed: () =>
                              _useSuggestion(_SuggestionType.understand),
                        ),
                    ],
                  ),
                ),
              ),

            // ── Input area ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(color: theme.dividerColor, width: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _controller,
                        enabled: !inputDisabled,
                        style: theme.textTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: _initializing
                              ? t.ai_initializing
                              : t.ai_input_hint,
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => _send(),
                        textInputAction: TextInputAction.send,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: inputDisabled ? null : _send,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: inputDisabled
                            ? cs.onSurface.withValues(alpha: 0.12)
                            : cs.primary,
                        shape: BoxShape.circle,
                      ),
                      child: inputDisabled
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: AppLoadingIndicator(
                                strokeWidth: 2,
                                color: cs.onSurface.withValues(alpha: 0.4),
                              ),
                            )
                          : Icon(Icons.arrow_forward,
                              color: cs.onPrimary, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom > 0
                    ? MediaQuery.viewInsetsOf(context).bottom
                    : MediaQuery.paddingOf(context).bottom + 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bubble ────────────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool isTyping;
  const _Bubble({required this.message, this.isTyping = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isUser = message.isUser;

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            message.text,
            style: theme.textTheme.bodyMedium?.copyWith(color: cs.onPrimary),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 8),
            child: Icon(Icons.auto_awesome, size: 16, color: cs.primary),
          ),
          Flexible(
            child: Container(
              margin: const EdgeInsets.only(bottom: 8, right: 48),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: isTyping
                  ? _TypingDots(color: cs.onSurfaceVariant)
                  : Text(
                      message.text,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: cs.onSurface),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Typing dots ───────────────────────────────────────────────────────────────

class _TypingDots extends StatefulWidget {
  final Color color;
  const _TypingDots({required this.color});
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
            3,
            (_) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                )),
      );
    }
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final phase = ((_ctrl.value - i * 0.25) % 1.0).clamp(0.0, 1.0);
              final y = phase < 0.5
                  ? Curves.easeOut.transform(phase * 2)
                  : 1.0 - Curves.easeIn.transform((phase - 0.5) * 2);
              return Transform.translate(
                offset: Offset(0, -4 * y),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.5 + 0.5 * y),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
