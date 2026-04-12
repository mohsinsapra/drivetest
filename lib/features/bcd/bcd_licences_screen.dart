import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';

import 'bcd_category_hub_screen.dart';
import 'bcd_sub_category_screen.dart';

class BCDLicencesScreen extends StatefulWidget {
  const BCDLicencesScreen({super.key});

  @override
  State<BCDLicencesScreen> createState() => _BCDLicencesScreenState();
}

class _BCDLicencesScreenState extends State<BCDLicencesScreen> {
  final _api = ApiService();
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
    _refreshTimer = Timer.periodic(_autoRefreshInterval, (_) => _silentRefresh());
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
      final categories = await _api.fetchBCDAllCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _animateList = false;
        });
      }
    } catch (e) {
      if (mounted) showAppSnackBar(Translations.of(context).bcd_failed_categories);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Refreshes data in the background without showing the shimmer loader.
  Future<void> _silentRefresh() async {
    try {
      final categories = await _api.fetchBCDAllCategories();
      if (mounted) setState(() => _categories = categories);
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
        ? AppPageRoute(builder: (_) => BCDSubCategoryScreen(parentCategory: cat))
        : AppPageRoute(builder: (_) => BCDCategoryHubScreen(category: cat));

    Navigator.push(context, route).then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(
            _savedScrollOffset.clamp(0, _scrollController.position.maxScrollExtent),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(Translations.of(context).bcd_categories)),
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
                        onPressed: () => _searchController.clear(),
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
                : RefreshIndicator(
                    onRefresh: _loadCategories,
                    child: _filtered.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(
                                height: 300,
                                child: Center(
                                  child: Text(
                                    _searchQuery.isNotEmpty
                                        ? Translations.of(context).bcd_no_match_search
                                        : Translations.of(context).bcd_no_categories,
                                    style: TextStyle(color: Colors.grey.shade500),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) => _StaggeredItem(
                              index: i,
                              animate: _animateList,
                              child: _CategoryCard(
                                category: _filtered[i],
                                onTap: () => _onCategoryTap(_filtered[i]),
                              ),
                            ),
                          ),
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
    final subscribed = category['is_subscribed'] == true;
    final product = category['subscription_product'] as Map<String, dynamic>?;
    final price = product?['price']?.toString();
    final currency = product?['currency']?.toString() ?? '';
    final durationDays = product?['duration_days'];

    final t = Translations.of(context);
    final String subtitle;
    if (subscribed) {
      subtitle = t.bcd_subscribed;
    } else if (price != null && price.isNotEmpty) {
      subtitle = '$price $currency · $durationDays days';
    } else {
      subtitle = t.bcd_tap_to_subscribe;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: subscribed
                ? const Color(0xFF059669).withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            subscribed ? LucideIcons.unlock : LucideIcons.lock,
            color:
                subscribed ? const Color(0xFF059669) : Colors.grey.shade500,
            size: 20,
          ),
        ),
        title: Text(category['name']?.toString() ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: subscribed
                ? const Color(0xFF059669)
                : Colors.grey.shade600,
            fontSize: 12,
            fontWeight:
                subscribed ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        trailing: const Icon(LucideIcons.chevronRight, size: 18),
        onTap: onTap,
      ),
    );
  }
}

/* ── Shared helpers ───────────────────────────────────────────────────────── */

class _Shimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade50,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 68,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _StaggeredItem extends StatefulWidget {
  final int index;
  final Widget child;
  final bool animate;
  const _StaggeredItem({required this.index, required this.child, this.animate = true});

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
    _slide = Tween<Offset>(
            begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    if (widget.animate) {
      Future.delayed(Duration(milliseconds: widget.index * 35),
          () { if (mounted) _ctrl.forward(); });
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
