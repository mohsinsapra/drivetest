import 'package:flutter/material.dart';

import 'package:lucide_icons/lucide_icons.dart';
import 'package:taxi_exam_app/core/services/tts_service.dart';

class TtsButton extends StatelessWidget {
  final String textToSpeak;
  final String languageCode;
  final double iconSize;
  final String tooltip;

  const TtsButton({
    Key? key,
    required this.textToSpeak,
    required this.languageCode,
    this.iconSize = 22,
    this.tooltip = 'Read aloud',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ttsService = TtsService();

    if (!ttsService.isTtsLanguageSupported(languageCode)) {
      return const SizedBox.shrink(); // Return empty if not supported
    }

    return IconButton(
      icon: Icon(
        LucideIcons.volume2,
        color: Colors.blueGrey,
        size: iconSize,
      ),
      tooltip: tooltip,
      onPressed: () {
        ttsService.speak(textToSpeak, languageCode, () {});
      },
    );
  }
}
