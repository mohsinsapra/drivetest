import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/auth/apple_sign_in_helper.dart';
import 'package:taxi_exam_app/core/auth/google_sign_in_helper.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/providers/theme_provider.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/core/widgets/app_button.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'package:taxi_exam_app/features/auth/debug_credentials.dart';
import 'package:taxi_exam_app/features/auth/forgot_password_screen.dart';
import 'package:taxi_exam_app/core/services/iap_service.dart';
import 'package:taxi_exam_app/core/storage/app_storage.dart';
import 'package:taxi_exam_app/core/services/navigation_feedback.dart';
import 'package:taxi_exam_app/features/onboarding/onboarding_screen.dart';
import 'package:taxi_exam_app/main_screen.dart';

enum _AuthView { landing, login, signup }

class AuthScreen extends StatefulWidget {
  final void Function(NavigatorState nav)? onAfterAuth;
  const AuthScreen({super.key, this.onAfterAuth});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  _AuthView _view = _AuthView.landing;
  bool _viewForward = true; // tracks slide direction

  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  String _googleLoadingStep = '';

  // Login state
  final _loginUsernameCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();
  bool _obscureLoginPw = true;
  String? _loginError;
  Map<String, String?> _loginErrors = {};

  // Signup state
  final _signupUsernameCtrl = TextEditingController();
  final _signupEmailCtrl = TextEditingController();
  final _signupPasswordCtrl = TextEditingController();
  bool _obscureSignupPw = true;
  Map<String, String?> _signupErrors = {};

