import 'dart:async'; // Import for TimeoutException
import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/features/tests/test_screen.dart';

class CreateCustomTestScreen extends StatefulWidget {
  final String categoryName;
  final String licenceId;
  final String categoryId;

  const CreateCustomTestScreen({
    Key? key,
    required this.categoryName,
    required this.licenceId,
    required this.categoryId,
  }) : super(key: key);

  @override
  State<CreateCustomTestScreen> createState() => _CreateCustomTestScreenState();
}

class _CreateCustomTestScreenState extends State<CreateCustomTestScreen>
    with WidgetsBindingObserver {
  bool isTimed = false;
  bool isInstantMarking = true;
  int numberOfQuestions = 10;
  bool includeSavedQuestions = false;
  final ApiService _apiService = ApiService();

  late TextEditingController _numberOfQuestionsController;

  bool _isLoadingDialogDisplayed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _numberOfQuestionsController =
        TextEditingController(text: numberOfQuestions.toString());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _numberOfQuestionsController.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // If the loading dialog is displayed, dismiss it
      if (_isLoadingDialogDisplayed && mounted) {
        Navigator.pop(context);
        _isLoadingDialogDisplayed = false;
      }
    }
  }

  void _onStartTest() async {
    // Show loading dialog
    _isLoadingDialogDisplayed = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    List<Question>? fetchedQuestions;

    try {
      // Fetch the questions with a timeout
      fetchedQuestions = await _apiService
          .fetchQuestions(
            widget.licenceId,
            widget.categoryId,
            pageSize: numberOfQuestions,
          )
          .timeout(const Duration(seconds: 15));

      // Check if questions are available
      if (fetchedQuestions == null || fetchedQuestions.isEmpty) {
        // Dismiss the loading dialog
        if (_isLoadingDialogDisplayed && mounted) {
          Navigator.pop(context);
          _isLoadingDialogDisplayed = false;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No questions available.'),
          ),
        );
        return;
      }
    } on TimeoutException catch (_) {
      // Dismiss the loading dialog
      if (_isLoadingDialogDisplayed && mounted) {
        Navigator.pop(context);
        _isLoadingDialogDisplayed = false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request timed out. Please try again.'),
        ),
      );
      return;
    } catch (e) {
      // Dismiss the loading dialog
      if (_isLoadingDialogDisplayed && mounted) {
        Navigator.pop(context);
        _isLoadingDialogDisplayed = false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start test: $e'),
        ),
      );
      return;
    } finally {
      // Ensure the loading dialog is dismissed
      if (_isLoadingDialogDisplayed && mounted) {
        Navigator.pop(context);
        _isLoadingDialogDisplayed = false;
      }
    }

    // Navigate to the test screen after the dialog is dismissed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Testscreen(
              questions: fetchedQuestions!,
              instantMarking: isInstantMarking,
              licenceId: widget.licenceId,
              categoryId: widget.categoryId,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const int maxQuestions =
        1000; // Set a consistent maximum number of questions

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
            child: const Text(
              'Start Test',
              style: TextStyle(color: Colors.white),
            ),
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
                    max: maxQuestions.toDouble(),
                    divisions: maxQuestions - 1,
                    label: '$numberOfQuestions',
                    onChanged: (value) {
                      setState(() {
                        numberOfQuestions = value.toInt();
                        _numberOfQuestionsController.text =
                            numberOfQuestions.toString();
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
                          controller: _numberOfQuestionsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'e.g. 10',
                          ),
                          onChanged: (value) {
                            final int? newValue = int.tryParse(value);
                            if (newValue != null &&
                                newValue > 0 &&
                                newValue <= maxQuestions) {
                              setState(() {
                                numberOfQuestions = newValue;
                              });
                            } else {
                              // Optionally handle invalid input
                            }
                          },
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
