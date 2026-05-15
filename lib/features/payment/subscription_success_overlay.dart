import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/models/purchase_receipt.dart';
import 'package:taxi_exam_app/features/payment/receipt_screen.dart';

/// Result of the success overlay interaction.
enum SubscriptionSuccessResult { startTests, backHome }

/// Shows a full-screen success modal after a successful purchase.
Future<SubscriptionSuccessResult?> showSubscriptionSuccess(
  BuildContext context, {
  required String productName,
  String? duration,
  String? amount,
  String? currency,
  PurchaseReceipt? receipt,
  int autoDismissSeconds = 5,
}) async {
  final result = await Navigator.of(context).push<SubscriptionSuccessResult>(
    PageRouteBuilder(
      fullscreenDialog: true,
      opaque: false,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      pageBuilder: (_, __, ___) => _PurchaseSuccessScreen(
        productName: productName,
        duration: duration,
        amount: amount,
        currency: currency,
        receipt: receipt,
      ),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: animation,
        child: child,
      ),
    ),
  );
  return result;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class _PurchaseSuccessScreen extends StatefulWidget {
  final String productName;
  final String? duration;
  final String? amount;
  final String? currency;
  final PurchaseReceipt? receipt;

  const _PurchaseSuccessScreen({
    required this.productName,
    this.duration,
    this.amount,
    this.currency,
    this.receipt,
  });

  @override
  State<_PurchaseSuccessScreen> createState() => _PurchaseSuccessScreenState();
}

class _PurchaseSuccessScreenState extends State<_PurchaseSuccessScreen>
    with TickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _checkScale;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeIn = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeCtrl.forward();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _scaleCtrl.forward();
      });
    });
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _handleStartTests() {
    Navigator.of(context).pop(SubscriptionSuccessResult.startTests);
  }

  void _handleBackToHome() {
    Navigator.of(context).pop(SubscriptionSuccessResult.backHome);
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;
    final surface = Theme.of(context).scaffoldBackgroundColor;

    // Tint the scaffold colour toward secondary (green) and primary (blue)
    // to create the soft pastel gradient seen in the reference design.
    final gradientColors = [
      surface,
      Color.lerp(surface, cs.secondary, 0.06)!,
      Color.lerp(surface, cs.primary, 0.05)!,
    ];

    final metaColor = cs.onSurface.withValues(alpha: 0.4);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FadeTransition(
        opacity: _fadeIn,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          ),
          child: Stack(
            children: [
              // Scattered decorative elements
              const _DecorativeDots(),

              // Main content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),

                      // Animated checkmark circle
                      ScaleTransition(
                        scale: _checkScale,
                        child: _CheckmarkBadge(successColor: cs.secondary),
                      ),

                      const SizedBox(height: 16),

                      // Small target icon (uses primary / brand colour)
                      Icon(
                        Icons.my_location_rounded,
                        size: 22,
                        color: cs.primary,
                      ),

                      const SizedBox(height: 28),

                      // Title
                      Text(
                        t.purchase_success_title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          height: 1.25,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Subtitle — dynamic product name, no translation key needed
                      Text(
                        widget.productName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: cs.onSurface.withValues(alpha: 0.6),
                          height: 1.5,
                        ),
                      ),

                      if (widget.duration != null || widget.amount != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.duration != null) ...[
                              Icon(Icons.access_time_rounded,
                                  size: 13, color: metaColor),
                              const SizedBox(width: 4),
                              Text(
                                widget.duration!,
                                style:
                                    TextStyle(fontSize: 13, color: metaColor),
                              ),
                            ],
                            if (widget.duration != null &&
                                widget.amount != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: Text('·',
                                    style: TextStyle(color: metaColor)),
                              ),
                            if (widget.amount != null)
                              Text(
                                '${widget.amount} ${widget.currency ?? 'SEK'}',
                                style:
                                    TextStyle(fontSize: 13, color: metaColor),
                              ),
                          ],
                        ),
                      ],

                      const Spacer(flex: 2),

                      // View receipt
                      if (widget.receipt != null)
                        TextButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ReceiptScreen(receipt: widget.receipt!),
                            ),
                          ),
                          icon:
                              const Icon(Icons.receipt_long_outlined, size: 16),
                          label: Text(
                            widget.receipt!.receiptNumber,
                            style: const TextStyle(fontSize: 13),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor:
                                cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Primary action button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleStartTests,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            t.purchase_success_start_tests,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Back to home
                      GestureDetector(
                        onTap: _handleBackToHome,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            t.purchase_success_back_home,
                            style: TextStyle(
                              fontSize: 15,
                              color: cs.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Checkmark badge ───────────────────────────────────────────────────────────

class _CheckmarkBadge extends StatelessWidget {
  final Color successColor;
  const _CheckmarkBadge({required this.successColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        color: successColor.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            color: successColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 56,
          ),
        ),
      ),
    );
  }
}

