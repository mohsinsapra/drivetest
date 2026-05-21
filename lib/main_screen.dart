import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/services/navigation_feedback.dart';
import 'package:taxi_exam_app/core/services/notification_service.dart';
import 'package:taxi_exam_app/core/storage/app_storage.dart';
import 'package:taxi_exam_app/features/home/home_screen.dart';
import 'package:taxi_exam_app/features/tests/licences_screen.dart';
import 'package:taxi_exam_app/features/bcd/bcd_screen.dart';
import 'package:taxi_exam_app/features/profile/profile_screen.dart';
import 'package:taxi_exam_app/features/dashboard/screens/exam_dashboard_screen.dart';

// Fixed page indices — these never change regardless of which tabs are visible.
const int _kPageHome = 0;
const int _kPageTests = 1;
const int _kPageDriveTest = 2;
const int _kPageProfile = 3;
const int _kPageDashboard = 4;

// All screens at their fixed positions in the PageView.
const List<Widget> _kAllScreens = [
  HomeScreen(),
  LicenceTypesScreen(),
  BCDScreen(),
  ProfileScreen(),
  ExamDashboardScreen(),
];

class _NavEntry {
  final IconData icon;
  final String label;
  final int pageIndex; // Fixed position in the PageView

  const _NavEntry({
    required this.icon,
    required this.label,
    required this.pageIndex,
  });
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  final ApiService _apiService = ApiService();

  // Hidden until backend confirms; prevents the Home tab from appearing
  // on first launch for users who don't have legacy tests enabled.
  bool _showLegacyTests = false;
  bool _showBcdTests = false;

  // Returns only the tabs the user should see, each pointing to a fixed page.
  // Progress is always first. Home + Tests only appear when the backend sets
  // show_legacy_tests = true on the user's account.
  List<_NavEntry> _navEntries(Translations t) {
    return [
      _NavEntry(
        icon: LucideIcons.home,
        label: t.home_my_progress,
        pageIndex: _kPageDashboard,
      ),
      if (_showLegacyTests) ...[
        _NavEntry(
          icon: LucideIcons.barChart2,
          label: t.home,
          pageIndex: _kPageHome,
        ),
        _NavEntry(
          icon: LucideIcons.bookOpenCheck,
          label: t.tests,
          pageIndex: _kPageTests,
        ),
      ],
      if (_showBcdTests)
        _NavEntry(
          icon: LucideIcons.graduationCap,
          label: t.bcd_drive_test,
          pageIndex: _kPageDriveTest,
        ),
      _NavEntry(
        icon: LucideIcons.user,
        label: t.profile,
        pageIndex: _kPageProfile,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<MainScreenProvider>(context, listen: false)
          .setIndex(_kPageDashboard);
      _loadTabFlags();
      NotificationService.init(_apiService).ignore();
    });
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
        isAdmin ? true : _flag(userData['show_legacy_tests'], false);
    final newShowBcd = isAdmin ? true : _flag(userData['show_bcd_tests'], true);

    // Nothing changed — skip the rebuild entirely.
    if (newShowLegacy == _showLegacyTests && newShowBcd == _showBcdTests) {
      return;
    }

    final provider = Provider.of<MainScreenProvider>(context, listen: false);
    final currentPage = provider.currentIndex;

    setState(() {
      _showLegacyTests = newShowLegacy;
      _showBcdTests = newShowBcd;
    });

    // If the current page is no longer visible after the tab change, redirect to Progress.
    final visiblePages = <int>{
      _kPageDashboard,
      if (_showLegacyTests) ...[_kPageHome, _kPageTests],
      if (_showBcdTests) _kPageDriveTest,
      _kPageProfile,
    };
    if (!visiblePages.contains(currentPage)) {
      provider.setIndex(_kPageDashboard);
    }
  }

  Future<void> _loadTabFlags() async {
    // Apply cached flags immediately (zero network latency) so tabs appear
    // on the first frame. The background refresh below keeps them up to date.
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(AppStorage.kUserJson);
      if (stored != null) {
        final map = jsonDecode(stored);
        if (map is Map<String, dynamic>) {
          await _applyFlagsFromMap(map);
        }
      }
    } catch (_) {}

