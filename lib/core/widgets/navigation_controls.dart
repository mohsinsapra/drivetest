import 'package:flutter/material.dart';

/// Bottom bar with "Back" and "Next / Finish" buttons.
///
/// Relies on the parent to tell it:
///  * whether we're at the first/last question
///  * what text should appear on the primary button
///  * two callbacks for the taps
class NavigationControls extends StatelessWidget {
  final bool atFirst;
  final bool atLast;
  final VoidCallback onBack;
  final VoidCallback onNextOrFinish;

  const NavigationControls({
    super.key,
    required this.atFirst,
    required this.atLast,
    required this.onBack,
    required this.onNextOrFinish,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Buttons bar ───────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          color: cardColor,
          child: Row(
            children: [
              // ── BACK ────────────────────────────────────────────────────
              Expanded(
                child: OutlinedButton(
                  onPressed: atFirst ? null : onBack,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    side: BorderSide(
                      color: atFirst
                          ? Theme.of(context).dividerColor
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: atFirst
                          ? Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.35)
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // ── NEXT / FINISH ────────────────────────────────────────────
              Expanded(
                child: ElevatedButton(
                  onPressed: onNextOrFinish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    atLast ? 'Finish' : 'Next',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Gradient overlaps 40dp UP into the scroll content above ───────
        Positioned(
          top: -40,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [cardColor, cardColor.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
