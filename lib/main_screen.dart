import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/services/navigation_feedback.dart';
import 'package:taxi_exam_app/core/services/notification_service.dart';
import 'package:taxi_exam_app/core/storage/app_storage.dart';
import 'package:taxi_exam_app/core/utils/platform_detector.dart';
import 'package:taxi_exam_app/core/providers/notification_provider.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/core/widgets/app_back_button.dart';
import 'package:taxi_exam_app/core/widgets/app_download_sheet.dart';
import 'package:taxi_exam_app/core/widgets/glass_box.dart';
import 'package:taxi_exam_app/features/notifications/notifications_screen.dart';
import 'package:taxi_exam_app/features/home/home_screen.dart';
import 'package:taxi_exam_app/features/tests/licences_screen.dart';
import 'package:taxi_exam_app/features/bcd/bcd_screen.dart';
import 'package:taxi_exam_app/features/profile/profile_screen.dart';
import 'package:taxi_exam_app/features/profile/providers/profile_provider.dart';
import 'package:taxi_exam_app/features/smart_learning/screens/smart_learning_screen.dart';
import 'package:taxi_exam_app/features/dashboard/screens/exam_dashboard_screen.dart';

const int _kPageHome = 0;
const int _kPageTests = 1;
const int _kPageDriveTest = 2;
const int _kPageSmartLearning = 3;
const int _kPageDashboard = 4;
const int _kPageProfile = 5;

const List<Widget> _kAllScreens = [
  HomeScreen(),
  LicenceTypesScreen(),
  BCDScreen(),
  SmartLearningScreen(),
  ExamDashboardScreen(),
  ProfileScreen(),
];

class _NavEntry {
  final IconData icon;
  final String label;
  final int pageIndex;

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

class MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final ProfileProvider _profile = ProfileProvider();

  late final AnimationController _profileAnimCtrl;
  late final Animation<Offset> _profileSlide;
  bool _profileVisible = false;

  int _displayedPage = _kPageDashboard;

