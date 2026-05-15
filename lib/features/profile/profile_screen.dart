import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/services/navigation_feedback.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'dart:io' show Platform;
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:taxi_exam_app/core/services/navigation_service.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'package:taxi_exam_app/features/profile/edit_profile_screen.dart';
import 'package:taxi_exam_app/features/profile/providers/profile_provider.dart';
import 'package:taxi_exam_app/features/profile/stats_screen.dart';
import 'package:taxi_exam_app/features/streak/streak_settings_screen.dart';
import 'package:taxi_exam_app/features/payment/receipt_screen.dart';
import 'package:taxi_exam_app/features/support/help_screen.dart';
import 'package:taxi_exam_app/settings/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/features/onboarding/onboarding_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _profile = ProfileProvider();

  late final AnimationController _ctrl;
  late final Animation<double> _avatarScale;
  late final Animation<double> _avatarFade;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _avatarScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack)),
    );
    _avatarFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic)),
    );
    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.2, 0.6, curve: Curves.easeOut)),
    );

    _profile.addListener(_onProfileChanged);
    _profile.loadUserFromPrefs().then((_) {
      if (_profile.username == null && mounted) {
        _profile.loadProfile().catchError((_) {});
      }
    });
    _ctrl.forward();
  }

  void _onProfileChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _profile.removeListener(_onProfileChanged);
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _showAppFeedbackDialog() async {
    final t = Translations.of(context);
    final subjectCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    String feedbackType = 'app_issue';

    final payload = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(t.auth_contact_support),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: feedbackType,
                decoration: InputDecoration(labelText: t.auth_feedback_type),
                items: [
                  DropdownMenuItem(
                      value: 'app_issue',
                      child: Text(t.auth_feedback_app_issue)),
                  DropdownMenuItem(
                      value: 'feature_request',
                      child: Text(t.auth_feedback_feature_request)),
                  const DropdownMenuItem(
                      value: 'payment_issue', child: Text('Payment issue')),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, {
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

    final ok = await _profile.submitFeedback(
      message: msg,
      subject: payload['subject'] ?? '',
      feedbackType: payload['type'] ?? 'app_issue',
    );

    if (!mounted) return;
    showAppSnackBar(
      ok ? t.auth_feedback_sent : t.auth_feedback_error,
      type: ok ? SnackBarType.success : SnackBarType.error,
    );
  }

  Future<void> _showGuestConvertSheet(BuildContext context) async {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;
    final usernameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String? error;
    bool loading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.guest_convert_title,
                  style: GoogleFonts.lexend(
                      fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(t.guest_convert_subtitle,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, color: cs.onSurfaceVariant)),
              const SizedBox(height: 20),
              TextField(
                controller: usernameCtrl,
                decoration: InputDecoration(
                  hintText: t.guest_username_hint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: t.guest_email_hint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: t.guest_password_hint,
                  border: const OutlineInputBorder(),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: TextStyle(color: cs.error, fontSize: 13)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          setSheetState(() {
                            loading = true;
                            error = null;
                          });
                          try {
                            await ApiService().convertGuest(
                              username: usernameCtrl.text.trim(),
                              email: emailCtrl.text.trim(),
                              password: passwordCtrl.text,
                            );
                            await _profile.loadProfile();
                            if (ctx.mounted) Navigator.of(ctx).pop();
                          } catch (e) {
                            setSheetState(() {
                              loading = false;
                              error =
                                  e.toString().replaceAll('Exception: ', '');
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    shape: const StadiumBorder(),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : Text(t.guest_convert_cta,
                          style: GoogleFonts.lexend(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePrimaryMenuTap(int index) async {
    try {
      final nav = NavigationService.navigatorKey.currentState;
      if (nav == null) {
        showAppSnackBar(
          'Unable to open this screen right now.',
          type: SnackBarType.error,
        );
        return;
      }
      switch (index) {
        case 0:
          await nav.push(
            AppPageRoute(builder: (_) => const EditProfileScreen()),
          );
          await _profile.loadUserFromPrefs();
          return;
        case 1:
          await nav.push(
            AppPageRoute(builder: (_) => const StatsScreen()),
          );
          return;
        case 2:
          await nav.push(
            AppPageRoute(builder: (_) => const StreakSettingsScreen()),
          );
          return;
        case 3:
          await nav.push(
            AppPageRoute(builder: (_) => const SettingsScreen()),
          );
          return;
        default:
          return;
      }
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(
        'Unable to open this screen right now.',
        type: SnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final menuItems = [
      (
        icon: Icons.person,
        color: const Color(0xFFFFCDD2),
        title: t.profile_edit
      ),
      (
        icon: Icons.bar_chart,
        color: const Color(0xFFE1BEE7),
        title: t.profile_stats
      ),
      (
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFFFE0B2),
        title: t.sg_profile_menu_label
      ),
      (
        icon: Icons.settings,
        color: const Color(0xFFE8F5E9),
        title: t.profile_settings
      ),
    ];
    final secondaryItems = [
      if (!kIsWeb && Platform.isIOS && !_profile.isGuest)
        (
          icon: Icons.subscriptions_rounded,
          color: const Color(0xFFE8F5E9),
          title: t.profile_manage_subscription,
          onTap: () => launchUrl(
            Uri.parse('https://apps.apple.com/account/subscriptions'),
            mode: LaunchMode.externalApplication,
          ),
        ),
      if (!_profile.isGuest)
        (
          icon: Icons.receipt_long_outlined,
          color: const Color(0xFFDCEEFB),
          title: t.profile_purchase_history,
          onTap: () => Navigator.push(
            context,
            AppPageRoute(builder: (_) => const PurchaseHistoryScreen()),
          ),
        ),
      (
        icon: Icons.tour_rounded,
        color: const Color(0xFFE8EAF6),
        title: t.profile_revisit_setup,
        onTap: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('onboarding_complete');
          if (!context.mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            AppPageRoute(builder: (_) => const OnboardingScreen()),
            (_) => false,
          );
        },
      ),
      if (!_profile.isGuest)
        (
          icon: Icons.person_add_alt,
          color: const Color(0xFFE0E0E0),
          title: t.profile_invite,
          onTap: () {},
        ),
      (
        icon: Icons.help_outline,
        color: const Color(0xFFE0E0E0),
        title: t.profile_help,
        onTap: () => Navigator.push(
          context,
          AppPageRoute(builder: (_) => const HelpScreen()),
        ),
      ),
      (
        icon: Icons.feedback_outlined,
        color: const Color(0xFFE0E0E0),
        title: t.profile_send_feedback,
        onTap: _showAppFeedbackDialog,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(t.profile),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () => Navigator.push(
              context,
              AppPageRoute(builder: (_) => const SettingsScreen()),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.only(bottom: bottomInset + 120),
          children: [
            const SizedBox(height: 24),

            // ── Animated avatar ────────────────────────────────────────
            RepaintBoundary(
              child: FadeTransition(
                opacity: _avatarFade,
                child: ScaleTransition(
                  scale: _avatarScale,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: const Icon(LucideIcons.user,
                            size: 48, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Animated header text ───────────────────────────────────
            FadeTransition(
              opacity: _headerFade,
              child: SlideTransition(
                position: _headerSlide,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _profile.isGuest
                            ? Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.08)
                            : Colors.pinkAccent.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _profile.isGuest
                            ? t.guest_banner_cta
                            : t.profile_student,
                        style: TextStyle(
                          color: _profile.isGuest
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!_profile.isGuest) ...[
                      Text(
                        _profile.username ?? t.loading,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _profile.email ?? '',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── Guest banner ───────────────────────────────────────────
            if (_profile.isGuest)
              _ProfileTile(
                index: 0,
                child: _GuestBanner(
                    onConvert: () => _showGuestConvertSheet(context)),
              ),

            // ── Staggered menu tiles ───────────────────────────────────
            ...menuItems
                .asMap()
                .entries
                .where((e) => !_profile.isGuest || e.key != 0)
                .map((e) => _ProfileTile(
                      index: e.key,
                      child: _buildMenuTile(
                        context,
                        icon: e.value.icon,
                        iconColor: e.value.color,
                        title: e.value.title,
                        onTap: () => _handlePrimaryMenuTap(e.key),
                      ),
                    )),

            _ProfileTile(
              index: menuItems.length,
              child: const Divider(thickness: 0.5, color: Color(0xFFE0E0E0)),
            ),

            ...secondaryItems.asMap().entries.map((e) => _ProfileTile(
                  index: menuItems.length + 1 + e.key,
                  child: _buildMenuTile(
                    context,
                    icon: e.value.icon,
                    iconColor: e.value.color,
                    title: e.value.title,
                    onTap: e.value.onTap,
                  ),
                )),

            _ProfileTile(
              index: menuItems.length + secondaryItems.length + 1,
              child: const Divider(thickness: 0.5, color: Color(0xFFE0E0E0)),
            ),

            // ── Debug: Sentry test + reset onboarding (debug builds only) ──
            if (kDebugMode) ...[
              _ProfileTile(
                index: menuItems.length + secondaryItems.length + 2,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ElevatedButton(
                    onPressed: () {
                      throw StateError('This is test exception');
                    },
                    child: const Text('Verify Sentry Setup'),
                  ),
                ),
              ),
              _ProfileTile(
                index: menuItems.length + secondaryItems.length + 3,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ElevatedButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('onboarding_complete');
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        AppPageRoute(builder: (_) => const OnboardingScreen()),
                        (_) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange),
                    child: const Text('Reset Onboarding'),
                  ),
                ),
              ),
            ],
            // ── Logout ─────────────────────────────────────────────────
            _ProfileTile(
              index: menuItems.length + secondaryItems.length + 2,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isDismissible: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (sheetContext) => const _LogoutSheet(),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.logout, size: 20),
                    label: Text(t.logout, style: const TextStyle(fontSize: 15)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Staggered fade + slide-in for profile list items.
class _ProfileTile extends StatefulWidget {
  final int index;
  final Widget child;
  const _ProfileTile({required this.index, required this.child});

  @override
  State<_ProfileTile> createState() => _ProfileTileState();
}

class _ProfileTileState extends State<_ProfileTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: 150 + widget.index * 35), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(position: _slide, child: widget.child),
        ),
      );
}

class _LogoutSheet extends StatefulWidget {
  const _LogoutSheet();

  @override
  State<_LogoutSheet> createState() => _LogoutSheetState();
}

class _LogoutSheetState extends State<_LogoutSheet> {
  bool _isLoading = false;

  Future<void> _doLogout() async {
    setState(() => _isLoading = true);
    try {
      await ProfileProvider().logout();
      vibrateLoginLogout();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    if (!mounted) return;
    showAppSnackBar('Logged out successfully.', type: SnackBarType.success);
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return PopScope(
      canPop: !_isLoading,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.logout,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 12),
            Text(t.profile_logout_confirm,
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(t.cancel),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _doLogout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(t.profile_yes_logout),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildMenuTile(
  BuildContext context, {
  required IconData icon,
  required String title,
  required VoidCallback onTap,
  Color? iconColor,
}) {
  return ListTile(
    leading: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: iconColor ?? Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.black),
    ),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}

class _GuestBanner extends StatelessWidget {
  const _GuestBanner({required this.onConvert});
  final VoidCallback onConvert;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  color: cs.onSurfaceVariant, size: 18),
              const SizedBox(width: 6),
              Text(
                t.guest_banner_title,
                style: GoogleFonts.lexend(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            t.guest_banner_subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: onConvert,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary.withValues(alpha: 0.9),
                foregroundColor: cs.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                t.guest_banner_cta,
                style: GoogleFonts.lexend(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
