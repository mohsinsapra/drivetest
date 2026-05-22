import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pull-to-refresh that uses [CupertinoSliverRefreshControl] on iOS/web
/// and [RefreshIndicator] on Android. Fires light haptic ticks during drag.
class AdaptiveRefreshIndicator extends StatefulWidget {
  const AdaptiveRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.slivers,
    this.physics,
    this.controller,
  });

  final Future<void> Function() onRefresh;
  final List<Widget> slivers;
  final ScrollPhysics? physics;
  final ScrollController? controller;

  @override
  State<AdaptiveRefreshIndicator> createState() =>
      _AdaptiveRefreshIndicatorState();
}

class _AdaptiveRefreshIndicatorState extends State<AdaptiveRefreshIndicator> {
  static const double _hapticTickInterval = 12.0;
  static const Duration _minHapticInterval = Duration(milliseconds: 30);

  double _totalOverscroll = 0.0;
  double _lastHapticThreshold = 0.0;
  DateTime? _lastHapticTime;

  static bool _useCupertino(BuildContext context) =>
      kIsWeb || Theme.of(context).platform == TargetPlatform.iOS;

  // iOS (BouncingScrollPhysics) never fires OverscrollNotification during a
  // pull — it allows the scroll position to go negative instead. We therefore
  // track both notification types and use the same threshold logic for each.
  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is OverscrollNotification && notification.overscroll < 0) {
      // Android: ClampingScrollPhysics fires OverscrollNotification with a
      // delta each event; accumulate to get total pull distance.
      _totalOverscroll += notification.overscroll.abs();
      _maybeFireHaptic();
    } else if (notification is ScrollUpdateNotification) {
      // iOS: scroll position goes below minScrollExtent while pulling down.
      final pull =
          notification.metrics.minScrollExtent - notification.metrics.pixels;
      if (pull > 0) {
        _totalOverscroll = pull;
        _maybeFireHaptic();
      }
    } else if (notification is ScrollEndNotification) {
      _totalOverscroll = 0.0;
      _lastHapticThreshold = 0.0;
      _lastHapticTime = null;
    }
    return false;
  }

  void _maybeFireHaptic() {
    final now = DateTime.now();
    final gapOk = _lastHapticTime == null ||
        now.difference(_lastHapticTime!) >= _minHapticInterval;
    if (gapOk && _totalOverscroll - _lastHapticThreshold >= _hapticTickInterval) {
      HapticFeedback.lightImpact();
      _lastHapticThreshold = _totalOverscroll;
      _lastHapticTime = now;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectivePhysics =
        widget.physics ?? const AlwaysScrollableScrollPhysics();

    if (_useCupertino(context)) {
      return NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: CustomScrollView(
          controller: widget.controller,
          physics: effectivePhysics,
          slivers: [
            CupertinoSliverRefreshControl(onRefresh: widget.onRefresh),
            ...widget.slivers,
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: CustomScrollView(
          controller: widget.controller,
          physics: effectivePhysics,
          slivers: widget.slivers,
        ),
      ),
    );
  }
}
