import 'package:taxi_exam_app/core/api/dio_client.dart';
import 'package:taxi_exam_app/core/services/payment_coordinator.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/services/bcd_cache.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';

import 'package:taxi_exam_app/features/profile/stats_screen.dart';

import 'bcd_document_viewer_screen.dart';
import 'bcd_test_screen.dart';
import 'bcd_text_utils.dart';
import 'bcd_traffic_signs_screen.dart';
import '../tests/saved_questions_preview_screen.dart';

/// Hub screen shown after tapping a category.
class BCDCategoryHubScreen extends StatefulWidget {
  final Map<String, dynamic> category;

  const BCDCategoryHubScreen({super.key, required this.category});

  @override
  State<BCDCategoryHubScreen> createState() => _BCDCategoryHubScreenState();
}

class _BCDCategoryHubScreenState extends State<BCDCategoryHubScreen> {
  final _api = ApiService();
  List<dynamic> _products = [];
  late final ValueNotifier<bool> _subscribedNotifier;

  bool get _subscribed => widget.category['is_subscribed'] == true;
  int get _categoryBcdId => widget.category['bcd_id'] as int;
  String get _categoryName => widget.category['name']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _subscribedNotifier = ValueNotifier(_subscribed);
  }

  @override
  void dispose() {
    _subscribedNotifier.dispose();
    super.dispose();
  }

  /* ── Paywall ──────────────────────────────────────────────────────────────── */

  Future<void> _showPaywall() async {
    if (_subscribed) return;
    final categoryProduct = widget.category['subscription_product'];
    if (categoryProduct != null) {
      _products = [categoryProduct];
    } else if (_products.isEmpty) {
      try {
        _products = await _api.fetchBCDSubscriptionProducts();
      } catch (_) {}
    }
    if (!mounted) return;

    final result = await PaymentCoordinator.show(
      context,
      products: _products,
      title: _categoryName,
      createStripeIntent: (p) => _api.createBCDPaymentIntent(p['id'] as int),
      onStripePaymentConfirmed: (id) => _api.confirmBCDPayment(id),
      onIAPPurchaseConfirmed: (p, transactionId) => _api.confirmBCDIAPPurchase(
        p['id'] as int,
        transactionId: transactionId,
      ),
    );

    if (result == null || !mounted) return;
    await DioClient().clearCache();
    BcdCache.instance.invalidate();
    await BcdCache.instance.ensureLoaded();
    if (!mounted) return;
    setState(() => widget.category['is_subscribed'] = true);
    _subscribedNotifier.value = true;
  }

  /* ── Practice (direct launch) ────────────────────────────────────────────── */

  bool _practiceLoading = false;

  Future<void> _startPractice() async {
    if (_practiceLoading) return;
    setState(() => _practiceLoading = true);
    try {
      await BcdCache.instance.ensureLoaded();
      final tests = BcdCache.instance.testsOf(_categoryBcdId);
      final free = tests.where((t) => t['is_free'] == true).toList();

      // If no free test, but user is subscribed, use the first test available
      final testToStart = free.isNotEmpty
          ? free.first
          : (_subscribed && tests.isNotEmpty ? tests.first : null);

      if (!mounted) return;

      if (testToStart == null) {
        showAppSnackBar(Translations.of(context).bcd_no_free_practice);
        return;
      }

      final bcdId = testToStart['bcd_id'] as int?;
      if (bcdId == null) return;
      Navigator.push(
        context,
        AppPageRoute(
          builder: (_) => BCDTestScreen(
            testId: bcdId,
            testName: testToStart['name']?.toString() ?? 'Practice',
            passScore: testToStart['pass_score'] as int? ?? 0,
            timeLimit: testToStart['time_limit'] as int? ?? 0,
            parentCategoryName: _categoryName,
            parentCategoryBcdId: _categoryBcdId,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        showAppSnackBar(Translations.of(context).bcd_failed_practice,
            type: SnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _practiceLoading = false);
    }
  }

  Future<void> _openSavedQuestions() async {
    try {
      final savedQuestions = await _api.fetchSavedQuestionsResolved(
        scopeType: 'bcd',
        bcdCategoryId: _categoryBcdId,
      );
      if (savedQuestions.isEmpty) {
        if (mounted) {
          showAppSnackBar(Translations.of(context).bcd_no_saved_questions);
        }
        return;
      }

      if (!mounted) return;
      if (savedQuestions.isEmpty) {
        showAppSnackBar(Translations.of(context).bcd_no_saved_questions_found);
        return;
      }

      Navigator.push(
        context,
        AppPageRoute(
          builder: (_) => SavedQuestionsPreviewScreen(
            questions: savedQuestions,
            licenceId: '',
            categoryId: '',
            licenceName: _categoryName,
            categoryName: _categoryName,
            bcdCategoryId: _categoryBcdId,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        showAppSnackBar(Translations.of(context).bcd_failed_saved,
            type: SnackBarType.error);
      }
    }
  }

  /* ── Navigation ───────────────────────────────────────────────────────────── */

  // Tiles that are always free (no subscription needed)
  static const _freeTiles = {
    'practice',
    'traffic_signs',
    'documents',
    'checklists',
    'tests',
    'saved_questions',
  };

  void _onTileTap(String tile) {
    // Only statistics is gated — everything else navigates freely
    if (!_subscribed && !_freeTiles.contains(tile)) {
      _showPaywall();
      return;
    }

    switch (tile) {
      case 'practice':
        _startPractice();
        break;
      case 'tests':
        // Always navigate — tests list shows banner + locked items if not subscribed.
        // Pass the shared notifier so it updates live when payment completes.
        Navigator.push(
            context,
            AppPageRoute(
              builder: (_) => _BCDTestsListScreen(
                categoryBcdId: _categoryBcdId,
                categoryName: _categoryName,
                practiceOnly: false,
                subscribedNotifier: _subscribedNotifier,
                onBuySubscription: _showPaywall,
                parentCategoryBcdId: _categoryBcdId,
              ),
            ));
        break;
      case 'documents':
        Navigator.push(
            context,
            AppPageRoute(
              builder: (_) => _BCDDocumentsScreen(
                categoryBcdId: _categoryBcdId,
                categoryName: _categoryName,
              ),
            ));
        break;
      case 'traffic_signs':
        Navigator.push(
            context,
            AppPageRoute(
              builder: (_) => const BCDTrafficSignsScreen(),
            ));
        break;
      case 'checklists':
        Navigator.push(
            context,
            AppPageRoute(
              builder: (_) => _BCDChecklistsScreen(
                categoryBcdId: _categoryBcdId,
                categoryName: _categoryName,
              ),
            ));
        break;
      case 'statistics':
        Navigator.push(
            context,
            AppPageRoute(
              builder: (_) => StatsScreen(
                subtitle: _categoryName,
                licenceNameFilter: _categoryName,
              ),
            ));
        break;
      case 'saved_questions':
        _openSavedQuestions();
        break;
    }
  }

  /* ── Build ────────────────────────────────────────────────────────────────── */

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_categoryName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_subscribed) ...[
              _SubscriptionBanner(onBuy: _showPaywall),
              const SizedBox(height: 20),
            ],
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _HubTile(
                  icon: LucideIcons.helpCircle,
                  label: t.bcd_hub_practice,
                  locked: false,
                  loading: _practiceLoading,
                  tileColor: const Color(0xFF10B981),
                  onTap: () => _onTileTap('practice'),
                ),
                _HubTile(
                  icon: LucideIcons.fileText,
                  label: t.bcd_hub_tests,
                  locked: !_subscribed,
                  tileColor: const Color(0xFF4F46E5),
                  onTap: () => _onTileTap('tests'),
                ),
                _HubTile(
                  icon: LucideIcons.bookOpen,
                  label: t.bcd_hub_theory_docs,
                  locked: false,
                  tileColor: const Color(0xFFF59E0B),
                  onTap: () => _onTileTap('documents'),
                ),
                _HubTile(
                  icon: LucideIcons.alertTriangle,
                  label: t.bcd_hub_traffic_signs,
                  locked: false,
                  tileColor: const Color(0xFFEF4444),
                  onTap: () => _onTileTap('traffic_signs'),
                ),
                _HubTile(
                  icon: LucideIcons.clipboardCheck,
                  label: t.bcd_hub_checklist,
                  locked: false,
                  tileColor: const Color(0xFF8B5CF6),
                  onTap: () => _onTileTap('checklists'),
                ),
                _HubTile(
                  icon: LucideIcons.barChart2,
                  label: t.bcd_hub_statistics,
                  locked: !_subscribed,
                  tileColor: const Color(0xFF0EA5E9),
                  onTap: () => _onTileTap('statistics'),
                ),
                _HubTile(
                  icon: LucideIcons.bookmark,
                  label: t.bcd_hub_saved_questions,
                  locked: false,
                  tileColor: const Color(0xFFEC4899),
                  onTap: () => _onTileTap('saved_questions'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/* ── Subscription banner ──────────────────────────────────────────────────── */

class _SubscriptionBanner extends StatelessWidget {
  final VoidCallback onBuy;
  const _SubscriptionBanner({required this.onBuy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border:
            Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.alertCircle,
                  color: Color(0xFFD97706), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Translations.of(context).bcd_no_subscription,
                      style: const TextStyle(
                        color: Color(0xFFD97706),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Translations.of(context).bcd_free_content_desc,
                      style: TextStyle(
                        color: const Color(0xFFD97706).withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onBuy,
            icon: const Icon(LucideIcons.shoppingCart, size: 16),
            label: Text(Translations.of(context).bcd_buy_subscription),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A5F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

/* ── Hub tile ─────────────────────────────────────────────────────────────── */

class _HubTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool locked;
  final bool loading;
  final VoidCallback onTap;
  final Color tileColor;
  const _HubTile({
    required this.icon,
    required this.label,
    required this.locked,
    required this.onTap,
    required this.tileColor,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = locked ? Colors.grey.shade400 : tileColor;
    final bgColor = locked
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06)
        : tileColor.withValues(alpha: 0.12);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: locked
          ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04)
          : (isDark
              ? Theme.of(context).cardColor
              : tileColor.withValues(alpha: 0.07)),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: loading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: color),
                          )
                        : Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: locked
                          ? Colors.grey.shade500
                          : Theme.of(context).colorScheme.onSurface,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            if (locked)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(LucideIcons.lock,
                    size: 14, color: Colors.grey.shade400),
              ),
          ],
        ),
      ),
    );
  }
}

/* ── Tests list screen ────────────────────────────────────────────────────── */

class _BCDTestsListScreen extends StatefulWidget {
  final int categoryBcdId;
  final String categoryName;
  final bool practiceOnly;
  final ValueNotifier<bool> subscribedNotifier;
  final VoidCallback onBuySubscription;
  final int? parentCategoryBcdId;

  const _BCDTestsListScreen({
    required this.categoryBcdId,
    required this.categoryName,
    required this.practiceOnly,
    required this.subscribedNotifier,
    required this.onBuySubscription,
    this.parentCategoryBcdId,
  });

  @override
  State<_BCDTestsListScreen> createState() => _BCDTestsListScreenState();
}

class _BCDTestsListScreenState extends State<_BCDTestsListScreen> {
  List<dynamic> _tests = [];
  bool _loading = true;

  bool get _subscribed => widget.subscribedNotifier.value;

  @override
  void initState() {
    super.initState();
    widget.subscribedNotifier.addListener(_onSubscriptionChanged);
    _load();
  }

  void _onSubscriptionChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.subscribedNotifier.removeListener(_onSubscriptionChanged);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await BcdCache.instance.ensureLoaded();
      final data = BcdCache.instance.testsOf(widget.categoryBcdId);
      if (mounted) {
        setState(() {
          _tests = widget.practiceOnly
              ? data.where((t) => t['is_free'] == true).toList()
              : data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(Translations.of(context).bcd_failed_tests,
            type: SnackBarType.error);
        setState(() => _loading = false);
      }
    }
  }

  void _onTap(dynamic test) {
    final isFree = test['is_free'] == true;
    // Block non-free tests if not subscribed
    if (!_subscribed && !isFree) {
      widget.onBuySubscription();
      return;
    }
    final bcdId = test['bcd_id'] as int?;
    if (bcdId == null) return;
    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => BCDTestScreen(
          testId: bcdId,
          testName: test['name']?.toString() ?? 'Test',
          passScore: test['pass_score'] as int? ?? 0,
          timeLimit: test['time_limit'] as int? ?? 0,
          parentCategoryName: widget.categoryName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.practiceOnly
        ? 'Practice – ${widget.categoryName}'
        : widget.categoryName;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _loading
          ? _buildShimmer()
          : _tests.isEmpty
              ? Center(
                  child: Text(
                    widget.practiceOnly
                        ? Translations.of(context).bcd_no_free_practice_tests
                        : Translations.of(context).bcd_no_tests,
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                )
              : Column(
                  children: [
                    if (!_subscribed && !widget.practiceOnly)
                      _TestsSubscriptionBanner(onBuy: widget.onBuySubscription),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _tests.length,
                        itemBuilder: (_, i) => _TestCard(
                          test: _tests[i],
                          forceUnsubscribed: !_subscribed,
                          onTap: () => _onTap(_tests[i]),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildShimmer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade50,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 72,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _TestsSubscriptionBanner extends StatelessWidget {
  final VoidCallback onBuy;
  const _TestsSubscriptionBanner({required this.onBuy});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border:
            Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.alertCircle,
              color: Color(0xFFD97706), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Translations.of(context).bcd_not_subscribed,
                  style: const TextStyle(
                    color: Color(0xFFD97706),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Translations.of(context).bcd_only_free_tests,
                  style: TextStyle(
                    color: const Color(0xFFD97706).withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onBuy,
                  child: Text(
                    Translations.of(context).bcd_buy_subscription_arrow,
                    style: TextStyle(
                      color: Color(0xFF1E3A5F),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
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

/* ── Documents screen ─────────────────────────────────────────────────────── */

class _BCDDocumentsScreen extends StatefulWidget {
  final int categoryBcdId;
  final String categoryName;
  const _BCDDocumentsScreen(
      {required this.categoryBcdId, required this.categoryName});

  @override
  State<_BCDDocumentsScreen> createState() => _BCDDocumentsScreenState();
}

class _BCDDocumentsScreenState extends State<_BCDDocumentsScreen> {
  final _api = ApiService();
  List<dynamic> _docs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _api.fetchBCDDocuments(widget.categoryBcdId).then((data) {
      if (mounted) {
        setState(() {
          _docs = data;
          _loading = false;
        });
      }
    }).catchError((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Theory Documents – ${widget.categoryName}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _docs.isEmpty
              ? Center(
                  child: Text(Translations.of(context).bcd_no_documents,
                      style: TextStyle(color: Colors.grey.shade500)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _docs.length,
                  itemBuilder: (_, i) {
                    final doc = _docs[i];
                    final fileName = doc['file_name']?.toString() ?? '';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        onTap: fileName.isEmpty
                            ? null
                            : () => Navigator.push(
                                  context,
                                  AppPageRoute(
                                    builder: (_) => BCDDocumentViewerScreen(
                                      title: cleanBcdText(
                                          doc['title']?.toString() ??
                                              'Document'),
                                      url: _api.bcdMediaUrl(fileName),
                                    ),
                                  ),
                                ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF3B5F8A).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(LucideIcons.fileText,
                              color: Color(0xFF3B5F8A), size: 18),
                        ),
                        title: Text(
                          cleanBcdText(doc['title']?.toString() ?? ''),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing:
                            const Icon(LucideIcons.externalLink, size: 18),
                      ),
                    );
                  },
                ),
    );
  }
}

/* ── Checklists screen ────────────────────────────────────────────────────── */

class _BCDChecklistsScreen extends StatefulWidget {
  final int categoryBcdId;
  final String categoryName;
  const _BCDChecklistsScreen(
      {required this.categoryBcdId, required this.categoryName});

  @override
  State<_BCDChecklistsScreen> createState() => _BCDChecklistsScreenState();
}

class _BCDChecklistsScreenState extends State<_BCDChecklistsScreen> {
  final _api = ApiService();
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _api.fetchBCDChecklists(widget.categoryBcdId).then((data) {
      if (mounted) {
        setState(() {
          _items = data;
          _loading = false;
        });
      }
    }).catchError((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Checklist – ${widget.categoryName}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Text(Translations.of(context).bcd_no_checklists,
                      style: TextStyle(color: Colors.grey.shade500)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  itemBuilder: (_, i) {
                    final item = _items[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      child: ExpansionTile(
                        shape: const RoundedRectangleBorder(
                          side: BorderSide.none,
                        ),
                        collapsedShape: const RoundedRectangleBorder(
                          side: BorderSide.none,
                        ),
                        expandedAlignment: Alignment.centerLeft,
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        childrenPadding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        leading: const Icon(LucideIcons.clipboardCheck,
                            color: Color(0xFF3B5F8A)),
                        title: Text(
                          cleanBcdText(item['title']?.toString() ?? ''),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        children: [
                          Text(
                            cleanBcdMultilineText(
                                item['content']?.toString() ?? ''),
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

/* ── Test card ────────────────────────────────────────────────────────────── */

class _TestCard extends StatelessWidget {
  final dynamic test;
  final VoidCallback onTap;
  final bool forceUnsubscribed;
  const _TestCard(
      {required this.test,
      required this.onTap,
      this.forceUnsubscribed = false});

  @override
  Widget build(BuildContext context) {
    final isFree = test['is_free'] == true;
    final subscribed = !forceUnsubscribed || isFree;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isFree
                      ? const Color(0xFF059669).withValues(alpha: 0.1)
                      : subscribed
                          ? const Color(0xFF4F46E5).withValues(alpha: 0.1)
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isFree
                      ? LucideIcons.gift
                      : subscribed
                          ? LucideIcons.clipboardList
                          : LucideIcons.lock,
                  size: 20,
                  color: isFree
                      ? const Color(0xFF059669)
                      : subscribed
                          ? const Color(0xFF4F46E5)
                          : Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cleanBcdText(test['name']?.toString() ?? ''),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      _Chip(
                          label:
                              '${test['question_count'] ?? 0} ${Translations.of(context).bcd_questions_label}'),
                      const SizedBox(width: 6),
                      _Chip(
                          label:
                              '${Translations.of(context).bcd_pass_label} ${test['pass_score'] ?? 0}%'),
                      if (isFree) ...[
                        const SizedBox(width: 6),
                        _Chip(
                            label: Translations.of(context).bcd_free_label,
                            color: const Color(0xFF059669)),
                      ],
                    ]),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight,
                  size: 18, color: subscribed ? null : Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color? color;
  const _Chip({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey.shade600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style:
              TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w500)),
    );
  }
}
