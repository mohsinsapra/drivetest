import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/features/auth/auth_screen.dart';
import 'package:taxi_exam_app/features/support/help_screen.dart';
import 'package:taxi_exam_app/settings/settings.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  String? _username;
  String? _email;
  final ApiService _apiService = ApiService();

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

    _loadUserFromPrefs();
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUser = prefs.getString('user');
    if (storedUser != null) {
      final Map<String, dynamic> userMap = jsonDecode(storedUser);
      if (mounted) {
        setState(() {
          _username = userMap['username'] ?? 'Unknown';
          _email = userMap['email'] ?? '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final menuItems = [
      (icon: Icons.person, color: const Color(0xFFFFCDD2), title: t.profile_edit),
      (icon: Icons.bar_chart, color: const Color(0xFFE1BEE7), title: t.profile_stats),
      (icon: Icons.settings, color: const Color(0xFFFFE0B2), title: t.profile_settings),
    ];
    final secondaryItems = [
      (icon: Icons.person_add_alt, color: const Color(0xFFE0E0E0), title: t.profile_invite),
      (icon: Icons.help_outline, color: const Color(0xFFE0E0E0), title: t.profile_help),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(t.profile),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: ListView(
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
                        color: Colors.pinkAccent.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        t.profile_student,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _username ?? t.loading,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _email ?? '',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── Staggered menu tiles ───────────────────────────────────
            ...menuItems.asMap().entries.map((e) => _ProfileTile(
                  index: e.key,
                  child: _buildMenuTile(
                    context,
                    icon: e.value.icon,
                    iconColor: e.value.color,
                    title: e.value.title,
                    onTap: e.value.title == 'Settings'
                        ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SettingsScreen()),
                            )
                        : () {},
                  ),
                )),

            _ProfileTile(
              index: menuItems.length,
              child: const Divider(
                  thickness: 0.5, color: Color(0xFFE0E0E0)),
            ),

            ...secondaryItems.asMap().entries.map((e) => _ProfileTile(
                  index: menuItems.length + 1 + e.key,
                  child: _buildMenuTile(
                    context,
                    icon: e.value.icon,
                    iconColor: e.value.color,
                    title: e.value.title,
                    onTap: e.value.title == 'Help'
                        ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const HelpScreen()),
                            )
                        : () {},
                  ),
                )),

            _ProfileTile(
              index: menuItems.length + secondaryItems.length + 1,
              child: const Divider(
                  thickness: 0.5, color: Color(0xFFE0E0E0)),
            ),

            // ── Logout ─────────────────────────────────────────────────
            _ProfileTile(
              index: menuItems.length + secondaryItems.length + 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      final outerContext = context;
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24)),
                        ),
                        builder: (context) => Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(t.logout,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red)),
                              const SizedBox(height: 12),
                              Text(t.profile_logout_confirm,
                                  style: const TextStyle(fontSize: 16)),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor:
                                            Theme.of(context).primaryColor,
                                        side: BorderSide(
                                            color: Theme.of(context)
                                                .primaryColor),
                                      ),
                                      child: Text(t.cancel),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await _apiService.logout();
                                        await Hive.deleteFromDisk();
                                        if (!outerContext.mounted) return;
                                        Navigator.of(outerContext)
                                            .pushAndRemoveUntil(
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const AuthScreen()),
                                          (route) => false,
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red),
                                      child: Text(t.profile_yes_logout),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
                    label: Text(t.logout,
                        style: const TextStyle(fontSize: 15)),
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
    _slide = Tween<Offset>(
            begin: const Offset(0.05, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(
        Duration(milliseconds: 150 + widget.index * 35),
        () { if (mounted) _ctrl.forward(); });
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
