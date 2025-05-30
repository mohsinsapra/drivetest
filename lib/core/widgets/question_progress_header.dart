import 'package:flutter/material.dart';

/// A tappable progress indicator used as the title in the Testscreen AppBar.
///
/// Shows a thin progress bar + the “current / total” counter.
/// Call [onTap] to open the question-navigation sheet.
class QuestionProgressHeader extends StatelessWidget {
  final int currentIndex;       // zero-based
  final int total;
  final VoidCallback onTap;

  const QuestionProgressHeader({
    super.key,
    required this.currentIndex,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentIndex + 1) / total;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── slim bar ────────────────────────────────────────────────────
            Container(
              width: 100,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // ── “x / n” counter ────────────────────────────────────────────
            Text(
              '${currentIndex + 1}/$total',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Colors.grey[500],
            ),
          ],
        ),
      ),
    );
  }
}
