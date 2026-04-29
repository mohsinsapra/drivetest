import 'package:taxi_exam_app/core/utils/app_page_route.dart';
// result_screen.dart
import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/features/tests/test_screen.dart';

class ResultScreen extends StatelessWidget {
  final List<Question> questions;
  final Map<int, String> userSelections;
  final String licenceId;
  final String categoryId;
  final bool hasPassed; // New parameter

  const ResultScreen({
    super.key,
    required this.questions,
    required this.userSelections,
    required this.licenceId,
    required this.categoryId,
    required this.hasPassed, // Initialize the new parameter
  });
  @override
  Widget build(BuildContext context) {
    int correctAnswers = 0;

    for (int i = 0; i < questions.length; i++) {
      final question = questions[i];
      final selectedOptionLabel = userSelections[i];

      if (selectedOptionLabel != null &&
          selectedOptionLabel == question.correctAnswer) {
        correctAnswers++;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Result: ${hasPassed ? 'Passed' : 'Failed'}',
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'You got $correctAnswers out of ${questions.length} correct!',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final question = questions[index];
                  final selectedOptionLabel = userSelections[index];
                  final isCorrect =
                      selectedOptionLabel == question.correctAnswer;

                  return Card(
                    child: ListTile(
                      title: Text('Question ${index + 1}: ${question.text}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Your Answer: ${selectedOptionLabel ?? 'No Answer'}'),
                          Text('Correct Answer: ${question.correctAnswer}'),
                        ],
                      ),
                      trailing: Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        color: isCorrect ? Colors.green : Colors.red,
                      ),
                      onTap: () {
                        // Navigate back to the question for review
                        Navigator.push(
                          context,
                          AppPageRoute(
                            builder: (context) => TestscreenWrapper(
                              questions: questions,
                              instantMarking: true,
                              licenceId: licenceId,
                              categoryId: categoryId,
                              initialQuestionIndex: index,
                              userSelections: userSelections,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
