import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/api/dio_client.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';
import 'package:taxi_exam_app/core/providers/notification_provider.dart';
import 'package:taxi_exam_app/core/services/bcd_cache.dart';
import 'package:taxi_exam_app/core/services/payment_coordinator.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:taxi_exam_app/features/bcd/bcd_test_screen.dart';
import 'package:taxi_exam_app/features/bcd/bcd_category_hub_screen.dart';
import 'package:taxi_exam_app/features/bcd/bcd_licences_screen.dart';
import 'package:taxi_exam_app/features/bcd/bcd_traffic_signs_screen.dart';
import 'package:taxi_exam_app/features/notifications/notifications_screen.dart';
import 'package:taxi_exam_app/features/profile/providers/profile_provider.dart';
import 'package:taxi_exam_app/features/tests/test_screen.dart';
import 'package:taxi_exam_app/core/utils/category_icon_mapper.dart';
import '../helpers/dashboard_helpers.dart';
import '../models/dashboard_stats.dart';
import '../models/exam_node.dart';
import '../models/subscribed_exam.dart';
import '../providers/dashboard_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class ExamDashboardScreen extends StatefulWidget {
  const ExamDashboardScreen({super.key});

  @override
  State<ExamDashboardScreen> createState() => _ExamDashboardScreenState();
}

