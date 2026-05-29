import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

/// App-wide helper for presenting full-screen Cupertino-style modal sheets.
///
/// Wraps [CupertinoScaffold.showCupertinoModalBottomSheet] so every call site
/// gets the iOS depth animation (background scales + pushes back) for free,
/// without repeating boilerplate.
///
/// The [builder] widget is responsible for its own background colour and shape.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return CupertinoScaffold.showCupertinoModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    builder: builder,
  );
}
