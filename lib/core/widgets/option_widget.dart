// widgets/option_widget.dart
import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import '../models/option.dart';
import '../models/question.dart';

class OptionWidget extends StatelessWidget {
  final Option option;
  final Question question;
  final bool isSelected;
  final bool isInstantMarking;
  final String selectedOptionId;
  final Function(String) onSelectOption;
  final String licenceId;
  final String categoryId;
  final ApiService apiService;

  const OptionWidget({
    super.key,
    required this.option,
    required this.question,
    required this.isSelected,
    required this.isInstantMarking,
    required this.selectedOptionId,
    required this.onSelectOption,
    required this.licenceId,
    required this.categoryId,
    required this.apiService,
  });

  Future<String> _loadImage(String imagePath) async {
    try {
      final imageUrl = await apiService.fetchImage(
        licenceId,
        categoryId,
        imagePath,
      );
      return imageUrl;
    } catch (e) {
      throw Exception('Failed to fetch image URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCorrect = option.optionLabel == question.correctAnswer;

    Color backgroundColor = Colors.white;
    if (isInstantMarking && selectedOptionId.isNotEmpty) {
      if (isSelected) {
        backgroundColor = isCorrect ? Colors.green[300]! : Colors.red[300]!;
      } else if (isCorrect) {
        backgroundColor = Colors.green[300]!;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        onTap: () => onSelectOption(option.optionLabel),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: Colors.grey[400]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                option.optionLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (option.text.isNotEmpty)
                      Text(
                        option.text,
                        style: const TextStyle(fontSize: 16),
                      ),
                    if (option.imageUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: FutureBuilder<String>(
                          future: _loadImage(option.imageUrl),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Text(
                                'Error loading image: ${snapshot.error}',
                                style: const TextStyle(color: Colors.red),
                              );
                            } else if (snapshot.hasData) {
                              return ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight:
                                      MediaQuery.of(context).size.height * 0.3,
                                ),
                                child: Image.network(
                                  snapshot.data!,
                                  fit: BoxFit.contain,
                                ),
                              );
                            } else {
                              return const Text('No image available.');
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
