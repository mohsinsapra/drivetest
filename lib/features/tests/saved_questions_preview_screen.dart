import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/features/tests/test_screen.dart';

class SavedQuestionsPreviewScreen extends StatelessWidget {
  final List<Question> questions;
  final String licenceId;
  final String categoryId;
  final String licenceName;
  final String categoryName;
  final int? bcdCategoryId;

  const SavedQuestionsPreviewScreen({
    super.key,
    required this.questions,
    required this.licenceId,
    required this.categoryId,
    required this.licenceName,
    required this.categoryName,
    this.bcdCategoryId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Questions')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${questions.length} saved question(s) in this category',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: questions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final q = questions[index];
                return ListTile(
                  tileColor: Colors.grey.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFFDBEAFE),
                    child: Text('${index + 1}',
                        style: const TextStyle(fontSize: 11)),
                  ),
                  title: Text(
                    q.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: q.questionId.isNotEmpty
                      ? Text('ID: ${q.questionId}',
                          maxLines: 1, overflow: TextOverflow.ellipsis)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: ElevatedButton.icon(
          onPressed: questions.isEmpty
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Testscreen(
                        questions: questions,
                        instantMarking: true,
                        licenceId: licenceId,
                        categoryId: categoryId,
                        licenceName: licenceName,
                        categoryName: '$categoryName • Saved',
                        bcdCategoryId: bcdCategoryId,
                        initiallySavedQuestionIds: questions
                            .map((q) => q.questionId)
                            .where((id) => id.isNotEmpty)
                            .toSet(),
                      ),
                    ),
                  );
                },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Saved Questions Test'),
        ),
      ),
    );
  }
}
