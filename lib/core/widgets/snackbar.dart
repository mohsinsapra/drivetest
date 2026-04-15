import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

enum SnackBarType { info, success, error }

const int _maxVisibleSnackBars = 3;
final List<ToastificationItem> _activeSnackBars = <ToastificationItem>[];

void _removeActiveSnackBarById(String id) {
  _activeSnackBars.removeWhere((item) => item.id == id);
}

void _syncActiveSnackBars() {
  _activeSnackBars.removeWhere(
      (item) => toastification.findToastificationItem(item.id) == null);
}

/// Shows a pill-shaped top-centered toast notification.
///
/// [type] controls the icon and accent colour:
///   - [SnackBarType.success] → green check
///   - [SnackBarType.error]   → red alert
///   - [SnackBarType.info]    → neutral (default)
void showAppSnackBar(
  String message, {
  SnackBarType type = SnackBarType.info,
  IconData? icon,
}) {
  _syncActiveSnackBars();

  while (_activeSnackBars.length >= _maxVisibleSnackBars) {
    final oldest = _activeSnackBars.removeAt(0);
    toastification.dismiss(oldest, showRemoveAnimation: false);
  }

  final ToastificationType toastType = switch (type) {
    SnackBarType.success => ToastificationType.success,
    SnackBarType.error => ToastificationType.error,
    SnackBarType.info => ToastificationType.info,
  };

  final (IconData resolvedIcon, Color iconColor) = switch (type) {
    SnackBarType.success => (Icons.check_circle_rounded, const Color(0xFF22C55E)),
    SnackBarType.error => (Icons.error_rounded, const Color(0xFFEF4444)),
    SnackBarType.info => (Icons.info_rounded, const Color(0xFF3B82F6)),
  };

  final item = toastification.show(
    type: toastType,
    icon: Icon(icon ?? resolvedIcon, size: 18, color: iconColor),
    style: ToastificationStyle.flat,
    alignment: Alignment.topCenter,
    description: Text(
      message,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        height: 1.3,
      ),
      textAlign: TextAlign.center,
      softWrap: true,
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
    showIcon: true,
    closeButtonShowType: CloseButtonShowType.none,
    closeOnClick: true,
    dragToClose: true,
    applyBlurEffect: false,
    callbacks: ToastificationCallbacks(
      onTap: (toastItem) => _removeActiveSnackBarById(toastItem.id),
      onDismissed: (toastItem) => _removeActiveSnackBarById(toastItem.id),
      onAutoCompleteCompleted: (toastItem) =>
          _removeActiveSnackBarById(toastItem.id),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.12),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  );

  _activeSnackBars.add(item);
}
