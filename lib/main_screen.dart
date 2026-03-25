import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/features/home/home_screen.dart';
import 'package:taxi_exam_app/features/tests/licences_screen.dart';
import 'package:taxi_exam_app/features/bcd/bcd_screen.dart';
import 'package:taxi_exam_app/features/profile/profile_screen.dart';

class _NavEntry {
  final IconData icon;
  final String label;
  final Widget screen;

  const _NavEntry({
    required this.icon,
    required this.label,
    required this.screen,
  });
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  late PageController _pageController;
  final ApiService _apiService = ApiService();

  bool _showLegacyTests = true;
  bool _showBcdTests = false;
  bool _listenerAttached = false;

  List<_NavEntry> get _navEntries {
    final items = <_NavEntry>[
      const _NavEntry(
        icon: LucideIcons.home,
        label: 'Home',
        screen: HomeScreen(),
      ),
    ];

    if (_showLegacyTests) {
      items.add(
        const _NavEntry(
          icon: LucideIcons.bookOpenCheck,
          label: 'Tests',
          screen: LicenceTypesScreen(),
        ),
      );
    }

    if (_showBcdTests) {
      items.add(
        const _NavEntry(
          icon: LucideIcons.graduationCap,
          label: 'BCD',
          screen: BCDScreen(),
        ),
      );
    }

    items.add(
      const _NavEntry(
        icon: LucideIcons.user,
        label: 'Profile',
        screen: ProfileScreen(),
      ),
    );

    return items;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadTabFlags();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<MainScreenProvider>(context, listen: false).setIndex(0);
      }
    });
  }

  bool _flag(dynamic value, bool fallback) {
    if (value is bool) return value;
    return fallback;
  }

  Future<void> _applyFlagsFromMap(Map<String, dynamic> userData) async {
    if (!mounted) return;
    setState(() {
      _showLegacyTests = _flag(userData['show_legacy_tests'], true);
      _showBcdTests = _flag(userData['show_bcd_tests'], false);
    });
    _ensureValidIndex();
  }

  void _ensureValidIndex() {
    if (!mounted) return;
    final provider = Provider.of<MainScreenProvider>(context, listen: false);
    final maxIndex = _navEntries.length - 1;
    final safeIndex = provider.currentIndex.clamp(0, maxIndex);
    if (safeIndex != provider.currentIndex) {
      provider.setIndex(safeIndex);
      _pageController.jumpToPage(safeIndex);
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_listenerAttached) return;
    _listenerAttached = true;
    Provider.of<MainScreenProvider>(context).addListener(() {
      if (!mounted) return;
      final index =
          Provider.of<MainScreenProvider>(context, listen: false).currentIndex;
      final safeIndex = index.clamp(0, _navEntries.length - 1);
      _pageController.jumpToPage(safeIndex);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    Provider.of<MainScreenProvider>(context, listen: false).setIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MainScreenProvider>(context);
    final entries = _navEntries;
    final selectedIndex = provider.currentIndex.clamp(0, entries.length - 1);
    final mq = MediaQuery.of(context);

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const ClampingScrollPhysics(),
            children: entries.map((e) => e.screen).toList(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _FloatingNavArea(
              currentIndex: selectedIndex,
              items: entries,
              onTap: (i) => provider.setIndex(i),
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
  final ValueChanged<int> onTap;
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
  final ValueChanged<int> onTap;

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
                  onTap: () => onTap(e.key),
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

  void setIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }
}
