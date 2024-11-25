// models/question.dart

import 'package:taxi_exam_app/core/models/option.dart';

class Question {
  final String text;
  final String imageUrl;
  final String correctAnswer;
  final String answerExplanation;
  final List<Option> options;

  Question({
    required this.text,
    required this.imageUrl,
    required this.correctAnswer,
    required this.answerExplanation,
    required this.options,
  });

  factory Question.fromMap(
      Map<String, dynamic> map, String Function(String? field) decryptField) {
    return Question(
      text: map['text'] ?? '',
      imageUrl: map['image_url'] ?? '',
      correctAnswer: map['correct_answer'] ?? '',
      answerExplanation: map['answer_explanation'] ?? '',
      options: List<Option>.from(
        (map['options'] ?? []).map((option) => Option.fromMap(option)),
      ),
    );
  }
}
