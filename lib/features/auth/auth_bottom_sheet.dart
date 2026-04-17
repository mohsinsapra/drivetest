import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/auth/google_sign_in_helper.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/services/bcd_cache.dart';
import 'package:taxi_exam_app/core/services/notification_service.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';

/// Shows a modal bottom sheet with login / sign-up tabs.
/// Returns `true` when the user successfully authenticates, `false`/null if dismissed.
Future<bool> showAuthBottomSheet(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AuthSheet(),
  );
  return result == true;
}

// ─────────────────────────────────────────────────────────────────────────────

class _AuthSheet extends StatefulWidget {
  const _AuthSheet();

  @override
  State<_AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<_AuthSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _api = ApiService();
  bool _loading = false;

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
    try {
      await NotificationService.init(ApiService())
          .timeout(const Duration(seconds: 6));
    } catch (_) {}
    if (mounted) Navigator.of(context).pop(true);
  }

  // ── Google ──────────────────────────────────────────────────────────────────

  Future<void> _googleSignIn() async {
    setState(() {
      _loading = true;
      _loginError = null;
    });
    try {
      final helper = GoogleSignInHelper.create();
      final user = await helper.signIn();
      if (user == null) {
        setState(() => _loading = false);
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
        _loading = false;
      });
    }
  }

  // ── Login ───────────────────────────────────────────────────────────────────

  Future<void> _login() async {
    final t = Translations.of(context);
    final errs = <String, String?>{};
    if (_loginUser.text.trim().isEmpty) errs['user'] = t.auth_val_username_required;
    if (_loginPass.text.isEmpty) errs['pass'] = t.auth_val_password_required;
    if (errs.isNotEmpty) {
      setState(() => _loginFieldErrors = errs);
      return;
    }
    setState(() {
      _loginFieldErrors = {};
      _loginError = null;
      _loading = true;
    });
    try {
      await _api.authenticate(
          _loginUser.text.trim(), _loginPass.text);
      if (!mounted) return;
      await _onSuccess();
    } on DioException {
      if (!mounted) return;
      setState(() {
        _loginError = t.auth_invalid_credentials;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loginError = Translations.of(context).auth_generic_error;
        _loading = false;
      });
    }
  }

  // ── Sign up ─────────────────────────────────────────────────────────────────

  Future<void> _signup() async {
    final t = Translations.of(context);
    final errs = <String, String?>{};
    if (_signupUser.text.trim().isEmpty) errs['user'] = t.auth_val_username_required;
    if (_signupEmail.text.trim().isEmpty) errs['email'] = t.auth_val_email_required;
    if (_signupPass.text.isEmpty) errs['pass'] = t.auth_val_password_required;
    if (errs.isNotEmpty) {
      setState(() => _signupFieldErrors = errs);
      return;
    }
    setState(() {
      _signupFieldErrors = {};
      _loading = true;
    });
    try {
      final resp = await _api.signup(
          _signupEmail.text.trim(),
          _signupUser.text.trim(),
          _signupPass.text);
      if (!mounted) return;
      if (resp.statusCode == 201) {
        // Auto-login after signup
        await _api.authenticate(_signupUser.text.trim(), _signupPass.text);
        if (!mounted) return;
        await _onSuccess();
      } else {
        setState(() => _loading = false);
        showAppSnackBar(t.auth_signup_failed, type: SnackBarType.error);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppSnackBar(
          Translations.of(context).auth_generic_error,
          type: SnackBarType.error);
    }
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark
        ? theme.colorScheme.onSurface.withValues(alpha: 0.08)
        : theme.colorScheme.onSurface.withValues(alpha: 0.06);
    final errBg = Colors.red.withValues(alpha: 0.06);

    return Container(
      decoration: BoxDecoration(
        color: hasError ? errBg : bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        onChanged: onChanged,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: onToggleObscure != null
              ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  onPressed: onToggleObscure,
                )
              : null,
        ),
      ),
    );
  }

  Widget _fieldErr(String? err) {
    if (err == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 5, left: 4),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 13, color: Colors.red.shade400),
          const SizedBox(width: 4),
          Expanded(
            child: Text(err,
                style: TextStyle(fontSize: 12, color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }

  Widget _submitButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ElevatedButton(
              onPressed: onPressed,
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15)),
            ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark ? theme.colorScheme.surface : theme.scaffoldBackgroundColor;

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
            t.onb_sign_in_to_subscribe,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            t.onb_sign_in_subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Google button
          InkWell(
            onTap: _loading ? null : _googleSignIn,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.08)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    t.auth_google_label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const Spacer(),
                  FaIcon(FontAwesomeIcons.google,
                      size: 18,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(child: Divider(color: theme.dividerColor)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'or',
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
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14),
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
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _loginError!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              ],
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
