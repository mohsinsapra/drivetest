import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/widgets/app_button.dart';

class TutorialCompleteOverlay extends StatefulWidget {
  final VoidCallback onDone;

  const TutorialCompleteOverlay({super.key, required this.onDone});

  @override
  State<TutorialCompleteOverlay> createState() =>
      _TutorialCompleteOverlayState();
}

class _TutorialCompleteOverlayState extends State<TutorialCompleteOverlay>
    with SingleTickerProviderStateMixin {
  // Single controller: sheet slides up first (0→0.28), content staggers (0.28→1.0).
  late final AnimationController _ctrl;

  late final Animation<Offset> _sheetSlide;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconFade;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _bodyFade;
  late final Animation<Offset> _bodySlide;
  late final Animation<double> _subtitleFade;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _buttonFade;
  late final Animation<Offset> _buttonSlide;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    Animation<double> curved(double begin, double end, Curve curve) =>
        CurvedAnimation(
            parent: _ctrl, curve: Interval(begin, end, curve: curve));

    const upStart = Offset(0, 0.18);

    _sheetSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0, 0.28, curve: Curves.easeOutCubic)));

    _iconFade = curved(0.22, 0.40, Curves.easeOut);
    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.22, 0.45, curve: Curves.elasticOut)));

    _titleFade = curved(0.40, 0.55, Curves.easeOut);
    _titleSlide = Tween<Offset>(begin: upStart, end: Offset.zero).animate(
        CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.40, 0.55, curve: Curves.easeOutCubic)));

    _bodyFade = curved(0.52, 0.67, Curves.easeOut);
    _bodySlide = Tween<Offset>(begin: upStart, end: Offset.zero).animate(
        CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.52, 0.67, curve: Curves.easeOutCubic)));

    _subtitleFade = curved(0.63, 0.78, Curves.easeOut);
    _subtitleSlide = Tween<Offset>(begin: upStart, end: Offset.zero).animate(
        CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.63, 0.78, curve: Curves.easeOutCubic)));

    _buttonFade = curved(0.78, 1.0, Curves.easeOut);
    _buttonSlide = Tween<Offset>(begin: upStart, end: Offset.zero).animate(
        CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.78, 1.0, curve: Curves.easeOutCubic)));

    _ctrl.forward();
  }

  void _dismiss() {
    _ctrl.reverse().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _staggered({
    required Animation<double> fade,
    required Animation<Offset> slide,
    required Widget child,
  }) {
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Translations.of(context);
    final hPad = (MediaQuery.of(context).size.width * 0.07).clamp(20.0, 52.0);

    return SlideTransition(
      position: _sheetSlide,
      child: Container(
        color: cs.surface,
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _iconFade,
                    child: ScaleTransition(
                      scale: _iconScale,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.primary.withValues(alpha: 0.1),
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 80,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _staggered(
                    fade: _titleFade,
                    slide: _titleSlide,
                    child: Text(
                      t.tut_complete_title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _staggered(
                    fade: _bodyFade,
                    slide: _bodySlide,
                    child: Text(
                      t.tut_complete_body,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: cs.onSurface.withValues(alpha: 0.6),
                        height: 1.6,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _staggered(
                    fade: _subtitleFade,
                    slide: _subtitleSlide,
                    child: Text(
                      t.tut_complete_subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha: 0.85),
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _staggered(
                    fade: _buttonFade,
                    slide: _buttonSlide,
                    child: AppButton(
                      label: t.tut_start_practicing,
                      onPressed: _dismiss,
                      height: 58,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
