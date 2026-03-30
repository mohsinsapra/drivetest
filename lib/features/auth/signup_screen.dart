import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'dart:convert'; // For json.decode
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/widgets/app_lottie.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/auth/google_sign_in_helper.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/providers/theme_provider.dart';
import 'package:taxi_exam_app/main_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  Map<String, String> _serverErrors = {};

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

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

      await _apiService.googleAuth(idToken: idToken, accessToken: accessToken);

      if (!mounted) return;

      final user = await _apiService.fetchCurrentUser();
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(user));
      }
      await Hive.deleteFromDisk();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          AppPageRoute(builder: (context) => const MainScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(GoogleSignInHelper.userMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _signup() async {
    if (!_formKey.currentState!.validate()) {
      // Form is invalid, do not proceed
      return;
    }

    setState(() {
      _isLoading = true;
      _serverErrors.clear(); // Clear previous errors
    });

    try {
      final response = await _apiService.signup(
        _emailController.text,
        _usernameController.text,
        _passwordController.text,
      );

      if (response.statusCode == 201) {
        // Signup successful
        if (!mounted) return;

        showAppSnackBar(Translations.of(context).auth_signup_success);
        Navigator.pop(context);
      } else {
        // Signup failed
        if (!mounted) return;

        // Parse server errors
        final errors = _parseErrors(response.body);

        setState(() {
          _serverErrors = errors;
        });

        // Show a general error message
        showAppSnackBar(Translations.of(context).auth_signup_failed);
      }
    } catch (e) {
      if (!mounted) return;

      // Handle exceptions
      showAppSnackBar(Translations.of(context).auth_generic_error);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<String, String> _parseErrors(String responseBody) {
    final Map<String, dynamic> errorData = json.decode(responseBody);

    final Map<String, String> errors = {};

    errorData.forEach((key, value) {
      if (value is List && value.isNotEmpty) {
        errors[key] = value.first;
      } else if (value is String) {
        errors[key] = value;
      }
    });

    return errors;
  }

  Future<void> _setLocale(AppLocale locale) async {
    await LocaleSettings.setLocale(locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', locale.languageCode);
  }

  String? _validateUsername(String? value) {
    final t = Translations.of(context);
    if (value == null || value.isEmpty) {
      return t.auth_val_username_required;
    } else if (value.length < 4) {
      return t.auth_val_username_length;
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final t = Translations.of(context);
    if (value == null || value.isEmpty) {
      return t.auth_val_email_required;
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return t.auth_val_email_invalid;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final t = Translations.of(context);
    if (value == null || value.isEmpty) {
      return t.auth_val_password_required;
    } else if (value.length < 6) {
      return t.auth_val_password_length;
    }
    return null;
  }

  Future<void> _showAppFeedbackDialog() async {
    final t = Translations.of(context);
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    final subjectCtrl =
        TextEditingController(text: t.auth_feedback_signup_issue);
    final messageCtrl = TextEditingController();
    String feedbackType = 'signup_issue';

    final payload = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(t.auth_contact_support),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: feedbackType,
                  decoration: InputDecoration(labelText: t.auth_feedback_type),
                  items: [
                    DropdownMenuItem(
                        value: 'signup_issue',
                        child: Text(t.auth_feedback_signup_issue)),
                    DropdownMenuItem(
                        value: 'app_issue',
                        child: Text(t.auth_feedback_app_issue)),
                    DropdownMenuItem(
                        value: 'feature_request',
                        child: Text(t.auth_feedback_feature_request)),
                    DropdownMenuItem(
                        value: 'other', child: Text(t.auth_feedback_other)),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setDialogState(() => feedbackType = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                      labelText: t.auth_feedback_email_optional),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subjectCtrl,
                  decoration: InputDecoration(
                      labelText: t.auth_feedback_subject_optional),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageCtrl,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: t.auth_feedback_message,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, {
                'email': emailCtrl.text.trim(),
                'subject': subjectCtrl.text.trim(),
                'message': messageCtrl.text.trim(),
                'type': feedbackType,
              }),
              child: Text(t.auth_submit),
            ),
          ],
        ),
      ),
    );

    if (!mounted || payload == null) return;
    final msg = (payload['message'] ?? '').trim();
    if (msg.isEmpty) return;

    final ok = await _apiService.submitAppFeedback(
      message: msg,
      subject: payload['subject'] ?? '',
      screenContext: 'signup',
      feedbackType: payload['type'] ?? 'signup_issue',
      contactEmail: payload['email'] ?? '',
    );
    if (!mounted) return;
    showAppSnackBar(ok ? t.auth_feedback_sent : t.auth_feedback_error);
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final currentLocale = LocaleSettings.currentLocale;
    final currentFlag = currentLocale == AppLocale.sv ? '🇸🇪' : '🇬🇧';

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(t.auth_create_account),
        centerTitle: true,
        actions: [
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
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                currentFlag,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          IconButton(
            icon: Icon(themeProvider.isDark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded),
            onPressed: () => context.read<ThemeProvider>().toggle(),
            tooltip: themeProvider.isDark ? 'Light mode' : 'Dark mode',
          ),
          IconButton(
            icon: const Icon(Icons.support_agent),
            onPressed: _showAppFeedbackDialog,
            tooltip: t.auth_contact_support,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 200,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: AppLottie(
                        asset: 'animations/signup.json',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: t.auth_username,
                      prefixIcon: const Icon(Icons.person),
                      errorText: _serverErrors['username'],
                    ),
                    validator: _validateUsername,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: t.auth_email,
                      prefixIcon: const Icon(Icons.email),
                      errorText: _serverErrors['email'],
                    ),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: t.auth_password,
                      prefixIcon: const Icon(Icons.lock),
                      errorText: _serverErrors['password'],
                    ),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _signup,
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  t.auth_sign_up_btn,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Text(
                                    t.auth_or,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _signInWithGoogle,
                                icon: const FaIcon(FontAwesomeIcons.google,
                                    size: 18),
                                label: Text(
                                  t.auth_google_continue,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
