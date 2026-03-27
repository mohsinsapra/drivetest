// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';

final _registered = <String>{};

Widget buildWebLottie({
  required String asset,
  double? height,
  BoxFit fit = BoxFit.contain,
}) {
  // Stable view-type id derived from the asset path
  final viewType =
      'lottie__${asset.replaceAll('/', '_').replaceAll('.', '_')}';

  if (!_registered.contains(viewType)) {
    _registered.add(viewType);
    // Flutter web builds serve assets at assets/assets/<path>
    final src = 'assets/assets/$asset';
    ui.platformViewRegistry.registerViewFactory(viewType, (int _) {
      final el = html.Element.tag('lottie-player')
        ..setAttribute('src', src)
        ..setAttribute('background', 'transparent')
        ..setAttribute('speed', '1')
        ..setAttribute('loop', '')
        ..setAttribute('autoplay', '')
        ..style.width = '100%'
        ..style.height = '100%';
      return el;
    });
  }

  return SizedBox(
    height: height,
    child: HtmlElementView(viewType: viewType),
  );
}
