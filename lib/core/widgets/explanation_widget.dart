// widgets/explanation_widget.dart
import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import '../models/question.dart';

class ExplanationWidget extends StatelessWidget {
  final Question question;
  final String licenceId;
  final String categoryId;
  final ApiService apiService;

  const ExplanationWidget({
    super.key,
    required this.question,
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
    if (question.answerExplanation.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text(
          'Explanation:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        FutureBuilder<String>(
          future: _loadImage(question.answerExplanation),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text(
                'Error loading image URL: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              );
            } else if (snapshot.hasData) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.network(
                    snapshot.data!,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            } else {
              return const Text('No image URL available.');
            }
          },
        ),
      ],
    );
  }
}
