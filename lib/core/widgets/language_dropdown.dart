import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';

/// Language selector styled like the dashboard's [PeriodDropdown]: a compact
/// trigger with a rotating chevron that opens a floating card menu with a
/// checkmark on the active option.
class LanguageDropdown extends StatefulWidget {
  const LanguageDropdown({
    super.key,
    required this.locale,
    required this.onChanged,
  });

  final AppLocale locale;
  final ValueChanged<AppLocale> onChanged;

  @override
  State<LanguageDropdown> createState() => _LanguageDropdownState();
}

class _LanguageDropdownState extends State<LanguageDropdown>
    with SingleTickerProviderStateMixin {
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  late final AnimationController _arrowCtrl;

  static const _options = [AppLocale.en, AppLocale.sv];

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
    _overlay?.remove();
    _overlay = null;
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

  void _select(AppLocale locale) {
    widget.onChanged(locale);
    _removeOverlay();
  }

  String _flag(AppLocale l) => l == AppLocale.sv ? '🇸🇪' : '🇬🇧';

  String _label(AppLocale l, Translations t) => l == AppLocale.sv
      ? t.auth_language_swedish
      : t.auth_language_english;

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
                  width: 170,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _options.map((l) {
                      final isSelected = widget.locale == l;
                      return InkWell(
                        onTap: () => _select(l),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 11),
                          child: Row(
                            children: [
                              Text(
                                _flag(l),
                                textScaler: TextScaler.noScaling,
                                style: const TextStyle(fontSize: 15),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _label(l, t),
                                  style: GoogleFonts.lexend(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color:
                                        isSelected ? cs.primary : cs.onSurface,
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
    final cs = Theme.of(context).colorScheme;
    final isOpen = _overlay != null;

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
          decoration: BoxDecoration(
            color: isOpen
                ? cs.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _flag(widget.locale),
                textScaler: TextScaler.noScaling,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 4),
              RotationTransition(
                turns: Tween(begin: 0.0, end: 0.5).animate(
                  CurvedAnimation(parent: _arrowCtrl, curve: Curves.easeInOut),
                ),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color:
                      isOpen ? cs.primary : cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
