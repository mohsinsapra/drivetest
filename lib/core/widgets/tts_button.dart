import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:taxi_exam_app/core/services/tts_service.dart';

class TtsButton extends StatefulWidget {
  final String textToSpeak;
  final String languageCode;
  final double iconSize;
  final String tooltip;

  const TtsButton({
    super.key,
    required this.textToSpeak,
    required this.languageCode,
    this.iconSize = 22,
    this.tooltip = 'Read aloud',
  });

  @override
  State<TtsButton> createState() => _TtsButtonState();
}

class _TtsButtonState extends State<TtsButton> {
  final TtsService ttsService = TtsService();
  bool isSupported = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLanguageSupport();
  }

  Future<void> _checkLanguageSupport() async {
    final supported =
        await ttsService.isTtsLanguageSupported(widget.languageCode);
    setState(() {
      isSupported = supported;
      isLoading = false;
    });
  }

  void _toggleSpeech() async {
    await ttsService.speak(widget.textToSpeak, widget.languageCode, () {
      setState(() {}); // Refresh icon when state changes
    });
    setState(() {}); // Update icon immediately after tap
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || !isSupported) {
      return const SizedBox.shrink();
    }

    final bool isSpeaking = ttsService.ttsState == TtsState.playing;

    return IconButton(
      icon: Icon(
        LucideIcons.volume2,
        color: isSpeaking
            ? Theme.of(context).colorScheme.primary
            : Colors.blueGrey,
        size: widget.iconSize,
      ),
      tooltip: widget.tooltip,
      onPressed: _toggleSpeech,
    );
  }
}
