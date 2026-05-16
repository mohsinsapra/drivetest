import 'package:flutter/foundation.dart';
import 'package:taxi_exam_app/core/models/local_notification.dart';
import 'package:taxi_exam_app/core/storage/app_storage.dart';

class NotificationProvider extends ChangeNotifier {
  static NotificationProvider? _instance;

  /// Global instance — set during app init, used by NotificationService.
  static NotificationProvider get instance {
    assert(_instance != null, 'NotificationProvider.create() not called');
    return _instance!;
  }

  static bool get isInitialized => _instance != null;

  List<LocalNotification> _notifications = [];

  List<LocalNotification> get notifications =>
      List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  String get topNotificationType {
    for (final n in _notifications) {
      if (!n.isRead) {
        return n.type;
      }
    }
    if (_notifications.isNotEmpty) {
      return _notifications.first.type;
    }
    return 'general';
  }

  NotificationProvider._();

  /// Open the Hive box, load persisted notifications, and register the instance.
  static Future<NotificationProvider> create() async {
    final box = await AppStorage.notificationsBox();
    final provider = NotificationProvider._();
    // Most-recent first
    provider._notifications = box.values.toList().reversed.toList();
    _instance = provider;
    return provider;
  }

  static Future<NotificationProvider> ensureInitialized() async {
    if (_instance != null) return _instance!;
    return create();
  }

  /// Add a new incoming notification (called from NotificationService).
  /// Skips if an identical notification (same type + title + body) was added
  /// within the last 10 seconds — prevents FCM retransmissions from doubling up.
  Future<void> add(String title, String body, {String type = 'general'}) async {
    final now = DateTime.now();
    final isDuplicate = _notifications.any((n) =>
        n.type == type &&
        n.title == title &&
        n.body == body &&
        now.difference(n.receivedAt).inSeconds < 10);
    if (isDuplicate) return;

    final n = LocalNotification(
      title: title,
      body: body,
      receivedAt: now,
      type: type,
    );
    try {
      final box = await AppStorage.notificationsBox();
      await box.add(n);
    } catch (e) {
      debugPrint('[NotificationProvider] Hive persist failed: $e');
    }
    _notifications.insert(0, n);
    notifyListeners();
  }

  Future<void> markRead(LocalNotification n) async {
    if (n.isRead) return;
    n.isRead = true;
    await n.save();
    notifyListeners();
  }

  Future<void> markAllRead() async {
    final unread = _notifications.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return;
    for (final n in unread) {
      n.isRead = true;
    }
    await Future.wait(unread.map((n) => n.save()));
    notifyListeners();
  }

  /// Whether any notification with [type] exists.
  bool hasType(String type) => _notifications.any((n) => n.type == type);

  /// Remove all notifications with the given [type].
  Future<void> removeByType(String type) async {
    final toRemove = _notifications.where((n) => n.type == type).toList();
    for (final n in toRemove) {
      try {
        await n.delete();
      } catch (_) {}
    }
    _notifications.removeWhere((n) => n.type == type);
    notifyListeners();
  }

  Future<void> clearAll() async {
    try {
      final box = await AppStorage.notificationsBox();
      await box.clear();
    } catch (e) {
      debugPrint('[NotificationProvider] clearAll box error: $e');
    }
    _notifications.clear();
    notifyListeners();
  }
}
