import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/auth/apple_sign_in_helper.dart';
import 'package:taxi_exam_app/core/auth/google_sign_in_helper.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/services/bcd_cache.dart';
import 'package:taxi_exam_app/core/services/iap_service.dart';
import 'package:taxi_exam_app/core/services/notification_service.dart';
import 'package:taxi_exam_app/core/widgets/app_button.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'package:taxi_exam_app/features/auth/debug_credentials.dart';

/// Shows a modal bottom sheet with login / sign-up tabs.
/// Returns `true` when the user successfully authenticates, `false`/null if dismissed.
///
/// Optional [title] and [subtitle] override the default localized header text.
/// Set [required] to true to prevent dismissal by tapping outside — use this
/// post-purchase so the user cannot leave without activating their subscription.
Future<bool> showAuthBottomSheet(
  BuildContext context, {
  String? title,
  String? subtitle,
  bool required = false,
  bool allowDemo = true,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: !required,
    enableDrag: !required,
    builder: (_) =>
        _AuthSheet(title: title, subtitle: subtitle, allowDemo: allowDemo),
  );
  return result == true;
}

// ─────────────────────────────────────────────────────────────────────────────

class _AuthSheet extends StatefulWidget {
  const _AuthSheet({this.title, this.subtitle, this.allowDemo = true});

  final String? title;
  final String? subtitle;
  final bool allowDemo;

  @override
  State<_AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<_AuthSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _api = ApiService();
  bool _appleLoading = false;
  bool _googleLoading = false;
  bool _formLoading = false;

  // Login
  final _loginUser = TextEditingController();
  final _loginPass = TextEditingController();
  bool _obscureLogin = true;
  String? _loginError;
  Map<String, String?> _loginFieldErrors = {};

  // Signup
  final _signupUser = TextEditingController();
  final _signupEmail = TextEditingController();
  final _signupPass = TextEditingController();
  bool _obscureSignup = true;
  Map<String, String?> _signupFieldErrors = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    if (kDebugMode) {
      _loginUser.text = kDebugUsername;
      _loginPass.text = kDebugPassword;
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _loginUser.dispose();
    _loginPass.dispose();
    _signupUser.dispose();
    _signupEmail.dispose();
    _signupPass.dispose();
    super.dispose();
  }

  // ── Auth success ────────────────────────────────────────────────────────────

  Future<void> _onSuccess() async {
    BcdCache.instance.invalidate();
    IAPService.instance.verifyDeferredReceipt().ignore();
    try {
      await NotificationService.init(ApiService())
          .timeout(const Duration(seconds: 6));
    } catch (_) {}
    if (mounted) Navigator.of(context).pop(true);
  }

  // ── Google ──────────────────────────────────────────────────────────────────

