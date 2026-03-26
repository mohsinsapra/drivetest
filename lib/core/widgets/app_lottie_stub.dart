import 'package:flutter/material.dart';

Widget buildWebLottie({
  required String asset,
  double? height,
  BoxFit fit = BoxFit.contain,
}) =>
    const SizedBox.shrink(); // never called on non-web
