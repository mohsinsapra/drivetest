// models/question.dart

import 'package:hive/hive.dart';
import 'package:taxi_exam_app/core/models/option.dart';
part 'question.g.dart';

@HiveType(typeId: 1)
class Question extends HiveObject {
  @HiveField(0)
  final String text;
  @HiveField(1)
  final String imageUrl;
  @HiveField(2)
  final String correctAnswer;
  @HiveField(3)
  final String answerExplanation;
  @HiveField(4)
  final List<Option> options;
  @HiveField(5)
  final String questionId;
  @HiveField(6)
  final List<String> images;

  Question({
    required this.text,
    required this.imageUrl,
    required this.correctAnswer,
    required this.answerExplanation,
    required this.options,
    this.questionId = '',
    this.images = const [],
  });

  factory Question.fromMap(
      Map<String, dynamic> map, String Function(String? field) decryptField) {
    return Question(
      text: map['text'] ?? '',
      imageUrl: map['image_url'] ?? '',
      correctAnswer: map['correct_answer'] ?? '',
      answerExplanation: map['answer_explanation'] ?? '',
      questionId: map['question_id']?.toString() ?? '',
      options: List<Option>.from(
        (map['options'] ?? []).map((option) => Option.fromMap(option)),
      ),
    );
  }

    Question copyWith({String? text, List<Option>? options, String? answerExplanation}) => Question(
        text: text ?? this.text,
        options: options ?? this.options,
        imageUrl: imageUrl,
        images: images,
        correctAnswer: correctAnswer,
        answerExplanation: answerExplanation ?? this.answerExplanation,
        questionId: questionId,
      );
}
