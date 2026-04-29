import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'package:taxi_exam_app/features/profile/providers/profile_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _profile = ProfileProvider();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _profile.addListener(_onProfileChange);
    _loadProfile();
  }

  @override
  void dispose() {
    _profile.removeListener(_onProfileChange);
    _usernameController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      await _profile.loadProfile();
      if (!mounted) return;
      _usernameController.text = _profile.username ?? '';
      _emailController.text = _profile.email ?? '';
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar('Failed to load profile data.', type: SnackBarType.error);
    }
  }

  void _onProfileChange() {
    if (mounted) setState(() {});
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

    try {
      await _profile.saveProfile(username: username, email: email);
      if (!mounted) return;
      showAppSnackBar('Profile updated.', type: SnackBarType.success);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(_profile.extractApiError(e), type: SnackBarType.error);
    }
  }

  Future<void> _setPassword() async {
    final password = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.length < 6) {
      showAppSnackBar('Password must be at least 6 characters.',
          type: SnackBarType.error);
      return;
    }
    if (password != confirm) {
      showAppSnackBar('Passwords do not match.', type: SnackBarType.error);
      return;
    }

    try {
      await _profile.setPassword(password);
      if (!mounted) return;
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      showAppSnackBar('Password set successfully.', type: SnackBarType.success);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(_profile.extractApiError(e), type: SnackBarType.error);
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

    try {
      await _profile.deleteAccount();
      if (!mounted) return;
      showAppSnackBar(t.auth_deleted_account_welcome_back,
          type: SnackBarType.success);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(_profile.extractApiError(e), type: SnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_profile.profileLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_profile.isDemo) ...[
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
            readOnly: _profile.isDemo,
            decoration: InputDecoration(
              labelText: 'Username',
              border: const OutlineInputBorder(),
              filled: _profile.isDemo,
              fillColor: _profile.isDemo ? const Color(0xFFF5F5F5) : null,
              suffixIcon: _profile.isDemo
                  ? const Icon(Icons.lock_outline, size: 18)
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            readOnly: _profile.isDemo,
            decoration: InputDecoration(
              labelText: 'Email',
              border: const OutlineInputBorder(),
              filled: _profile.isDemo,
              fillColor: _profile.isDemo ? const Color(0xFFF5F5F5) : null,
              suffixIcon: _profile.isDemo
                  ? const Icon(Icons.lock_outline, size: 18)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: (_profile.savingProfile || _profile.isDemo)
                ? null
                : _saveProfile,
            child: _profile.savingProfile
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save Changes'),
          ),
          if (_profile.isGoogleAccount) ...[
            const SizedBox(height: 28),
            const Divider(thickness: 0.6, color: Color(0xFFE6E6E6)),
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
          ] else if (!_profile.hasPassword) ...[
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 12),
            const Text('Set Password',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            TextField(
              controller: _newPasswordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(_obscurePassword
                      ? Icons.visibility
                      : Icons.visibility_off),
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
                  onPressed: () => setState(() =>
                      _obscureConfirmPassword = !_obscureConfirmPassword),
                  icon: Icon(_obscureConfirmPassword
                      ? Icons.visibility
                      : Icons.visibility_off),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _profile.settingPassword ? null : _setPassword,
              child: _profile.settingPassword
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Set Password'),
            ),
          ],
          const SizedBox(height: 28),
          const Divider(thickness: 0.6, color: Color(0xFFE6E6E6)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            onPressed: _profile.deletingAccount ? null : _deleteAccount,
            icon: _profile.deletingAccount
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_forever),
            label: Text(
                _profile.deletingAccount ? 'Deleting...' : 'Delete Account'),
          ),
        ],
      ),
    );
  }
}
