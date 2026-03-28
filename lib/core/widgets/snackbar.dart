import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

enum SnackBarType { info, success, error }

/// Shows a pill-shaped top-centered toast notification.
///
/// [type] controls the icon and accent colour:
///   - [SnackBarType.success] → green check
///   - [SnackBarType.error]   → red alert
///   - [SnackBarType.info]    → neutral (default)
void showAppSnackBar(String message, {SnackBarType type = SnackBarType.info}) {
  final ToastificationType toastType = switch (type) {
    SnackBarType.success => ToastificationType.success,
    SnackBarType.error => ToastificationType.error,
    SnackBarType.info => ToastificationType.info,
  };

  toastification.show(
    type: toastType,
    style: ToastificationStyle.flat,
    alignment: Alignment.topCenter,
    title: Text(
      message,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        height: 1.3,
      ),
    ),
    autoCloseDuration: const Duration(seconds: 3),
    animationDuration: const Duration(milliseconds: 300),
    animationBuilder: (context, animation, alignment, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1.5),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
    borderRadius: BorderRadius.circular(50),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    showProgressBar: false,
    showIcon: type != SnackBarType.info,
    closeButtonShowType: CloseButtonShowType.none,
    closeOnClick: true,
    dragToClose: true,
    applyBlurEffect: false,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.12),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
