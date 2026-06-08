import 'package:taxi_exam_app/core/widgets/app_button.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/services/navigation_feedback.dart';
import 'package:taxi_exam_app/core/theme/app_surface_colors.dart';
import 'package:taxi_exam_app/core/widgets/app_surface_card.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'dart:io' show Platform;
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_exam_app/core/constants/app_text_styles.dart';

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
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

class _ProfileScreenState extends State<ProfileScreen> {
  final _profile = ProfileProvider();
  String _version = '';

  @override
  void initState() {
    super.initState();
    _profile.addListener(_onProfileChanged);
    _profile.loadUserFromPrefs().then((_) {
      if (mounted) _profile.loadProfile().catchError((_) {});
    });
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _version = '${info.version} (${info.buildNumber})');
    }
  }

  void _onProfileChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _profile.removeListener(_onProfileChanged);
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
            AppTextButton(
              label: t.cancel,
              onPressed: () => Navigator.pop(ctx),
            ),
            AppFilledButton(
              label: t.auth_submit,
              onPressed: () => Navigator.pop(ctx, {
                'subject': subjectCtrl.text.trim(),
                'message': messageCtrl.text.trim(),
                'type': feedbackType,
              }),
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
              AppButton(
                label: t.guest_convert_cta,
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
                            error = e.toString().replaceAll('Exception: ', '');
                          });
                        }
                      },
                loading: loading,
                height: 52,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigate(Widget screen) async {
    final nav = NavigationService.navigatorKey.currentState;
    if (nav == null) {
      showAppSnackBar('Unable to open this screen right now.',
          type: SnackBarType.error);
      return;
    }
    await nav.push(AppPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final surfaces = AppSurfaceColors.fromTheme(Theme.of(context));

    return Scaffold(
      backgroundColor: surfaces.page,
      appBar: AppBar(
        backgroundColor: surfaces.page,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(t.settings_title, style: AppTextStyles.headingMedium()),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // ── Guest banner ───────────────────────────────────────────
          if (_profile.isGuest) ...[
            _GuestBanner(onConvert: () => _showGuestConvertSheet(context)),
            const SizedBox(height: 12),
          ],

          // ── Profile card ───────────────────────────────────────────
          _SettingsCard(
            dividerColor: surfaces.divider,
            children: [
              _ProfileHeaderRow(
                profile: _profile,
                onTap: () async {
                  if (_profile.isGuest) {
                    await _showGuestConvertSheet(context);
                    return;
                  }
                  await _navigate(const EditProfileScreen());
                  await _profile.loadUserFromPrefs();
                },
              ),
              if (!_profile.isGuest)
                _SettingsRow(
                  icon: Icons.person_outline_rounded,
                  iconBgColor: const Color(0xFF636366),
                  title: t.profile_edit,
                  onTap: () async {
                    await _navigate(const EditProfileScreen());
                    await _profile.loadUserFromPrefs();
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Account card ───────────────────────────────────────────
          _SettingsCard(
            dividerColor: surfaces.divider,
            children: [
              _SettingsRow(
                icon: Icons.bar_chart_rounded,
                iconBgColor: const Color(0xFF5E5CE6),
                title: t.profile_stats,
                onTap: () => _navigate(const StatsScreen()),
              ),
              _SettingsRow(
                icon: Icons.local_fire_department_rounded,
                iconBgColor: const Color(0xFFFF9500),
                title: t.sg_profile_menu_label,
                onTap: () => _navigate(const StreakSettingsScreen()),
              ),
              _SettingsRow(
                icon: Icons.settings_rounded,
                iconBgColor: const Color(0xFF636366),
                title: t.profile_settings,
                onTap: () => _navigate(const SettingsScreen()),
              ),
              _SettingsRow(
                icon: Icons.receipt_long_rounded,
                iconBgColor: const Color(0xFF007AFF),
                title: t.profile_purchase_history,
                onTap: () => _navigate(const PurchaseHistoryScreen()),
              ),
              if (!kIsWeb && Platform.isIOS && !_profile.isGuest)
                _SettingsRow(
                  icon: Icons.subscriptions_rounded,
                  iconBgColor: const Color(0xFF34C759),
                  title: t.profile_manage_subscription,
                  isExternal: true,
                  onTap: () => launchUrl(
                    Uri.parse('https://apps.apple.com/account/subscriptions'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Preferences section ────────────────────────────────────
          _SectionLabel(
            label: t.profile_section_preferences,
            color: surfaces.sectionLabel,
          ),
          const SizedBox(height: 8),
          _SettingsCard(
            dividerColor: surfaces.divider,
            children: [
              _SettingsRow(
                icon: Icons.tour_rounded,
                iconBgColor: const Color(0xFF5E5CE6),
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
                _SettingsRow(
                  icon: Icons.person_add_alt_1_rounded,
                  iconBgColor: const Color(0xFFAF52DE),
                  title: t.profile_invite,
                  onTap: () {},
                ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Resources section ──────────────────────────────────────
          _SectionLabel(
            label: t.profile_section_resources,
            color: surfaces.sectionLabel,
          ),
          const SizedBox(height: 8),
          _SettingsCard(
            dividerColor: surfaces.divider,
            children: [
              _SettingsRow(
                icon: Icons.help_outline_rounded,
                iconBgColor: const Color(0xFF007AFF),
                title: t.profile_help,
                onTap: () => _navigate(const HelpScreen()),
              ),
              _SettingsRow(
                icon: Icons.feedback_outlined,
                iconBgColor: const Color(0xFFFF3B30),
                title: t.profile_send_feedback,
                onTap: _showAppFeedbackDialog,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Sign out ───────────────────────────────────────────────
          _SettingsCard(
            dividerColor: surfaces.divider,
            children: [
              _SettingsRow(
                icon: Icons.logout_rounded,
                iconBgColor: const Color(0xFFFF3B30),
                title: t.logout,
                titleColor: const Color(0xFFFF3B30),
                showChevron: false,
                onTap: () => showModalBottomSheet(
                  context: context,
                  isDismissible: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (_) => const _LogoutSheet(),
                ),
              ),
            ],
          ),

          // ── Debug buttons (debug builds only) ─────────────────────
          if (kDebugMode) ...[
            const SizedBox(height: 12),
            _SettingsCard(
              dividerColor: surfaces.divider,
              children: [
                _SettingsRow(
                  icon: Icons.bug_report_rounded,
                  iconBgColor: Colors.orange,
                  title: 'Verify Sentry Setup',
                  showChevron: false,
                  onTap: () => throw StateError('This is test exception'),
                ),
                _SettingsRow(
                  icon: Icons.refresh_rounded,
                  iconBgColor: Colors.orange,
                  title: 'Reset Onboarding',
                  showChevron: false,
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
              ],
            ),
          ],

          // ── App version ────────────────────────────────────────────
          const SizedBox(height: 32),
          if (_version.isNotEmpty)
            Center(
              child: Text(
                '${t.settings_app_version} $_version',
                style: AppTextStyles.bodySmall(color: surfaces.sectionLabel),
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ── Reusable card container ────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final Color dividerColor;

  const _SettingsCard({
    required this.children,
    required this.dividerColor,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i < children.length - 1) {
        rows.add(Divider(
          height: 1,
          thickness: 0.5,
          indent: 56,
          color: dividerColor,
        ));
      }
    }
    return AppSurfaceCard(
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: rows,
      ),
    );
  }
}

// ── Section label ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.bodySmall(color: color),
      ),
    );
  }
}

// ── Profile header row ─────────────────────────────────────────────────────

class _ProfileHeaderRow extends StatelessWidget {
  final ProfileProvider profile;
  final VoidCallback onTap;

  const _ProfileHeaderRow({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      key: const Key('profile-header-row'),
      onTap: onTap,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: cs.primary.withValues(alpha: 0.15),
              child: Icon(LucideIcons.user, size: 26, color: cs.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.isGuest
                        ? t.guest_banner_title
                        : (profile.username ?? t.loading),
                    style: AppTextStyles.bodyLarge(),
                  ),
                  Text(
                    profile.isGuest
                        ? t.guest_banner_cta
                        : t.profile_view_profile,
                    style: AppTextStyles.bodySmall(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Generic settings row ───────────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final String title;
  final Color? titleColor;
  final VoidCallback onTap;
  final bool isExternal;
  final bool showChevron;

  const _SettingsRow({
    required this.icon,
    required this.iconBgColor,
    required this.title,
    required this.onTap,
    this.titleColor,
    this.isExternal = false,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyLarge(color: titleColor),
              ),
            ),
            if (showChevron)
              Icon(
                isExternal ? Icons.open_in_new_rounded : Icons.chevron_right,
                color: cs.onSurfaceVariant,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Logout sheet ───────────────────────────────────────────────────────────

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
              style: AppTextStyles.headingLarge(color: Colors.red),
            ),
            const SizedBox(height: 12),
            Text(t.profile_logout_confirm, style: AppTextStyles.bodyLarge()),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppTextButton(
                    label: t.cancel,
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppDangerButton(
                    label: t.profile_yes_logout,
                    onPressed: _doLogout,
                    loading: _isLoading,
                    height: 48,
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

// ── Guest banner ───────────────────────────────────────────────────────────

class _GuestBanner extends StatelessWidget {
  const _GuestBanner({required this.onConvert});
  final VoidCallback onConvert;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primaryContainer.withValues(alpha: 0.18),
            cs.primary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  color: cs.primary.withValues(alpha: 0.7), size: 18),
              const SizedBox(width: 6),
              Text(
                t.guest_banner_title,
                style: GoogleFonts.lexend(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
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
          AppButton(
            label: t.guest_banner_cta,
            onPressed: onConvert,
            height: 44,
            fontSize: 14,
          ),
        ],
      ),
    );
  }
}
