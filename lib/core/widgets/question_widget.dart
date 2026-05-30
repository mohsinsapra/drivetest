import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/models/image_viewer.dart';
import 'package:taxi_exam_app/core/widgets/tts_button.dart';

class QuestionHeaderWidget extends StatelessWidget {
  final String questionText;
  final String questionImageUrl;
  final String currentLanguageCode;

  const QuestionHeaderWidget({
    super.key,
    required this.questionText,
    required this.questionImageUrl,
    required this.currentLanguageCode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.3,
            ),
            children: [
              TextSpan(text: '$questionText '),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: TtsButton(
                  textToSpeak: questionText,
                  languageCode: currentLanguageCode,
                  iconSize: 24,
                  tooltip: 'Read aloud',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (questionImageUrl.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GestureDetector(
                onTap: () => showImageViewer(context, [questionImageUrl]),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                  ),
                  child: CachedNetworkImage(
                    imageUrl: questionImageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
