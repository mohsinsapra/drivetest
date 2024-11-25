import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/features/tests/test_screen.dart';

class CreateCustomTestScreen extends StatefulWidget {
  final String categoryName;
  final String licenceId;
  final String categoryId;

  const CreateCustomTestScreen({
    super.key,
    required this.categoryName,
    required this.licenceId,
    required this.categoryId,
  });
  @override
  State<CreateCustomTestScreen> createState() => _CreateCustomTestScreenState();
}

class _CreateCustomTestScreenState extends State<CreateCustomTestScreen> {
  bool isTimed = false;
  bool isInstantMarking = true;
  int numberOfQuestions = 10;
  bool includeSavedQuestions = false;
  final ApiService _apiService = ApiService();

  void _onStartTest() async {
    // Handle starting the test

    final fetchedQuestions = await _apiService.fetchQuestions(
        widget.licenceId, widget.categoryId,
        pageSize: numberOfQuestions);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Testscreen(
            questions: fetchedQuestions, // List of questions from API
            instantMarking:
                isInstantMarking, // Enable or disable instant marking
            licenceId: widget.licenceId,
            categoryId: widget.licenceId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.categoryName),
        actions: [
          TextButton(
            onPressed: _onStartTest,
            child: const Text('Start Test'),
          ),
        ],
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            SwitchListTile(
              title: const Text('Timed Test'),
              subtitle: const Text('Enable a time limit for the test'),
              value: isTimed,
              onChanged: (value) {
                setState(() {
                  isTimed = value;
                });
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Instant Marking'),
              subtitle: const Text('Show correct answer after each question'),
              value: isInstantMarking,
              onChanged: (value) {
                setState(() {
                  isInstantMarking = value;
                });
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Number of Questions'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Slider(
                    value: numberOfQuestions.toDouble(),
                    min: 1,
                    max: 1000,
                    divisions: 999,
                    label: '$numberOfQuestions',
                    onChanged: (value) {
                      setState(() {
                        numberOfQuestions = value.toInt();
                      });
                    },
                  ),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Enter number of questions:'),
                      ),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'e.g. 10',
                          ),
                          onChanged: (value) {
                            final int? newValue = int.tryParse(value);
                            if (newValue != null &&
                                newValue > 0 &&
                                newValue <= 100) {
                              setState(() {
                                numberOfQuestions = newValue;
                              });
                            }
                          },
                          controller: TextEditingController(
                            text: numberOfQuestions.toString(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Include Saved Questions'),
              subtitle: const Text('Include questions you previously saved'),
              value: includeSavedQuestions,
              onChanged: (value) {
                setState(() {
                  includeSavedQuestions = value;
                });
              },
            ),
            const Divider(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _onStartTest,
              child: const Text('Start Test'),
            ),
          ],
        ),
      ),
    );
  }
}
