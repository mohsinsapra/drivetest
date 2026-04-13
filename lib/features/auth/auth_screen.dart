import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'dart:convert';

import 'package:taxi_exam_app/core/services/notification_service.dart';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/api/dio_client.dart';
import 'package:taxi_exam_app/core/auth/google_sign_in_helper.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/providers/theme_provider.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'package:taxi_exam_app/features/auth/forgot_password_screen.dart';
import 'package:taxi_exam_app/main_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  // Login state
  final TextEditingController _loginUsernameController =
      TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();
  bool _obscureLoginPassword = true;
  String? _loginError;
  Map<String, String?> _loginErrors = {};

  // Signup state
  final TextEditingController _signupUsernameController =
      TextEditingController();
  final TextEditingController _signupEmailController = TextEditingController();
  final TextEditingController _signupPasswordController =
      TextEditingController();
  bool _obscureSignupPassword = true;
  Map<String, String?> _signupErrors = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginUsernameController.dispose();
    _loginPasswordController.dispose();
    _signupUsernameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    super.dispose();
  }

  Future<void> _setLocale(AppLocale locale) async {
    await LocaleSettings.setLocale(locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', locale.languageCode);
  }

  Future<void> _navigateToMain({required bool isFirstLogin}) async {
    final user = await _apiService.fetchCurrentUser();
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(user));
      _showWelcomeMessage(
        Map<String, dynamic>.from(user as Map),
        isFirstLogin: isFirstLogin,
      );
    }
    await Hive.close();
    await Hive.deleteFromDisk();
    await DioClient().init();
    // Register FCM token now that auth tokens are loaded
    NotificationService.init(_apiService).ignore();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        AppPageRoute(builder: (context) => const MainScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  void _showWelcomeMessage(
    Map<String, dynamic> user, {
    required bool isFirstLogin,
  }) {
    final t = Translations.of(context);

    if (isFirstLogin) {
      showAppSnackBar(
        t.auth_welcome_first_login,
        type: SnackBarType.success,
      );
      return;
    }

    showAppSnackBar(
      t.auth_welcome_returning,
      type: SnackBarType.success,
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _loginError = null;
    });
    try {
      final googleSignIn = GoogleSignInHelper.create();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      if (idToken == null && accessToken == null) {
        throw Exception('No authentication token received');
      }
      final isFirstLogin =
          await _apiService.googleAuth(idToken: idToken, accessToken: accessToken);
      if (!mounted) return;
      await _navigateToMain(isFirstLogin: isFirstLogin);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_isDeletedAccountError(e)) {
          _loginError = Translations.of(context).auth_deleted_account_welcome_back;
        } else {
          _loginError = GoogleSignInHelper.userMessage(e);
        }
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _login() async {
    final t = Translations.of(context);
    final errors = <String, String?>{};
    if (_loginUsernameController.text.trim().isEmpty) {
      errors['username'] = t.auth_val_username_required;
    }
    if (_loginPasswordController.text.isEmpty) {
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
        _loginUsernameController.text.trim(),
        _loginPasswordController.text,
      );
      if (!mounted) return;
      await _navigateToMain(isFirstLogin: isFirstLogin);
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

  Future<void> _loginAsDemo() async {
    _loginUsernameController.text = 'demo';
    _loginPasswordController.text = 'Demo@123';
    await _login();
  }

  Future<void> _signup() async {
    final t = Translations.of(context);
    final errors = <String, String?>{};
    if (_signupUsernameController.text.trim().isEmpty) {
      errors['username'] = t.auth_val_username_required;
    } else if (_signupUsernameController.text.trim().length < 4) {
      errors['username'] = t.auth_val_username_length;
    }
    if (_signupEmailController.text.trim().isEmpty) {
      errors['email'] = t.auth_val_email_required;
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
        .hasMatch(_signupEmailController.text.trim())) {
      errors['email'] = t.auth_val_email_invalid;
    }
    if (_signupPasswordController.text.isEmpty) {
      errors['password'] = t.auth_val_password_required;
    } else if (_signupPasswordController.text.length < 6) {
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
        _signupEmailController.text,
        _signupUsernameController.text,
        _signupPasswordController.text,
      );
      if (!mounted) return;
      if (response.statusCode == 201) {
        showAppSnackBar(t.auth_signup_success, type: SnackBarType.success);
        _tabController.animateTo(0);
      } else {
        final Map<String, dynamic> errorData =
            json.decode(response.body) as Map<String, dynamic>;
        final serverErrors = <String, String?>{};
        errorData.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            serverErrors[key] = value.first as String;
          } else if (value is String) {
            serverErrors[key] = value;
          }
        });
        setState(() => _signupErrors = serverErrors);
        showAppSnackBar(Translations.of(context).auth_signup_failed);
      }
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(Translations.of(context).auth_generic_error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Wraps field widgets in a themed container that suppresses all
  /// InputDecorationTheme borders (so theme borders never bleed through).
  Widget _buildFieldContainer({
    required List<Widget> children,
    required Color fieldBg,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: const InputDecorationTheme(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: fieldBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: children),
      ),
    );
  }


  InputDecoration _fieldDecoration({
    String? hint,
    Widget? suffixWidget,
    double s = 1.0,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        fontSize: 14 * s,
      ),
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16 * s),
      suffixIcon: suffixWidget,
    );
  }

  Widget _fieldError(String? error, double s) {
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Row(
        children: [
          Icon(Icons.error_outline,
              color: Colors.red.shade400, size: 13),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                color: Colors.red.shade400,
                fontSize: 12 * s,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final isDark = context.watch<ThemeProvider>().isDark;
    final currentLocale = LocaleSettings.currentLocale;
    final currentFlag = currentLocale == AppLocale.sv ? '🇸🇪' : '🇬🇧';

    // Scale factor: 1.0 on tall screens (≥ 812), shrinks on shorter ones, min 0.78
    final s =
        (MediaQuery.of(context).size.height / 812.0).clamp(0.78, 1.0);

    // Use theme.cardColor for all cards/fields (dark: #1C1C1E, light: white)
    // For subtle contrast on white scaffold, fall back to a tinted card bg
    final fieldBg = isDark
        ? theme.cardColor
        : theme.colorScheme.onSurface.withValues(alpha: 0.06);

    final tabContainerBg = fieldBg;

    // Active tab pill: slightly lighter than the container in dark, scaffold bg in light
    final tabActiveBg = isDark
        ? Color.lerp(theme.cardColor, theme.colorScheme.onSurface, 0.12)!
        : theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top bar ──
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PopupMenuButton<AppLocale>(
                        tooltip: 'Language',
                        onSelected: _setLocale,
                        itemBuilder: (context) => [
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
                          padding: const EdgeInsets.only(left: 18, right: 10, top: 6, bottom: 6),
                          child: Text(currentFlag,
                              style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                        child: VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: theme.dividerColor.withValues(alpha: 0.4),
                        ),
                      ),
                      IconButton(
                        padding: const EdgeInsets.only(left: 10, right: 18, top: 6, bottom: 6),
                        constraints: const BoxConstraints(),
                        icon: Icon(isDark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined),
                        onPressed: () => context.read<ThemeProvider>().toggle(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Body: logo (flex 2) + content (flex 5) ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo — centered in its flexible slice
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Image.asset(
                        'assets/icon/icon.png',
                        height: 64 * s,
                        width: 64 * s,
                      ),
                    ),
                  ),

                  // Google button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.auth_express_google,
                          style: TextStyle(
                            fontSize: 12 * s,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        SizedBox(height: 8 * s),
                        InkWell(
                          onTap: _isLoading ? null : _signInWithGoogle,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14 * s),
                            decoration: BoxDecoration(
                              color: fieldBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  t.auth_google_label,
                                  style: TextStyle(
                                    fontSize: 15 * s,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                const Spacer(),
                                FaIcon(
                                  FontAwesomeIcons.google,
                                  size: 18 * s,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16 * s),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Divider(
                      height: 1,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                  ),

                  // Tab bar
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 24, vertical: 6 * s),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: tabContainerBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: tabActiveBg,
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
                        unselectedLabelColor: theme.colorScheme.onSurface
                            .withValues(alpha: 0.4),
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14 * s,
                        ),
                        unselectedLabelStyle: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 14 * s,
                        ),
                        dividerColor: Colors.transparent,
                        tabs: [
                          Tab(text: t.auth_tab_login),
                          Tab(text: t.auth_tab_signup),
                        ],
                      ),
                    ),
                  ),

                  // Form — fills remaining space, scrollable per tab
                  Expanded(
                    flex: 5,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // ── Login ──
                        SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(height: 12 * s),
                              if (_loginError != null) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.error_outline,
                                        color: Colors.red, size: 16),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _loginError!,
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 13 * s,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6 * s),
                              ],
                              // Username field
                              _buildFieldContainer(
                                children: [
                                  TextField(
                                    controller: _loginUsernameController,
                                    keyboardType: TextInputType.emailAddress,
                                    onChanged: (_) => setState(
                                        () => _loginErrors.remove('username')),
                                    style: TextStyle(
                                      fontSize: 14 * s,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    decoration: _fieldDecoration(
                                      hint: t.auth_username,
                                      s: s,
                                    ),
                                  ),
                                ],
                                fieldBg: _loginErrors['username'] != null
                                    ? Colors.red.withValues(alpha: 0.06)
                                    : fieldBg,
                              ),
                              _fieldError(_loginErrors['username'], s),
                              SizedBox(height: 8 * s),
                              // Password field
                              _buildFieldContainer(
                                children: [
                                  TextField(
                                    controller: _loginPasswordController,
                                    obscureText: _obscureLoginPassword,
                                    onChanged: (_) => setState(
                                        () => _loginErrors.remove('password')),
                                    style: TextStyle(
                                      fontSize: 14 * s,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    decoration: _fieldDecoration(
                                      hint: t.auth_password,
                                      s: s,
                                      suffixWidget: TextButton(
                                        onPressed: () => setState(() =>
                                            _obscureLoginPassword =
                                                !_obscureLoginPassword),
                                        child: Text(
                                          _obscureLoginPassword
                                              ? t.auth_show_password
                                              : t.auth_hide_password,
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.5),
                                            fontSize: 13 * s,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                fieldBg: _loginErrors['password'] != null
                                    ? Colors.red.withValues(alpha: 0.06)
                                    : fieldBg,
                              ),
                              _fieldError(_loginErrors['password'], s),
                              SizedBox(height: 14 * s),
                              // Login button
                              SizedBox(
                                height: 50 * s,
                                child: _isLoading
                                    ? const Center(
                                        child: CircularProgressIndicator())
                                    : ElevatedButton(
                                        onPressed: _login,
                                        child: Text(
                                          t.auth_login_title,
                                          style: TextStyle(
                                            fontSize: 15 * s,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                              ),
                              SizedBox(height: 16 * s),
                              // Forgot password
                              Center(
                                child: GestureDetector(
                                  onTap: () => Navigator.of(context).push(
                                    AppPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  ),
                                  child: Text(
                                    t.auth_forgot_password,
                                    style: TextStyle(
                                      fontSize: 14 * s,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 10 * s),
                              // Demo login — subtle
                              if (!_isLoading)
                                Center(
                                  child: TextButton(
                                    onPressed: _loginAsDemo,
                                    child: Text(
                                      t.auth_skip_demo_short,
                                      style: TextStyle(
                                        fontSize: 12 * s,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ),
                                ),
                              SizedBox(height: 16 * s),
                            ],
                          ),
                        ),

                        // ── Sign up ──
                        SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(height: 12 * s),
                              // Username field
                              _buildFieldContainer(
                                fieldBg: _signupErrors['username'] != null
                                    ? Colors.red.withValues(alpha: 0.06)
                                    : fieldBg,
                                children: [
                                  TextField(
                                    controller: _signupUsernameController,
                                    onChanged: (_) => setState(
                                        () => _signupErrors.remove('username')),
                                    style: TextStyle(
                                      fontSize: 14 * s,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    decoration: _fieldDecoration(
                                        hint: t.auth_username, s: s),
                                  ),
                                ],
                              ),
                              _fieldError(_signupErrors['username'], s),
                              SizedBox(height: 8 * s),
                              // Email field
                              _buildFieldContainer(
                                fieldBg: _signupErrors['email'] != null
                                    ? Colors.red.withValues(alpha: 0.06)
                                    : fieldBg,
                                children: [
                                  TextField(
                                    controller: _signupEmailController,
                                    keyboardType: TextInputType.emailAddress,
                                    onChanged: (_) => setState(
                                        () => _signupErrors.remove('email')),
                                    style: TextStyle(
                                      fontSize: 14 * s,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    decoration: _fieldDecoration(
                                        hint: t.auth_email, s: s),
                                  ),
                                ],
                              ),
                              _fieldError(_signupErrors['email'], s),
                              SizedBox(height: 8 * s),
                              // Password field
                              _buildFieldContainer(
                                fieldBg: _signupErrors['password'] != null
                                    ? Colors.red.withValues(alpha: 0.06)
                                    : fieldBg,
                                children: [
                                  TextField(
                                    controller: _signupPasswordController,
                                    obscureText: _obscureSignupPassword,
                                    onChanged: (_) => setState(
                                        () => _signupErrors.remove('password')),
                                    style: TextStyle(
                                      fontSize: 14 * s,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    decoration: _fieldDecoration(
                                      hint: t.auth_password,
                                      s: s,
                                      suffixWidget: TextButton(
                                        onPressed: () => setState(() =>
                                            _obscureSignupPassword =
                                                !_obscureSignupPassword),
                                        child: Text(
                                          _obscureSignupPassword
                                              ? t.auth_show_password
                                              : t.auth_hide_password,
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.5),
                                            fontSize: 13 * s,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              _fieldError(_signupErrors['password'], s),
                              SizedBox(height: 14 * s),
                              SizedBox(
                                height: 50 * s,
                                child: _isLoading
                                    ? const Center(
                                        child: CircularProgressIndicator())
                                    : ElevatedButton(
                                        onPressed: _signup,
                                        child: Text(
                                          t.auth_sign_up_btn,
                                          style: TextStyle(
                                            fontSize: 15 * s,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                              ),
                              SizedBox(height: 16 * s),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