class _ExamDashboardScreenState extends State<ExamDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().init();
    });
  }

  Future<void> _handleSubscribe() async {
    List<dynamic> products = [];
    try {
      products = await ApiService().fetchBCDSubscriptionProducts();
    } catch (_) {}
    if (!mounted || products.isEmpty) return;

    final result = await PaymentCoordinator.show(
      context,
      products: products,
      createStripeIntent: (p) =>
          ApiService().createBCDPaymentIntent(p['id'] as int),
      onStripePaymentConfirmed: (id) => ApiService().confirmBCDPayment(id),
      onIAPPurchaseConfirmed: (p, transactionId) =>
          ApiService().confirmBCDIAPPurchase(
        (p['id'] as num).toInt(),
        transactionId: transactionId,
      ),
    );

    if (result == null || !mounted) return;
    await DioClient().clearCache();
    BcdCache.instance.invalidate();
    if (mounted) context.read<DashboardProvider>().syncNow();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (provider.syncing)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Consumer<NotificationProvider>(
              builder: (_, notifProvider, __) => Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded),
                    onPressed: () => Navigator.of(context).push(
                      AppPageRoute(builder: (_) => const NotificationsScreen()),
                    ),
                  ),
                  if (notifProvider.unreadCount > 0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
      body: switch (provider.status) {
        DashboardStatus.idle ||
        DashboardStatus.loading =>
          const Center(child: CircularProgressIndicator()),
        DashboardStatus.error => _ErrorView(
            errorKind: provider.errorKind,
            onRetry: () => context.read<DashboardProvider>().init(),
          ),
        DashboardStatus.loaded => RefreshIndicator(
            onRefresh: () => context.read<DashboardProvider>().syncNow(),
            child: _DashboardBody(
                provider: provider, onSubscribe: _handleSubscribe),
          ),
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.provider, required this.onSubscribe});
  final DashboardProvider provider;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    final stats = provider.selectedStats;
    final t = Translations.of(context);
    final theme = Theme.of(context);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // ── Hero ──────────────────────────────────────────────────────────────
        SliverToBoxAdapter(child: _HeroSection(stats: stats)),

        // ── My Exams carousel ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _ExamCarouselSection(
              provider: provider, onSubscribe: onSubscribe),
        ),

        // ── Performance overview ──────────────────────────────────────────────
        if (stats != null)
          SliverToBoxAdapter(
            child: _PerformanceOverviewSection(stats: stats),
          ),

        // ── Focus areas ───────────────────────────────────────────────────────
        if (stats != null) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
              child: Text(
                t.dash_focus_areas,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _FocusCategoriesSection(stats: stats),
          ),
        ],

        // ── Weekly streak ─────────────────────────────────────────────────────
        if (stats != null) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
              child: Text(
                t.dash_weekly_streak,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _WeeklyStreakSection(streak: stats.streak),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection({this.stats});
  final ExamDashboardStats? stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final t = Translations.of(context);
    final progress = stats?.overallProgressPercent ?? 0;

    final String subtitle;
    if (progress == 0) {
      subtitle = t.dash_hero_sub_start;
    } else if (progress < 50) {
      subtitle = t.dash_hero_sub_progress;
    } else if (progress < 100) {
      subtitle = t.dash_hero_sub_almost;
    } else {
      subtitle = t.dash_hero_sub_done;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.dash_my_progress,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Exam carousel
// ─────────────────────────────────────────────────────────────────────────────

class _ExamCarouselSection extends StatelessWidget {
  const _ExamCarouselSection(
      {required this.provider, required this.onSubscribe});
  final DashboardProvider provider;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    final exams = provider.exams;
    final t = Translations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            t.dash_my_exams,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        if (exams.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const _FreeBCDHubCard(),
                const SizedBox(height: 12),
                _FreeVagmarkesCard(
                  onTap: () => Navigator.push(
                    context,
                    AppPageRoute(builder: (_) => const BCDTrafficSignsScreen()),
                  ),
                ),
                if (!ProfileProvider().isGuest) ...[
                  const SizedBox(height: 12),
                  _SubscribeCTACard(onSubscribe: onSubscribe),
                ],
              ],
            ),
          ),
        ] else
          SizedBox(
            height: 190,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: exams.length,
              itemBuilder: (context, i) {
                final exam = exams[i];
                final isSelected = exam.id == provider.selectedExam?.id;
                final progress = provider.overviewProgress[exam.id] ?? 0.0;

                final bcdId = int.tryParse(exam.id);
                final endDate =
                    bcdId != null ? BcdCache.instance.endDateFor(bcdId) : null;

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.read<DashboardProvider>().selectExam(exam);
                    },
                    child: _ExamCard(
                      exam: exam,
                      progress: progress,
                      isActive: isSelected,
                      endDate: endDate,
                      onArrowTap: () => _handleExamArrowTap(
                        context,
                        exam,
                        provider,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Free BCD hub card — finds the free "Vägmärkestest" category by name and
// navigates directly to its hub screen.
// ─────────────────────────────────────────────────────────────────────────────

class _FreeBCDHubCard extends StatefulWidget {
  const _FreeBCDHubCard();

  @override
  State<_FreeBCDHubCard> createState() => _FreeBCDHubCardState();
}

class _FreeBCDHubCardState extends State<_FreeBCDHubCard> {
  Map<String, dynamic>? _category;

  @override
  void initState() {
    super.initState();
    _resolveCategory();
  }

  Future<void> _resolveCategory() async {
    await BcdCache.instance.ensureLoaded();
    if (!mounted) return;
    final match = _findFreeCategory();
    if (match != null) setState(() => _category = match);
  }

  /// Finds a free (no subscription required) category, preferring one whose
  /// name contains "Vägmärkestest". Falls back to the first free category, then
  /// the first category in the list.
  Map<String, dynamic>? _findFreeCategory() {
    final cats = BcdCache.instance.categories;
    if (cats.isEmpty) return null;

    final match = cats.firstWhereOrNull(
          (c) =>
              (c['name']?.toString() ?? '').toLowerCase().contains('vägmärk'),
        ) ??
        cats.firstWhereOrNull((c) => c['subscription_product'] == null) ??
        cats.first;
    return Map<String, dynamic>.from(match);
  }

  void _handleTap() {
    final cat = _category;
    if (cat == null) {
      Navigator.push(
        context,
        AppPageRoute(builder: (_) => const BCDLicencesScreen()),
      );
      return;
    }
    Navigator.push(
      context,
      AppPageRoute(builder: (_) => BCDCategoryHubScreen(category: cat)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Translations.of(context);

    final catName = _category?['name']?.toString();
    final displayTitle = catName ?? t.dash_free_hub_title;
    final accent =
        catName != null ? categoryColor(catName) : const Color(0xFF4F46E5);
    final icon =
        catName != null ? categoryIcon(catName) : Icons.menu_book_rounded;

    return InkWell(
      onTap: _handleTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayTitle,
                          style: GoogleFonts.lexend(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF059669).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          t.dash_free_hub_badge,
                          style: GoogleFonts.lexend(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF059669),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.dash_free_hub_subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        t.free_trial_banner_cta,
                        style: GoogleFonts.lexend(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded,
                          size: 14, color: cs.primary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Free Vägmärkestest card — shown when the user has no subscribed exams
// ─────────────────────────────────────────────────────────────────────────────

class _FreeVagmarkesCard extends StatelessWidget {
  const _FreeVagmarkesCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Translations.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(LucideIcons.alertTriangle,
                  color: Color(0xFFD97706), size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.free_trial_banner_title,
                          style: GoogleFonts.lexend(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF059669).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          t.free_trial_banner_badge,
                          style: GoogleFonts.lexend(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF059669),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.free_trial_banner_subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        t.free_trial_banner_cta,
                        style: GoogleFonts.lexend(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(LucideIcons.arrowRight, size: 14, color: cs.primary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subscribe CTA — shown when the user has no subscribed exams
// ─────────────────────────────────────────────────────────────────────────────

class _SubscribeCTACard extends StatelessWidget {
  const _SubscribeCTACard({required this.onSubscribe});
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Translations.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.dash_no_exams_found,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            t.bcd_free_content_desc,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onSubscribe,
              icon: const Icon(Icons.shopping_cart_outlined, size: 18),
              label: Text(t.bcd_buy_subscription),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary.withValues(alpha: 0.85),
                foregroundColor: cs.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({
    required this.exam,
    required this.progress,
    required this.isActive,
    this.endDate,
    this.onArrowTap,
  });
  final SubscribedExam exam;
  final double progress; // 0–100
  final bool isActive;
  final String? endDate;
  final VoidCallback? onArrowTap;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String? _expiryLabel() {
    final iso = endDate;
    if (iso == null || iso.isEmpty) return null;
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = dt.difference(now);
      final dateStr = '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
      if (diff.inDays < 0) return 'Expired $dateStr';
      if (diff.inDays == 0) return 'Expires today';
      if (diff.inDays == 1) return 'Expires tomorrow';
      if (diff.inDays <= 14) return 'Expires in ${diff.inDays} days';
      return 'Expires $dateStr';
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final progressValue = (progress / 100.0).clamp(0.0, 1.0);
    final progressLabel = '${progress.toStringAsFixed(0)}%';
    final t = Translations.of(context);
    final typeLabel =
        exam.isBcd ? t.dash_exam_type_test : t.dash_exam_type_taxi;

    if (isActive) {
      return Container(
        width: 260,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primary, cs.primaryContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    typeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Text(
                  exam.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_expiryLabel() != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _expiryLabel()!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CircularProgressRing(
                      value: progressValue,
                      label: progressLabel,
                      trackColor: Colors.white.withValues(alpha: 0.2),
                      progressColor: Colors.white,
                      textColor: Colors.white,
                    ),
                    GestureDetector(
                      onTap: onArrowTap,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Inactive card
    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              typeLabel,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.55),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Text(
            exam.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CircularProgressRing(
                value: progressValue,
                label: progressLabel,
                trackColor: cs.surfaceContainerHighest,
                progressColor: cs.primary,
                textColor: cs.onSurface,
              ),
              GestureDetector(
                onTap: onArrowTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: cs.onSurface.withValues(alpha: 0.3),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircularProgressRing extends StatelessWidget {
  const _CircularProgressRing({
    required this.value,
    required this.label,
    required this.trackColor,
    required this.progressColor,
    required this.textColor,
  });
  final double value;
  final String label;
  final Color trackColor;
  final Color progressColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: 4,
            backgroundColor: trackColor,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Performance overview
// ─────────────────────────────────────────────────────────────────────────────

class _PerformanceOverviewSection extends StatelessWidget {
  const _PerformanceOverviewSection({required this.stats});
  final ExamDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final t = Translations.of(context);
    final avgSecs = stats.avgDurationSeconds;
    final avgMinutes = avgSecs ~/ 60;
    final avgTimeLabel = avgSecs == 0 ? '—' : '${avgMinutes}m';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
          child: Text(
            t.dash_performance_overview,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.history_rounded,
                  iconBgColor: cs.primary.withValues(alpha: 0.1),
                  iconColor: cs.primary,
                  label: t.dash_total_attempts,
                  value: '${stats.totalAttempts}',
                  subtitle: stats.totalAttempts == 0
                      ? t.dash_stat_none_yet
                      : t.dash_stat_completed,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.layers_rounded,
                  iconBgColor: cs.secondaryContainer.withValues(alpha: 0.5),
                  iconColor: cs.secondary,
                  label: t.dash_batches_done,
                  value: '${stats.completedBatchCount}',
                  subtitle: t.dash_stat_of_n.replaceAll(
                    '{total}',
                    '${stats.totalBatchCount}',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.timer_rounded,
                  iconBgColor: cs.tertiaryContainer.withValues(alpha: 0.3),
                  iconColor: cs.tertiary,
                  label: t.dash_avg_time,
                  value: avgTimeLabel,
                  subtitle: avgSecs > 0 ? t.dash_stat_per_session : '—',
                  subtitleColor: avgSecs > 0 ? cs.tertiary : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
    this.subtitleColor,
  });
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              height: 1.3,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.labelSmall?.copyWith(
              color: subtitleColor ?? cs.onSurface.withValues(alpha: 0.4),
              fontWeight: FontWeight.w500,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Focus categories
// ─────────────────────────────────────────────────────────────────────────────

class _FocusCategoriesSection extends StatefulWidget {
  const _FocusCategoriesSection({required this.stats});
  final ExamDashboardStats stats;

  @override
  State<_FocusCategoriesSection> createState() =>
      _FocusCategoriesSectionState();
}

class _FocusCategoriesSectionState extends State<_FocusCategoriesSection> {
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    final cats = widget.stats.categoryStats;
    if (cats != null && cats.isNotEmpty) {
      _expanded.add(cats.first.node.id);
    }
  }

  @override
  void didUpdateWidget(_FocusCategoriesSection old) {
    super.didUpdateWidget(old);
    if (old.stats.exam.id != widget.stats.exam.id) {
      _expanded.clear();
      final cats = widget.stats.categoryStats;
      if (cats != null && cats.isNotEmpty) {
        _expanded.add(cats.first.node.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;
    if (stats.categoryStats != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: stats.categoryStats!.asMap().entries.map((entry) {
            final cat = entry.value;
            final isExpanded = _expanded.contains(cat.node.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CategoryListItem(
                cat: cat,
                icon: categoryIcon(cat.node.name),
                color: categoryColor(cat.node.name),
                isExpanded: isExpanded,
                onToggle: () => setState(() {
                  if (isExpanded) {
                    _expanded.remove(cat.node.id);
                  } else {
                    _expanded.add(cat.node.id);
                  }
                }),
                stats: stats,
              ),
            );
          }).toList(),
        ),
      );
    }

    // 2-layer exam: show batches directly
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: stats.allBatchStats
            .asMap()
            .entries
            .map((e) => Padding(
                  padding: EdgeInsets.only(
                    bottom: e.key < stats.allBatchStats.length - 1 ? 8 : 0,
                  ),
                  child: _BatchRow(
                    batch: e.value,
                    exam: stats.exam,
                    onTap: stats.exam.isBcd
                        ? () => _launchBatch(
                            context, stats.exam, e.value.node, null)
                        : null,
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _CategoryListItem extends StatelessWidget {
  const _CategoryListItem({
    required this.cat,
    required this.icon,
    required this.color,
    required this.isExpanded,
    required this.onToggle,
    required this.stats,
  });
  final CategoryStats cat;
  final IconData icon;
  final Color color;
  final bool isExpanded;
  final VoidCallback onToggle;
  final ExamDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final t = Translations.of(context);
    final statusText = cat.touchedBatches == 0
        ? t.dash_not_started
        : t.dash_avg_score_label.replaceAll(
            '{score}',
            cat.averageScore.toStringAsFixed(0),
          );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: isExpanded ? cs.surfaceContainerLow : theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpanded
              ? cs.primary.withValues(alpha: 0.15)
              : cs.onSurface.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.node.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${t.dash_batches_count.replaceAll('{n}', '${cat.totalBatches}')} • $statusText',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.25 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: cs.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: cs.onSurface.withValues(alpha: 0.07),
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: cat.batchStats
                            .asMap()
                            .entries
                            .map((e) => Padding(
                                  padding: EdgeInsets.only(
                                    bottom: e.key < cat.batchStats.length - 1
                                        ? 8
                                        : 0,
                                  ),
                                  child: _BatchRow(
                                    batch: e.value,
                                    exam: stats.exam,
                                    onTap: stats.exam.isBcd
                                        ? () => _launchBatch(
                                              context,
                                              stats.exam,
                                              e.value.node,
                                              cat.node.name,
                                            )
                                        : null,
                                  ),
                                ))
                            .toList(),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Weekly streak
// ─────────────────────────────────────────────────────────────────────────────

class _WeeklyStreakSection extends StatelessWidget {
  const _WeeklyStreakSection({required this.streak});
  final StreakSummary streak;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final t = Translations.of(context);
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));
    final dayLabels = [
      t.dash_day_mon,
      t.dash_day_tue,
      t.dash_day_wed,
      t.dash_day_thu,
      t.dash_day_fri,
      t.dash_day_sat,
      t.dash_day_sun,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cs.inverseSurface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Left: streak info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.amber,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          t.dash_streak_title.replaceAll(
                            '{n}',
                            '${streak.currentStreak}',
                          ),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: cs.onInverseSurface,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _StreakStatLabel(
                        label: t.dash_streak_current,
                        value: t.dash_streak_days.replaceAll(
                          '{n}',
                          '${streak.currentStreak}',
                        ),
                        valueColor: cs.onInverseSurface,
                        labelColor: cs.onInverseSurface,
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      _StreakStatLabel(
                        label: t.dash_streak_best,
                        value: t.dash_streak_days.replaceAll(
                          '{n}',
                          '${streak.bestStreak}',
                        ),
                        valueColor: cs.onInverseSurface,
                        labelColor: cs.onInverseSurface,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Right: bar chart
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final day = days[i];
                final isActive = streak.isActiveDay(day);
                final isToday = day.year == now.year &&
                    day.month == now.month &&
                    day.day == now.day;
                final isFuture = day.isAfter(now);

                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            height:
                                isActive ? 40 : (isToday && !isFuture ? 18 : 0),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.amber
                                  : Colors.amber.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dayLabels[i],
                        style: TextStyle(
                          color: isToday
                              ? Colors.amber
                              : cs.onInverseSurface.withValues(alpha: 0.5),
                          fontSize: 9,
                          fontWeight:
                              isToday ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakStatLabel extends StatelessWidget {
  const _StreakStatLabel({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.labelColor,
  });
  final String label;
  final String value;
  final Color valueColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: labelColor.withValues(alpha: 0.6),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Batch row
// ─────────────────────────────────────────────────────────────────────────────

class _BatchRow extends StatefulWidget {
  const _BatchRow({
    required this.batch,
    required this.exam,
    this.onTap,
  });
  final BatchStats batch;
  final SubscribedExam exam;
  final VoidCallback? onTap;

  @override
  State<_BatchRow> createState() => _BatchRowState();
}

class _BatchRowState extends State<_BatchRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final batch = widget.batch;

    Color dotColor;
    if (batch.isCompleted) {
      dotColor = Colors.green;
    } else if (batch.isLowScore) {
      dotColor = Colors.orange;
    } else if (batch.isUntouched) {
      dotColor = cs.onSurface.withValues(alpha: 0.2);
    } else {
      dotColor = cs.primary;
    }

    final allAttempts = context.watch<DashboardProvider>().attempts;
    final batchAttempts = DashboardHelpers.attemptsForBatch(
      allAttempts,
      widget.exam,
      batch.node,
    )..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    final hasPaused = batchAttempts.any((a) => a.isPaused);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: _expanded ? cs.surfaceContainerLow : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _expanded
              ? cs.primary.withValues(alpha: 0.15)
              : cs.onSurface.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        batch.node.name,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (hasPaused)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(
                          Icons.pause_circle_outline_rounded,
                          size: 14,
                          color: Colors.orange,
                        ),
                      ),
                    if (batch.isUntouched)
                      Text(
                        Translations.of(context).dash_not_started,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.35),
                        ),
                      )
                    else
                      Text(
                        '${batch.averageScore.toStringAsFixed(0)}%',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: dotColor,
                        ),
                      ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _expanded ? 0.25 : 0.0,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: cs.onSurface.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: _expanded
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        color: cs.surface,
                        border: Border(
                          top: BorderSide(
                            color: cs.onSurface.withValues(alpha: 0.07),
                          ),
                        ),
                      ),
                      child: _BatchAttemptHistory(
                        batchAttempts: batchAttempts,
                        exam: widget.exam,
                        batch: batch,
                        onNewTest: widget.onTap,
                        onResume: (attempt) => _resumeAttempt(
                            context, attempt, widget.exam, batch),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Batch attempt history (expandable panel inside _BatchRow)
// ─────────────────────────────────────────────────────────────────────────────

class _BatchAttemptHistory extends StatelessWidget {
  const _BatchAttemptHistory({
    required this.batchAttempts,
    required this.exam,
    required this.batch,
    required this.onNewTest,
    required this.onResume,
  });
  final List<TestAttempt> batchAttempts;
  final SubscribedExam exam;
  final BatchStats batch;
  final VoidCallback? onNewTest;
  final void Function(TestAttempt) onResume;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fmt = DateFormat('d MMM y');

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action buttons row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                if (onNewTest != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onNewTest,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('New Test'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          if (batchAttempts.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Text(
                'No attempts yet',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              child: Text(
                'Previous attempts',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.5),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...() {
              final shown = batchAttempts.take(3).toList();
              return shown.map((a) {
                final isPaused = a.isPaused;
                final scoreColor = a.hasPassed ? Colors.green : cs.error;
                final dur = a.durationSeconds ?? 0;
                final durLabel =
                    dur > 0 ? DashboardHelpers.formatDuration(dur) : '—';

                return Column(
                  children: [
                    InkWell(
                      onTap: isPaused ? () => onResume(a) : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        child: Row(
                          children: [
                            Icon(
                              isPaused
                                  ? Icons.pause_circle_filled_rounded
                                  : (a.hasPassed
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_rounded),
                              size: 18,
                              color: isPaused
                                  ? Colors.orange
                                  : (a.hasPassed ? Colors.green : cs.error),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fmt.format(a.dateTime),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    durLabel,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color:
                                          cs.onSurface.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isPaused)
                              Text(
                                'Resume',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            else
                              Text(
                                '${a.score.toStringAsFixed(0)}%',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scoreColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (a != shown.last)
                      Divider(
                        height: 1,
                        indent: 38,
                        color: cs.onSurface.withValues(alpha: 0.05),
                      ),
                  ],
                );
              });
            }(),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Resume attempt navigation helper
// ─────────────────────────────────────────────────────────────────────────────

void _resumeAttempt(
  BuildContext context,
  TestAttempt attempt,
  SubscribedExam exam,
  BatchStats batch,
) {
  if (attempt.questions.isNotEmpty) {
    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => TestscreenWrapper(
          questions: attempt.questions,
          instantMarking: true,
          licenceId: attempt.licenceId ?? '',
          categoryId: attempt.categoryId ?? '',
          licenceName: attempt.licenceName ?? '',
          categoryName: attempt.categoryName ?? '',
          initialQuestionIndex: attempt.currentQuestionIndex,
          userSelections: attempt.userSelections,
          resumeTestId: attempt.testId,
          bcdCategoryId: attempt.bcdCategoryId,
        ),
      ),
    ).then((_) {
      if (context.mounted) context.read<DashboardProvider>().refresh();
    });
  } else {
    // No questions stored (synced from backend) — start fresh for this batch
    _launchBatch(context, exam, batch.node, null);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Exam card arrow tap handler
// ─────────────────────────────────────────────────────────────────────────────

void _handleExamArrowTap(
  BuildContext context,
  SubscribedExam exam,
  DashboardProvider provider,
) {
  final paused = DashboardHelpers.latestPausedAttemptForExam(
    provider.attempts,
    exam,
  );

  if (paused != null) {
    // Resume the most recent paused attempt
    if (paused.questions.isNotEmpty) {
      Navigator.push(
        context,
        AppPageRoute(
          builder: (_) => TestscreenWrapper(
            questions: paused.questions,
            instantMarking: true,
            licenceId: paused.licenceId ?? '',
            categoryId: paused.categoryId ?? '',
            licenceName: paused.licenceName ?? '',
            categoryName: paused.categoryName ?? '',
            initialQuestionIndex: paused.currentQuestionIndex,
            userSelections: paused.userSelections,
            resumeTestId: paused.testId,
            bcdCategoryId: paused.bcdCategoryId,
          ),
        ),
      ).then((_) {
        if (context.mounted) provider.refresh();
      });
    } else {
      // No questions saved — find the batch and start fresh
      final stats = provider.selectedStats;
      final continueNode = stats?.continueNode;
      if (continueNode != null) {
        _launchBatch(context, exam, continueNode.node, null);
      }
    }
    return;
  }

  // No paused attempt — launch the continue node
  provider.selectExam(exam);
  final stats = provider.selectedStats;
  final continueNode = stats?.continueNode;
  if (continueNode != null) {
    _launchBatch(context, exam, continueNode.node, null);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error view
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.errorKind, required this.onRetry});
  final DashboardErrorKind errorKind;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;

    final (icon, message) = switch (errorKind) {
      DashboardErrorKind.network => (
          Icons.wifi_off_rounded,
          t.dash_network_error,
        ),
      DashboardErrorKind.server => (
          Icons.cloud_off_rounded,
          t.dash_server_error,
        ),
      DashboardErrorKind.unknown => (
          Icons.error_outline_rounded,
          t.dash_unknown_error,
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: cs.error),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(t.dash_retry),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Navigation helper
// ─────────────────────────────────────────────────────────────────────────────

void _launchBatch(
  BuildContext context,
  SubscribedExam exam,
  ExamNode batchNode,
  String? categoryName,
) {
  if (!exam.isBcd) return;

  final parentBcdId = int.tryParse(batchNode.parentId ?? exam.id) ?? 0;
  final parentName = categoryName ?? exam.name;

  Navigator.push(
    context,
    AppPageRoute(
      builder: (_) => BCDTestScreen(
        testId: int.tryParse(batchNode.id) ?? 0,
        testName: batchNode.name,
        passScore: batchNode.passScore,
        timeLimit: batchNode.targetDurationSeconds ~/ 60,
        parentCategoryName: parentName,
        parentCategoryBcdId: parentBcdId,
      ),
    ),
  ).then((_) {
    if (context.mounted) context.read<DashboardProvider>().refresh();
  });
}
