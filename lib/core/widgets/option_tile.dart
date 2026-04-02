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

  /// Layout scale factor — pass the screen-height-based `s` from the parent
  /// screen for responsive sizing. Defaults to 1.0 (no scaling).
  final double scale;

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
    this.scale = 1.0,
  });

  // --- Helper colour getters -------------------------------------------------
  Color _backgroundColor(BuildContext ctx) {
    if (!showInstantMarking) {
      return isSelected
          ? Theme.of(ctx).primaryColor.withValues(alpha: 0.1)
          : Colors.white;
    }
    // If this is the correct answer, always show green background
    if (isCorrectAnswer) {
      return Colors.green[50]!;
    }
    // If user selected this and it's wrong, show red background
    if (isSelected) {
      return Colors.red[50]!;
    }
    return Colors.white;
  }

  Color _borderColor(BuildContext ctx) {
    if (!showInstantMarking) {
      return isSelected ? Theme.of(ctx).primaryColor : Colors.grey[300]!;
    }
    if (isCorrectAnswer) return Colors.green[400]!;
    if (isSelected) return Colors.red[400]!;
    return Colors.grey[200]!;
  }

  double _borderWidth() {
    if (!showInstantMarking) return isSelected ? 1.0 : 0.5;
    return (isCorrectAnswer || isSelected) ? 2.0 : 0.5;
  }
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final s = scale;
    
    // Determine the icon and color for the bullet/indicator
    Widget? indicatorIcon;
    Color indicatorColor = Colors.transparent;
    Color indicatorBorderColor = Colors.grey[400]!;

    if (showInstantMarking) {
      if (isCorrectAnswer) {
        indicatorColor = Colors.green;
        indicatorBorderColor = Colors.green;
        indicatorIcon = Icon(Icons.check, size: 14 * s, color: Colors.white);
      } else if (isSelected) {
        indicatorColor = Colors.red;
        indicatorBorderColor = Colors.red;
        indicatorIcon = Icon(Icons.close, size: 14 * s, color: Colors.white);
      }
    } else if (isSelected) {
      indicatorColor = Theme.of(context).primaryColor;
      indicatorBorderColor = Theme.of(context).primaryColor;
      indicatorIcon = Icon(Icons.circle, size: 10 * s, color: Colors.white);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12 * s),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: 16 * s,
              vertical: 14 * s,
            ),
            decoration: BoxDecoration(
              color: _backgroundColor(context),
              border: Border.all(
                color: _borderColor(context),
                width: _borderWidth(),
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
                    // radio-style bullet or result icon
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24 * s,
                      height: 24 * s,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: indicatorColor,
                        border: Border.all(
                          color: indicatorBorderColor,
                          width: 2,
                        ),
                      ),
                      child: Center(child: indicatorIcon),
                    ),
                    SizedBox(width: 12 * s),

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
                                fontSize: 15 * s,
                                fontWeight: (isSelected || (showInstantMarking && isCorrectAnswer))
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: showInstantMarking
                                    ? (isCorrectAnswer 
                                        ? Colors.green[700] 
                                        : (isSelected ? Colors.red[700] : Colors.black87))
                                    : (isSelected
                                        ? Theme.of(context).primaryColor
                                        : Colors.black87),
                              ),
                            ),
                          ),
                          SizedBox(width: 6 * s),
                          TtsButton(
                            textToSpeak: text,
                            languageCode: languageCode,
                            iconSize: 18 * s,
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
                    margin: EdgeInsets.only(top: 10 * s),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl!,
                        width: double.infinity,
                        height: 110 * s,
                        fit: BoxFit.cover,
                        loadingBuilder: (c, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            width: double.infinity,
                            height: 110 * s,
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
                          height: 110 * s,
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
