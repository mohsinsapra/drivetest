import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/models/local_notification.dart';
import 'package:taxi_exam_app/core/providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          t.notifications_title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
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
      body: Consumer<NotificationProvider>(
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
