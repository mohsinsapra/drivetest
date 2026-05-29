import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:taxi_exam_app/core/models/option.dart';

class QuestionTabContext {
  final String title;
  final String text;
  final List<Uint8List> images;
  const QuestionTabContext({
    required this.title,
    required this.text,
    required this.images,
  });
}

class AiChatService {
  late final ChatSession _chat;

  AiChatService._();

  static Future<AiChatService> forQuestion({
    required String questionText,
    required List<Option> options,
    required String correctAnswer,
    required String explanation,
    List<Uint8List> images = const [],
    List<QuestionTabContext> tabs = const [],
    String defaultLanguage = 'Swedish',
  }) async {
    final service = AiChatService._();
    await service._init(
      questionText: questionText,
      options: options,
      correctAnswer: correctAnswer,
      explanation: explanation,
      images: images,
      tabs: tabs,
      defaultLanguage: defaultLanguage,
    );
    return service;
  }

  Future<void> _init({
    required String questionText,
    required List<Option> options,
    required String correctAnswer,
    required String explanation,
    required List<Uint8List> images,
    required List<QuestionTabContext> tabs,
    String defaultLanguage = 'Swedish',
  }) async {
    final model = GenerativeModel(
      model: 'gemini-3.1-flash-lite',
      apiKey: _resolveApiKey(),
      systemInstruction: Content.system(
        'You are a teacher who ONLY explains the specific taxi exam question provided. '
        'You NEVER discuss anything outside of this question — no other topics, no general chat. '
        'If the user asks about anything unrelated, always reply in $defaultLanguage: '
        '"I can only help you with this question." '
        'LANGUAGE RULE: Your default reply language is $defaultLanguage. '
        'However, if the user writes their message in a different language, '
        'detect that language and reply in it instead — no exceptions. '
        'Keep answers short and clear (2–4 sentences).',
      ),
    );

    final optionsText = options
        .map((o) => '${o.optionLabel.toUpperCase()}) ${_stripHtml(o.text)}')
        .join('\n');

    final tabsText = tabs.isNotEmpty
        ? '\n\n${tabs.map((t) => 'Tab "${t.title}":\n${_stripHtml(t.text)}').join('\n\n')}'
        : '';

    final contextParts = <Part>[
      TextPart(
        'Question: ${_stripHtml(questionText)}\n\n'
        'Answer options:\n$optionsText\n\n'
        'Correct answer: ${correctAnswer.toUpperCase()}\n\n'
        'Explanation: ${_stripHtml(explanation)}'
        '$tabsText',
      ),
    ];

    for (final bytes in images) {
      contextParts.add(DataPart('image/jpeg', bytes));
    }

    for (final tab in tabs) {
      if (tab.images.isEmpty) continue;
      contextParts.add(TextPart(
        'The following image(s) are from the background tab "${tab.title}" '
        '— they provide situational context for the question, not the question itself.',
      ));
      for (final bytes in tab.images) {
        contextParts.add(DataPart('image/jpeg', bytes));
      }
    }

    // Seed context without biasing response language — the system prompt
    // handles language detection from the user's first message.
    _chat = model.startChat(history: [
      Content.multi(contextParts),
      Content.model([TextPart('I understand the question. What would you like to know?')]),
    ]);
  }

  int _lastExchangeTokens = 0;

  /// Token count reported by the last completed exchange.
  /// Falls back to 0 if usageMetadata is unavailable in streaming mode.
  int get lastExchangeTokens => _lastExchangeTokens;

  Stream<String> sendMessage(String userMessage) async* {
    _lastExchangeTokens = 0;
    final response = _chat.sendMessageStream(Content.text(userMessage));
    GenerateContentResponse? lastChunk;
    await for (final chunk in response) {
      lastChunk = chunk;
      final text = chunk.text;
      if (text != null) yield text;
    }
    _lastExchangeTokens = lastChunk?.usageMetadata?.totalTokenCount ?? 0;
  }

  // On web dotenv is not loaded — use dart-define injected value instead.
  // On native (iOS/Android) dotenv is loaded — read from there.
  static String _resolveApiKey() {
    const dartDefine = String.fromEnvironment('GEMINI_API_KEY');
    if (dartDefine.isNotEmpty) return dartDefine;
    if (!kIsWeb) {
      try {
        return dotenv.env['GEMINI_API_KEY'] ?? '';
      } catch (_) {}
    }
    return '';
  }

  static String _stripHtml(String html) => html
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&ouml;', 'ö')
      .replaceAll('&aring;', 'å')
      .replaceAll('&auml;', 'ä')
      .replaceAll('&Ouml;', 'Ö')
      .replaceAll('&Aring;', 'Å')
      .replaceAll('&Auml;', 'Ä')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
