import 'dart:async';

import 'package:flutter/material.dart';

import '../services/navigation_service.dart';

enum SnackBarType { info, success, error }

// ─── Data ─────────────────────────────────────────────────────────────────────

class _NotifItem {
  final String id;
  final String message;
  final SnackBarType type;
  final IconData? icon;
  Timer? _timer;

  _NotifItem({required this.message, required this.type, this.icon})
      : id = UniqueKey().toString();
}

// ─── Global state ─────────────────────────────────────────────────────────────

final _items = <_NotifItem>[];
OverlayEntry? _overlayEntry;
_NotifOverlayState? _overlayState;

void showAppSnackBar(
  String message, {
  SnackBarType type = SnackBarType.info,
  IconData? icon,
}) {
  // Dedup: skip if same message is already visible
  if (_items.any((i) => i.message == message)) return;

  final item = _NotifItem(message: message, type: type, icon: icon);
  _items.add(item);
  item._timer = Timer(const Duration(seconds: 4), () => _dismissItem(item.id));

  if (_overlayEntry == null) {
    _mountOverlay();
  } else {
    _overlayState?._onItemAdded(item);
  }
}

void _dismissItem(String id) {
  final idx = _items.indexWhere((i) => i.id == id);
  if (idx == -1) return;
  _items[idx]._timer?.cancel();
  _overlayState?._onItemRemoved(id);
}

void _mountOverlay() {
  final overlay = NavigationService.navigatorKey.currentState?.overlay;
  if (overlay == null) return;
  _overlayEntry = OverlayEntry(builder: (_) => const _NotifOverlay());
  overlay.insert(_overlayEntry!);
}

void _cleanupOverlay() {
  _overlayEntry?.remove();
  _overlayEntry = null;
  _overlayState = null;
}

// ─── Overlay widget ───────────────────────────────────────────────────────────

class _NotifOverlay extends StatefulWidget {
  const _NotifOverlay();

  @override
  State<_NotifOverlay> createState() => _NotifOverlayState();
}

class _NotifOverlayState extends State<_NotifOverlay>
    with TickerProviderStateMixin {
  final List<_NotifItem> _visible = [];
  final Map<String, AnimationController> _ctrls = {};

  static const _enterDuration = Duration(milliseconds: 360);
  static const _exitDuration = Duration(milliseconds: 260);
  static const int _maxVisible = 3;

  @override
  void initState() {
    super.initState();
    _overlayState = this;
    // Seed any items that were queued before the overlay mounted
    for (final item in _items) {
      _addToVisible(item, animate: false);
    }
    if (_visible.isNotEmpty) {
      _ctrls[_visible.last.id]?.forward();
    }
  }

  void _onItemAdded(_NotifItem item) => _addToVisible(item, animate: true);

  void _addToVisible(_NotifItem item, {required bool animate}) {
    if (!mounted) return;
    final ctrl = AnimationController(
      vsync: this,
      duration: _enterDuration,
      value: animate ? 0.0 : 1.0,
    );
    _ctrls[item.id] = ctrl;
    setState(() => _visible.add(item));
    if (animate) ctrl.forward();
  }

  void _onItemRemoved(String id) {
    if (!mounted) return;
    final ctrl = _ctrls[id];
    if (ctrl == null) return;
    // Guard against double-dismiss
    if (ctrl.status == AnimationStatus.reverse ||
        ctrl.status == AnimationStatus.dismissed) {
      return;
    }

    ctrl.duration = _exitDuration;
    ctrl.reverse().then((_) {
      if (!mounted) return;
      ctrl.dispose();
      _ctrls.remove(id);
      _items.removeWhere((i) => i.id == id);
      setState(() => _visible.removeWhere((i) => i.id == id));
      if (_items.isEmpty) _cleanupOverlay();
    });
  }

  @override
  void dispose() {
    _overlayState = null;
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shown = _visible.length > _maxVisible
        ? _visible.sublist(_visible.length - _maxVisible)
        : List<_NotifItem>.from(_visible);

    if (shown.isEmpty) return const SizedBox.shrink();

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              for (int i = 0; i < shown.length; i++) _buildCard(shown, i),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(List<_NotifItem> shown, int i) {
    final item = shown[i];
    // depth 0 = front card (highest z-order, rendered last)
    final depth = shown.length - 1 - i;
    final isFront = depth == 0;
    final ctrl = _ctrls[item.id];
    if (ctrl == null) return const SizedBox.shrink();

    const double peekOffset = 10.0;
    const double scaleStep = 0.06;
    final targetScale = 1.0 - depth * scaleStep;
    final targetY = depth * peekOffset;

    final card = _NotifCard(item: item);

    return TweenAnimationBuilder<double>(
      key: ValueKey('${item.id}_scale'),
      tween: Tween<double>(end: targetScale),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (_, scale, __) => TweenAnimationBuilder<double>(
        key: ValueKey('${item.id}_y'),
        tween: Tween<double>(end: targetY),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        builder: (_, yOffset, __) => AnimatedBuilder(
          animation: ctrl,
          builder: (_, __) {
            final p = ctrl.value;
            // Enter: slides down from above; exit: slides back up
            final slideY = (1.0 - p) * -56.0;
            return Transform.translate(
              offset: Offset(0, yOffset + slideY),
              child: Transform.scale(
                scale: scale * (0.85 + 0.15 * p),
                alignment: Alignment.topCenter,
                child: Opacity(
                  opacity: p.clamp(0.0, 1.0),
                  child: isFront
                      ? GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _dismissItem(item.id),
                          onVerticalDragEnd: (d) {
                            if (d.velocity.pixelsPerSecond.dy < -150) {
                              _dismissItem(item.id);
                            }
                          },
                          child: card,
                        )
                      : IgnorePointer(child: card),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Card widget ──────────────────────────────────────────────────────────────

class _NotifCard extends StatelessWidget {
  final _NotifItem item;

  const _NotifCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardColor;

    final (IconData resolvedIcon, Color iconColor) = switch (item.type) {
      SnackBarType.success => (Icons.check_circle_rounded, Colors.green.shade600),
      SnackBarType.error   => (Icons.error_rounded, cs.error),
      SnackBarType.info    => (Icons.info_rounded, cs.primary),
    };

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon ?? resolvedIcon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              item.message,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                height: 1.3,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
