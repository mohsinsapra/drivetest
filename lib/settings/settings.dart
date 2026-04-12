import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/providers/font_provider.dart';
import 'package:taxi_exam_app/core/providers/theme_provider.dart';
import 'package:taxi_exam_app/core/services/version_service.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isTimed = false;
  bool isInstantMarking = false;
  bool includeSavedQuestions = false;
  int numberOfQuestions = 10;
  int maxQuestions = 1000;
  VersionInfo? _versionInfo;
  bool _isAdmin = false;
  Map<String, dynamic>? _backendInfo;

  final ApiService _apiService = ApiService();
  final TextEditingController _numberOfQuestionsController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadVersionInfo();
    _loadAdminState();
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
      includeSavedQuestions =
          prefs.getBool('includeSavedQuestions') ?? false;
      numberOfQuestions = prefs.getInt('numberOfQuestions') ?? 10;
      _numberOfQuestionsController.text = numberOfQuestions.toString();
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isTimed', isTimed);
    await prefs.setBool('isInstantMarking', isInstantMarking);
    await prefs.setBool('includeSavedQuestions', includeSavedQuestions);
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
    final isDark = themeProvider.isDark;

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

                  // Dark mode
                  SwitchListTile(
                    title: Text(t.settings_dark_mode),
                    subtitle: Text(t.settings_dark_mode_sub),
                    value: isDark,
                    onChanged: (_) => themeProvider.toggle(),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.indigo.shade900
                            : Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: isDark ? Colors.white : Colors.amber.shade700,
                        size: 20,
                      ),
                    ),
                  ),

                  const Divider(height: 1, indent: 16, endIndent: 16),

                  // Font picker
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.purple.withValues(alpha: 0.2)
                            : Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.font_download_rounded,
                          color: isDark ? Colors.purple.shade200 : Colors.purple.shade600, size: 20),
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

                  const Divider(height: 1, indent: 16, endIndent: 16),

                  // Language
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.blue.withValues(alpha: 0.2)
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.language_rounded,
                          color: isDark ? Colors.blue.shade200 : Colors.blue.shade600, size: 20),
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

                  const SizedBox(height: 8),

                  // ── Test Preferences ────────────────────────────────────
                  _SectionHeader(t.settings_test_prefs),

                  SwitchListTile(
                    title: Text(t.settings_timed_test),
                    subtitle: Text(t.settings_timed_test_sub),
                    value: isTimed,
                    onChanged: (v) => setState(() => isTimed = v),
                  ),

                  const Divider(height: 1, indent: 16, endIndent: 16),

                  SwitchListTile(
                    title: Text(t.settings_instant_marking),
                    subtitle: Text(t.settings_instant_marking_sub),
                    value: isInstantMarking,
                    onChanged: (v) => setState(() => isInstantMarking = v),
                  ),

                  const Divider(height: 1, indent: 16, endIndent: 16),

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
                            Expanded(
                                child: Text(t.settings_enter_num)),
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

                  const Divider(height: 1, indent: 16, endIndent: 16),

                  SwitchListTile(
                    title: Text(t.settings_include_saved),
                    subtitle: Text(t.settings_include_saved_sub),
                    value: includeSavedQuestions,
                    onChanged: (v) =>
                        setState(() => includeSavedQuestions = v),
                  ),

                  const SizedBox(height: 8),

                  // ── Version Info ─────────────────────────────────────────
                  _SectionHeader(t.settings_version),

                  if (_versionInfo != null) ...[
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
                    ),
                  ] else
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    ),

                  // ── Backend Info (admin only) ─────────────────────────────
                  if (_isAdmin) ...[
                    _SectionHeader('Backend Info'),
                    if (_backendInfo == null)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          children: [
                            _VersionRow('Status',
                                (_backendInfo!['status'] ?? 'unknown').toString()),
                            _VersionRow('Debug Mode',
                                (_backendInfo!['debug_mode'] ?? false).toString()),
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
                                  _formatDeployDate((_backendInfo!['version']
                                          as Map)['commit_date']
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
                ],
              ),
            ),

            // Save button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _savePreferences();
                    if (!mounted) return;
                    showAppSnackBar(t.settings_saved);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(t.save),
                ),
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
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 1.0,
          ),
        ),
      );
}

// ── Language chip ─────────────────────────────────────────────────────────────

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LangChip(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 13)),
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
