// widgets/question_widget.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import '../models/question.dart';

class QuestionWidget extends StatefulWidget {
  final Question question;
  final String licenceId;
  final String categoryId;
  final ApiService apiService;
  final String questionText;

  const QuestionWidget({
    super.key,
    required this.question,
    required this.licenceId,
    required this.categoryId,
    required this.apiService,
    required this.questionText,
  });

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
                    final imageUrl = snapshot.data!;
                    return GestureDetector(
                      onTap: () {
                        showGeneralDialog(
                          context: context,
                          barrierColor:
                              Colors.black, // Ensures FULL black overlay
                          barrierDismissible: true,
                          barrierLabel: "Image Viewer",
                          pageBuilder:
                              (context, animation, secondaryAnimation) {
                            return Scaffold(
                              backgroundColor: Colors.black,
                              body: SafeArea(
                                child: Stack(
                                  children: [
                                    PhotoView(
                                      imageProvider: NetworkImage(imageUrl),
                                      backgroundDecoration: const BoxDecoration(
                                          color: Colors.black),
                                      minScale:
                                          PhotoViewComputedScale.contained,
                                      maxScale:
                                          PhotoViewComputedScale.covered * 2.0,
                                      loadingBuilder: (context, _) =>
                                          const Center(
                                              child:
                                                  CircularProgressIndicator()),
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Center(
                                                  child: Icon(Icons.error,
                                                      color: Colors.white)),
                                    ),
                                    Positioned(
                                      top: 20,
                                      right: 20,
                                      child: IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.white, size: 30),
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.4,
                          maxWidth: MediaQuery.of(context).size.width * 0.9,
                        ),
                        child: Image.network(imageUrl, fit: BoxFit.contain),
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