  Future<void> _googleSignIn() async {
    setState(() {
      _googleLoading = true;
      _loginError = null;
    });
    try {
      final helper = GoogleSignInHelper.create();
      await helper.signOut();
      final user = await helper.signIn();
      if (user == null) {
        setState(() => _googleLoading = false);
        return;
      }
      final auth = await user.authentication;
      await _api.googleAuth(
          idToken: auth.idToken, accessToken: auth.accessToken);
      if (!mounted) return;
      await _onSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loginError = GoogleSignInHelper.userMessage(e);
        _googleLoading = false;
      });
    }
  }

  // ── Apple ───────────────────────────────────────────────────────────────────

  Future<void> _appleSignIn() async {
    setState(() {
      _appleLoading = true;
      _loginError = null;
    });
    try {
      final credential = await AppleSignInHelper.signIn();
      final identityToken = credential.identityToken;
      if (identityToken == null) throw Exception('No identity token received');
      await _api.appleAuth(
        identityToken: identityToken,
        firstName: credential.givenName,
        lastName: credential.familyName,
      );
      if (!mounted) return;
      await _onSuccess();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('AuthorizationErrorCode.canceled')) {
        setState(() => _appleLoading = false);
        return;
      }
      setState(() {
        _loginError = Translations.of(context).auth_generic_error;
        _appleLoading = false;
      });
    }
  }

  // ── Login ───────────────────────────────────────────────────────────────────

  Future<void> _login() async {
    final t = Translations.of(context);
    final errs = <String, String?>{};
    if (_loginUser.text.trim().isEmpty) {
      errs['user'] = t.auth_val_username_required;
    }
    if (_loginPass.text.isEmpty) errs['pass'] = t.auth_val_password_required;
    if (errs.isNotEmpty) {
      setState(() => _loginFieldErrors = errs);
      return;
    }
    setState(() {
      _loginFieldErrors = {};
      _loginError = null;
      _formLoading = true;
    });
    try {
      await _api.authenticate(_loginUser.text.trim(), _loginPass.text);
      if (!mounted) return;
      await _onSuccess();
    } on DioException catch (e) {
      if (!mounted) return;
      // Timeout and throttle errors are shown via DioClient snackbar — suppress inline.
      final silenced = e.response?.statusCode == 429 ||
          e.response?.statusCode == 503 ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout;
      setState(() {
        _loginError = silenced ? null : t.auth_invalid_credentials;
        _formLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loginError = Translations.of(context).auth_generic_error;
        _formLoading = false;
      });
    }
  }

  // ── Sign up ─────────────────────────────────────────────────────────────────

  Future<void> _signup() async {
    final t = Translations.of(context);
    final errs = <String, String?>{};
    if (_signupUser.text.trim().isEmpty) {
      errs['user'] = t.auth_val_username_required;
    }
    if (_signupEmail.text.trim().isEmpty) {
      errs['email'] = t.auth_val_email_required;
    }
    if (_signupPass.text.isEmpty) errs['pass'] = t.auth_val_password_required;
    if (errs.isNotEmpty) {
      setState(() => _signupFieldErrors = errs);
      return;
    }
    setState(() {
      _signupFieldErrors = {};
      _formLoading = true;
    });
    try {
      final resp = await _api.signup(
          _signupEmail.text.trim(), _signupUser.text.trim(), _signupPass.text);
      if (!mounted) return;
      if (resp.statusCode == 201) {
        // Auto-login after signup
        await _api.authenticate(_signupUser.text.trim(), _signupPass.text);
        if (!mounted) return;
        await _onSuccess();
      } else {
        setState(() => _formLoading = false);
        showAppSnackBar(t.auth_signup_failed, type: SnackBarType.error);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _formLoading = false);
      showAppSnackBar(Translations.of(context).auth_generic_error,
          type: SnackBarType.error);
    }
  }

  // ── Demo login ───────────────────────────────────────────────────────────────

  Future<void> _loginAsDemo() async {
    _loginUser.text = kDebugUsername;
    _loginPass.text = kDebugPassword;
    await _login();
  }

  // ── UI helpers ───────────────────────────────────────────────────────────────

  Widget _field({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    bool hasError = false,
    TextInputType keyboard = TextInputType.text,
    VoidCallback? onToggleObscure,
    void Function(String)? onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
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
          obscureText: obscure,
          keyboardType: keyboard,
          onChanged: onChanged,
          style: GoogleFonts.plusJakartaSans(fontSize: 15, color: cs.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              color: cs.outlineVariant,
            ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            suffixIcon: onToggleObscure != null
                ? TextButton(
                    onPressed: onToggleObscure,
                    child: Text(
                      obscure
                          ? Translations.of(context).auth_show_password
                          : Translations.of(context).auth_hide_password,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: cs.outline,
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _fieldErr(String? err) {
    if (err == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 13, color: cs.error),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              err,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: cs.error),
            ),
          ),
        ],
      ),
    );
  }

  bool get _anyLoading => _appleLoading || _googleLoading || _formLoading;

  Widget _submitButton(String label, VoidCallback onPressed) {
    final t = Translations.of(context);
    return AppButton(
      height: 54,
      label: label,
      loading: _formLoading,
      loadingLabel: t.auth_signing_in,
      onPressed: _anyLoading ? null : onPressed,
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg =
        isDark ? theme.colorScheme.surface : theme.scaffoldBackgroundColor;

    // Shrink on small screens
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Text(
            widget.title ?? t.onb_sign_in_to_subscribe,
            style: GoogleFonts.lexend(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.subtitle ?? t.onb_sign_in_subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Apple button (iOS/macOS only — must appear before Google per Guideline 4.8)
          if (AppleSignInHelper.isAvailable()) ...[
            AppButton(
              height: 54,
              label: t.auth_express_apple,
              loading: _appleLoading,
              loadingLabel: t.auth_signing_in,
              onPressed: _anyLoading ? null : _appleSignIn,
              icon: FaIcon(FontAwesomeIcons.apple,
                  size: 20, color: theme.colorScheme.onPrimary),
            ),
            const SizedBox(height: 10),
          ],

          // Google button
          AppButton(
            height: 54,
            label: t.auth_express_google,
            loading: _googleLoading,
            loadingLabel: t.auth_signing_in,
            onPressed: _anyLoading ? null : _googleSignIn,
            icon: FaIcon(FontAwesomeIcons.google,
                size: 18, color: theme.colorScheme.onPrimary),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(child: Divider(color: theme.dividerColor)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  t.auth_or,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
              Expanded(child: Divider(color: theme.dividerColor)),
            ],
          ),
          const SizedBox(height: 10),

          // Tab bar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.08)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabs,
              indicator: BoxDecoration(
                color: isDark ? theme.cardColor : theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: theme.colorScheme.onSurface,
              unselectedLabelColor:
                  theme.colorScheme.onSurface.withValues(alpha: 0.4),
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontSize: 14),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: t.auth_tab_login),
                Tab(text: t.auth_tab_signup),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Login error banner
          if (_loginError != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: theme.colorScheme.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _loginError!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Tab forms — fixed height avoids overflow / layout thrash
          SizedBox(
            height: 200,
            child: TabBarView(
              controller: _tabs,
              children: [
                // ── Login ──
                _LoginForm(
                  userCtrl: _loginUser,
                  passCtrl: _loginPass,
                  obscure: _obscureLogin,
                  fieldErrors: _loginFieldErrors,
                  onToggleObscure: () =>
                      setState(() => _obscureLogin = !_obscureLogin),
                  onUserChanged: (_) =>
                      setState(() => _loginFieldErrors.remove('user')),
                  onPassChanged: (_) =>
                      setState(() => _loginFieldErrors.remove('pass')),
                  buildField: _field,
                  buildErr: _fieldErr,
                ),
                // ── Sign up ──
                _SignupForm(
                  userCtrl: _signupUser,
                  emailCtrl: _signupEmail,
                  passCtrl: _signupPass,
                  obscure: _obscureSignup,
                  fieldErrors: _signupFieldErrors,
                  onToggleObscure: () =>
                      setState(() => _obscureSignup = !_obscureSignup),
                  onUserChanged: (_) =>
                      setState(() => _signupFieldErrors.remove('user')),
                  onEmailChanged: (_) =>
                      setState(() => _signupFieldErrors.remove('email')),
                  onPassChanged: (_) =>
                      setState(() => _signupFieldErrors.remove('pass')),
                  buildField: _field,
                  buildErr: _fieldErr,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // CTA button changes label per tab
          AnimatedBuilder(
            animation: _tabs,
            builder: (_, __) => _submitButton(
              _tabs.index == 0 ? t.auth_login_title : t.auth_sign_up_btn,
              _tabs.index == 0 ? _login : _signup,
            ),
          ),

          // Demo login (debug only, hidden when called from onboarding)
          if (kDebugMode && widget.allowDemo) ...[
            const SizedBox(height: 8),
            Center(
              child: AppTextButton(
                label: t.auth_skip_demo_short,
                onPressed: _anyLoading ? null : _loginAsDemo,
                foregroundColor: Theme.of(context).colorScheme.outline,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Login form (extracted so TabBarView has fixed-height children)
// ─────────────────────────────────────────────────────────────────────────────

typedef _FieldBuilder = Widget Function({
  required TextEditingController controller,
  required String hint,
  bool obscure,
  bool hasError,
  TextInputType keyboard,
  VoidCallback? onToggleObscure,
  void Function(String)? onChanged,
});

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.userCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.fieldErrors,
    required this.onToggleObscure,
    required this.onUserChanged,
    required this.onPassChanged,
    required this.buildField,
    required this.buildErr,
  });

  final TextEditingController userCtrl;
  final TextEditingController passCtrl;
  final bool obscure;
  final Map<String, String?> fieldErrors;
  final VoidCallback onToggleObscure;
  final ValueChanged<String> onUserChanged;
  final ValueChanged<String> onPassChanged;
  final _FieldBuilder buildField;
  final Widget Function(String?) buildErr;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Column(
      children: [
        buildField(
          controller: userCtrl,
          hint: t.auth_username,
          hasError: fieldErrors['user'] != null,
          keyboard: TextInputType.emailAddress,
          onChanged: onUserChanged,
        ),
        buildErr(fieldErrors['user']),
        const SizedBox(height: 8),
        buildField(
          controller: passCtrl,
          hint: t.auth_password,
          obscure: obscure,
          hasError: fieldErrors['pass'] != null,
          onToggleObscure: onToggleObscure,
          onChanged: onPassChanged,
        ),
        buildErr(fieldErrors['pass']),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Signup form
// ─────────────────────────────────────────────────────────────────────────────

class _SignupForm extends StatelessWidget {
  const _SignupForm({
    required this.userCtrl,
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.fieldErrors,
    required this.onToggleObscure,
    required this.onUserChanged,
    required this.onEmailChanged,
    required this.onPassChanged,
    required this.buildField,
    required this.buildErr,
  });

  final TextEditingController userCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool obscure;
  final Map<String, String?> fieldErrors;
  final VoidCallback onToggleObscure;
  final ValueChanged<String> onUserChanged;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onPassChanged;
  final _FieldBuilder buildField;
  final Widget Function(String?) buildErr;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Column(
      children: [
        buildField(
          controller: userCtrl,
          hint: t.auth_username,
          hasError: fieldErrors['user'] != null,
          onChanged: onUserChanged,
        ),
        buildErr(fieldErrors['user']),
        const SizedBox(height: 8),
        buildField(
          controller: emailCtrl,
          hint: t.auth_email,
          hasError: fieldErrors['email'] != null,
          keyboard: TextInputType.emailAddress,
          onChanged: onEmailChanged,
        ),
        buildErr(fieldErrors['email']),
        const SizedBox(height: 8),
        buildField(
          controller: passCtrl,
          hint: t.auth_password,
          obscure: obscure,
          hasError: fieldErrors['pass'] != null,
          onToggleObscure: onToggleObscure,
          onChanged: onPassChanged,
        ),
        buildErr(fieldErrors['pass']),
      ],
    );
  }
}
