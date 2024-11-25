import 'package:flutter/material.dart';

class Testscreen extends StatefulWidget {
  final List<dynamic> questions;
  final bool instantMarking;

  const Testscreen({
    super.key,
    required this.questions,
    required this.instantMarking,
  });

  @override
  State<Testscreen> createState() => _TestscreenState();
}

class _TestscreenState extends State<Testscreen> {
  int currentQuestionIndex = 0;
  String? selectedOptionId;
  bool showExplanation = false;

  void _selectOption(String optionId) {
    if (widget.instantMarking) {
      final correctAnswerId =
          widget.questions[currentQuestionIndex]['correct_answer'];
      setState(() {
        selectedOptionId = optionId;
        showExplanation = true;
      });

      // Add a delay for visual feedback when incorrect
      // if (optionId != correctAnswerId) {
      //   Future.delayed(const Duration(milliseconds: 500), () {
      //     if (mounted) {
      //       setState(() {
      //         selectedOptionId = null;
      //       });
      //     }
      //   });
      // }
    }
  }

  void _nextQuestion() {
    if (currentQuestionIndex < widget.questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedOptionId = null;
        showExplanation = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have reached the end of the quiz!')),
      );
    }
  }

  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
        selectedOptionId = null;
        showExplanation = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This is the first question!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[currentQuestionIndex];
    final options = question['options'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Question ${currentQuestionIndex + 1} of ${widget.questions.length}'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              question['text'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = selectedOptionId == option['option_label'];
                  final isCorrect =
                      option['option_label'] == question['correct_answer'];

                  Color backgroundColor = Colors.white;
                  if (widget.instantMarking && selectedOptionId != null) {
                    if (isSelected) {
                      backgroundColor =
                          isCorrect ? Colors.green[300]! : Colors.red[300]!;
                    } else if (isCorrect) {
                      backgroundColor = Colors.green[100]!;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: GestureDetector(
                      onTap: () => _selectOption(option['option_label']),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text(
                              option['option_label'],
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                option['text'],
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (showExplanation && question['answer_explanation'] != null) ...[
              const Divider(),
              const Text(
                'Explanation:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                question['answer_explanation'],
                style: const TextStyle(fontSize: 14),
              ),
            ],
            const Divider(),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly, // Space buttons evenly
              children: [
                ElevatedButton(
                  onPressed: _previousQuestion,
                  child: const Text('Back'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('EN/SV'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Save'),
                ),
                ElevatedButton(
                  onPressed: _nextQuestion,
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
