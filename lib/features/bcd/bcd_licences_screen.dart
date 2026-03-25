import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
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

  List<dynamic> _categories = [];
  bool _loading = false;
  String _searchQuery = '';

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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _loading = true);
    try {
      // is_subscribed is computed server-side from BCDUserSubscription
      // (PAID, not expired, covers that category) — no client-side logic needed.
      final categories = await _api.fetchBCDAllCategories();
      if (mounted) setState(() => _categories = categories);
    } catch (e) {
      if (mounted) showAppSnackBar('Failed to load categories');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onCategoryTap(dynamic category) {
    final hasChildren = category['has_children'] == true;
    final cat = Map<String, dynamic>.from(category);

    final route = hasChildren
        ? MaterialPageRoute(builder: (_) => BCDSubCategoryScreen(parentCategory: cat))
        : MaterialPageRoute(builder: (_) => BCDCategoryHubScreen(category: cat));

    Navigator.push(context, route).then((_) => _loadCategories());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search categories…',
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
                fillColor: Colors.grey.shade100,
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
                : _filtered.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isNotEmpty
                              ? 'No categories match "$_searchQuery"'
                              : 'No categories available.',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _StaggeredItem(
                          index: i,
                          child: _CategoryCard(
                            category: _filtered[i],
                            onTap: () => _onCategoryTap(_filtered[i]),
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

    final String subtitle;
    if (subscribed) {
      subtitle = 'Subscribed';
    } else if (price != null && price.isNotEmpty) {
      subtitle = '$price $currency · $durationDays days';
    } else {
      subtitle = 'Tap to subscribe';
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
                : Colors.grey.shade100,
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
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
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
  const _StaggeredItem({required this.index, required this.child});

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
    Future.delayed(Duration(milliseconds: widget.index * 35),
        () { if (mounted) _ctrl.forward(); });
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
