// widgets/question_widget.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import '../models/question.dart';

class QuestionWidget extends StatelessWidget {
  final Question question;
  final String licenceId;
  final String categoryId;
  final ApiService apiService;

  final String questionText; // Added parameter for translated text

  const QuestionWidget({
    super.key,
    required this.question,
    required this.licenceId,
    required this.categoryId,
    required this.apiService,
    required this.questionText, // Include in constructor
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (questionText
            .isNotEmpty) // Use questionText instead of question.text
          Text(
            questionText,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        if (question.imageUrl.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Center(
              child: FutureBuilder<String>(
                future: _loadImage(question.imageUrl),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text(
                      'Error loading image: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    );
                  } else if (snapshot.hasData) {
                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: CachedNetworkImage(
                        imageUrl: snapshot.data!,
                        placeholder: (context, url) =>
                            const CircularProgressIndicator(),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    );
                  } else {
                    return const Text('No image available.');
                  }
                },
              ),
            ),
          ),
      ],
    );
  }
}
