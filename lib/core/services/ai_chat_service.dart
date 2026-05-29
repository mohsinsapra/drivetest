import 'package:taxi_exam_app/core/api/dio_client.dart';
import 'package:taxi_exam_app/core/models/chat_message.dart';

class AiChatService {
  final String questionId;
  final String language;

  AiChatService({required this.questionId, required this.language});

  Future<String> sendMessage(String message, List<ChatMessage> history) async {
    final dio = DioClient().dio;

    final historyPayload = history
        .where((m) => m.text.isNotEmpty)
        .map((m) => {'text': m.text, 'isUser': m.isUser})
        .toList();

    final response = await dio.post<Map<String, dynamic>>(
      'api/v2/ai/chat/',
      data: {
        'question_id': questionId,
        'message': message,
        'language': language,
        'history': historyPayload,
      },
    );

    return (response.data?['response'] as String?) ?? '';
  }
}