// ── Decorative dots & squiggles ───────────────────────────────────────────────

class _DecorativeDots extends StatelessWidget {
  const _DecorativeDots();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand(
      child: CustomPaint(
        painter: _DecorationPainter(),
      ),
    );
  }
}

class _DecorationPainter extends CustomPainter {
  const _DecorationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    _dot(canvas, size, 0.72, 0.12, const Color(0xFF4CAF72), 7);
    _dot(canvas, size, 0.15, 0.18, const Color(0xFFFF5252), 5);
    _dot(canvas, size, 0.85, 0.25, const Color(0xFF6B7CFF), 9);
    _dot(canvas, size, 0.10, 0.42, const Color(0xFFFFD740), 6);
    _dot(canvas, size, 0.88, 0.45, const Color(0xFFFF80AB), 5);
    _dot(canvas, size, 0.20, 0.72, const Color(0xFF4CAF72), 8);
    _dot(canvas, size, 0.78, 0.68, const Color(0xFFFFD740), 10);
    _dot(canvas, size, 0.50, 0.88, const Color(0xFF6B7CFF), 6);
    _dot(canvas, size, 0.05, 0.60, const Color(0xFFFF5252), 4);
    _dot(canvas, size, 0.93, 0.62, const Color(0xFF4CAF72), 5);
    _dot(canvas, size, 0.60, 0.08, const Color(0xFFFF80AB), 7);
    _dot(canvas, size, 0.30, 0.08, const Color(0xFF6B7CFF), 5);

    _ring(canvas, size, 0.82, 0.15, const Color(0xFFFFD740), 9, 2);
    _ring(canvas, size, 0.08, 0.30, const Color(0xFF4CAF72), 8, 2);
    _ring(canvas, size, 0.92, 0.80, const Color(0xFF6B7CFF), 10, 2);
    _ring(canvas, size, 0.18, 0.85, const Color(0xFFFF5252), 7, 2);

    _squiggle(canvas, size, 0.12, 0.52, const Color(0xFF6B7CFF), false);
    _squiggle(canvas, size, 0.80, 0.35, const Color(0xFFFF5252), true);
    _squiggle(canvas, size, 0.65, 0.80, const Color(0xFFFFD740), false);
  }

  void _dot(Canvas c, Size s, double fx, double fy, Color color, double r) {
    c.drawCircle(
        Offset(s.width * fx, s.height * fy), r, Paint()..color = color);
  }

  void _ring(
      Canvas c, Size s, double fx, double fy, Color color, double r, double w) {
    c.drawCircle(
      Offset(s.width * fx, s.height * fy),
      r,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w,
    );
  }

  void _squiggle(
      Canvas c, Size s, double fx, double fy, Color color, bool flip) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final cx = s.width * fx;
    final cy = s.height * fy;
    final yDir = flip ? -1.0 : 1.0;

    final path = Path()
      ..moveTo(cx, cy)
      ..cubicTo(
        cx + 8,
        cy - 12 * yDir,
        cx + 18,
        cy + 12 * yDir,
        cx + 26,
        cy,
      );

    c.save();
    c.translate(cx, cy);
    c.rotate(flip ? math.pi / 4 : -math.pi / 4);
    c.translate(-cx, -cy);
    c.drawPath(path, paint);
    c.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