  // Guest session state
  bool _hasSavedGuestSession = false;
  bool _isGuestLoading = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _loginUsernameCtrl.text = 'abc';
      _loginPasswordCtrl.text = 'abc';
    }
    _checkSavedGuestSession();
  }

  Future<void> _checkSavedGuestSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasToken = prefs.getString(AppStorage.kGuestRefreshToken) != null;
      if (mounted) setState(() => _hasSavedGuestSession = hasToken);
    } catch (_) {}
  }

  Future<void> _continueAsGuest() async {
    if (_isGuestLoading) return;
    setState(() => _isGuestLoading = true);
    try {
      await _apiService.guestLogin();
      if (!mounted) return;
      // Pre-seed BcdCache so MainScreen doesn't show a loading spinner while
      // waiting for /self. Errors are non-fatal — MainScreen will retry.
      _apiService.fetchCurrentUser().ignore();
      // Retry any IAP receipt — best-effort, do not block navigation.
      IAPService.instance.hasDeferredReceipt().then((has) {
        if (has) {
          IAPService.instance.verifyDeferredReceipt().catchError((_) => null);
        }
      });
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        AppPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        showAppSnackBar(Translations.of(context).auth_guest_session_error,
            type: SnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _isGuestLoading = false);
    }
  }

  @override
  void dispose() {
    _loginUsernameCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _signupUsernameCtrl.dispose();
    _signupEmailCtrl.dispose();
    _signupPasswordCtrl.dispose();
    super.dispose();
  }

  void _navigate(_AuthView view) {
    setState(() {
      _viewForward = view != _AuthView.landing;
      _view = view;
      _loginError = null;
      _loginErrors = {};
      _signupErrors = {};
    });
  }

  // ── Locale ────────────────────────────────────────────────────────────────

  Future<void> _setLocale(AppLocale locale) async {
    await LocaleSettings.setLocale(locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', locale.languageCode);
  }

  // ── Navigation after auth ─────────────────────────────────────────────────

  Future<void> _navigateToMain({
    required bool isFirstLogin,
    String? displayName,
  }) async {
    IAPService.instance.verifyDeferredReceipt().ignore();
    // Welcome message uses the name from Google/Apple — no extra self/ call needed.
    // MainScreen._loadTabFlags() will fetch self/ for feature flags on its own.
    if (displayName != null || isFirstLogin) {
      _showWelcomeMessage({'first_name': displayName ?? ''},
          isFirstLogin: isFirstLogin);
    }
    // NotificationService.init is called in MainScreen.initState — skip here
    // to avoid a duplicate register-token/ call.
    if (!mounted) return;
    final navigator = Navigator.of(context);
    final afterAuth = widget.onAfterAuth;
    navigator.pushAndRemoveUntil(
      AppPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
    if (afterAuth != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => afterAuth(navigator));
    }
  }

  void _showWelcomeMessage(Map<String, dynamic> user,
      {required bool isFirstLogin}) {
    final t = Translations.of(context);
    showAppSnackBar(
      isFirstLogin ? t.auth_welcome_first_login : t.auth_welcome_returning,
      type: SnackBarType.success,
    );
  }

  // ── Google Sign In ────────────────────────────────────────────────────────

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _googleLoadingStep = Translations.of(context).auth_google_connecting;
      _loginError = null;
    });
    try {
      await Sentry.addBreadcrumb(
          Breadcrumb(message: 'Google Sign-In: started', category: 'auth'));
      final googleSignIn = GoogleSignInHelper.create();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        await Sentry.addBreadcrumb(Breadcrumb(
            message: 'Google Sign-In: user cancelled', category: 'auth'));
        setState(() {
          _isGoogleLoading = false;
          _googleLoadingStep = '';
        });
        return;
      }
      if (mounted) {
        setState(() => _googleLoadingStep =
            Translations.of(context).auth_google_verifying);
      }
      await Sentry.addBreadcrumb(Breadcrumb(
          message: 'Google Sign-In: user obtained, fetching auth tokens',
          category: 'auth'));
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      if (idToken == null && accessToken == null) {
        throw Exception('No authentication token received');
      }
      if (mounted) {
        setState(() => _googleLoadingStep =
            Translations.of(context).auth_google_signing_in);
      }
      await Sentry.addBreadcrumb(Breadcrumb(
          message:
              'Google Sign-In: tokens received, calling backend googleAuth',
          category: 'auth'));
      final isFirstLogin = await _apiService.googleAuth(
          idToken: idToken, accessToken: accessToken);
      await Sentry.addBreadcrumb(Breadcrumb(
          message:
              'Google Sign-In: backend googleAuth succeeded, isFirstLogin=$isFirstLogin',
          category: 'auth'));
      if (mounted) {
        setState(() => _googleLoadingStep = isFirstLogin
            ? Translations.of(context).auth_google_creating
            : Translations.of(context).auth_google_loading);
      }
      if (!mounted) return;
      vibrateLoginLogout();
      try {
        await _navigateToMain(
            isFirstLogin: isFirstLogin, displayName: googleUser.displayName);
      } catch (navError) {
        debugPrint(
            'AuthScreen: navigation error after Google login — $navError');
        if (mounted) {
          final navigator = Navigator.of(context);
          final afterAuth = widget.onAfterAuth;
          navigator.pushAndRemoveUntil(
            AppPageRoute(builder: (_) => const MainScreen()),
            (route) => false,
          );
          if (afterAuth != null) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => afterAuth(navigator));
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loginError = _isDeletedAccountError(e)
            ? Translations.of(context).auth_deleted_account_welcome_back
            : GoogleSignInHelper.userMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
          _googleLoadingStep = '';
        });
      }
    }
  }

  // ── Apple Sign In ────────────────────────────────────────────────────────

  Future<void> _signInWithApple() async {
    setState(() {
      _isAppleLoading = true;
      _loginError = null;
    });
    try {
      await Sentry.addBreadcrumb(
          Breadcrumb(message: 'Apple Sign-In: started', category: 'auth'));
      final credential = await AppleSignInHelper.signIn();
      final identityToken = credential.identityToken;
      if (identityToken == null) throw Exception('No identity token received');
      await Sentry.addBreadcrumb(Breadcrumb(
          message: 'Apple Sign-In: credential obtained', category: 'auth'));
      final isFirstLogin = await _apiService.appleAuth(
        identityToken: identityToken,
        firstName: credential.givenName,
        lastName: credential.familyName,
      );
      await Sentry.addBreadcrumb(Breadcrumb(
          message:
              'Apple Sign-In: backend succeeded, isFirstLogin=$isFirstLogin',
          category: 'auth'));
      if (!mounted) return;
      vibrateLoginLogout();
      await _navigateToMain(isFirstLogin: isFirstLogin);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('AuthorizationErrorCode.canceled')) {
        setState(() => _isAppleLoading = false);
        return;
      }
      setState(() {
        _loginError = Translations.of(context).auth_generic_error;
      });
    } finally {
      if (mounted) setState(() => _isAppleLoading = false);
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<void> _login() async {
    final t = Translations.of(context);
    final errors = <String, String?>{};
    if (_loginUsernameCtrl.text.trim().isEmpty) {
      errors['username'] = t.auth_val_username_required;
    }
    if (_loginPasswordCtrl.text.isEmpty) {
      errors['password'] = t.auth_val_password_required;
    }
    if (errors.isNotEmpty) {
      setState(() => _loginErrors = errors);
      return;
    }
    setState(() {
      _loginErrors = {};
      _isLoading = true;
      _loginError = null;
    });
    try {
      final isFirstLogin = await _apiService.authenticate(
        _loginUsernameCtrl.text.trim(),
        _loginPasswordCtrl.text,
      );
      if (!mounted) return;
      vibrateLoginLogout();
      try {
        await _navigateToMain(isFirstLogin: isFirstLogin);
      } catch (navError) {
        if (!mounted) return;
        debugPrint('AuthScreen: navigation error after login — $navError');
        if (mounted) {
          final navigator = Navigator.of(context);
          final afterAuth = widget.onAfterAuth;
          navigator.pushAndRemoveUntil(
            AppPageRoute(builder: (_) => const MainScreen()),
            (route) => false,
          );
          if (afterAuth != null) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => afterAuth(navigator));
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loginError = _isDeletedAccountError(e)
            ? Translations.of(context).auth_deleted_account_welcome_back
            : Translations.of(context).auth_invalid_credentials;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginAsDemo() async {
    _loginUsernameCtrl.text = kDebugUsername;
    _loginPasswordCtrl.text = kDebugPassword;
    await _login();
  }

  // ── Signup ────────────────────────────────────────────────────────────────

  Future<void> _signup() async {
    final t = Translations.of(context);
    final errors = <String, String?>{};
    if (_signupUsernameCtrl.text.trim().isEmpty) {
      errors['username'] = t.auth_val_username_required;
    } else if (_signupUsernameCtrl.text.trim().length < 4) {
      errors['username'] = t.auth_val_username_length;
    }
    if (_signupEmailCtrl.text.trim().isEmpty) {
      errors['email'] = t.auth_val_email_required;
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
        .hasMatch(_signupEmailCtrl.text.trim())) {
      errors['email'] = t.auth_val_email_invalid;
    }
    if (_signupPasswordCtrl.text.isEmpty) {
      errors['password'] = t.auth_val_password_required;
    } else if (_signupPasswordCtrl.text.length < 6) {
      errors['password'] = t.auth_val_password_length;
    }
    if (errors.isNotEmpty) {
      setState(() => _signupErrors = errors);
      return;
    }
    setState(() {
      _signupErrors = {};
      _isLoading = true;
    });
    try {
      final response = await _apiService.signup(
        _signupEmailCtrl.text,
        _signupUsernameCtrl.text,
        _signupPasswordCtrl.text,
      );
      if (!mounted) return;
      if (response.statusCode == 201) {
        showAppSnackBar(t.auth_signup_success, type: SnackBarType.success);
        _navigate(_AuthView.login);
      } else {
        final errorData = json.decode(response.body) as Map<String, dynamic>;
        final serverErrors = <String, String?>{};
        errorData.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            serverErrors[key] = value.first as String;
          } else if (value is String) {
            serverErrors[key] = value;
          }
        });
        setState(() => _signupErrors = serverErrors);
        showAppSnackBar(t.auth_signup_failed, type: SnackBarType.error);
      }
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(Translations.of(context).auth_generic_error,
          type: SnackBarType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isDeletedAccountError(Object error) {
    if (error is! DioException) return false;
    final data = error.response?.data;
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final code = (map['code'] ?? '').toString();
      final detail = (map['detail'] ?? '').toString().toLowerCase();
      if (code == 'account_deleted') return true;
      if (detail.contains('account has been deleted')) return true;
    }
    return false;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: kDebugMode
          ? FloatingActionButton.small(
              backgroundColor: Colors.orange,
              tooltip: 'Reset Onboarding',
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('onboarding_complete');
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  AppPageRoute(builder: (_) => const OnboardingScreen()),
                  (_) => false,
                );
              },
              child: const Icon(Icons.refresh, size: 18),
            )
          : null,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, anim) {
          final forward = _viewForward;
          final slide = Tween<Offset>(
            begin: Offset(forward ? 1.0 : -1.0, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
          return SlideTransition(position: slide, child: child);
        },
        child: switch (_view) {
          _AuthView.landing => _LandingView(
              key: const ValueKey('landing'),
              isGoogleLoading: _isGoogleLoading,
              googleLoadingStep: _googleLoadingStep,
              isAppleLoading: _isAppleLoading,
              isGuestLoading: _isGuestLoading,
              hasSavedGuestSession: _hasSavedGuestSession,
              loginError: _loginError,
              onGoogle: _signInWithGoogle,
              onApple: _signInWithApple,
              onLogin: () => _navigate(_AuthView.login),
              onSignup: () => _navigate(_AuthView.signup),
              onSetLocale: _setLocale,
              onContinueAsGuest: _continueAsGuest,
            ),
          _AuthView.login => _LoginView(
              key: const ValueKey('login'),
              isLoading: _isLoading,
              usernameCtrl: _loginUsernameCtrl,
              passwordCtrl: _loginPasswordCtrl,
              obscurePassword: _obscureLoginPw,
              onToggleObscure: () =>
                  setState(() => _obscureLoginPw = !_obscureLoginPw),
              loginError: _loginError,
              fieldErrors: _loginErrors,
              onLogin: _login,
              onDemoLogin: _loginAsDemo,
              onBack: () => _navigate(_AuthView.landing),
              onGoSignup: () => _navigate(_AuthView.signup),
              onForgotPassword: () => Navigator.of(context).push(
                AppPageRoute(builder: (_) => const ForgotPasswordScreen()),
              ),
            ),
          _AuthView.signup => _SignupView(
              key: const ValueKey('signup'),
              isLoading: _isLoading,
              usernameCtrl: _signupUsernameCtrl,
              emailCtrl: _signupEmailCtrl,
              passwordCtrl: _signupPasswordCtrl,
              obscurePassword: _obscureSignupPw,
              onToggleObscure: () =>
                  setState(() => _obscureSignupPw = !_obscureSignupPw),
              fieldErrors: _signupErrors,
              onSignup: _signup,
              onBack: () => _navigate(_AuthView.landing),
              onGoLogin: () => _navigate(_AuthView.login),
            ),
        },
      ),
    );
  }
}

