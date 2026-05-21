import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import '../providers/dashboard_provider.dart';

class PeriodDropdown extends StatefulWidget {
  const PeriodDropdown({
    super.key,
    required this.period,
    required this.onChanged,
  });

  final PeriodFilter period;
  final ValueChanged<PeriodFilter> onChanged;

  @override
  State<PeriodDropdown> createState() => _PeriodDropdownState();
}

class _PeriodDropdownState extends State<PeriodDropdown>
    with SingleTickerProviderStateMixin {
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  late final AnimationController _arrowCtrl;

  static const _options = [
    PeriodFilter.today,
    PeriodFilter.sevenDays,
    PeriodFilter.thisMonth,
    PeriodFilter.all,
  ];

  @override
  void initState() {
    super.initState();
    _arrowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _arrowCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_overlay != null) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    _arrowCtrl.forward();
    final overlay = Overlay.of(context);
    _overlay = OverlayEntry(builder: _buildOverlay);
    overlay.insert(_overlay!);
    if (mounted) setState(() {});
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
    _arrowCtrl.reverse();
    if (mounted) setState(() {});
  }

  void _select(PeriodFilter p) {
    widget.onChanged(p);
    _removeOverlay();
  }

  String _label(PeriodFilter p, Translations t) => switch (p) {
        PeriodFilter.today => t.dash_period_today,
        PeriodFilter.sevenDays => t.dash_period_7days,
        PeriodFilter.thisMonth => t.home_this_month,
        PeriodFilter.all => t.dash_period_all,
      };

  Widget _buildOverlay(BuildContext ctx) {
    final t = Translations.of(ctx);
    final cs = Theme.of(ctx).colorScheme;
    final theme = Theme.of(ctx);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _removeOverlay,
      child: Stack(
        children: [
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(0, 6),
            child: GestureDetector(
              onTap: () {},
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                color: theme.cardColor,
                child: Container(
                  width: 160,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _options.map((p) {
                      final isSelected = widget.period == p;
                      return InkWell(
                        onTap: () => _select(p),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 11),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _label(p, t),
                                  style: GoogleFonts.lexend(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? cs.primary
                                        : cs.onSurface,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_rounded,
                                    size: 16, color: cs.primary),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isOpen = _overlay != null;

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: isOpen ? cs.primary.withValues(alpha: 0.1) : theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              if (!isOpen)
                BoxShadow(
                  color: cs.onSurface.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _label(widget.period, t),
                style: GoogleFonts.lexend(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isOpen ? cs.primary : cs.onSurface,
                ),
              ),
              const SizedBox(width: 6),
              RotationTransition(
                turns: Tween(begin: 0.0, end: 0.5).animate(
                  CurvedAnimation(
                      parent: _arrowCtrl, curve: Curves.easeInOut),
                ),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: isOpen
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
