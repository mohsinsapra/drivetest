import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/router/route_names.dart';

class _NavEntry {
  final IconData icon;
  final String label;
  final String route;
  final bool Function(_TabFlags flags) isVisible;

  const _NavEntry({
    required this.icon,
    required this.label,
    required this.route,
    required this.isVisible,
  });
}

class _TabFlags {
  final bool showLegacyTests;
  final bool showBcdTests;

  const _TabFlags({this.showLegacyTests = true, this.showBcdTests = false});
}

const List<_NavEntry> _kAllEntries = [
  _NavEntry(
    icon: LucideIcons.home,
    label: 'Home',
    route: Routes.home,
    isVisible: _alwaysVisible,
  ),
  _NavEntry(
    icon: LucideIcons.bookOpenCheck,
    label: 'Tests',
    route: Routes.tests,
    isVisible: _showTests,
  ),
  _NavEntry(
    icon: LucideIcons.graduationCap,
    label: 'Drive Test',
    route: Routes.bcd,
    isVisible: _showBcd,
  ),
  _NavEntry(
    icon: LucideIcons.user,
    label: 'Profile',
    route: Routes.profile,
    isVisible: _alwaysVisible,
  ),
];

bool _alwaysVisible(_TabFlags _) => true;
bool _showTests(_TabFlags f) => f.showLegacyTests;
bool _showBcd(_TabFlags f) => f.showBcdTests;

// Fixed branch indices matching StatefulShellRoute branches order:
// 0 = home, 1 = tests, 2 = bcd, 3 = profile
const int _kBranchHome    = 0;
const int _kBranchTests   = 1;
const int _kBranchBcd     = 2;
const int _kBranchProfile = 3;

int _branchIndexForRoute(String route) {
  switch (route) {
    case Routes.home:    return _kBranchHome;
    case Routes.tests:   return _kBranchTests;
    case Routes.bcd:     return _kBranchBcd;
    case Routes.profile: return _kBranchProfile;
    default:             return _kBranchHome;
  }
}

class MainScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainScreen({super.key, required this.navigationShell});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  final ApiService _apiService = ApiService();
  _TabFlags _flags = const _TabFlags();

  @override
  void initState() {
    super.initState();
    _loadTabFlags();
  }

  bool _flag(dynamic value, bool fallback) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.trim().toLowerCase();
      if (v == 'true' || v == '1' || v == 'yes') return true;
      if (v == 'false' || v == '0' || v == 'no') return false;
    }
    return fallback;
  }

  Future<void> _applyFlagsFromMap(Map<String, dynamic> userData) async {
    if (!mounted) return;
    final isAdmin = _flag(userData['is_administrator'], false);
    final newShowLegacy =
        isAdmin ? true : _flag(userData['show_legacy_tests'], true);
    final newShowBcd =
        isAdmin ? true : _flag(userData['show_bcd_tests'], false);

    final newFlags = _TabFlags(showLegacyTests: newShowLegacy, showBcdTests: newShowBcd);
    if (newFlags.showLegacyTests == _flags.showLegacyTests &&
        newFlags.showBcdTests == _flags.showBcdTests) {
      return;
    }

    setState(() => _flags = newFlags);

    // If current tab is now hidden, go home.
    final currentBranch = widget.navigationShell.currentIndex;
    final visibleEntries = _kAllEntries.where((e) => e.isVisible(_flags)).toList();
    final visibleBranches =
        visibleEntries.map((e) => _branchIndexForRoute(e.route)).toSet();
    if (!visibleBranches.contains(currentBranch) && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(Routes.home);
      });
    }
  }

  Future<void> _loadTabFlags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      if (userJson != null && userJson.isNotEmpty) {
        final parsed = jsonDecode(userJson);
        if (parsed is Map<String, dynamic>) {
          await _applyFlagsFromMap(parsed);
        }
      }

      final fresh = await _apiService.fetchCurrentUser();
      if (fresh is Map<String, dynamic>) {
        await prefs.setString('user', jsonEncode(fresh));
        await _applyFlagsFromMap(fresh);
      }
    } catch (_) {
      // Keep defaults if loading flags fails.
    }
  }

  List<_NavEntry> get _visibleEntries =>
      _kAllEntries.where((e) => e.isVisible(_flags)).toList();

  int _navIndexFromBranch(int branchIndex) {
    final visible = _visibleEntries;
    for (var i = 0; i < visible.length; i++) {
      if (_branchIndexForRoute(visible[i].route) == branchIndex) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final entries = _visibleEntries;
    final currentBranch = widget.navigationShell.currentIndex;
    final selectedNavIndex = _navIndexFromBranch(currentBranch);
    final mq = MediaQuery.of(context);

    return Scaffold(
      body: Stack(
        children: [
          widget.navigationShell,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _FloatingNavArea(
              currentIndex: selectedNavIndex,
              items: entries,
              onTap: (entry) {
                final branchIndex = _branchIndexForRoute(entry.route);
                widget.navigationShell.goBranch(
                  branchIndex,
                  initialLocation: branchIndex ==
                      widget.navigationShell.currentIndex,
                );
              },
              bottomInset: mq.padding.bottom,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Floating nav area ────────────────────────────────────────────────────────

class _FloatingNavArea extends StatelessWidget {
  final int currentIndex;
  final List<_NavEntry> items;
  final ValueChanged<_NavEntry> onTap;
  final double bottomInset;

  const _FloatingNavArea({
    required this.currentIndex,
    required this.items,
    required this.onTap,
    required this.bottomInset,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset + 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _FloatingNavPill(
            currentIndex: currentIndex,
            items: items,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

// ─── Pill nav bar ────────────────────────────────────────────────────────────

class _FloatingNavPill extends StatelessWidget {
  final int currentIndex;
  final List<_NavEntry> items;
  final ValueChanged<_NavEntry> onTap;

  static const double _itemW = 56;
  static const double _itemH = 44;
  static const double _pad = 5;

  const _FloatingNavPill({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_pad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SizedBox(
        width: items.length * _itemW,
        height: _itemH,
        child: Stack(
          children: [
            // Sliding indicator pill
            AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              left: currentIndex * _itemW,
              top: 0,
              width: _itemW,
              height: _itemH,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
            ),
            // Icons
            Row(
              children: items.asMap().entries.map((e) {
                final isActive = currentIndex == e.key;
                return GestureDetector(
                  onTap: () => onTap(e.value),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: _itemW,
                    height: _itemH,
                    child: Icon(
                      e.value.icon,
                      size: 22,
                      color: isActive ? Colors.black87 : Colors.grey.shade500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Provider (kept for backward compatibility) ───────────────────────────────

class MainScreenProvider extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }
}
