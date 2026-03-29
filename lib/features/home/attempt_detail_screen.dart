import 'package:taxi_exam_app/core/utils/app_page_route.dart';
// attempt_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';
import 'package:taxi_exam_app/features/tests/test_screen.dart';

class AttemptDetailScreen extends StatelessWidget {
  final TestAttempt attempt;

  const AttemptDetailScreen({super.key, required this.attempt});

  @override
  Widget build(BuildContext context) {
    final questions = attempt.questions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attempt Details'),
      ),
      body: ListView.builder(
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final question = questions[index];
          final userAnswer = attempt.userSelections[index];
          final isCorrect = userAnswer == question.correctAnswer;

          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text('Question ${index + 1}: ${question.text}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text('Your Answer: $userAnswer'),
                  Text(
                    'Correct Answer: ${question.correctAnswer}',
                    style: TextStyle(
                      color: isCorrect ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              onTap: () {
                // Open Testscreen at the selected question
                Navigator.push(
                  context,
                  AppPageRoute(
                    builder: (context) => Testscreen(
                      questions: questions,
                      instantMarking: true, // Enable instant marking for review
                      licenceId: '', // Pass appropriate values
                      categoryId: '',
                      initialQuestionIndex: index,
                      userSelections: attempt.userSelections,
                      isReviewMode: true, // Set review mode
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
