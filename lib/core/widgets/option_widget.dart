import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/widgets/tts_button.dart';

class OptionWidget extends StatelessWidget {
  final String optionText;
  final String optionLabel;
  final String correctAnswer;
  final String? imageUrl;
  final String currentLanguageCode;
  final bool isSelected;
  final bool instantMarking;
  final VoidCallback onTap;

  const OptionWidget({
    super.key,
    required this.optionText,
    required this.optionLabel,
    required this.correctAnswer,
    this.imageUrl,
    required this.currentLanguageCode,
    required this.isSelected,
    required this.instantMarking,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCorrect = optionLabel == correctAnswer;

    final backgroundColor = instantMarking
        ? (isSelected
            ? (isCorrect ? Colors.green[100] : Colors.red[100])
            : (isCorrect ? Colors.green[100] : Colors.white))
        : (isSelected
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Colors.white);

    final borderColor = instantMarking
        ? (isCorrect
            ? Colors.green[200]!
            : isSelected
                ? Colors.red[200]!
                : Colors.grey[100]!)
        : (isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!);

    final borderWidth = instantMarking
        ? ((isCorrect || isSelected) ? 1.5 : 0.5)
        : (isSelected ? 1 : 0.5);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: backgroundColor,
              border:
                  Border.all(color: borderColor, width: borderWidth.toDouble()),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Circle
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey[400]!,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.circle,
                              size: 12, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    // Text + TTS
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              optionText,
                              softWrap: true,
                              overflow: TextOverflow.visible,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TtsButton(
                            textToSpeak: optionText,
                            languageCode: currentLanguageCode,
                            iconSize: 20,
                            tooltip: 'Read option aloud',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (imageUrl != null && imageUrl!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl!,
                        width: double.infinity,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported,
                                    size: 24, color: Colors.grey[400]),
                                const SizedBox(height: 4),
                                Text('Image not available',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600])),
                              ],
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
