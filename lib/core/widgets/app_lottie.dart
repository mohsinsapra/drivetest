import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'app_lottie_web.dart'
    if (dart.library.io) 'app_lottie_stub.dart' as platform;

/// Drop-in replacement for [Lottie.asset] that works on ALL platforms.
///
/// On Flutter Web, Lottie's path rendering causes a StackOverflowError in
/// the engine's lazy_path.dart. This widget uses the native lottie-player
/// web component on web (bypassing Flutter's path renderer entirely) and
/// the normal lottie package on mobile/desktop.
class AppLottie extends StatelessWidget {
  final String asset;
  final double? height;
  final double? width;
  final BoxFit fit;

  const AppLottie({
    super.key,
    required this.asset,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return platform.buildWebLottie(asset: asset, height: height, fit: fit);
    }
    return Lottie.asset(
      'assets/$asset',
      width: width,
      height: height,
      fit: fit,
      repeat: true,
      renderCache: RenderCache.raster,
      options: LottieOptions(enableMergePaths: false),
    );
  }
}
