// test_screen.dart
import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/core/widgets/explanation_widget.dart';
import 'package:taxi_exam_app/core/widgets/option_widget.dart';
import 'package:taxi_exam_app/core/widgets/question_widget.dart';
import 'package:no_screenshot/no_screenshot.dart';

class Testscreen extends StatefulWidget {
  final List<Question> questions;
  final bool instantMarking;
  final String licenceId;
  final String categoryId;

  const Testscreen({
    super.key,
    required this.questions,
    required this.instantMarking,
    required this.licenceId,
    required this.categoryId,
  });

  @override
  State<Testscreen> createState() => _TestscreenState();
}

class _TestscreenState extends State<Testscreen> {
  int currentQuestionIndex = 0;
  String selectedOptionId = '';
  bool showExplanation = false;
  final _noScreenshot = NoScreenshot.instance;

  final ApiService _apiService = ApiService();

  void _selectOption(String optionId) {
    if (widget.instantMarking) {
      setState(() {
        selectedOptionId = optionId;
        showExplanation = true;
      });
    }
  }

  void _nextQuestion() {
    if (currentQuestionIndex < widget.questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedOptionId = '';
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
        selectedOptionId = '';
        showExplanation = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This is the first question!')),
      );
    }
  }

  void disableScreenshot() async {
    await _noScreenshot.screenshotOff();
    // debugPrint('Screenshot Off: $result');
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[currentQuestionIndex];
    // Clone the list to avoid mutating the original data

// Sort options by 'option_label' or any other key
    question.options.sort((a, b) => a.optionLabel.compareTo(b.optionLabel));
    disableScreenshot();
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Question ${currentQuestionIndex + 1} of ${widget.questions.length}'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Question Widget
              QuestionWidget(
                question: question,
                licenceId: widget.licenceId,
                categoryId: widget.categoryId,
                apiService: _apiService,
              ),
              const SizedBox(height: 16),
              // Options
              ...question.options.map((option) => OptionWidget(
                    option: option,
                    question: question,
                    isSelected: selectedOptionId == option.optionLabel,
                    isInstantMarking: widget.instantMarking,
                    selectedOptionId: selectedOptionId,
                    onSelectOption: _selectOption,
                    licenceId: widget.licenceId,
                    categoryId: widget.categoryId,
                    apiService: _apiService,
                  )),
              // Explanation
              if (showExplanation)
                ExplanationWidget(
                  question: question,
                  licenceId: widget.licenceId,
                  categoryId: widget.categoryId,
                  apiService: _apiService,
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 32.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
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
        ),
      ),
    );
  }
}
