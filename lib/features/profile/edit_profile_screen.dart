import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';
import 'package:taxi_exam_app/core/services/navigation_service.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'package:taxi_exam_app/features/auth/auth_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ApiService _apiService = ApiService();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _loading = true;
  bool _savingProfile = false;
  bool _settingPassword = false;
  bool _deletingAccount = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _hasPassword = true;
  bool _isGoogleAccount = false;
  bool _isDemo = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await _apiService.fetchCurrentUser();
      if (!mounted) return;

      final userMap = Map<String, dynamic>.from(user as Map);
      setState(() {
        _usernameController.text = (userMap['username'] ?? '').toString();
        _emailController.text = (userMap['email'] ?? '').toString();
        _hasPassword =
            (userMap['has_password'] ?? userMap['has_usable_password']) == true;
        _isGoogleAccount = userMap['is_google_account'] == true;
        _isDemo = userMap['is_demo'] == true;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppSnackBar('Failed to load profile data.', type: SnackBarType.error);
    }
  }

  Future<void> _saveProfile() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();

    if (username.isEmpty) {
      showAppSnackBar('Username is required.', type: SnackBarType.error);
      return;
    }
    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      showAppSnackBar('Please enter a valid email.', type: SnackBarType.error);
      return;
    }

    setState(() => _savingProfile = true);
    try {
      final updated = await _apiService.updateProfile(
        username: username,
        email: email,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(updated));

      if (!mounted) return;
      showAppSnackBar('Profile updated.', type: SnackBarType.success);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        _extractApiErrorMessage(e),
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _setPassword() async {
    final password = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.length < 6) {
      showAppSnackBar(
        'Password must be at least 6 characters.',
        type: SnackBarType.error,
      );
      return;
    }
    if (password != confirm) {
      showAppSnackBar('Passwords do not match.', type: SnackBarType.error);
      return;
    }

    setState(() => _settingPassword = true);
    try {
      await _apiService.setPassword(newPassword: password);
      if (!mounted) return;

      setState(() {
        _hasPassword = true;
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });
      showAppSnackBar('Password set successfully.', type: SnackBarType.success);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(_extractApiErrorMessage(e), type: SnackBarType.error);
    } finally {
      if (mounted) setState(() => _settingPassword = false);
    }
  }

  Future<void> _deleteAccount() async {
    final t = Translations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action is permanent and will remove your account data. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deletingAccount = true);
    try {
      await _apiService.deleteAccount();

      try {
        await _apiService.logout();
      } catch (_) {}

      try {
        final prefs = await SharedPreferences.getInstance();
        final lang = prefs.getString('language');
        final isDark = prefs.getBool('dark_mode');
        final onboardingDone = prefs.getBool('onboarding_complete');
        await prefs.clear();
        if (lang != null) await prefs.setString('language', lang);
        if (isDark != null) await prefs.setBool('dark_mode', isDark);
        if (onboardingDone != null) {
          await prefs.setBool('onboarding_complete', onboardingDone);
        }
      } catch (_) {}

      try {
        final attemptsBox = await Hive.openBox<TestAttempt>('testAttempts');
        await attemptsBox.clear();
        await Hive.close();
        await Hive.deleteFromDisk();
      } catch (_) {}

      final nav = NavigationService.navigatorKey.currentState;
      nav?.pushAndRemoveUntil(
        AppPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
      showAppSnackBar(
        t.auth_deleted_account_welcome_back,
        type: SnackBarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(_extractApiErrorMessage(e), type: SnackBarType.error);
      setState(() => _deletingAccount = false);
    }
  }

  String _extractApiErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        final usernameErrors = map['username'];
        final emailErrors = map['email'];
        final detail = map['detail'];

        if (usernameErrors is List && usernameErrors.isNotEmpty) {
          final first = usernameErrors.first.toString();
          if (first.toLowerCase().contains('already exists')) {
            return 'This username is already taken.';
          }
          return first;
        }
        if (emailErrors is List && emailErrors.isNotEmpty) {
          final first = emailErrors.first.toString();
          if (first.toLowerCase().contains('already exists')) {
            return 'This email is already in use.';
          }
          return first;
        }
        if (detail != null && detail.toString().trim().isNotEmpty) {
          return detail.toString();
        }
      }
      if (data is String && data.trim().isNotEmpty) return data;
    }
    return 'Request failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_isDemo) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline, color: Color(0xFF856404)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Demo accounts cannot change username or email.',
                      style: TextStyle(color: Color(0xFF856404)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _usernameController,
            readOnly: _isDemo,
            decoration: InputDecoration(
              labelText: 'Username',
              border: const OutlineInputBorder(),
              filled: _isDemo,
              fillColor: _isDemo ? const Color(0xFFF5F5F5) : null,
              suffixIcon: _isDemo ? const Icon(Icons.lock_outline, size: 18) : null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            readOnly: _isDemo,
            decoration: InputDecoration(
              labelText: 'Email',
              border: const OutlineInputBorder(),
              filled: _isDemo,
              fillColor: _isDemo ? const Color(0xFFF5F5F5) : null,
              suffixIcon: _isDemo ? const Icon(Icons.lock_outline, size: 18) : null,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: (_savingProfile || _isDemo) ? null : _saveProfile,
            child: _savingProfile
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save Changes'),
          ),
          if (_isGoogleAccount) ...[
            const SizedBox(height: 28),
            const Divider(
              thickness: 0.6,
              color: Color(0xFFE6E6E6),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF1A73E8)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You are signed in with Google. Password changes are managed through your Google account.',
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!_hasPassword) ...[
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Set Password',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _newPasswordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  icon: Icon(_obscureConfirmPassword
                      ? Icons.visibility
                      : Icons.visibility_off),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _settingPassword ? null : _setPassword,
              child: _settingPassword
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Set Password'),
            ),
          ],
          const SizedBox(height: 28),
          const Divider(
            thickness: 0.6,
            color: Color(0xFFE6E6E6),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            onPressed: _deletingAccount ? null : _deleteAccount,
            icon: _deletingAccount
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_forever),
            label: Text(_deletingAccount ? 'Deleting...' : 'Delete Account'),
          ),
        ],
      ),
    );
  }
}
