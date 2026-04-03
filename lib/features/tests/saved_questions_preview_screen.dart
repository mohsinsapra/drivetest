import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/core/router/route_args.dart';
import 'package:taxi_exam_app/core/router/route_names.dart';
import 'package:taxi_exam_app/core/services/saved_questions_service.dart';

class SavedQuestionsPreviewScreen extends StatefulWidget {
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
  State<SavedQuestionsPreviewScreen> createState() =>
      _SavedQuestionsPreviewScreenState();
}

class _SavedQuestionsPreviewScreenState
    extends State<SavedQuestionsPreviewScreen> {
  late List<Question> _questions;
  final Set<String> _expandedKeys = <String>{};

  String _itemKey(Question q, int index) =>
      q.questionId.isNotEmpty ? q.questionId : 'idx_$index';

  String _correctAnswerText(Question q) {
    final matches = q.options.where((o) => o.optionLabel == q.correctAnswer);
    if (matches.isNotEmpty) {
      return matches.first.text;
    }
    return q.correctAnswer;
  }

  @override
  void initState() {
    super.initState();
    _questions = List<Question>.from(widget.questions);
  }

  Future<void> _unsaveWithUndo(int index) async {
    if (index < 0 || index >= _questions.length) return;
    final q = _questions[index];
    if (q.questionId.isEmpty) return;

    final isSaved = await SavedQuestionsService.toggleSavedScoped(
      q.questionId,
      questionText: q.text,
      licenceId: widget.licenceId,
      categoryId: widget.categoryId,
      bcdCategoryId: widget.bcdCategoryId,
    );

    if (!mounted) return;
    if (isSaved) return;

    setState(() {
      _expandedKeys.remove(_itemKey(q, index));
      _questions.removeAt(index);
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Question removed from saved'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            final restored = await SavedQuestionsService.toggleSavedScoped(
              q.questionId,
              questionText: q.text,
              licenceId: widget.licenceId,
              categoryId: widget.categoryId,
              bcdCategoryId: widget.bcdCategoryId,
            );
            if (!mounted || !restored) return;
            setState(() {
              final insertAt = index.clamp(0, _questions.length);
              _questions.insert(insertAt, q);
            });
          },
        ),
      ),
    );
  }

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
              '${_questions.length} saved question(s) in this category',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: _questions.isEmpty
                ? Center(
                    child: Text(
                      'No saved questions in this category.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _questions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final q = _questions[index];
                      final answerText = _correctAnswerText(q);
                      final key = _itemKey(q, index);
                      final expanded = _expandedKeys.contains(key);
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            setState(() {
                              if (expanded) {
                                _expandedKeys.remove(key);
                              } else {
                                _expandedKeys.add(key);
                              }
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: const Color(0xFFDBEAFE),
                                      child: Text('${index + 1}',
                                          style: const TextStyle(fontSize: 11)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        q.text,
                                        maxLines: expanded ? null : 2,
                                        overflow: expanded
                                            ? TextOverflow.visible
                                            : TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Unsave',
                                      icon: const Icon(
                                          Icons.bookmark_remove_outlined),
                                      onPressed: () => _unsaveWithUndo(index),
                                    ),
                                    Icon(
                                      expanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: Colors.grey.shade600,
                                    ),
                                  ],
                                ),
                                if (answerText.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0FDF4),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: const Color(0xFFBBF7D0)),
                                    ),
                                    child: Text(
                                      'Correct answer: $answerText',
                                      style: const TextStyle(
                                        color: Color(0xFF166534),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                                if (expanded) ...[
                                  const SizedBox(height: 10),
                                  Divider(
                                      color: Colors.grey.shade300, height: 1),
                                  const SizedBox(height: 10),
                                  Text(
                                    q.answerExplanation.isNotEmpty
                                        ? q.answerExplanation
                                        : 'No explanation available.',
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: ElevatedButton.icon(
          onPressed: _questions.isEmpty
              ? null
              : () {
                  context.push(Routes.test, extra: TestScreenArgs(
                    questions: _questions,
                    instantMarking: true,
                    licenceId: widget.licenceId,
                    categoryId: widget.categoryId,
                    licenceName: widget.licenceName,
                    categoryName: '${widget.categoryName} • Saved',
                    bcdCategoryId: widget.bcdCategoryId,
                    initiallySavedQuestionIds: _questions
                        .map((q) => q.questionId)
                        .where((id) => id.isNotEmpty)
                        .toSet(),
                  ));
                },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Saved Questions Test'),
        ),
      ),
    );
  }
}
