import 'package:flutter/material.dart';

class QuestionNavigationGrid extends StatelessWidget {
  final int questionCount;
  final Map<int, String> userSelections;
  final int currentIndex;
  final void Function(int index) onTap;

  const QuestionNavigationGrid({
    super.key,
    required this.questionCount,
    required this.userSelections,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemCount: questionCount,
      itemBuilder: (ctx, index) {
        final isAnswered = userSelections[index] != null;
        final isCurrent = index == currentIndex;
        final primary = Theme.of(ctx).colorScheme.primary;
        return GestureDetector(
          onTap: () => onTap(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isCurrent
                  ? primary
                  : isAnswered
                      ? Colors.green.withValues(alpha: 0.12)
                      : Theme.of(ctx)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCurrent
                    ? primary
                    : isAnswered
                        ? Colors.green.withValues(alpha: 0.4)
                        : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.none,
                    color: isCurrent
                        ? Colors.white
                        : isAnswered
                            ? Colors.green
                            : Theme.of(ctx)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                  ),
                ),
                if (isAnswered && !isCurrent)
                  const Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 10,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
