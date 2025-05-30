import 'package:flutter/material.dart';
import 'tts_button.dart'; // ⬅️ update path if needed

class Option extends StatelessWidget {
  final String text;
  final String optionLabel;
  final String? imageUrl;

  /// `true` when the user tapped this option.
  final bool isSelected;

  /// Whether the test is in instant-marking mode *and* the user already
  /// chose something for this question.
  final bool showInstantMarking;

  /// If `showInstantMarking` is true, this decides the green (✔︎) or red (✘) colour.
  final bool isCorrectAnswer;

  /// Called when the tile is tapped.
  final VoidCallback onTap;

  /// ISO-639-1 code used by TTS (e.g. “en”, “sv” …)
  final String languageCode;

  const Option({
    super.key,
    required this.text,
    required this.optionLabel,
    this.imageUrl,
    required this.isSelected,
    required this.showInstantMarking,
    required this.isCorrectAnswer,
    required this.onTap,
    this.languageCode = 'sv',
  });

  // --- Helper colour getters -------------------------------------------------
  Color _backgroundColor(BuildContext ctx) {
    if (!showInstantMarking) {
      return isSelected
          ? Theme.of(ctx).primaryColor.withOpacity(0.1)
          : Colors.white;
    }
    if (isSelected) {
      return isCorrectAnswer ? Colors.green[100]! : Colors.red[100]!;
    }
    return isCorrectAnswer ? Colors.green[200]! : Colors.white;
  }

  Color _borderColor(BuildContext ctx) {
    if (!showInstantMarking) {
      return isSelected ? Theme.of(ctx).primaryColor : Colors.grey[300]!;
    }
    if (isCorrectAnswer) return Colors.green[200]!;
    if (isSelected) return Colors.red[200]!;
    return Colors.grey[200]!;
  }

  double _borderWidth() {
    if (!showInstantMarking) return isSelected ? 1.0 : 0.5;
    return (isCorrectAnswer || isSelected) ? 1.5 : 0.5;
  }
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
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
              color: _backgroundColor(context),
              border: Border.all(
                color: _borderColor(context),
                width: _borderWidth(),
              ),
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
                // ── label row ────────────────────────────────────────────────
                Row(
                  children: [
                    // radio-style bullet
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

                    // option text + TTS
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              text,
                              softWrap: true,
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
                            textToSpeak: text,
                            languageCode: languageCode,
                            iconSize: 20,
                            tooltip: 'Read option aloud',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // ── thumbnail (optional) ────────────────────────────────────
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
                        loadingBuilder: (c, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            width: double.infinity,
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
                                  value: progress.expectedTotalBytes != null
                                      ? progress.cumulativeBytesLoaded /
                                          progress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (c, _, __) => Container(
                          width: double.infinity,
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
                                      color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                        ),
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