  bool _showLegacyTests = false;
  bool _showBcdTests = false;
  bool _isNavCompact = false;

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
        icon: LucideIcons.compass,
        label: t.smart_learning_title,
        pageIndex: _kPageSmartLearning,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _profileAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _profileSlide = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _profileAnimCtrl,
      curve: Curves.easeInOutCubic,
    ));
    _profile.addListener(_onProfileChanged);
    _profile.loadUserFromPrefs().then((_) {
      if (mounted) _profile.loadProfile().catchError((_) {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<MainScreenProvider>(context, listen: false)
          .setIndex(_kPageDashboard);
      setState(() => _displayedPage = _kPageDashboard);
      _loadTabFlags();
      NotificationService.init(_apiService).ignore();
      _maybeShowAppDownloadSheet();
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

    if (newShowLegacy == _showLegacyTests && newShowBcd == _showBcdTests) {
      return;
    }

    final provider = Provider.of<MainScreenProvider>(context, listen: false);
    final currentPage = provider.currentIndex;

    setState(() {
      _showLegacyTests = newShowLegacy;
      _showBcdTests = newShowBcd;
    });

    final visiblePages = <int>{
      _kPageDashboard,
      if (_showLegacyTests) ...[_kPageHome, _kPageTests],
      if (_showBcdTests) _kPageDriveTest,
      _kPageSmartLearning,
      _kPageProfile,
    };
    if (!visiblePages.contains(currentPage)) {
      provider.setIndex(_kPageDashboard);
      setState(() => _displayedPage = _kPageDashboard);
    }
  }

  Future<void> _loadTabFlags() async {
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

    _apiService.fetchCurrentUser().then((fresh) {
      if (fresh is Map<String, dynamic>) {
        _applyFlagsFromMap(fresh);
      }
    }).ignore();
  }

  void _maybeShowAppDownloadSheet() {
    if (!kIsWeb) return;
    final platform = detectWebPlatform();
    if (platform == WebPlatform.none) return;
    showAppDownloadSheet(context, platform: platform).ignore();
  }

  void _handleScroll(ScrollNotification n) {
    if (n is ScrollUpdateNotification) {
      final delta = n.scrollDelta ?? 0;
      if (delta > 3 && !_isNavCompact) {
        setState(() => _isNavCompact = true);
      } else if (delta < -3 && _isNavCompact) {
        setState(() => _isNavCompact = false);
      }
    }
    if (n is ScrollEndNotification && n.metrics.pixels <= 40 && _isNavCompact) {
      setState(() => _isNavCompact = false);
    }
  }

  void _handleNavigationChange(MainScreenProvider provider, int pageIndex) {
    if (_profileVisible) {
      _profileAnimCtrl.stop();
      setState(() => _profileVisible = false);
    }
    final didChange = provider.setIndex(pageIndex);
    setState(() {
      _displayedPage = pageIndex;
      _isNavCompact = false;
    });
    if (didChange) {
      playNavigationFeedback();
    }
  }

  void _onProfileChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _profileAnimCtrl.dispose();
    _profile.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _openProfile() {
    setState(() => _profileVisible = true);
    _profileAnimCtrl.forward(from: 0.0);
    playNavigationFeedback();
  }

  Future<void> _closeProfile() async {
    await _profileAnimCtrl.reverse();
    if (mounted) setState(() => _profileVisible = false);
    playNavigationFeedback();
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final provider = Provider.of<MainScreenProvider>(context);
    final entries = _navEntries(t);
    final displayedPage = _displayedPage.clamp(0, _kAllScreens.length - 1);

    final navIndex =
        entries.indexWhere((e) => e.pageIndex == provider.currentIndex);
    final selectedNavIndex = navIndex >= 0 ? navIndex : 0;

    final mq = MediaQuery.of(context);

    return Scaffold(
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (n) {
              _handleScroll(n);
              return false;
            },
            child: _LazyIndexedStack(
              index: displayedPage,
              children: _kAllScreens,
            ),
          ),
          if (_profileVisible)
            SlideTransition(
              position: _profileSlide,
              child: const Material(child: ProfileScreen()),
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
              isCompact: _isNavCompact,
            ),
          ),
          if (_profileVisible)
            Positioned(
              top: mq.padding.top,
              left: 8,
              child: AppBackButton(onPressed: _closeProfile),
            )
          else
            Positioned(
              top: mq.padding.top + 8,
              left: 16,
              child: _ProfileAvatarButton(
                profile: _profile,
                onTap: _openProfile,
              ),
            ),
          if (!_profileVisible)
            Positioned(
              top: mq.padding.top + 8,
              right: 16,
              child: const _NotificationButton(),
            ),
        ],
      ),
    );
  }
}

// ─── Notification button ───────────────────────────────────────────────────────

