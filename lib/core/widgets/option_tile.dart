import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'tts_button.dart';

class Option extends StatefulWidget {
  final String text;
  final String optionLabel;
  final String? imageUrl;
  final bool isSelected;
  final bool showInstantMarking;
  final bool isCorrectAnswer;
  final VoidCallback onTap;
  final String languageCode;
  final double scale;
  final String? explanation;

  const Option({
    super.key,
    required this.text,
    required this.optionLabel,
    this.imageUrl,
    required this.isSelected,
    required this.showInstantMarking,
    required this.isCorrectAnswer,
    required this.onTap,
    this.languageCode = 'sv',
    this.scale = 1.0,
    this.explanation,
  });

  static String stripHtml(String html) => html
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&ouml;', 'ö')
      .replaceAll('&aring;', 'å')
      .replaceAll('&auml;', 'ä')
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  @override
  State<Option> createState() => _OptionState();
}

class _OptionState extends State<Option> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  // Phase 1 (0→0.35): circle shrinks to 0  — old shape disappears
  // Phase 2 (0.35→1): new shape grows from 0 → 1.25 → 1.0  — result pops in
  late Animation<double> _shrink; // 1.0 → 0.0
  late Animation<double> _grow; // 0.0 → 1.25 → 1.0
  late Animation<double> _rotation; // 0 → pi/4 only for correct (diamond)

  bool _wasMarking = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _buildAnimations();

    if (widget.showInstantMarking &&
        (widget.isCorrectAnswer || widget.isSelected)) {
      _ctrl.value = 1.0;
      _wasMarking = true;
    }
  }

  void _buildAnimations() {
    _shrink = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
      ),
    );

    _grow = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.25), weight: 65),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 35),
    ]).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
      ),
    );

    _rotation = Tween<double>(begin: 0, end: pi / 4).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void didUpdateWidget(Option old) {
    super.didUpdateWidget(old);
    final nowActive = widget.showInstantMarking &&
        (widget.isCorrectAnswer || widget.isSelected);
    final wasActive =
        old.showInstantMarking && (old.isCorrectAnswer || old.isSelected);

    if (nowActive && !wasActive && !_wasMarking) {
      if (MediaQuery.of(context).disableAnimations) {
        _ctrl.value = 1.0;
      } else {
        // Start at 0.35 to skip Phase 1 (the blue/grey shrink) and jump
        // directly into Phase 2 (the green/red grow with check/cross icon).
        _ctrl.forward(from: 0.35);
      }
      _wasMarking = true;
    } else if (!nowActive && wasActive) {
      _ctrl.value = 0;
      _wasMarking = false;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── colours ────────────────────────────────────────────────────────────────
  Color _backgroundColor(BuildContext ctx) {
    if (!widget.showInstantMarking) {
      if (widget.isSelected) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Theme.of(ctx)
            .colorScheme
            .primary
            .withValues(alpha: isDark ? 0.25 : 0.1);
      }
      return Theme.of(ctx).cardColor;
    }
    if (widget.isCorrectAnswer) return Colors.green.withValues(alpha: 0.15);
    if (widget.isSelected) return Colors.red.withValues(alpha: 0.15);
    return Theme.of(ctx).cardColor;
  }

  Color _borderColor(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final def =
        isDark ? Colors.white.withValues(alpha: 0.10) : Colors.grey[200]!;
    if (!widget.showInstantMarking) {
      return widget.isSelected
          ? Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.4)
          : def;
    }
    // After marking: no hard border — background color carries the state
    return Colors.transparent;
  }

  double _borderWidth() {
    if (!widget.showInstantMarking) return widget.isSelected ? 1.5 : 1.0;
    return 0;
  }

  // ── animated indicator ─────────────────────────────────────────────────────
  Widget _buildIndicator(BuildContext ctx, double s) {
    final bool active = widget.showInstantMarking &&
        (widget.isCorrectAnswer || widget.isSelected);

    // Static circle for non-active tiles
    if (!active) {
      Color fill = Colors.transparent;
      Color border =
          Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.35);
      Widget? inner;
      if (widget.isSelected) {
        fill = Theme.of(ctx).primaryColor;
        border = Theme.of(ctx).primaryColor;
        inner = Icon(Icons.circle, size: 10 * s, color: Colors.white);
      }
      return Container(
        width: 24 * s,
        height: 24 * s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fill,
          border: Border.all(color: border, width: 2),
        ),
        child: inner != null ? Center(child: inner) : null,
      );
    }

    final bool isCorrect = widget.isCorrectAnswer;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        // Phase 1 (t < 0.35): old circle shrinks away
        // Phase 2 (t >= 0.35): new result shape grows in
        final bool showResult = t >= 0.35;
        final double scaleFactor = showResult ? _grow.value : _shrink.value;
        final double rotAngle =
            (isCorrect && showResult) ? _rotation.value : 0.0;

        final BoxDecoration decoration = isCorrect
            ? BoxDecoration(
                color: showResult
                    ? Colors.green
                    : Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(5 * s),
              )
            : BoxDecoration(
                shape: BoxShape.circle,
                color: showResult ? Colors.red : Theme.of(ctx).primaryColor,
              );

        return Transform.scale(
          scale: scaleFactor.clamp(0.0, 2.0),
          child: Transform.rotate(
            angle: rotAngle,
            child: Container(
              width: 24 * s,
              height: 24 * s,
              decoration: decoration,
              child: Center(
                child: Transform.rotate(
                  angle: -rotAngle, // keep icon upright inside diamond
                  child: Icon(
                    isCorrect ? Icons.check : Icons.close,
                    size: 14 * s,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final s = widget.scale;

    return Container(
      margin: EdgeInsets.only(bottom: 12 * s),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: () {},
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: 16 * s,
              vertical: 14 * s,
            ),
            decoration: BoxDecoration(
              color: _backgroundColor(context),
              border: Border.all(
                color: _borderColor(context),
                width: _borderWidth(),
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── label row ──────────────────────────────────────────────
                Row(
                  children: [
                    _buildIndicator(context, s),
                    SizedBox(width: 12 * s),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              widget.text,
                              softWrap: true,
                              style: TextStyle(
                                fontSize: 15 * s,
                                fontWeight: (widget.isSelected ||
                                        (widget.showInstantMarking &&
                                            widget.isCorrectAnswer))
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: widget.showInstantMarking
                                    ? (widget.isCorrectAnswer
                                        ? Colors.green[700]
                                        : (widget.isSelected
                                            ? Colors.red[700]
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface))
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          SizedBox(width: 6 * s),
                          TtsButton(
                            textToSpeak: widget.text,
                            languageCode: widget.languageCode,
                            iconSize: 18 * s,
                            tooltip: 'Read option aloud',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── explanation (correct answer only) ──────────────────────
                if (widget.showInstantMarking &&
                    widget.isCorrectAnswer &&
                    widget.explanation != null &&
                    widget.explanation!.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 10 * s, left: 36 * s),
                    child: Text(
                      Option.stripHtml(widget.explanation!),
                      style: TextStyle(
                        fontSize: 14 * s,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.75),
                        height: 1.5,
                      ),
                    ),
                  ),

                // ── thumbnail ──────────────────────────────────────────────
                if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 10 * s),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: widget.imageUrl!,
                        width: double.infinity,
                        height: 110 * s,
                        fit: BoxFit.cover,
                        placeholder: (c, _) => Container(
                          width: double.infinity,
                          height: 110 * s,
                          decoration: BoxDecoration(
                            color: Theme.of(c).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (c, _, __) => Container(
                          width: double.infinity,
                          height: 110 * s,
                          decoration: BoxDecoration(
                            color: Theme.of(c).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported,
                                  size: 24,
                                  color: Theme.of(c)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.4)),
                              const SizedBox(height: 4),
                              Text('Image not available',
                                  style: TextStyle(
                                      color: Theme.of(c)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
