import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/api/dio_client.dart';
import 'package:taxi_exam_app/core/router/route_names.dart';

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
    final data = await _initializeApp();
    final remaining =
        const Duration(milliseconds: 1400) - stopwatch.elapsed;
    if (remaining > Duration.zero) await Future.delayed(remaining);

    if (!mounted) return;

    final onboardingComplete = data['onboardingComplete'] ?? false;
    final isAuthenticated = data['isAuthenticated'] ?? false;

    final String next;
    if (!onboardingComplete) {
      next = Routes.intro;
    } else if (!isAuthenticated) {
      next = Routes.auth;
    } else {
      next = Routes.home;
    }

    // ignore: use_build_context_synchronously
    context.go(next);
  }

  Future<Map<String, bool>> _initializeApp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final onboardingComplete =
          prefs.getBool('onboarding_complete') ?? false;

      await DioClient().reloadTokens();

      final hasTokens = DioClient().refreshToken != null &&
          DioClient().accessToken != null;
      bool isAuthenticated = false;

      if (hasTokens) {
        try {
          await ApiService().fetchCurrentUser();
          isAuthenticated = true;
        } catch (e) {
          debugPrint('SplashScreen: token validation failed — $e');
          await DioClient().logout();
        }
      }

      return {
        'onboardingComplete': onboardingComplete,
        'isAuthenticated': isAuthenticated,
      };
    } catch (e) {
      debugPrint('SplashScreen: init error — $e');
      return {'onboardingComplete': false, 'isAuthenticated': false};
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
