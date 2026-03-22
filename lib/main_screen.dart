import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:taxi_exam_app/features/home/home_screen.dart';
import 'package:taxi_exam_app/features/tests/licences_screen.dart';
import 'package:taxi_exam_app/features/profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  late PageController _pageController;

  final List<Widget> _screens = [
    const HomeScreen(),
    const LicenceTypesScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<MainScreenProvider>(context, listen: false).setIndex(0);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Provider.of<MainScreenProvider>(context).addListener(() {
      if (!mounted) return;
      final index =
          Provider.of<MainScreenProvider>(context, listen: false).currentIndex;
      _pageController.jumpToPage(index);
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

    return Scaffold(
      // extendBody lets PageView render behind the transparent bottomNavigationBar
      // so scroll-aware widgets (ListView, SingleChildScrollView) still pad correctly
      extendBody: true,
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const ClampingScrollPhysics(),
        children: _screens,
      ),
      bottomNavigationBar: _FloatingNavArea(
        currentIndex: provider.currentIndex,
        onTap: (i) => provider.setIndex(i),
      ),
    );
  }
}

// ─── Floating nav area (transparent container holding pill + FAB) ────────────

class _FloatingNavArea extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingNavArea({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _FloatingNavPill(
              currentIndex: currentIndex,
              onTap: onTap,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pill nav bar ────────────────────────────────────────────────────────────

class _FloatingNavPill extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (icon: LucideIcons.home, label: 'Home'),
    (icon: LucideIcons.bookOpenCheck, label: 'Tests'),
    (icon: LucideIcons.user, label: 'Profile'),
  ];

  // Fixed dimensions so AnimatedPositioned can calculate offsets
  static const double _itemW = 56;
  static const double _itemH = 44;
  static const double _pad = 5;

  const _FloatingNavPill({
    required this.currentIndex,
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
        width: _items.length * _itemW,
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
            // Icons (rendered on top of the indicator)
            Row(
              children: _items.asMap().entries.map((e) {
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
                      color: isActive
                          ? Colors.black87
                          : Colors.grey.shade500,
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
