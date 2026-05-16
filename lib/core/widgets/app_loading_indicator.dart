import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key, this.color, this.strokeWidth = 4.0});

  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final radius = constraints.hasBoundedWidth
              ? (constraints.maxWidth / 2).clamp(6.0, 16.0)
              : 10.0;
          return Center(
            child: CupertinoActivityIndicator(color: color, radius: radius),
          );
        },
      );
    }
    return CircularProgressIndicator(color: color, strokeWidth: strokeWidth);
  }
}
