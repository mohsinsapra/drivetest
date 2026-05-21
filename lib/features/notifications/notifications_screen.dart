import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/models/local_notification.dart';
import 'package:taxi_exam_app/core/providers/notification_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with WidgetsBindingObserver {
  AuthorizationStatus? _permissionStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check when user returns from Settings
    if (state == AppLifecycleState.resumed) _checkPermission();
  }

  Future<void> _checkPermission() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    if (mounted) {
      setState(() => _permissionStatus = settings.authorizationStatus);
    }
  }

  Future<void> _requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission();
    if (mounted) {
      setState(() => _permissionStatus = settings.authorizationStatus);
    }
  }

  Future<void> _openAppSettings() async {
    if (kIsWeb) {
      _showWebSettingsDialog();
      return;
    }
    if (Platform.isIOS) {
      await launchUrl(Uri.parse('app-settings:'));
    } else {
      await launchUrl(
        Uri.parse('android.settings.APP_NOTIFICATION_SETTINGS'),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  void _showWebSettingsDialog() {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: cs.surface,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.info, size: 26, color: cs.primary),
              ),
              const SizedBox(height: 16),
              Text(
                t.notifications_permission_web_dialog_title,
                textAlign: TextAlign.center,
                style: GoogleFonts.lexend(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                t.notifications_permission_web_dialog_body,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: Text(
                    t.notifications_permission_web_dialog_ok,
                    style: GoogleFonts.lexend(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(BuildContext context, DateTime dt) {
    final t = Translations.of(context);
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return t.notifications_just_now;
    if (diff.inMinutes < 60) {
      return t.notifications_minutes_ago.replaceAll('{n}', '${diff.inMinutes}');
    }
    if (diff.inHours < 24) {
      return t.notifications_hours_ago.replaceAll('{n}', '${diff.inHours}');
    }
    if (diff.inDays < 7) {
      return t.notifications_days_ago.replaceAll('{n}', '${diff.inDays}');
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final permissionDenied = _permissionStatus == AuthorizationStatus.denied;
    final permissionNotDetermined =
        _permissionStatus == AuthorizationStatus.notDetermined;
    final needsPermission = permissionDenied || permissionNotDetermined;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Material(
            color: theme.cardColor,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.maybePop(context),
              child: Icon(
                Icons.arrow_back_rounded,
                color: theme.appBarTheme.iconTheme?.color,
                size: 20,
              ),
            ),
          ),
        ),
        title: Text(
          t.notifications_title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          if (!needsPermission)
            Consumer<NotificationProvider>(
              builder: (_, provider, __) {
                if (provider.notifications.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (provider.unreadCount > 0)
                      TextButton(
                        onPressed: provider.markAllRead,
                        child: Text(
                          t.notifications_mark_all_read,
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: Icon(LucideIcons.trash2,
                          size: 18, color: Colors.grey.shade500),
                      tooltip: t.notifications_clear,
                      onPressed: () => _confirmClear(context, provider, t),
                    ),
                    const SizedBox(width: 4),
                  ],
                );
              },
            ),
        ],
      ),
      body: _permissionStatus == null
          ? const SizedBox.shrink() // loading — avoid flicker
          : needsPermission
              ? _PermissionState(
                  denied: permissionDenied,
                  colorScheme: colorScheme,
                  onRequest:
                      permissionDenied ? _openAppSettings : _requestPermission,
                )
              : Consumer<NotificationProvider>(
                  builder: (_, provider, __) {
                    if (provider.notifications.isEmpty) {
                      return _EmptyState(t: t, colorScheme: colorScheme);
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      itemCount: provider.notifications.length,
                      itemBuilder: (_, i) {
                        final n = provider.notifications[i];
                        return _NotificationCard(
                          notification: n,
                          timeAgo: _timeAgo(context, n.receivedAt),
                          onTap: () => provider.markRead(n),
                          colorScheme: colorScheme,
                          theme: theme,
                        );
                      },
                    );
                  },
                ),
    );
  }

  void _confirmClear(
      BuildContext context, NotificationProvider provider, Translations t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(t.notifications_clear_confirm_title,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(t.notifications_clear_confirm_body,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(t.cancel,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      provider.clearAll();
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(t.notifications_clear,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
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

// ─── Notification card ────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final LocalNotification notification;
  final String timeAgo;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _NotificationCard({
    required this.notification,
    required this.timeAgo,
    required this.onTap,
    required this.colorScheme,
    required this.theme,
  });

  IconData _iconForType(String type, bool isUnread) {
    switch (type) {
      case 'subscription':
        return LucideIcons.creditCard;
      case 'app_update':
        return LucideIcons.download;
      case 'payment':
        return LucideIcons.wallet;
      case 'warning':
        return LucideIcons.alertTriangle;
      default:
        return isUnread ? LucideIcons.bellRing : LucideIcons.bell;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isUnread
            ? colorScheme.primary.withValues(alpha: 0.06)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon container
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isUnread
                        ? colorScheme.primary.withValues(alpha: 0.12)
                        : Colors.grey.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _iconForType(notification.type, isUnread),
                    size: 18,
                    color:
                        isUnread ? colorScheme.primary : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: isUnread
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isUnread)
                            Container(
                              width: 7,
                              height: 7,
                              margin: const EdgeInsets.only(top: 5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                      if (notification.body.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          notification.body,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 11,
                          color: isUnread
                              ? colorScheme.primary.withValues(alpha: 0.7)
                              : Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Permission state ─────────────────────────────────────────────────────────

class _PermissionState extends StatelessWidget {
  const _PermissionState({
    required this.denied,
    required this.colorScheme,
    required this.onRequest,
  });

  final bool denied;
  final ColorScheme colorScheme;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.bellOff,
                size: 34,
                color: colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              t.notifications_permission_off_title,
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              denied
                  ? t.notifications_permission_denied_body
                  : t.notifications_permission_not_determined_body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onRequest,
                icon: Icon(
                  denied ? LucideIcons.settings : LucideIcons.bell,
                  size: 18,
                ),
                label: Text(
                  denied
                      ? t.notifications_permission_open_settings
                      : t.notifications_permission_enable,
                  style: GoogleFonts.lexend(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final Translations t;
  final ColorScheme colorScheme;

  const _EmptyState({required this.t, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.bellOff,
                size: 30,
                color: colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t.notifications_empty_title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              t.notifications_empty_subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