class _NotificationButton extends StatelessWidget {
  const _NotificationButton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Consumer<NotificationProvider>(
      builder: (_, notifProvider, __) => GestureDetector(
        onTap: () => Navigator.of(context).push(
          AppPageRoute(builder: (_) => const NotificationsScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: GlassBox(
            borderRadius: BorderRadius.circular(24),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: cs.onSurface.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(Icons.notifications_none_rounded,
                    size: 22, color: cs.onSurface.withValues(alpha: 0.75)),
                if (notifProvider.unreadCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: cs.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
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

// ─── Profile avatar button ─────────────────────────────────────────────────────

class _ProfileAvatarButton extends StatelessWidget {
  final ProfileProvider profile;
  final VoidCallback onTap;

  const _ProfileAvatarButton({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final initial = (profile.username?.isNotEmpty == true)
        ? profile.username![0].toUpperCase()
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: theme.cardColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: cs.onSurface.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: cs.onSurface.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: initial != null
                ? Text(
                    initial,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withValues(alpha: 0.75),
                    ),
                  )
                : Icon(
                    LucideIcons.user,
                    size: 22,
                    color: cs.onSurface.withValues(alpha: 0.75),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Floating nav area ─────────────────────────────────────────────────────────

class _FloatingNavArea extends StatelessWidget {
  final int currentIndex;
  final List<_NavEntry> items;
  final ValueChanged<int> onTap;
  final double bottomInset;
  final bool isCompact;

  const _FloatingNavArea({
    required this.currentIndex,
    required this.items,
    required this.onTap,
    required this.bottomInset,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset + 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _FloatingNavPill(
            currentIndex: currentIndex,
            items: items,
            onTap: onTap,
            isCompact: isCompact,
          ),
        ],
      ),
    );
  }
}

double _lerpDouble(double a, double b, double t) => a + (b - a) * t;

// ─── Pill nav bar – Liquid Glass ───────────────────────────────────────────────

class _FloatingNavPill extends StatefulWidget {
  final int currentIndex;
  final List<_NavEntry> items;
  final ValueChanged<int> onTap;
  final bool isCompact;

  static const double _itemWFull = 64.0;
  static const double _itemHFull = 56.0;
  static const double _itemWCompact = 52.0;
  static const double _itemHCompact = 44.0;
  static const double _pad = 6.0;

  const _FloatingNavPill({
    required this.currentIndex,
    required this.items,
    required this.onTap,
    required this.isCompact,
  });

  @override
  State<_FloatingNavPill> createState() => _FloatingNavPillState();
}

class _FloatingNavPillState extends State<_FloatingNavPill>
    with SingleTickerProviderStateMixin {
  final _pillKey = GlobalKey();
  int? _dragNavIndex;
  bool _isDragging = false;
  Offset _stretchPixels = Offset.zero;

  late final AnimationController _springController;
  late Animation<Offset> _springAnim;

  int get _activeNavIndex => _isDragging
      ? (_dragNavIndex ?? widget.currentIndex)
      : widget.currentIndex;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _springAnim = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(
      CurvedAnimation(parent: _springController, curve: Curves.easeOutBack),
    );
    _springController.addListener(() {
      if (mounted) setState(() => _stretchPixels = _springAnim.value);
    });
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  int _navIndexAt(Offset globalPos) {
    final box = _pillKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return widget.currentIndex;
    final local = box.globalToLocal(globalPos);
    final adjusted = local.dx - _FloatingNavPill._pad;
    final itemW = widget.isCompact
        ? _FloatingNavPill._itemWCompact
        : _FloatingNavPill._itemWFull;
    return (adjusted / itemW).floor().clamp(0, widget.items.length - 1);
  }

  double _edgeOverscroll(Offset globalPos) {
    final box = _pillKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return 0;
    final local = box.globalToLocal(globalPos);
    final itemW = widget.isCompact
        ? _FloatingNavPill._itemWCompact
        : _FloatingNavPill._itemWFull;
    final pillW = widget.items.length * itemW + _FloatingNavPill._pad * 2;
    if (local.dx < _FloatingNavPill._pad) {
      return (local.dx - _FloatingNavPill._pad).clamp(-36.0, 0.0);
    }
    if (local.dx > pillW - _FloatingNavPill._pad) {
      return (local.dx - (pillW - _FloatingNavPill._pad)).clamp(0.0, 36.0);
    }
    return 0;
  }

  void _releaseSpring(double dx) {
    if (dx == 0) return;
    _springAnim = Tween<Offset>(
      begin: Offset(dx * 0.45, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _springController, curve: Curves.easeOutBack),
    );
    _springController.forward(from: 0);
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
    final overscroll = _edgeOverscroll(d.globalPosition);
    if (idx != _dragNavIndex) {
      setState(() => _dragNavIndex = idx);
      widget.onTap(widget.items[idx].pageIndex);
    }
    setState(() => _stretchPixels = Offset(overscroll * 0.4, 0));
  }

  void _onDragEnd(DragEndDetails _) {
    final lastStretch = _stretchPixels.dx;
    setState(() {
      _isDragging = false;
      _dragNavIndex = null;
      _stretchPixels = Offset.zero;
    });
    _releaseSpring(lastStretch);
  }

  @override
  Widget build(BuildContext context) {
    final activeIdx = _activeNavIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Single TweenAnimationBuilder drives ALL dimensions in sync —
    // no overflow and no visual lag between pill size and icon size.
    return GestureDetector(
      onTapUp: _onTapUp,
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      behavior: HitTestBehavior.opaque,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: widget.isCompact ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
        builder: (context, t, _) {
          final itemW = _lerpDouble(
              _FloatingNavPill._itemWFull, _FloatingNavPill._itemWCompact, t);
          final itemH = _lerpDouble(
              _FloatingNavPill._itemHFull, _FloatingNavPill._itemHCompact, t);
          final iconSize = _lerpDouble(26.0, 22.0, t);
          final pillWidth =
              widget.items.length * itemW + _FloatingNavPill._pad * 2;
          final innerH = itemH - _FloatingNavPill._pad * 2;

          return AnimatedScale(
            scale: _isDragging ? 1.07 : 1.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: RawLiquidStretch(
              stretchPixels: _stretchPixels,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.13),
                      blurRadius: 30,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: LiquidGlass.withOwnLayer(
                  key: _pillKey,
                  shape: const LiquidRoundedSuperellipse(borderRadius: 50),
                  settings: LiquidGlassSettings(
                    thickness: 20,
                    blur: 24,
                    glassColor: isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.white.withValues(alpha: 0.50),
                    lightIntensity: 0.55,
                    saturation: 1.1,
                  ),
                  glassContainsChild: true,
                  child: SizedBox(
                    width: pillWidth,
                    height: itemH,
                    child: Padding(
                      padding: const EdgeInsets.all(_FloatingNavPill._pad),
                      child: Stack(
                        children: [
                          // Indicator — dedicated tween for left so it doesn't
                          // fight the outer compact/expand tween.
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                              begin: activeIdx * itemW,
                              end: activeIdx * itemW,
                            ),
                            duration:
                                Duration(milliseconds: _isDragging ? 60 : 280),
                            curve: Curves.easeOutCubic,
                            builder: (context, left, _) => Positioned(
                              left: left,
                              top: 0,
                              width: itemW,
                              height: innerH,
                              child: AnimatedScale(
                                scale: _isDragging ? 0.93 : 1.0,
                                duration: const Duration(milliseconds: 150),
                                curve: Curves.easeOutBack,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.18)
                                        : Colors.white.withValues(alpha: 0.45),
                                    borderRadius: BorderRadius.circular(40),
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.55),
                                      width: 0.8,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: widget.items.asMap().entries.map((e) {
                              final isActive = activeIdx == e.key;
                              final distance = (e.key - activeIdx).abs();
                              final dragScale = _isDragging
                                  ? (distance == 0
                                      ? 1.45
                                      : (distance == 1 ? 1.15 : 1.0))
                                  : 1.0;
                              return SizedBox(
                                width: itemW,
                                height: innerH,
                                child: Center(
                                  child: AnimatedScale(
                                    scale: dragScale,
                                    duration: const Duration(milliseconds: 120),
                                    curve: Curves.easeOut,
                                    child: Icon(
                                      e.value.icon,
                                      size: iconSize,
                                      color: isActive
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.45),
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
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Lazy IndexedStack ─────────────────────────────────────────────────────────

class _LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const _LazyIndexedStack({required this.index, required this.children});

  @override
  State<_LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<_LazyIndexedStack> {
  late final List<bool> _built;

  @override
  void initState() {
    super.initState();
    _built = List.generate(
      widget.children.length,
      (i) => i == widget.index,
    );
  }

  @override
  void didUpdateWidget(_LazyIndexedStack old) {
    super.didUpdateWidget(old);
    if (!_built[widget.index]) {
      setState(() => _built[widget.index] = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      children: [
        for (int i = 0; i < widget.children.length; i++)
          _built[i] ? widget.children[i] : const SizedBox.shrink(),
      ],
    );
  }
}

// ─── Provider ──────────────────────────────────────────────────────────────────

class MainScreenProvider extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  bool setIndex(int index) {
    if (_currentIndex == index) return false;
    _currentIndex = index;
    notifyListeners();
    return true;
  }
}
