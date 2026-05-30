import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TestTimerChip extends StatelessWidget {
  final ValueNotifier<int> timerNotifier;
  final bool visible;
  final VoidCallback onToggle;

  const TestTimerChip({
    super.key,
    required this.timerNotifier,
    required this.visible,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: timerNotifier,
      builder: (_, secs, __) {
        final isUrgent = secs <= 60 && visible;
        final primary = Theme.of(context).colorScheme.primary;
        final m = secs ~/ 60;
        final sec = secs % 60;
        final display =
            '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Center(
            child: GestureDetector(
              onTap: onToggle,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isUrgent
                      ? Colors.red.withValues(alpha: 0.1)
                      : primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      visible ? Icons.timer : Icons.timer_off_outlined,
                      size: 15,
                      color: isUrgent ? Colors.red : primary,
                    ),
                    if (visible) ...[
                      const SizedBox(width: 4),
                      Text(
                        display,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isUrgent ? Colors.red : primary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
