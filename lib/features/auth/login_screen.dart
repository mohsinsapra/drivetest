import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/widgets/app_lottie.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/api/dio_client.dart';
import 'package:taxi_exam_app/main_screen.dart';

import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _authError;
  bool _rememberMe = false;
  bool _obscurePassword = true;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _authError = null;
    });

    try {
      final googleSignIn = GoogleSignIn(
        clientId:
            '678561448025-n2jia0bm2q47ojt4dmba4o7bg2opu18t.apps.googleusercontent.com',
        serverClientId: kIsWeb
            ? null
            : '678561448025-n2jia0bm2q47ojt4dmba4o7bg2opu18t.apps.googleusercontent.com',
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled
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
      await Hive.close();
      await Hive.deleteFromDisk();
      await DioClient().init();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('GOOGLE AUTH ERROR: ${e.toString()}');
      setState(() {
        _authError = 'Google sign-in failed: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loginAsDemo() async {
    // Set demo credentials
    _usernameController.text = 'demo';
    _passwordController.text = 'Demo@123';

    // Call authenticate
    await _authenticate();
  }

  Future<void> _authenticate() async {
    setState(() {
      _isLoading = true;
      _authError = null;
    });

    try {
      await _apiService.authenticate(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      // Debug: Check if tokens are properly set
      debugPrint(
          'Login successful: AccessToken: ${DioClient().accessToken != null}, RefreshToken: ${DioClient().refreshToken != null}');

      // Cache user information
      final user = await _apiService.fetchCurrentUser();
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(user));
      }
      await Hive.close();
      await Hive.deleteFromDisk();

      // Tokens are already stored in secure storage by ApiService.authenticate()
      // Only store in SharedPreferences if Remember Me is checked for backward compatibility
      if (_rememberMe) {
        final refreshToken = DioClient().refreshToken;
        final accessToken = DioClient().accessToken;

        if (refreshToken != null && accessToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('refreshToken', refreshToken);
          await prefs.setString('accessToken', accessToken);
        }
      }

      // Re-initialize DioClient to get a fresh Dio instance + cache
      await DioClient().init();

      if (mounted) {
        // Navigate directly to MainScreen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint(e.toString());
      setState(() {
        _authError = 'Invalid username or password';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showAppFeedbackDialog() async {
    final emailCtrl = TextEditingController();
    final subjectCtrl = TextEditingController(text: 'Login issue');
    final messageCtrl = TextEditingController();
    String feedbackType = 'login_issue';

    final payload = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Contact support'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: feedbackType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(
                        value: 'login_issue', child: Text('Login issue')),
                    DropdownMenuItem(
                        value: 'app_issue', child: Text('App issue')),
                    DropdownMenuItem(
                        value: 'feature_request',
                        child: Text('Feature request')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
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
                  decoration:
                      const InputDecoration(labelText: 'Email (optional)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subjectCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Subject (optional)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageCtrl,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, {
                'email': emailCtrl.text.trim(),
                'subject': subjectCtrl.text.trim(),
                'message': messageCtrl.text.trim(),
                'type': feedbackType,
              }),
              child: const Text('Submit'),
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
      screenContext: 'login',
      feedbackType: payload['type'] ?? 'login_issue',
      contactEmail: payload['email'] ?? '',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Thanks! Your feedback was sent.'
            : 'Could not send feedback. Please try again.'),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // _usernameController.text = 'mohsinsapra';
    // _passwordController.text = "Sarach@123";
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent),
            onPressed: _showAppFeedbackDialog,
            tooltip: 'Contact support',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 250,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: AppLottie(
                    asset: 'animations/login.json',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Error message
              if (_authError != null)
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _authError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),

              // Username field
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // Remember me checkbox and Forgot Password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      value: _rememberMe,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Remember me'),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _rememberMe = value);
                      },
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Login button
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _authenticate,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
              const SizedBox(height: 24),

              // Divider
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 16),

              // Google Sign-In button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: const FaIcon(FontAwesomeIcons.google, size: 18),
                  label: const Text(
                    'Continue with Google',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Sign-up prompt
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SignupScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Sign up',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Skip for now button (Demo login)
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _isLoading ? null : _loginAsDemo,
                  icon: const Icon(Icons.preview, size: 16),
                  label: const Text('Skip for now (Try Demo)'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                    textStyle: const TextStyle(fontSize: 13),
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
