/// Lightweight cache coordinator for home screen backend data.
///
/// Any part of the app that saves a new test attempt should call
/// [HomeDataCache.invalidate] so the home screen re-syncs on the next visit.
class HomeDataCache {
  HomeDataCache._();

  static DateTime? _lastSync;
  static const Duration syncInterval = Duration(minutes: 5);

  /// Whether a backend sync is needed (cache expired or never run).
  static bool get isStale =>
      _lastSync == null || DateTime.now().difference(_lastSync!) >= syncInterval;

  /// Record that a fresh sync just completed.
  static void markSynced() => _lastSync = DateTime.now();

  /// Force a backend sync on the next home screen load.
  static void invalidate() => _lastSync = null;
}
