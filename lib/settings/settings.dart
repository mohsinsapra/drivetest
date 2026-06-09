import 'package:taxi_exam_app/core/constants/app_text_styles.dart';
import 'package:taxi_exam_app/core/theme/app_surface_colors.dart';
import 'package:taxi_exam_app/core/widgets/app_button.dart';
import 'package:taxi_exam_app/core/widgets/app_loading_indicator.dart';
import 'package:taxi_exam_app/core/widgets/app_surface_card.dart';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/providers/font_provider.dart';
import 'package:taxi_exam_app/core/providers/theme_provider.dart';
import 'package:taxi_exam_app/core/services/version_service.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  bool isTimed = false;
  bool isInstantMarking = false;
  bool includeSavedQuestions = false;
  bool randomize = true;
  bool shuffleOnDevice = true;
  int numberOfQuestions = 10;
  int maxQuestions = 1000;
  VersionInfo? _versionInfo;
  bool _isAdmin = false;
  Map<String, dynamic>? _backendInfo;

  // Notifications
  bool _notificationsEnabled = true;
  AuthorizationStatus? _notificationPermission;

  final ApiService _apiService = ApiService();
  final TextEditingController _numberOfQuestionsController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPreferences();
    _loadVersionInfo();
    _loadAdminState();
    _loadNotificationState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadNotificationState();
  }

  Future<void> _loadAdminState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      if (userJson != null && userJson.isNotEmpty) {
        final parsed = jsonDecode(userJson);
        if (parsed is Map<String, dynamic>) {
          final isAdmin = parsed['is_administrator'] == true;
          if (mounted) setState(() => _isAdmin = isAdmin);
          if (isAdmin) _loadBackendVersion();
        }
      }
    } catch (e) {
      debugPrint('Failed to load admin state: $e');
    }
  }

  Future<void> _loadNotificationState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      if (mounted) {
        setState(() {
          _notificationsEnabled =
              prefs.getBool('notifications_enabled') ?? true;
          _notificationPermission = settings.authorizationStatus;
        });
      }
    } catch (_) {
      // Web or unsupported platform — default to enabled, no OS permission
      if (mounted) {
        setState(() {
          _notificationsEnabled = true;
          _notificationPermission = AuthorizationStatus.authorized;
        });
      }
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    HapticFeedback.lightImpact();

    if (value) {
      final status = _notificationPermission;
      if (status == AuthorizationStatus.denied) {
        // Can't request again — send user to OS settings
        _openNotificationSettings();
        return;
      }
      if (status == AuthorizationStatus.notDetermined || status == null) {
        final result = await FirebaseMessaging.instance.requestPermission();
        if (mounted) {
          setState(() => _notificationPermission = result.authorizationStatus);
        }
        if (result.authorizationStatus != AuthorizationStatus.authorized &&
            result.authorizationStatus != AuthorizationStatus.provisional) {
          return; // Permission not granted — don't flip the switch
        }
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    if (mounted) setState(() => _notificationsEnabled = value);
  }

  Future<void> _openNotificationSettings() async {
    if (kIsWeb) return;
    if (Platform.isIOS) {
      await launchUrl(Uri.parse('app-settings:'));
    } else {
      await launchUrl(
        Uri.parse('android.settings.APP_NOTIFICATION_SETTINGS'),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Future<void> _loadBackendVersion() async {
    try {
      final info = await _apiService.fetchBackendVersion();
      if (mounted) setState(() => _backendInfo = info);
    } catch (e) {
      debugPrint('Failed to load backend version: $e');
    }
  }

  Future<void> _loadVersionInfo() async {
    try {
      final versionInfo = await VersionService.getVersionInfo();
      setState(() => _versionInfo = versionInfo);
    } catch (e) {
      debugPrint('Failed to load version info: $e');
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isTimed = prefs.getBool('isTimed') ?? false;
      isInstantMarking = prefs.getBool('isInstantMarking') ?? false;
      includeSavedQuestions = prefs.getBool('includeSavedQuestions') ?? false;
      randomize = prefs.getBool('randomize') ?? true;
      shuffleOnDevice = prefs.getBool('shuffleOnDevice') ?? true;
      numberOfQuestions = prefs.getInt('numberOfQuestions') ?? 10;
      _numberOfQuestionsController.text = numberOfQuestions.toString();
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isTimed', isTimed);
    await prefs.setBool('isInstantMarking', isInstantMarking);
    await prefs.setBool('includeSavedQuestions', includeSavedQuestions);
    await prefs.setBool('randomize', randomize);
    await prefs.setBool('shuffleOnDevice', shuffleOnDevice);
    await prefs.setInt('numberOfQuestions', numberOfQuestions);
  }

  String _formatDeployDate(String? raw) {
    if (raw == null || raw.isEmpty || raw == 'unknown') return 'unknown';
    final normalized = raw.contains(' ')
        ? raw.replaceFirst(' ', 'T').replaceFirstMapped(
              RegExp(r'([+-]\d{2})(\d{2})$'),
              (m) => '${m.group(1)}:${m.group(2)}',
            )
        : raw;
    final parsed = DateTime.tryParse(normalized);
    if (parsed == null) return raw;
    return DateFormat('MMM d, yyyy h:mm a').format(parsed.toLocal());
  }

  Future<void> _setLocale(AppLocale locale) async {
    LocaleSettings.setLocale(locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', locale.languageCode);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final fontProvider = Provider.of<FontProvider>(context);
    final currentLocale = LocaleSettings.currentLocale;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(t.settings_title)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  // ── Appearance ──────────────────────────────────────────
                  _SectionHeader(t.settings_appearance),
                  _SettingsSectionCard(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: themeProvider.themeMode == ThemeMode.dark
                                ? Colors.indigo.shade900
                                : themeProvider.themeMode == ThemeMode.light
                                    ? Colors.amber.shade100
                                    : (isDark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            themeProvider.themeMode == ThemeMode.dark
                                ? Icons.dark_mode_rounded
                                : themeProvider.themeMode == ThemeMode.light
                                    ? Icons.light_mode_rounded
                                    : Icons.brightness_auto_rounded,
                            color: themeProvider.themeMode == ThemeMode.dark
                                ? Colors.white
                                : themeProvider.themeMode == ThemeMode.light
                                    ? Colors.amber.shade700
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                            size: 20,
                          ),
                        ),
                        title: Text(t.settings_theme_label),
                        subtitle: Text(t.settings_theme_sub),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _LangChip(
                              label: t.settings_theme_system,
                              selected:
                                  themeProvider.themeMode == ThemeMode.system,
                              onTap: () =>
                                  themeProvider.setMode(ThemeMode.system),
                            ),
                            const SizedBox(width: 6),
                            _LangChip(
                              label: t.settings_theme_light,
                              selected:
                                  themeProvider.themeMode == ThemeMode.light,
                              onTap: () =>
                                  themeProvider.setMode(ThemeMode.light),
                            ),
                            const SizedBox(width: 6),
                            _LangChip(
                              label: t.settings_theme_dark,
                              selected:
                                  themeProvider.themeMode == ThemeMode.dark,
                              onTap: () =>
                                  themeProvider.setMode(ThemeMode.dark),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16, color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.purple.withValues(alpha: 0.05)
                                : Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.font_download_rounded,
                              color: isDark
                                  ? Colors.purple.shade200
                                  : Colors.purple.shade600,
                              size: 20),
                        ),
                        title: const Text('Font'),
                        subtitle: Text(fontProvider.fontFamily),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _LangChip(
                              label: 'NudMoto',
                              selected: fontProvider.fontFamily == 'NudMoto',
                              onTap: () => fontProvider.setFont('NudMoto'),
                            ),
                            const SizedBox(width: 8),
                            _LangChip(
                              label: 'Inter',
                              selected: fontProvider.fontFamily == 'Inter',
                              onTap: () => fontProvider.setFont('Inter'),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16, color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.blue.withValues(alpha: 0.05)
                                : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.language_rounded,
                              color: isDark
                                  ? Colors.blue.shade200
                                  : Colors.blue.shade600,
                              size: 20),
                        ),
                        title: Text(t.settings_language),
                        subtitle: Text(t.settings_language_sub),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _LangChip(
                              label: '🇬🇧 EN',
                              selected: currentLocale == AppLocale.en,
                              onTap: () => _setLocale(AppLocale.en),
                            ),
                            const SizedBox(width: 8),
                            _LangChip(
                              label: '🇸🇪 SV',
                              selected: currentLocale == AppLocale.sv,
                              onTap: () => _setLocale(AppLocale.sv),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ── Notifications ───────────────────────────────────────
                  _SectionHeader(t.settings_notifications),
                  _SettingsSectionCard(
                    children: [
                      SwitchListTile(
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.orange.withValues(alpha: 0.05)
                                : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _notificationsEnabled &&
                                    _notificationPermission ==
                                        AuthorizationStatus.authorized
                                ? Icons.notifications_rounded
                                : Icons.notifications_off_rounded,
                            color: isDark
                                ? Colors.orange.shade200
                                : Colors.orange.shade600,
                            size: 20,
                          ),
                        ),
                        title: Text(t.settings_notifications_toggle),
                        subtitle: Text(
                          _notificationPermission == AuthorizationStatus.denied
                              ? t.settings_notifications_denied
                              : _notificationsEnabled
                                  ? t.settings_notifications_on_sub
                                  : t.settings_notifications_off_sub,
                        ),
                        value: _notificationsEnabled &&
                            _notificationPermission !=
                                AuthorizationStatus.denied,
                        onChanged: _toggleNotifications,
                      ),
                      if (_notificationPermission ==
                              AuthorizationStatus.denied &&
                          !kIsWeb)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: AppOutlinedButton(
                            label: t.settings_notifications_open_settings,
                            onPressed: _openNotificationSettings,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ── Test Preferences ────────────────────────────────────
                  _SectionHeader(t.settings_test_prefs),
                  _SettingsSectionCard(
                    children: [
                      SwitchListTile(
                        title: Text(t.settings_timed_test),
                        subtitle: Text(t.settings_timed_test_sub),
                        value: isTimed,
                        onChanged: (v) {
                          HapticFeedback.lightImpact();
                          setState(() => isTimed = v);
                        },
                      ),
                      Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16, color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
                      SwitchListTile(
                        title: Text(t.settings_instant_marking),
                        subtitle: Text(t.settings_instant_marking_sub),
                        value: isInstantMarking,
                        onChanged: (v) {
                          HapticFeedback.lightImpact();
                          setState(() => isInstantMarking = v);
                        },
                      ),
                      Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16, color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
                      SwitchListTile(
                        title: const Text('Randomize Questions'),
                        subtitle: const Text(
                          'Get a fresh set of different questions every time you start a test',
                        ),
                        value: randomize,
                        onChanged: (v) {
                          HapticFeedback.lightImpact();
                          setState(() => randomize = v);
                        },
                      ),
                      Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16, color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
                      SwitchListTile(
                        title: const Text('Shuffle Question Order'),
                        subtitle: const Text(
                          'Keep the same questions but show them in a different order each time',
                        ),
                        value: shuffleOnDevice,
                        onChanged: (v) {
                          HapticFeedback.lightImpact();
                          setState(() => shuffleOnDevice = v);
                        },
                      ),
                      Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16, color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
                      ListTile(
                        title: Text(t.settings_num_questions),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Slider(
                              value: numberOfQuestions.toDouble(),
                              min: 1,
                              max: maxQuestions.toDouble(),
                              divisions: maxQuestions - 1,
                              label: '$numberOfQuestions',
                              onChanged: (value) {
                                setState(() {
                                  numberOfQuestions = value.toInt();
                                  _numberOfQuestionsController.text =
                                      numberOfQuestions.toString();
                                });
                              },
                            ),
                            Row(
                              children: [
                                Expanded(child: Text(t.settings_enter_num)),
                                SizedBox(
                                  width: 80,
                                  child: TextField(
                                    controller: _numberOfQuestionsController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                        hintText: 'e.g. 10',
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 8)),
                                    onChanged: (value) {
                                      final n = int.tryParse(value);
                                      if (n != null &&
                                          n > 0 &&
                                          n <= maxQuestions) {
                                        setState(() => numberOfQuestions = n);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16, color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
                      SwitchListTile(
                        title: Text(t.settings_include_saved),
                        subtitle: Text(t.settings_include_saved_sub),
                        value: includeSavedQuestions,
                        onChanged: (v) {
                          HapticFeedback.lightImpact();
                          setState(() => includeSavedQuestions = v);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ── Version Info ─────────────────────────────────────────
                  _SectionHeader(t.settings_version),
                  _SettingsSectionCard(
                    children: [
                      if (_versionInfo != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: Column(
                            children: [
                              _VersionRow(t.settings_app_version,
                                  'v${_versionInfo!.appVersion} (${_versionInfo!.buildNumber})'),
                              if (_versionInfo!.hasGitInfo) ...[
                                _VersionRow(
                                    t.settings_commit, _versionInfo!.shortHash),
                                _VersionRow(
                                    t.settings_branch, _versionInfo!.branch),
                                _VersionRow(t.settings_last_update,
                                    _versionInfo!.commitDate),
                              ],
                            ],
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: AppLoadingIndicator(),
                        ),
                    ],
                  ),

                  // ── Backend Info (admin only) ─────────────────────────────
                  if (_isAdmin) ...[
                    const _SectionHeader('Backend Info'),
                    _SettingsSectionCard(
                      children: [
                        if (_backendInfo == null)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: AppLoadingIndicator(),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            child: Column(
                              children: [
                                _VersionRow(
                                    'Status',
                                    (_backendInfo!['status'] ?? 'unknown')
                                        .toString()),
                                _VersionRow(
                                    'Debug Mode',
                                    (_backendInfo!['debug_mode'] ?? false)
                                        .toString()),
                                if (_backendInfo!['version'] is Map) ...[
                                  _VersionRow(
                                      'Branch',
                                      ((_backendInfo!['version']
                                                  as Map)['branch'] ??
                                              'unknown')
                                          .toString()),
                                  _VersionRow(
                                      'Commit',
                                      ((_backendInfo!['version']
                                                  as Map)['short_hash'] ??
                                              'unknown')
                                          .toString()),
                                  _VersionRow(
                                      'Last Deploy',
                                      _formatDeployDate(
                                          ((_backendInfo!['version']
                                                  as Map)['commit_date'])
                                              ?.toString())),
                                  _VersionRow(
                                      'Author',
                                      ((_backendInfo!['version']
                                                  as Map)['commit_author'] ??
                                              'unknown')
                                          .toString()),
                                  _VersionRow(
                                      'Message',
                                      ((_backendInfo!['version']
                                                  as Map)['commit_message'] ??
                                              'unknown')
                                          .toString()),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Save button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: AppFilledButton(
                label: t.save,
                borderRadius: 12,
                onPressed: () async {
                  await _savePreferences();
                  if (!mounted) return;
                  showAppSnackBar(t.settings_saved);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    final surfaces = AppSurfaceColors.fromTheme(Theme.of(context));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.bodySmall(color: surfaces.sectionLabel),
      ),
    );
  }
}

class _SettingsSectionCard extends StatelessWidget {
  const _SettingsSectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppSurfaceCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(children: children),
        ),
      ),
    );
  }
}

// ── Language chip ─────────────────────────────────────────────────────────────

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LangChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      );
}

// ── Version info row ──────────────────────────────────────────────────────────

class _VersionRow extends StatelessWidget {
  final String label;
  final String value;
  const _VersionRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(label,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            ),
            Expanded(
              child: Text(
                value,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
}