    // Background refresh — silently update if the server returns different flags.
    _apiService.fetchCurrentUser().then((fresh) {
      if (fresh is Map<String, dynamic>) {
        _applyFlagsFromMap(fresh);
      }
    }).ignore();
  }

  void _handleNavigationChange(MainScreenProvider provider, int pageIndex) {
    final didChange = provider.setIndex(pageIndex);
    if (didChange) {
      playNavigationFeedback();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final provider = Provider.of<MainScreenProvider>(context);
    final entries = _navEntries(t);
    final currentPage = provider.currentIndex.clamp(0, _kAllScreens.length - 1);

    // Find which nav entry matches the current page for highlighting.
    final navIndex = entries.indexWhere((e) => e.pageIndex == currentPage);
    final selectedNavIndex = navIndex >= 0 ? navIndex : 0;

    final mq = MediaQuery.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // IndexedStack keeps every screen alive and switches instantly
          // without any index-mapping between visible tabs and screen positions.
          IndexedStack(
            index: currentPage,
            children: _kAllScreens,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _FloatingNavArea(
              currentIndex: selectedNavIndex,
              items: entries,
              onTap: (pageIndex) {
                _handleNavigationChange(provider, pageIndex);
              },
              bottomInset: mq.padding.bottom,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Floating nav area (transparent container holding pill + FAB) ────────────

class _FloatingNavArea extends StatelessWidget {
  final int currentIndex;
  final List<_NavEntry> items;
  final ValueChanged<int> onTap; // receives fixed pageIndex
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
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            child: _FloatingNavPill(
              currentIndex: currentIndex,
              items: items,
              onTap: onTap,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pill nav bar ────────────────────────────────────────────────────────────

class _FloatingNavPill extends StatefulWidget {
  final int currentIndex;
  final List<_NavEntry> items;
  final ValueChanged<int> onTap; // receives fixed pageIndex

  static const double _itemW = 56;
  static const double _itemH = 44;
  static const double _pad = 5;

  const _FloatingNavPill({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  State<_FloatingNavPill> createState() => _FloatingNavPillState();
}

class _FloatingNavPillState extends State<_FloatingNavPill> {
  final _pillKey = GlobalKey();
  int? _dragNavIndex;
  bool _isDragging = false;

  int get _activeNavIndex => _isDragging
      ? (_dragNavIndex ?? widget.currentIndex)
      : widget.currentIndex;

  // Convert a global screen position to a nav tab index.
  int _navIndexAt(Offset globalPos) {
    final box = _pillKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return widget.currentIndex;
    final local = box.globalToLocal(globalPos);
    final adjusted = local.dx - _FloatingNavPill._pad;
    return (adjusted / _FloatingNavPill._itemW)
        .floor()
        .clamp(0, widget.items.length - 1);
  }

  void _onTapUp(TapUpDetails d) {
    final idx = _navIndexAt(d.globalPosition);
    widget.onTap(widget.items[idx].pageIndex);
  }

  void _onDragStart(DragStartDetails d) {
    final idx = _navIndexAt(d.globalPosition);
    setState(() {
      _isDragging = true;
      _dragNavIndex = idx;
    });
    widget.onTap(widget.items[idx].pageIndex);
  }

  void _onDragUpdate(DragUpdateDetails d) {
    final idx = _navIndexAt(d.globalPosition);
    if (idx != _dragNavIndex) {
      setState(() => _dragNavIndex = idx);
      widget.onTap(widget.items[idx].pageIndex);
    }
  }

  void _onDragEnd(DragEndDetails _) {
    setState(() {
      _isDragging = false;
      _dragNavIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeIdx = _activeNavIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapUp: _onTapUp,
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      behavior: HitTestBehavior.opaque,
      child: Container(
        key: _pillKey,
        padding: const EdgeInsets.all(_FloatingNavPill._pad),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
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
          width: widget.items.length * _FloatingNavPill._itemW,
          height: _FloatingNavPill._itemH,
          child: Stack(
            children: [
              // Sliding indicator — snappy during drag, smooth on tap/release
              AnimatedPositioned(
                duration: Duration(milliseconds: _isDragging ? 60 : 300),
                curve: Curves.easeInOutCubic,
                left: activeIdx * _FloatingNavPill._itemW,
                top: 0,
                width: _FloatingNavPill._itemW,
                height: _FloatingNavPill._itemH,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
              ),
              // Icons
              Row(
                children: widget.items.asMap().entries.map((e) {
                  final isActive = activeIdx == e.key;
                  final distance = (e.key - activeIdx).abs();
                  // Magnify during drag: active = 1.45×, neighbours = 1.15×
                  final scale = _isDragging
                      ? (distance == 0 ? 1.45 : (distance == 1 ? 1.15 : 1.0))
                      : 1.0;
                  return SizedBox(
                    width: _FloatingNavPill._itemW,
                    height: _FloatingNavPill._itemH,
                    child: Center(
                      child: AnimatedScale(
                        scale: scale,
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOut,
                        child: Icon(
                          e.value.icon,
                          size: 22,
                          color: isActive
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Floating action button ──────────────────────────────────────────────────

class _FloatingFab extends StatefulWidget {
  final VoidCallback onTap;

  const _FloatingFab({required this.onTap});

  @override
  State<_FloatingFab> createState() => _FloatingFabState();
}

class _FloatingFabState extends State<_FloatingFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _controller.reverse();
  void _onTapUp(_) async {
    await _controller.forward();
    widget.onTap();
  }

  void _onTapCancel() => _controller.forward();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFFE05C63),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE05C63).withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

class MainScreenProvider extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  bool setIndex(int index) {
    if (_currentIndex == index) {
      return false;
    }
    _currentIndex = index;
    notifyListeners();
    return true;
  }
}
