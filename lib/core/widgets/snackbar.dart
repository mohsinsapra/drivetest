import 'dart:async';

import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/services/navigation_service.dart';

void showAppSnackBar(String message, {Color? backgroundColor}) {
  debugPrint('showAppSnackBar called with message: $message');
  final context = NavigationService.navigatorKey.currentContext;
  if (context == null) return;
  final overlay = NavigationService.navigatorKey.currentState!.overlay!;
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(builder: (context) {
    return _TopSnackBar(
      key: UniqueKey(),
      message: message,
      backgroundColor: backgroundColor,
      onDismissed: () {
        overlayEntry.remove();
      },
    );
  });

  WidgetsBinding.instance.addPostFrameCallback((_) {
    overlay.insert(overlayEntry);
  });
}

class _TopSnackBar extends StatefulWidget {
  final String message;
  final Color? backgroundColor;
  final VoidCallback onDismissed;

  const _TopSnackBar({
    super.key,
    required this.message,
    this.backgroundColor,
    required this.onDismissed,
  });

  @override
  _TopSnackBarState createState() => _TopSnackBarState();
}

class _TopSnackBarState extends State<_TopSnackBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismissed();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPadding + 10,
      left: 20.0,
      right: 20.0,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: DefaultTextStyle(
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.message,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
