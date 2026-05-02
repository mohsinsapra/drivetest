import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/api/dio_client.dart';
import 'package:taxi_exam_app/core/services/notification_service.dart';
import 'package:taxi_exam_app/features/auth/auth_screen.dart';
import 'package:taxi_exam_app/features/onboarding/onboarding_screen.dart';
import 'package:taxi_exam_app/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Entry animations (run once, 900 ms)
  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _boltSlideAnim;
  late final Animation<double> _footerFadeAnim;

  // Continuous spinning arc
  late final AnimationController _spinCtrl;
  late final Animation<double> _spinAnim;

  // Pulsing glow dot
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);

    _scaleAnim = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutBack),
    );

    // Bolt chip slides down into position from above
    _boltSlideAnim = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    // Footer fades in during the second half of entry
    _footerFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
      ),
    );

    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _spinAnim = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(_spinCtrl);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.18).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _entryCtrl.forward();
    _run();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _spinCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── App bootstrap logic (unchanged from original) ────────────────────────

  Future<void> _run() async {
    final stopwatch = Stopwatch()..start();

    // SharedPreferences read and token reload are independent — run in parallel.
    bool onboardingComplete = false;
    try {
      final results = await Future.wait([
        SharedPreferences.getInstance(),
        DioClient().reloadTokens(),
      ]);
      final prefs = results[0] as SharedPreferences;
      onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    } catch (_) {}

    final hasTokens =
        DioClient().refreshToken != null && DioClient().accessToken != null;

    final data = await _initializeApp(onboardingComplete, hasTokens).timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        debugPrint(
          'SplashScreen: _initializeApp hard timeout — proceeding unauthenticated',
        );
        DioClient().logout();
        return {
          'onboardingComplete': onboardingComplete,
          'isAuthenticated': false,
        };
      },
    );

    final remaining = const Duration(milliseconds: 1400) - stopwatch.elapsed;
    if (remaining > Duration.zero) await Future.delayed(remaining);

    if (!mounted) return;

    onboardingComplete = data['onboardingComplete'] ?? onboardingComplete;
    final isAuthenticated = data['isAuthenticated'] ?? false;

    final Widget next;
    if (!onboardingComplete) {
      next = const OnboardingScreen();
    } else if (!isAuthenticated) {
      next = const AuthScreen();
    } else {
      next = const MainScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => next,
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  // hasTokens is pre-computed in _run() alongside SharedPreferences to avoid
  // calling reloadTokens() twice.
  Future<Map<String, bool>> _initializeApp(
      bool onboardingComplete, bool hasTokens) async {
    bool isAuthenticated = false;
    try {
      if (hasTokens) {
        try {
          await ApiService()
              .fetchCurrentUser()
              .timeout(const Duration(seconds: 7));
          isAuthenticated = true;
        } catch (e) {
          debugPrint('SplashScreen: token validation failed — $e');
          // Only wipe tokens on a confirmed 401 (server explicitly rejected them).
          // A connection/DNS/timeout error means the network is unavailable —
          // keep the tokens so the user stays logged in and can retry later.
          final is401 = e is DioException && e.response?.statusCode == 401;
          if (is401) {
            await DioClient().logout();
          } else {
            // Network unreachable — treat as authenticated to avoid a spurious
            // logout. The MainScreen will refresh data once connectivity returns.
            isAuthenticated = true;
          }
        }

        if (isAuthenticated) {
          // Non-fatal — don't block navigation waiting for FCM registration.
          NotificationService.init(ApiService()).ignore();
        }
      }
    } catch (e) {
      debugPrint('SplashScreen: init error — $e');
    }
    return {
      'onboardingComplete': onboardingComplete,
      'isAuthenticated': isAuthenticated,
    };
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          // ── Ambient background blobs ──────────────────────────────────
          Positioned(
            top: -size.height * 0.08,
            left: -size.width * 0.08,
            width: size.width * 0.65,
            height: size.height * 0.55,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    cs.primaryContainer.withValues(alpha: 0.18),
                    cs.primaryContainer.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.08,
            right: -size.width * 0.08,
            width: size.width * 0.65,
            height: size.height * 0.55,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    cs.secondaryContainer.withValues(alpha: 0.28),
                    cs.secondaryContainer.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // ── Central branding cluster ──────────────────────────────────
          Center(
            child: AnimatedBuilder(
              animation: _entryCtrl,
              builder: (_, child) => Opacity(
                opacity: _fadeAnim.value,
                child: Transform.scale(scale: _scaleAnim.value, child: child),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title group + floating bolt chip
                  SizedBox(
                    width: 300,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Column(
                          children: [
                            Text(
                              'DRIVE TEST',
                              style: GoogleFonts.lexend(
                                fontSize: 58,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                letterSpacing: -1.5,
                                color: cs.primary,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: cs.secondaryContainer,
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Text(
                                'HELLO SWEDEN',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.5,
                                  color: cs.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Bolt chip — animates down from above on entry
                        AnimatedBuilder(
                          animation: _boltSlideAnim,
                          builder: (_, child) => Positioned(
                            top: -16 + _boltSlideAnim.value,
                            right: -16,
                            child: Opacity(
                              opacity: (_boltSlideAnim.value == 0)
                                  ? 1.0
                                  : 1.0 - (_boltSlideAnim.value / 20.0),
                              child: child!,
                            ),
                          ),
                          child: Transform.rotate(
                            angle: 12 * math.pi / 180,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: cs.secondaryContainer,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: cs.onSurface.withValues(alpha: 0.08),
                                    blurRadius: 32,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.bolt,
                                color: cs.onSecondaryContainer,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Kinetic loading ring
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Static outer ring
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: cs.primary.withValues(alpha: 0.18),
                              width: 4,
                            ),
                          ),
                        ),

                        // Spinning ¾ arc
                        AnimatedBuilder(
                          animation: _spinAnim,
                          builder: (_, __) => Transform.rotate(
                            angle: _spinAnim.value,
                            child: CustomPaint(
                              size: const Size(64, 64),
                              painter: _ArcPainter(color: cs.primary),
                            ),
                          ),
                        ),

                        // Pulsing glow dot
                        AnimatedBuilder(
                          animation: _pulseAnim,
                          builder: (_, __) => Transform.scale(
                            scale: _pulseAnim.value,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: cs.tertiaryContainer,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: cs.tertiaryContainer.withValues(
                                      alpha: 0.6,
                                    ),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  AnimatedBuilder(
                    animation: _fadeAnim,
                    builder: (_, child) =>
                        Opacity(opacity: _fadeAnim.value, child: child),
                    child: Text(
                      'Preparing your success...',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: cs.outline,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Editorial footer ──────────────────────────────────────────
          Positioned(
            bottom: 52,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _footerFadeAnim,
              builder: (_, child) => Opacity(
                opacity: _footerFadeAnim.value,
                child: child,
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 2,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ACADEMIC EXCELLENCE THROUGH KINETIC LEARNING',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Spinning arc painter (¾ circle, bottom-right quarter omitted) ──────────
class _ArcPainter extends CustomPainter {
  const _ArcPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    // 270° arc starting from the top (−π/2), leaving a gap at the bottom-right
    canvas.drawArc(rect, -math.pi / 2, 3 * math.pi / 2, false, paint);
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.color != color;
}
