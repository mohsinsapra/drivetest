import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Pull-to-refresh that uses [CupertinoSliverRefreshControl] on iOS/web
/// and [RefreshIndicator] on Android. Callers supply sliver children.
class AdaptiveRefreshIndicator extends StatelessWidget {
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

  static bool _useCupertino(BuildContext context) =>
      kIsWeb || Theme.of(context).platform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context) {
    final effectivePhysics = physics ?? const AlwaysScrollableScrollPhysics();

    if (_useCupertino(context)) {
      return CustomScrollView(
        controller: controller,
        physics: effectivePhysics,
        slivers: [
          CupertinoSliverRefreshControl(onRefresh: onRefresh),
          ...slivers,
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        controller: controller,
        physics: effectivePhysics,
        slivers: slivers,
      ),
    );
  }
}
