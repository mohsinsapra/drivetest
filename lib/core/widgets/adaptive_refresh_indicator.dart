import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _hapticChannel = MethodChannel('com.taxiexam/haptic');

/// Pull-to-refresh that uses [CupertinoSliverRefreshControl] on iOS/web
/// and [RefreshIndicator] on Android. Fires light haptic ticks during drag.
class AdaptiveRefreshIndicator extends StatefulWidget {
  const AdaptiveRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.slivers,
    this.physics,
    this.controller,
    this.refreshIndicatorExtent = 60,
  });

  final Future<void> Function() onRefresh;
  final List<Widget> slivers;
  final ScrollPhysics? physics;
  final ScrollController? controller;

  /// How tall the indicator stays while refreshing. Increase to push the
  /// spinner below top overlays (e.g. gradient / status-bar fade).
  final double refreshIndicatorExtent;

  @override
  State<AdaptiveRefreshIndicator> createState() =>
      _AdaptiveRefreshIndicatorState();
}

class _AdaptiveRefreshIndicatorState extends State<AdaptiveRefreshIndicator> {
  static const double _hapticTickInterval = 0.05;

  double _totalOverscroll = 0.0;
  double _lastHapticThreshold = 0.0;

  static bool _useCupertino(BuildContext context) =>
      kIsWeb || Theme.of(context).platform == TargetPlatform.iOS;

  // iOS (BouncingScrollPhysics) never fires OverscrollNotification during a
  // pull — it allows the scroll position to go negative instead. We therefore
  // track both notification types and use the same threshold logic for each.
  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is OverscrollNotification && notification.overscroll < 0) {
      _totalOverscroll += notification.overscroll.abs();
      _maybeFireHaptic();
    } else if (notification is ScrollUpdateNotification) {
      final pull =
          notification.metrics.minScrollExtent - notification.metrics.pixels;
      if (pull > 0) {
        _totalOverscroll = pull;
        _maybeFireHaptic();
      }
    } else if (notification is ScrollEndNotification) {
      _totalOverscroll = 0.0;
      _lastHapticThreshold = 0.0;
    }
    return false;
  }

  void _maybeFireHaptic() {
    if (_totalOverscroll - _lastHapticThreshold < _hapticTickInterval) return;
    _lastHapticThreshold = _totalOverscroll;
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android)) {
      _hapticChannel.invokeMethod<void>('tick').catchError((_) {
        HapticFeedback.selectionClick();
      });
    } else {
      HapticFeedback.selectionClick();
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
          clipBehavior: Clip.none,
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: widget.onRefresh,
              refreshIndicatorExtent: widget.refreshIndicatorExtent,
              refreshTriggerPullDistance: widget.refreshIndicatorExtent + 40,
            ),
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
          clipBehavior: Clip.none,
          slivers: widget.slivers,
        ),
      ),
    );
  }
}
