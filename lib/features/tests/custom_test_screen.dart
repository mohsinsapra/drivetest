import 'package:flutter/material.dart';

class CreateCustomTestScreen extends StatefulWidget {
  final String categoryName;

  const CreateCustomTestScreen({super.key, required this.categoryName});

  @override
  State<CreateCustomTestScreen> createState() => _CreateCustomTestScreenState();
}

class _CreateCustomTestScreenState extends State<CreateCustomTestScreen> {
  bool isTimed = false;
  bool isInstantMarking = false;
  int numberOfQuestions = 10;
  bool includeSavedQuestions = false;

  void _onStartTest() {
    // Handle starting the test
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Starting test for category: ${widget.categoryName}\n'
          'Timed: $isTimed\n'
          'Instant Marking: $isInstantMarking\n'
          'Questions: $numberOfQuestions\n'
          'Include Saved: $includeSavedQuestions',
        ),
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
                    max: 100,
                    divisions: 99,
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
