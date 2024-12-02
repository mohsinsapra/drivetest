// widgets/option_widget.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import '../models/option.dart';
import '../models/question.dart';

class OptionWidget extends StatefulWidget {
  final Option option;
  final Question question;
  final bool isSelected;
  final bool isInstantMarking;
  final String selectedOptionId;
  final Function(String) onSelectOption;
  final String licenceId;
  final String categoryId;
  final ApiService apiService;
  final String optionText;

  const OptionWidget({
    Key? key,
    required this.option,
    required this.question,
    required this.isSelected,
    required this.isInstantMarking,
    required this.selectedOptionId,
    required this.onSelectOption,
    required this.licenceId,
    required this.categoryId,
    required this.apiService,
    required this.optionText,
  }) : super(key: key);

  @override
  _OptionWidgetState createState() => _OptionWidgetState();
}

class _OptionWidgetState extends State<OptionWidget> {
  late Future<String> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _loadImage(widget.option.imageUrl);
  }

  @override
  void didUpdateWidget(covariant OptionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.option.imageUrl != widget.option.imageUrl) {
      _imageFuture = _loadImage(widget.option.imageUrl);
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
    final isCorrect =
        widget.option.optionLabel == widget.question.correctAnswer;

    Color backgroundColor = Colors.white;
    if (widget.isInstantMarking && widget.selectedOptionId.isNotEmpty) {
      if (widget.isSelected) {
        backgroundColor = isCorrect ? Colors.green[300]! : Colors.red[300]!;
      } else if (isCorrect) {
        backgroundColor = Colors.green[300]!;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        onTap: () => widget.onSelectOption(widget.option.optionLabel),
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
                widget.option.optionLabel,
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
                    if (widget.optionText.isNotEmpty)
                      Text(
                        widget.optionText,
                        style: const TextStyle(fontSize: 16),
                      ),
                    if (widget.option.imageUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: FutureBuilder<String>(
                          future: _imageFuture,
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
