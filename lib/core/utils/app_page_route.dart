import 'package:flutter/material.dart';

/// Drop-in replacement for [MaterialPageRoute] with a snappier 220 ms
/// forward / 180 ms reverse transition. Uses the same platform-appropriate
/// animation (iOS slide, Android zoom) — just faster, so the UI feels
/// more responsive without changing any visible behaviour.
class AppPageRoute<T> extends MaterialPageRoute<T> {
  AppPageRoute({
    required super.builder,
    super.settings,
    super.fullscreenDialog,
    super.maintainState,
  });

  @override
  Duration get transitionDuration => const Duration(milliseconds: 220);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 180);
}
