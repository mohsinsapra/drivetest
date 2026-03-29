import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

/// Shows a subscription success bottom sheet with Lottie animation.
/// Pre-loads the composition before opening so it appears instantly.
Future<void> showSubscriptionSuccess(
  BuildContext context, {
  required String productName,
  String? duration,
  String? amount,
  String? currency,
  int autoDismissSeconds = 5,
}) async {
  LottieComposition? composition;
  try {
    final data = await rootBundle.load('assets/animations/animation3.json');
    composition = await LottieComposition.fromByteData(data);
  } catch (_) {}

  if (!context.mounted) return;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    isDismissible: true,
    enableDrag: true,
    builder: (_) => _SubscriptionSuccessSheet(
      productName: productName,
      duration: duration,
      amount: amount,
      currency: currency,
      autoDismissSeconds: autoDismissSeconds,
      composition: composition,
    ),
  );
}

class _SubscriptionSuccessSheet extends StatefulWidget {
  final String productName;
  final String? duration;
  final String? amount;
  final String? currency;
  final int autoDismissSeconds;
  final LottieComposition? composition;

  const _SubscriptionSuccessSheet({
    required this.productName,
    this.duration,
    this.amount,
    this.currency,
    required this.autoDismissSeconds,
    this.composition,
  });

  @override
  State<_SubscriptionSuccessSheet> createState() =>
      _SubscriptionSuccessSheetState();
}

class _SubscriptionSuccessSheetState extends State<_SubscriptionSuccessSheet>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final AnimationController _checkCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _checkScale;
  Timer? _dismissTimer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.autoDismissSeconds;

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeCtrl.forward();
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _checkCtrl.forward();
      });
    });

    _startDismissTimer();
  }

  void _startDismissTimer() {
    _dismissTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        if (mounted) Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _checkCtrl.dispose();
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: EdgeInsets.only(
          top: mq.size.height * 0.35,
          left: 12,
          right: 12,
          bottom: mq.padding.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 32),

            // Animated green checkmark
            ScaleTransition(
              scale: _checkScale,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFF00C896).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00C896),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Lottie animation (pre-loaded, plays once)
            if (widget.composition != null)
              SizedBox(
                height: 90,
                child: Lottie(
                  composition: widget.composition!,
                  repeat: false,
                  fit: BoxFit.contain,
                ),
              ),

            const SizedBox(height: 4),

            const Text(
              'Subscription Activated!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                widget.productName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4A4A6A),
                ),
              ),
            ),

            if (widget.duration != null || widget.amount != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.duration != null) ...[
                    const Icon(Icons.access_time_rounded,
                        size: 14, color: Color(0xFF9E9EB8)),
                    const SizedBox(width: 4),
                    Text(
                      widget.duration!,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF9E9EB8)),
                    ),
                  ],
                  if (widget.duration != null && widget.amount != null)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('·',
                          style: TextStyle(color: Color(0xFF9E9EB8))),
                    ),
                  if (widget.amount != null)
                    Text(
                      '${widget.amount} ${widget.currency ?? 'SEK'}',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF9E9EB8)),
                    ),
                ],
              ),
            ],

            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C896),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _secondsLeft > 0 ? 'Done  ($_secondsLeft)' : 'Done',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
