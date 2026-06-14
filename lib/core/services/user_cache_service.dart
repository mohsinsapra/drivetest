import 'package:taxi_exam_app/core/services/analytics_service.dart';
import 'package:taxi_exam_app/core/storage/app_storage.dart';

/// Coordinates a full user-session teardown on logout.
///
/// Two distinct concerns are handled here:
///   1. **Storage** — delegated to [AppStorage.clearUserData], which clears
///      every Hive box, SharedPreferences bookmark key, and in-memory cache.
///   2. **Provider state** — [onProviderReset] is a callback registered by
///      main.dart after providers are created.  It resets DashboardProvider
///      and NotificationProvider so a new user starts with a blank slate.
///
/// Both the explicit logout path ([ApiService.logout]) and the automatic
/// 401-redirect path ([DioClient.logoutAndRedirect]) call [clearAll].
class UserCacheService {
  UserCacheService._();

  /// Registered once in main.dart after providers are instantiated.
  static Future<void> Function()? onProviderReset;

  /// Clears ALL user-specific state in the correct order:
  ///   0. In-memory provider state (DashboardProvider, NotificationProvider)
  ///   1. Hive boxes, SharedPreferences bookmarks, in-memory service caches
  ///      — see [AppStorage.clearUserData] for the full list.
  static Future<void> clearAll() async {
    // Reset provider state before storage so providers don't re-read stale data.
    await onProviderReset?.call();
    await AppStorage.clearUserData();
    // Detach analytics identity so the next user isn't attributed to this one.
    await AnalyticsService().clearUser();
  }
}
