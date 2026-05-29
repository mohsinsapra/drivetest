import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class PerformanceMetricCard extends StatelessWidget {
  const PerformanceMetricCard({
    super.key,
    required this.color,
    required this.bgColor,
    required this.icon,
    required this.progress,
    required this.value,
    required this.title,
    required this.chip,
    required this.chipColor,
    required this.chipDot,
    required this.description,
    this.isCompact = false,
    this.numericValue,
    this.isLoading = false,
  });

  final Color color;
  final Color bgColor;
  final IconData icon;
  final double progress;
  final String value;
  final String title;
  final String chip;
  final Color? chipColor;
  final bool chipDot;
  final String description;
  final bool isCompact;
  final double? numericValue;
  final bool isLoading;

  static const _dur = Duration(milliseconds: 900);
  static const _curve = Interval(0.25, 1.0, curve: Curves.easeOutCubic);

  Widget _arc(double size) => RepaintBoundary(
        child: TweenAnimationBuilder<double>(
          key: ValueKey('arc_${color.toARGB32()}_$progress'),
          tween: Tween(begin: 0.0, end: progress),
          duration: _dur,
          curve: _curve,
          builder: (_, p, __) => CustomPaint(
            size: Size(size, size),
            painter: _ArcPainter(
              progress: p,
              color: color,
              trackColor: color.withValues(alpha: 0.12),
            ),
          ),
        ),
      );

  Widget _counter(TextStyle style) {
    if (numericValue != null) {
      return TweenAnimationBuilder<double>(
        key: ValueKey('val_${color.toARGB32()}_$numericValue'),
        tween: Tween(begin: 0.0, end: numericValue),
        duration: _dur,
        curve: _curve,
        builder: (_, v, __) => Text('${v.round()}', style: style),
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
              .animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      child: Text(value, key: ValueKey(value), style: style),
    );
  }

  Widget _chip(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor != null
            ? chipColor!.withValues(alpha: 0.12)
            : cs.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (chipDot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            chip,
            style: GoogleFonts.lexend(
              fontWeight: FontWeight.w600,
              color: chipColor ?? cs.onSurface.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (isLoading) return _buildShimmer(context);
    return isCompact ? _buildCompact(context, cs) : _buildFull(context, cs);
  }

  Widget _buildShimmer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: isDark
          ? cs.onSurface.withValues(alpha: 0.15)
          : cs.onSurface.withValues(alpha: 0.08),
      highlightColor: isDark
          ? cs.onSurface.withValues(alpha: 0.28)
          : cs.onSurface.withValues(alpha: 0.15),
      child: isCompact ? _buildCompactShimmer() : _buildFullShimmer(),
    );
  }

  Widget _buildCompactShimmer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 52,
            height: 26,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 72,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullShimmer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 140,
                      height: 15,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _arc(60),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisSize: MainAxisSize.min,
            children: [
              _counter(GoogleFonts.lexend(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: color,
                height: 1.0,
              )),
              if (chip.isNotEmpty) ...[
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '/ $chip',
                    style: GoogleFonts.lexend(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withValues(alpha: 0.45),
                      height: 1.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.lexend(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.65),
              height: 1.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildFull(BuildContext context, ColorScheme cs) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 88,
                    height: 88,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _arc(88),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 26, color: color),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _counter(GoogleFonts.lexend(
                          fontWeight: FontWeight.w900,
                          color: color,
                          height: 1.0,
                          fontSize: 36,
                        )),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: GoogleFonts.lexend(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.45),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(top: 14, right: 14, child: _chip(context)),
          ],
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  static final _start = -math.pi / 2;
  static final _sweep = 2 * math.pi;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _start,
      _sweep,
      false,
      trackPaint,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        _start,
        _sweep * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress || old.color != color;
}