// ─── Shared: Auth text field ──────────────────────────────────────────────────

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.error,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasError = error != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: hasError
                ? cs.error.withValues(alpha: 0.06)
                : cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: hasError
                ? Border.all(color: cs.error.withValues(alpha: 0.3))
                : Border.all(color: cs.outlineVariant.withValues(alpha: 0.15)),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: const InputDecorationTheme(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscureText,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                color: cs.onSurface,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: cs.outlineVariant,
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                suffixIcon: suffixIcon,
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: cs.error, size: 13),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    error!,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: cs.error),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Shared: Back button app bar ──────────────────────────────────────────────

class _AuthAppBar extends StatelessWidget {
  const _AuthAppBar({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
          children: [
            Material(
              color: cs.surfaceContainerLow,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onBack,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(Icons.arrow_back_rounded,
                      color: cs.primary, size: 22),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'DRIVE TEST',
              style: GoogleFonts.lexend(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Unified animated background for all auth screens ──────────────────────────
// Contains ambient glow, kinetic stripes, and free-motion items (vehicles + energy)
// that loop seamlessly via phase offset.

class _AmbientItem {
  const _AmbientItem({
    required this.icon,
    required this.startX,
    required this.startY,
    required this.velX,
    required this.velY,
    required this.rotSpeed,
    required this.phase,
    required this.iconSize,
    required this.opacity,
  });
  final IconData icon;
  final double
      startX; // normalized entry position (can be < 0 or > 1 = off-screen)
  final double startY;
  final double velX; // total x travel over one cycle (screen fractions)
  final double velY; // total y travel over one cycle
  final double
      rotSpeed; // full rotations per cycle (negative = counter-clockwise)
  final double phase; // 0–1 stagger offset so items enter at different times
  final double iconSize;
  final double opacity;
}

const _kAmbientItems = [
  // ── vehicles ──
  _AmbientItem(
      icon: Icons.directions_car_rounded,
      startX: -0.18,
      startY: 0.12,
      velX: 1.40,
      velY: 0.08,
      rotSpeed: 0.50,
      phase: 0.00,
      iconSize: 18,
      opacity: 0.08),
  _AmbientItem(
      icon: Icons.local_taxi,
      startX: -0.18,
      startY: 0.45,
      velX: 1.35,
      velY: -0.06,
      rotSpeed: 0.40,
      phase: 0.22,
      iconSize: 17,
      opacity: 0.08),
  _AmbientItem(
      icon: Icons.pedal_bike,
      startX: -0.18,
      startY: 0.72,
      velX: 1.30,
      velY: 0.10,
      rotSpeed: 0.70,
      phase: 0.55,
      iconSize: 16,
      opacity: 0.07),
  _AmbientItem(
      icon: Icons.two_wheeler,
      startX: 1.18,
      startY: 0.28,
      velX: -1.38,
      velY: 0.05,
      rotSpeed: -0.45,
      phase: 0.12,
      iconSize: 15,
      opacity: 0.07),
  _AmbientItem(
      icon: Icons.airport_shuttle_rounded,
      startX: 1.18,
      startY: 0.60,
      velX: -1.32,
      velY: -0.08,
      rotSpeed: -0.35,
      phase: 0.68,
      iconSize: 16,
      opacity: 0.06),
  _AmbientItem(
      icon: Icons.electric_scooter,
      startX: 1.18,
      startY: 0.85,
      velX: -1.28,
      velY: 0.04,
      rotSpeed: -0.60,
      phase: 0.38,
      iconSize: 14,
      opacity: 0.06),
  _AmbientItem(
      icon: Icons.directions_bus_rounded,
      startX: 0.20,
      startY: -0.18,
      velX: 0.06,
      velY: 1.40,
      rotSpeed: 0.30,
      phase: 0.05,
      iconSize: 20,
      opacity: 0.06),
  _AmbientItem(
      icon: Icons.local_shipping_rounded,
      startX: 0.65,
      startY: -0.18,
      velX: -0.04,
      velY: 1.35,
      rotSpeed: -0.25,
      phase: 0.48,
      iconSize: 17,
      opacity: 0.06),
  _AmbientItem(
      icon: Icons.directions_railway,
      startX: 0.40,
      startY: 1.18,
      velX: 0.08,
      velY: -1.40,
      rotSpeed: 0.20,
      phase: 0.30,
      iconSize: 18,
      opacity: 0.06),
  _AmbientItem(
      icon: Icons.traffic,
      startX: 0.80,
      startY: 1.18,
      velX: -0.05,
      velY: -1.32,
      rotSpeed: -0.15,
      phase: 0.75,
      iconSize: 15,
      opacity: 0.05),

  // ── energy & environment (cloud, flash, thunder) ──
  _AmbientItem(
      icon: Icons.bolt_rounded,
      startX: -0.25,
      startY: 0.30,
      velX: 1.50,
      velY: 0.15,
      rotSpeed: 2.00,
      phase: 0.10,
      iconSize: 22,
      opacity: 0.12),
  _AmbientItem(
      icon: Icons.cloud_rounded,
      startX: 1.25,
      startY: 0.15,
      velX: -1.50,
      velY: 0.05,
      rotSpeed: 0.15,
      phase: 0.45,
      iconSize: 26,
      opacity: 0.10),
  _AmbientItem(
      icon: Icons.electric_bolt_rounded,
      startX: 0.30,
      startY: -0.25,
      velX: 0.08,
      velY: 1.50,
      rotSpeed: -1.50,
      phase: 0.70,
      iconSize: 20,
      opacity: 0.12),
  _AmbientItem(
      icon: Icons.flash_on_rounded,
      startX: 0.70,
      startY: 1.25,
      velX: -0.08,
      velY: -1.50,
      rotSpeed: 1.20,
      phase: 0.25,
      iconSize: 20,
      opacity: 0.10),
  _AmbientItem(
      icon: Icons.auto_awesome_rounded,
      startX: -0.20,
      startY: 0.80,
      velX: 1.40,
      velY: -0.15,
      rotSpeed: 3.00,
      phase: 0.88,
      iconSize: 18,
      opacity: 0.15),
  _AmbientItem(
      icon: Icons.thunderstorm_rounded,
      startX: 1.20,
      startY: 0.60,
      velX: -1.40,
      velY: -0.08,
      rotSpeed: 0.30,
      phase: 0.35,
      iconSize: 22,
      opacity: 0.08),
  _AmbientItem(
      icon: Icons.cyclone,
      startX: 0.50,
      startY: 1.20,
      velX: -0.15,
      velY: -1.40,
      rotSpeed: 4.00,
      phase: 0.58,
      iconSize: 18,
      opacity: 0.07),
  _AmbientItem(
      icon: Icons.wb_sunny_rounded,
      startX: -0.20,
      startY: 0.05,
      velX: 1.40,
      velY: 0.02,
      rotSpeed: 0.05,
      phase: 0.82,
      iconSize: 24,
      opacity: 0.08),

  // ── diagonals ──
  _AmbientItem(
      icon: Icons.local_taxi,
      startX: -0.18,
      startY: -0.12,
      velX: 1.30,
      velY: 1.25,
      rotSpeed: 0.55,
      phase: 0.18,
      iconSize: 16,
      opacity: 0.07),
  _AmbientItem(
      icon: Icons.directions_car_rounded,
      startX: -0.15,
      startY: 0.35,
      velX: 1.25,
      velY: 0.90,
      rotSpeed: 0.45,
      phase: 0.62,
      iconSize: 15,
      opacity: 0.06),
  _AmbientItem(
      icon: Icons.two_wheeler,
      startX: 1.15,
      startY: -0.10,
      velX: -1.28,
      velY: 1.20,
      rotSpeed: -0.50,
      phase: 0.42,
      iconSize: 14,
      opacity: 0.06),
];

class _AnimatedAuthBg extends StatefulWidget {
  const _AnimatedAuthBg();

  @override
  State<_AnimatedAuthBg> createState() => _AnimatedAuthBgState();
}

class _AnimatedAuthBgState extends State<_AnimatedAuthBg>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<double> _randomScales;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 42),
    );

    final rand = math.Random(42);
    _randomScales = List.generate(
      _kAmbientItems.length,
      (_) => 0.7 + rand.nextDouble() * 0.5,
    );

    // Defer the animation until the route transition finishes so it doesn't
    // compete with the slide-in and cause dropped frames.
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) _ctrl.repeat();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);

    return Stack(
      children: [
        // Top-left glow
        Positioned(
          top: -size.height * 0.1,
          left: -size.width * 0.15,
          width: size.width * 0.7,
          height: size.width * 0.7,
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
        // Bottom-right shape
        Positioned(
          bottom: -size.height * 0.08,
          right: -size.width * 0.12,
          child: Transform.rotate(
            angle: 0.21,
            child: Container(
              width: size.width * 0.6,
              height: size.width * 0.6,
              decoration: BoxDecoration(
                color: cs.secondaryContainer.withValues(alpha: 0.25),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(120),
                ),
              ),
            ),
          ),
        ),
        // Kinetic stripe
        Positioned(
          bottom: 48,
          left: 0,
          child: Container(
            width: 100,
            height: 4,
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.35),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(9999),
                bottomRight: Radius.circular(9999),
              ),
            ),
          ),
        ),
        // Free-motion items with rotation
        AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return Stack(
              children: List.generate(_kAmbientItems.length, (i) {
                final v = _kAmbientItems[i];
                final scale = _randomScales[i];
                final progress = (_ctrl.value + v.phase) % 1.0;
                final px = v.startX + v.velX * progress;
                final py = v.startY + v.velY * progress;
                final angle = progress * v.rotSpeed * 2 * math.pi;

                // Fade in/out near the edges of travel (first/last 8% of path)
                final fade = (progress < 0.08
                        ? progress / 0.08
                        : progress > 0.92
                            ? (1.0 - progress) / 0.08
                            : 1.0)
                    .clamp(0.0, 1.0);

                return Positioned(
                  left: size.width * px,
                  top: size.height * py,
                  child: Opacity(
                    opacity: v.opacity * fade,
                    child: Transform.rotate(
                      angle: angle,
                      child: Icon(
                        v.icon,
                        size: v.iconSize * scale,
                        color: cs.primary,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}

// ─── View 1: Landing ─────────────────────────────────────────────────────────

class _LandingView extends StatelessWidget {
  const _LandingView({
    super.key,
    required this.isGoogleLoading,
    required this.googleLoadingStep,
    required this.isAppleLoading,
    required this.isGuestLoading,
    required this.hasSavedGuestSession,
    required this.loginError,
    required this.onGoogle,
    required this.onApple,
    required this.onLogin,
    required this.onSignup,
    required this.onSetLocale,
    required this.onContinueAsGuest,
  });

  final bool isGoogleLoading;
  final String googleLoadingStep;
  final bool isAppleLoading;
  final bool isGuestLoading;
  final bool hasSavedGuestSession;
  final String? loginError;
  final VoidCallback onGoogle;
  final VoidCallback onApple;
  final VoidCallback onLogin;
  final VoidCallback onSignup;
  final Future<void> Function(AppLocale) onSetLocale;
  final VoidCallback onContinueAsGuest;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = context.watch<ThemeProvider>().isDark;
    final currentLocale = LocaleSettings.currentLocale;
    final currentFlag = currentLocale == AppLocale.sv ? '🇸🇪' : '🇬🇧';

    return Stack(
      children: [
        const _AnimatedAuthBg(),
        SafeArea(
          child: Column(
            children: [
              // Top-right: language + theme toggle
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 16),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(9999),
                      boxShadow: [
                        BoxShadow(
                          color: cs.onSurface.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PopupMenuButton<AppLocale>(
                          tooltip: Translations.of(context).settings_language,
                          onSelected: onSetLocale,
                          itemBuilder: (_) => [
                            CheckedPopupMenuItem<AppLocale>(
                              value: AppLocale.en,
                              checked: currentLocale == AppLocale.en,
                              child: const Text('🇬🇧 English'),
                            ),
                            CheckedPopupMenuItem<AppLocale>(
                              value: AppLocale.sv,
                              checked: currentLocale == AppLocale.sv,
                              child: const Text('🇸🇪 Svenska'),
                            ),
                          ],
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 6, 10, 6),
                            child: Text(currentFlag,
                                style: const TextStyle(fontSize: 20)),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 20,
                          color: cs.outlineVariant.withValues(alpha: 0.4),
                        ),
                        IconButton(
                          padding: const EdgeInsets.fromLTRB(10, 6, 16, 6),
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            isDark
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                            size: 20,
                            color: cs.onSurfaceVariant,
                          ),
                          onPressed: () =>
                              context.read<ThemeProvider>().toggle(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Branding — flexible top half
              Expanded(
                flex: 5,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: RichText(
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            text: TextSpan(
                              style: GoogleFonts.lexend(
                                fontSize: 56,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -2,
                                height: 1.0,
                                color: cs.onSurface,
                              ),
                              children: [
                                const TextSpan(text: 'DRIVE '),
                                TextSpan(
                                  text: 'TEST',
                                  style: GoogleFonts.lexend(
                                    fontStyle: FontStyle.italic,
                                    color: cs.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          Translations.of(context).auth_landing_subtitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            color: cs.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        if (loginError != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: cs.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: cs.error, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    loginError!,
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13, color: cs.error),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Action cluster — bottom half
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Log in — full-width gradient button
                      AppButton(
                        label: Translations.of(context).auth_tab_login,
                        onPressed: onLogin,
                      ),
                      const SizedBox(height: 10),
                      // Social sign-in icons — row below login button
                      SizedBox(
                        height: 54,
                        child: Row(
                          children: [
                            if (AppleSignInHelper.isAvailable()) ...[
                              AppSocialButton(
                                icon: FontAwesomeIcons.apple,
                                iconSize: 22,
                                loading: isAppleLoading,
                                onPressed: isGoogleLoading ? null : onApple,
                              ),
                              const SizedBox(width: 10),
                            ],
                            AppSocialButton(
                              icon: FontAwesomeIcons.google,
                              iconSize: 18,
                              loading: isGoogleLoading,
                              loadingLabel: googleLoadingStep.isNotEmpty
                                  ? googleLoadingStep
                                  : null,
                              onPressed: isAppleLoading ? null : onGoogle,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Sign-up footer text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${Translations.of(context).auth_landing_new_here} ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          GestureDetector(
                            onTap: onSignup,
                            child: Text(
                              Translations.of(context).auth_create_account_link,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: cs.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Continue as guest — light text link (only if prior session exists)
                      if (hasSavedGuestSession) ...[
                        const SizedBox(height: 12),
                        isGuestLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: cs.onSurfaceVariant),
                              )
                            : GestureDetector(
                                onTap: onContinueAsGuest,
                                child: Text(
                                  Translations.of(context)
                                      .auth_continue_as_guest,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: cs.onSurfaceVariant
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── View 2: Login form ───────────────────────────────────────────────────────

class _LoginView extends StatelessWidget {
  const _LoginView({
    super.key,
    required this.isLoading,
    required this.usernameCtrl,
    required this.passwordCtrl,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.loginError,
    required this.fieldErrors,
    required this.onLogin,
    required this.onDemoLogin,
    required this.onBack,
    required this.onGoSignup,
    required this.onForgotPassword,
  });

  final bool isLoading;
  final TextEditingController usernameCtrl;
  final TextEditingController passwordCtrl;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final String? loginError;
  final Map<String, String?> fieldErrors;
  final VoidCallback onLogin;
  final VoidCallback onDemoLogin;
  final VoidCallback onBack;
  final VoidCallback onGoSignup;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Translations.of(context);

    return Stack(
      children: [
        const _AnimatedAuthBg(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AuthAppBar(onBack: onBack),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Editorial headline
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          top: -24,
                          left: -16,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  cs.secondaryContainer.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Translations.of(context).auth_login_heading,
                              style: GoogleFonts.lexend(
                                fontSize: 46,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.5,
                                height: 1.0,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              Translations.of(context).auth_login_subtitle,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Error banner
                    if (loginError != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: cs.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: cs.error, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(loginError!,
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13, color: cs.error)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Username or Email
                    _AuthField(
                      label: t.auth_username,
                      controller: usernameCtrl,
                      hint: t.auth_username_hint,
                      keyboardType: TextInputType.emailAddress,
                      error: fieldErrors['username'],
                    ),
                    const SizedBox(height: 18),

                    // Password
                    _AuthField(
                      label: t.auth_password,
                      controller: passwordCtrl,
                      hint: '••••••••',
                      obscureText: obscurePassword,
                      error: fieldErrors['password'],
                      suffixIcon: TextButton(
                        onPressed: onToggleObscure,
                        child: Text(
                          obscurePassword
                              ? t.auth_show_password
                              : t.auth_hide_password,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: cs.outline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: onForgotPassword,
                        child: Text(
                          t.auth_forgot_password,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: cs.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Sign In button
                    AppButton(
                      label: t.auth_login_title,
                      loading: isLoading,
                      loadingLabel: t.auth_signing_in,
                      onPressed: onLogin,
                    ),
                    const SizedBox(height: 16),

                    // Demo login (debug only)
                    if (kDebugMode)
                      Center(
                        child: TextButton(
                          onPressed: isLoading ? null : onDemoLogin,
                          child: Text(
                            t.auth_skip_demo_short,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: cs.outline,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),

                    // Switch to signup
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${t.auth_no_account} ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          GestureDetector(
                            onTap: onGoSignup,
                            child: Text(
                              t.auth_tab_signup,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: cs.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── View 3: Sign Up form ─────────────────────────────────────────────────────

class _SignupView extends StatelessWidget {
  const _SignupView({
    super.key,
    required this.isLoading,
    required this.usernameCtrl,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.fieldErrors,
    required this.onSignup,
    required this.onBack,
    required this.onGoLogin,
  });

  final bool isLoading;
  final TextEditingController usernameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final Map<String, String?> fieldErrors;
  final VoidCallback onSignup;
  final VoidCallback onBack;
  final VoidCallback onGoLogin;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Translations.of(context);

    return Stack(
      children: [
        const _AnimatedAuthBg(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AuthAppBar(onBack: onBack),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Editorial headline
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          top: -20,
                          left: -16,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  cs.secondaryContainer.withValues(alpha: 0.22),
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: GoogleFonts.lexend(
                                  fontSize: 46,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.5,
                                  height: 1.1,
                                  color: cs.onSurface,
                                ),
                                children: [
                                  TextSpan(
                                      text:
                                          '${Translations.of(context).auth_signup_heading_plain}\n'),
                                  TextSpan(
                                    text: Translations.of(context)
                                        .auth_signup_heading_italic,
                                    style: GoogleFonts.lexend(
                                      fontStyle: FontStyle.italic,
                                      color: cs.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              Translations.of(context).auth_signup_subtitle,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Username
                    _AuthField(
                      label: t.auth_username,
                      controller: usernameCtrl,
                      hint: t.auth_signup_username_hint,
                      error: fieldErrors['username'],
                    ),
                    const SizedBox(height: 18),

                    // Email
                    _AuthField(
                      label: t.auth_email,
                      controller: emailCtrl,
                      hint: t.auth_signup_email_hint,
                      keyboardType: TextInputType.emailAddress,
                      error: fieldErrors['email'],
                    ),
                    const SizedBox(height: 18),

                    // Password
                    _AuthField(
                      label: t.auth_password,
                      controller: passwordCtrl,
                      hint: '••••••••',
                      obscureText: obscurePassword,
                      error: fieldErrors['password'],
                      suffixIcon: TextButton(
                        onPressed: onToggleObscure,
                        child: Text(
                          obscurePassword
                              ? t.auth_show_password
                              : t.auth_hide_password,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: cs.outline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Create Account button
                    AppButton(
                      label: t.auth_sign_up_btn,
                      loading: isLoading,
                      loadingLabel: t.auth_signing_in,
                      onPressed: onSignup,
                    ),
                    const SizedBox(height: 40),

                    // Switch to login
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${t.auth_have_account}  ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          GestureDetector(
                            onTap: onGoLogin,
                            child: Text(
                              t.auth_tab_login,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: cs.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
