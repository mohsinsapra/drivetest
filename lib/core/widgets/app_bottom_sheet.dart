import 'package:flutter/material.dart';

class AppBottomSheetContainer extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final double heightFactor;
  final Widget child;

  /// Optional banner rendered between the header divider and the child.
  /// Used by the tutorial to prompt the user without polluting the widget tree.
  final Widget? hint;

  const AppBottomSheetContainer({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.heightFactor = 0.8,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * heightFactor,
          minHeight: 0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (title != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      title!,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
              ),
            ],
            if (hint != null) hint!,
            Flexible(child: child),
            SafeArea(top: false, child: const SizedBox(height: 8)),
          ],
        ),
      ),
    );
  }
}
