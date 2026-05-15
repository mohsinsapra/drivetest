import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui;

final _registered = <String>{};

Widget buildWebLottie({
  required String asset,
  double? height,
  BoxFit fit = BoxFit.contain,
}) {
  // Stable view-type id derived from the asset path
  final viewType = 'lottie__${asset.replaceAll('/', '_').replaceAll('.', '_')}';

  if (!_registered.contains(viewType)) {
    _registered.add(viewType);
    // Flutter web builds serve assets at assets/assets/<path>
    final src = 'assets/assets/$asset';
    ui.platformViewRegistry.registerViewFactory(viewType, (int _) {
      final el = web.document.createElement('lottie-player') as web.HTMLElement
        ..setAttribute('src', src)
        ..setAttribute('background', 'transparent')
        ..setAttribute('speed', '1')
        ..setAttribute('loop', '')
        ..setAttribute('autoplay', '');
      el.style.width = '100%';
      el.style.height = '100%';
      return el as Object;
    });
  }

  return SizedBox(
    height: height,
    child: HtmlElementView(viewType: viewType),
  );
}
