import 'package:flutter/material.dart';
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
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.80, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _run();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    // Ensure splash is visible for a minimum time even on fast devices.
    final stopwatch = Stopwatch()..start();

    // Read the onboarding flag first — SharedPreferences is local and fast.
    // This ensures it is available even if _initializeApp times out or throws.
    bool onboardingComplete = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      onboardingComplete = false; // TODO: remove — force onboarding for testing
      // onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    } catch (_) {}

    final data = await _initializeApp(onboardingComplete).timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        debugPrint('SplashScreen: _initializeApp hard timeout — proceeding unauthenticated');
        DioClient().logout();
        return {'onboardingComplete': onboardingComplete, 'isAuthenticated': false};
      },
    );
    final remaining =
        const Duration(milliseconds: 1400) - stopwatch.elapsed;
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
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  Future<Map<String, bool>> _initializeApp(bool onboardingComplete) async {
    try {
      await DioClient().reloadTokens();

      final hasTokens = DioClient().refreshToken != null &&
          DioClient().accessToken != null;
      bool isAuthenticated = false;

      if (hasTokens) {
        try {
          // Cap at 7 s: a 401 with token refresh + retry can chain into
          // ~75 s of Dio timeouts (5 s connect + 20 s receive, twice).
          // Without this cap the splash screen hangs until all retries exhaust.
          await ApiService().fetchCurrentUser().timeout(
            const Duration(seconds: 7),
          );
          isAuthenticated = true;
        } catch (e) {
          debugPrint('SplashScreen: token validation failed — $e');
          // Clear tokens so any in-flight background request's interceptor
          // doesn't fire logoutAndRedirect() after we've already navigated.
          await DioClient().logout();
        }

        // Notification init is non-fatal and must be outside the auth
        // try/catch. On iOS web, requestPermission() can throw (Web Push
        // unsupported pre-Safari 16.4), which was calling logout() and
        // wiping tokens while isAuthenticated remained true → 401 on MainScreen.
        if (isAuthenticated) {
          try {
            await NotificationService.init(ApiService());
          } catch (e) {
            debugPrint('SplashScreen: notification init failed (non-fatal) — $e');
          }
        }
      }

      return {
        'onboardingComplete': onboardingComplete,
        'isAuthenticated': isAuthenticated,
      };
    } catch (e) {
      debugPrint('SplashScreen: init error — $e');
      return {'onboardingComplete': onboardingComplete, 'isAuthenticated': false};
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // ── Centred logo + name ──
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Opacity(
                opacity: _fade.value,
                child: Transform.scale(scale: _scale.value, child: child),
              ),
              child: Image.asset(
                'assets/icon/icon.png',
                width: 100,
                height: 100,
              ),
            ),
          ),

          // ── Thin loading bar at the bottom ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: _fade,
              builder: (_, __) => Opacity(
                opacity: _fade.value,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  minHeight: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
