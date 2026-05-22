import 'package:taxi_exam_app/core/widgets/app_back_button.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/core/widgets/adaptive_refresh_indicator.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/api/dio_client.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/services/bcd_cache.dart';
import 'package:taxi_exam_app/core/utils/category_icon_mapper.dart';
import 'package:taxi_exam_app/core/utils/category_sort_utils.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';

import 'bcd_category_hub_screen.dart';
import 'bcd_sub_category_screen.dart';

class BCDLicencesScreen extends StatefulWidget {
  const BCDLicencesScreen({super.key});

  @override
  State<BCDLicencesScreen> createState() => _BCDLicencesScreenState();
}

class _BCDLicencesScreenState extends State<BCDLicencesScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  List<dynamic> _categories = [];
  bool _loading = false;
  bool _animateList = true;
  String _searchQuery = '';
  double _savedScrollOffset = 0;
  Timer? _refreshTimer;

  static const _autoRefreshInterval = Duration(hours: 1);

  List<dynamic> get _filtered {
    if (_searchQuery.isEmpty) return _categories;
    final q = _searchQuery.toLowerCase();
    return _categories
        .where((c) => (c['name']?.toString() ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchController.addListener(
        () => setState(() => _searchQuery = _searchController.text));
    _refreshTimer =
        Timer.periodic(_autoRefreshInterval, (_) => _silentRefresh());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _loading = true);
    try {
      await BcdCache.instance.ensureLoaded();
      if (mounted) {
        setState(() {
          _categories =
              sortSubscribedCategoriesFirst(BcdCache.instance.categories);
          _animateList = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(Translations.of(context).bcd_failed_categories,
            type: SnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Pull-to-refresh: bust all caches and re-fetch from backend so that
  /// subscription status changes (new purchase or expiry) are reflected immediately.
  Future<void> _forceRefresh() async {
    try {
      BcdCache.instance.invalidate();
      await DioClient().clearCache();
      await ApiService().fetchCurrentUser(forceRefresh: true);
      if (mounted) {
        setState(() {
          _categories =
              sortSubscribedCategoriesFirst(BcdCache.instance.categories);
        });
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(Translations.of(context).bcd_failed_categories,
            type: SnackBarType.error);
      }
    }
  }

  // Refreshes data in the background without showing the shimmer loader.
  Future<void> _silentRefresh() async {
    try {
      BcdCache.instance.invalidate();
      await BcdCache.instance.ensureLoaded();
      if (mounted) {
        setState(() {
          _categories =
              sortSubscribedCategoriesFirst(BcdCache.instance.categories);
        });
      }
    } catch (_) {
      // silent — don't bother the user if background refresh fails
    }
  }

  void _onCategoryTap(dynamic category) {
    _savedScrollOffset =
        _scrollController.hasClients ? _scrollController.offset : 0;

    final hasChildren = category['has_children'] == true;
    final cat = Map<String, dynamic>.from(category);

    final route = hasChildren
        ? AppPageRoute(
            builder: (_) => BCDSubCategoryScreen(parentCategory: cat))
        : AppPageRoute(builder: (_) => BCDCategoryHubScreen(category: cat));

    Navigator.push(context, route).then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(
            _savedScrollOffset.clamp(
                0, _scrollController.position.maxScrollExtent),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(Translations.of(context).bcd_categories), leading: const AppBackButton()),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: Translations.of(context).bcd_search_categories,
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: _searchController.clear,
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? _Shimmer()
                : AdaptiveRefreshIndicator(
                    onRefresh: _forceRefresh,
                    controller: _scrollController,
                    slivers: _filtered.isEmpty
                        ? [
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Text(
                                  _searchQuery.isNotEmpty
                                      ? Translations.of(context)
                                          .bcd_no_match_search
                                      : Translations.of(context)
                                          .bcd_no_categories,
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ),
                            ),
                          ]
                        : [
                            SliverPadding(
                              padding: const EdgeInsets.all(16),
                              sliver: SliverList.builder(
                                itemCount: _filtered.length,
                                itemBuilder: (_, i) {
                                  final cat = _filtered[i];
                                  return _StaggeredItem(
                                    index: i,
                                    animate: _animateList,
                                    child: _CategoryCard(
                                      category: cat,
                                      onTap: () => _onCategoryTap(cat),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                  ),
          ),
        ],
      ),
    );
  }
}

/* ── Category card ────────────────────────────────────────────────────────── */

class _CategoryCard extends StatelessWidget {
  final dynamic category;
  final VoidCallback onTap;
  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final subscribed = category['is_subscribed'] == true;
    final isFree = category['subscription_product'] == null;
    final testCount = (category['test_count'] as num?)?.toInt() ?? 0;
    final attemptCount = (category['attempt_count'] as num?)?.toInt() ?? 0;
    final product = category['subscription_product'] as Map<String, dynamic>?;
    final price = product?['price']?.toString();
    final currency = product?['currency']?.toString() ?? '';
    final durationDays = product?['duration_days'];
    final name = category['name']?.toString() ?? '';
    final t = Translations.of(context);

    // Semantic accent — green is universal success/unlock, primary is the app blue
    const Color successGreen = Color(0xFF059669);
    final Color accent;
    final String badgeLabel;
    if (subscribed) {
      accent = successGreen;
      badgeLabel = t.bcd_subscribed;
    } else if (isFree) {
      accent = cs.primary;
      badgeLabel = 'Free';
    } else {
      accent = cs.onSurfaceVariant;
      badgeLabel = (price != null && price.isNotEmpty)
          ? '$price $currency'
          : t.bcd_tap_to_subscribe;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            categoryIcon(name),
                            color: accent.withValues(
                                alpha: (subscribed || isFree) ? 1.0 : 0.45),
                            size: 21,
                          ),
                        ),
                        if (!subscribed && !isFree)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: cs.surface,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.lock_rounded,
                                size: 10,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              _AccessBadge(label: badgeLabel, color: accent),
                              if ((subscribed || isFree) && testCount > 0) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '$attemptCount / $testCount attempted',
                                  style: TextStyle(
                                      fontSize: 11, color: cs.onSurfaceVariant),
                                ),
                              ],
                              if (!isFree &&
                                  !subscribed &&
                                  durationDays != null) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '· $durationDays days',
                                  style: TextStyle(
                                      fontSize: 11, color: cs.outline),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(LucideIcons.chevronRight, size: 18, color: cs.outline),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccessBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _AccessBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/* ── Shared helpers ───────────────────────────────────────────────────────── */

class _Shimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: cs.surfaceContainerHighest,
      highlightColor: cs.surface,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 7,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 96,
          decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class _StaggeredItem extends StatefulWidget {
  final int index;
  final Widget child;
  final bool animate;
  const _StaggeredItem(
      {required this.index, required this.child, this.animate = true});

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    if (widget.animate) {
      Future.delayed(Duration(milliseconds: widget.index * 35), () {
        if (mounted) _ctrl.forward();
      });
    } else {
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}
