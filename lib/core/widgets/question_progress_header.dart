import 'package:flutter/material.dart';

/// A tappable progress indicator used as the title in the Testscreen AppBar.
///
/// Shows a thin progress bar + the "current / total" counter.
/// Call [onTap] to open the question-navigation sheet.
class QuestionProgressHeader extends StatelessWidget {
  final int currentIndex; // zero-based
  final int total;
  final VoidCallback onTap;
  final bool showLabel;
  final double barHeight;

  const QuestionProgressHeader({
    super.key,
    required this.currentIndex,
    required this.total,
    required this.onTap,
    this.showLabel = true,
    this.barHeight = 10,
  });

  @override
  Widget build(BuildContext context) {
    final safeTotal = total <= 0 ? 1 : total;
    final rawProgress = (currentIndex + 1) / safeTotal;
    final progress = rawProgress.clamp(0.0, 1.0);
    final visibleProgress = progress == 0 ? 0.0 : progress.clamp(0.04, 1.0);

    final trackColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.grey[300]!;
    final fillColor = Theme.of(context).primaryColor;
    final radius = barHeight / 2;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showChevron = constraints.maxWidth > 110;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: SizedBox(
                    height: barHeight,
                    child: Stack(
                      children: [
                        Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: trackColor,
                            borderRadius: BorderRadius.circular(radius),
                          ),
                        ),
                        if (visibleProgress > 0)
                          FractionallySizedBox(
                            widthFactor: visibleProgress,
                            child: Container(
                              height: barHeight,
                              decoration: BoxDecoration(
                                color: fillColor,
                                borderRadius: BorderRadius.circular(radius),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (showLabel) ...[
                  const SizedBox(width: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${currentIndex + 1}/$safeTotal',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (showChevron) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
