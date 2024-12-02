// widgets/question_widget.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import '../models/question.dart';

class QuestionWidget extends StatefulWidget {
  final Question question;
  final String licenceId;
  final String categoryId;
  final ApiService apiService;
  final String questionText;

  const QuestionWidget({
    Key? key,
    required this.question,
    required this.licenceId,
    required this.categoryId,
    required this.apiService,
    required this.questionText,
  }) : super(key: key);

  @override
  _QuestionWidgetState createState() => _QuestionWidgetState();
}

class _QuestionWidgetState extends State<QuestionWidget> {
  late Future<String> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _loadImage(widget.question.imageUrl);
  }

  @override
  void didUpdateWidget(covariant QuestionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.imageUrl != widget.question.imageUrl) {
      _imageFuture = _loadImage(widget.question.imageUrl);
    }
  }

  Future<String> _loadImage(String imagePath) async {
    try {
      final imageUrl = await widget.apiService.fetchImage(
        widget.licenceId,
        widget.categoryId,
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
        if (widget.questionText.isNotEmpty)
          Text(
            widget.questionText,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        if (widget.question.imageUrl.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Center(
              child: FutureBuilder<String>(
                future: _imageFuture,
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
