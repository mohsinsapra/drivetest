import 'package:taxi_exam_app/core/widgets/app_loading_indicator.dart';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/api/dio_client.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/services/bcd_cache.dart';
import 'package:taxi_exam_app/core/services/iap_service.dart';
import 'package:taxi_exam_app/core/services/payment_coordinator.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/core/widgets/app_button.dart';
import 'package:taxi_exam_app/features/auth/auth_bottom_sheet.dart';
import 'package:taxi_exam_app/features/auth/auth_screen.dart';
import 'package:taxi_exam_app/features/bcd/bcd_category_hub_screen.dart';
import 'package:taxi_exam_app/features/bcd/bcd_sub_category_screen.dart';
import 'package:taxi_exam_app/features/payment/subscription_success_overlay.dart';
import 'package:taxi_exam_app/main_screen.dart';

typedef OnboardingLoadProducts = Future<List<Map<String, dynamic>>> Function();
typedef OnboardingIsLoggedIn = bool Function();
typedef OnboardingAuthSheet = Future<bool> Function(
  BuildContext context, {
  String? title,
  String? subtitle,
  bool required,
});
typedef OnboardingPayment = Future<SubscriptionSuccessResult?> Function(
  BuildContext context,
  List<Map<String, dynamic>> products,
);
typedef OnboardingPostPurchase = Future<void> Function(
  BuildContext context,
  SubscriptionSuccessResult result,
  List<Map<String, dynamic>> products,
);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    this.loadProducts = _defaultLoadProducts,
    this.isLoggedIn = _defaultIsLoggedIn,
    this.showAuthSheet = _defaultShowAuthSheet,
    this.processPayment = _defaultProcessPayment,
    this.postPurchase = _defaultPostPurchase,
  });

  final OnboardingLoadProducts loadProducts;
  final OnboardingIsLoggedIn isLoggedIn;
  final OnboardingAuthSheet showAuthSheet;
  final OnboardingPayment processPayment;
  final OnboardingPostPurchase postPurchase;

  static Future<List<Map<String, dynamic>>> _defaultLoadProducts() async {
    final raw = await ApiService().fetchBCDSubscriptionProducts();
    return raw
        .whereType<Map<String, dynamic>>()
        .where((p) => p['is_free'] != true && p['is_active'] != false)
        .toList();
  }

  static Future<bool> _defaultShowAuthSheet(
    BuildContext context, {
    String? title,
    String? subtitle,
    bool required = false,
  }) async {
    if (DioClient().accessToken != null) return true;
    return showAuthBottomSheet(context,
        title: title, subtitle: subtitle, required: required, allowDemo: false);
  }

  static bool _defaultIsLoggedIn() => DioClient().accessToken != null;

  static Future<SubscriptionSuccessResult?> _defaultProcessPayment(
    BuildContext context,
    List<Map<String, dynamic>> products,
  ) async {
    final api = ApiService();
    return PaymentCoordinator.pay(
      context,
      products: products,
      createStripeIntent: (prods) async {
        if (prods.length == 1) {
          return api.createBCDPaymentIntent(prods.first['id'] as int);
        }
        return api.createBCDBundlePaymentIntent(
            prods.map((p) => p['id'] as int).toList());
      },
      onStripePaymentConfirmed: api.confirmBCDPayment,
      onIAPPurchaseConfirmed: (product, transactionId) =>
          api.confirmBCDIAPPurchase(
        (product['id'] as num).toInt(),
        transactionId: transactionId,
      ),
    );
  }

  static Future<void> _defaultPostPurchase(
    BuildContext context,
    SubscriptionSuccessResult result,
    List<Map<String, dynamic>> products,
  ) async {
    await DioClient().clearCache();
    BcdCache.instance.invalidate();
    try {
      await BcdCache.instance.ensureLoaded();
    } catch (e) {
      debugPrint('[Onboarding] cache refresh failed after purchase: $e');
    }

    if (!context.mounted) return;

    // Resolve which BCD category to land on (only for "Start Tests" taps).
    Map<String, dynamic>? targetCategory;
    if (result == SubscriptionSuccessResult.startTests) {
      for (final p in products) {
        final ids = p['category_bcd_ids'] as List<dynamic>?;
        final id = ids?.firstOrNull;
        if (id == null) continue;
        targetCategory = BcdCache.instance.categories.firstWhereOrNull(
          (c) => c['bcd_id']?.toString() == id.toString(),
        );
        if (targetCategory != null) break;
      }
    }

    // Navigate: replace onboarding with MainScreen, then optionally push category.
    // NOTE: findAncestorStateOfType cannot locate the current widget's own state,
    // so navigation is driven directly here using the navigator.
    final navigator = Navigator.of(context);
    navigator.pushReplacement(AppPageRoute(builder: (_) => const MainScreen()));
    if (targetCategory != null) {
      final cat = Map<String, dynamic>.from(targetCategory)
        ..['is_subscribed'] = true;
      navigator.push(
        cat['has_children'] == true
            ? AppPageRoute(
                builder: (_) => BCDSubCategoryScreen(parentCategory: cat))
            : AppPageRoute(builder: (_) => BCDCategoryHubScreen(category: cat)),
      );
    }
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // Pages: 0 = Category, 1 = Exam date, 2 = Weekly goal, 3 = Plan (purchase)
  static const int _totalSteps = 3; // 4 pages (indices 0–3)

  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Products
  List<Map<String, dynamic>> _products = [];
  bool _loadingProducts = true;
  final List<Map<String, dynamic>> _selectedProducts = [];
  bool _purchaseInFlight = false;
  List<Map<String, dynamic>> _mySubscriptions = [];

  // Step 0 — exam date (default: 3 months from today)
  DateTime _examDeadline = DateTime(
    DateTime.now().year,
    DateTime.now().month + 3,
    DateTime.now().day,
  );
  _DateOption _selectedDateOption = _DateOption.threeMonths;

  // Step 0 — weekday study schedule (0=Mon … 6=Sun), default Mon–Fri
  Set<int> _selectedWeekdays = {0, 1, 2, 3, 4};

  @override
  void initState() {
    super.initState();
    _fetchProductsInBackground();
    if (widget.isLoggedIn()) {
      _fetchMySubscriptions();
    }
  }

  Future<void> _fetchMySubscriptions({bool forceRefresh = false}) async {
    try {
      final data = await ApiService()
          .fetchMyBCDSubscriptions(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() => _mySubscriptions = data.cast<Map<String, dynamic>>());
      }
    } catch (_) {}
  }

  bool _isOwned(Map<String, dynamic> product) {
    final productId = product['id']?.toString();
    if (productId == null) return false;
    return _mySubscriptions.any((s) {
      final p = s['product'];
      final subProductId = ((p is Map) ? p['id'] : p)?.toString();
      return subProductId == productId && s['status'] == 'paid';
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchProductsInBackground() async {
    try {
      final raw = await widget.loadProducts();
      if (mounted) {
        setState(() {
          _products = raw;
          _loadingProducts = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  Future<void> _saveProgressPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('exam_deadline', _examDeadline.toIso8601String());
      await prefs.setInt('practice_days_per_week', _selectedWeekdays.length);
    } catch (_) {}
  }

  Future<void> _markOnboardingComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);
    } catch (_) {}
  }

  Future<void> _saveAndExit() async {
    final navigator = Navigator.of(context);
    await _saveProgressPrefs();
    await _markOnboardingComplete();
    if (!mounted) return;
    navigator.pushReplacement(
      widget.isLoggedIn()
          ? AppPageRoute(builder: (_) => const MainScreen())
          : AppPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  void _goNext() {
    if (_currentStep < _totalSteps) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _saveAndExit();
    }
  }

  void _goBack() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 30)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() {
        _examDeadline = picked;
        _selectedDateOption = _DateOption.custom;
      });
    }
  }

  /// Returns the first BCD category from [BcdCache] that matches the
  /// `category_bcd_ids` of any product in [products], or null if none match.
  Map<String, dynamic>? _resolveCategoryForProducts(
      List<Map<String, dynamic>> products) {
    for (final p in products) {
      final ids = p['category_bcd_ids'] as List<dynamic>?;
      final id = ids?.firstOrNull;
      if (id == null) continue;
      final cat = BcdCache.instance.categories.firstWhereOrNull(
        (c) => c['bcd_id']?.toString() == id.toString(),
      );
      if (cat != null) return cat;
    }
    return null;
  }

  /// Replaces onboarding with [MainScreen] then, if [targetCategory] is set,
  /// pushes the category hub so the user lands in their chosen subject.
  void _navigateToMainAndCategory(
    NavigatorState navigator,
    Map<String, dynamic>? targetCategory,
  ) {
    navigator.pushReplacement(AppPageRoute(builder: (_) => const MainScreen()));
    if (targetCategory == null) return;
    final cat = Map<String, dynamic>.from(targetCategory);
    final hasChildren = cat['has_children'] == true;
    navigator.push(
      hasChildren
          ? AppPageRoute(
              builder: (_) => BCDSubCategoryScreen(parentCategory: cat))
          : AppPageRoute(builder: (_) => BCDCategoryHubScreen(category: cat)),
    );
  }

  Future<void> _handleStartFree() async {
    if (_purchaseInFlight || !mounted) return;
    setState(() => _purchaseInFlight = true);

    // Only create a guest session when the user is not already logged in.
    // If they are authenticated, calling guestLogin() would overwrite their
    // tokens with guest credentials, effectively logging them out.
    if (!widget.isLoggedIn()) {
      try {
        await ApiService().guestLogin();
      } catch (e) {
        if (mounted) setState(() => _purchaseInFlight = false);
        return;
      }
    }

    await BcdCache.instance.ensureLoaded();

    await _saveProgressPrefs();
    await _markOnboardingComplete();
    if (!mounted) return;

    _navigateToMainAndCategory(
      Navigator.of(context),
      _resolveCategoryForProducts(_selectedProducts),
    );
  }

  Future<_PrePurchaseChoice?> _showPrePurchaseSheet() =>
      showModalBottomSheet<_PrePurchaseChoice>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => const _PrePurchaseSheet(),
      );

  Future<void> _handlePurchaseTap({Map<String, dynamic>? only}) async {
    final products = only != null
        ? [only]
        : List<Map<String, dynamic>>.from(_selectedProducts);
    if (products.isEmpty || !mounted || _purchaseInFlight) return;

    setState(() => _purchaseInFlight = true);

    // Force-refresh subscriptions only if logged in (validates token too).
    if (widget.isLoggedIn()) {
      await _fetchMySubscriptions(forceRefresh: true);

      // Re-check auth: if the token was cleared by the 401 handler, abort here.
      // logoutAndRedirect() is already navigating to AuthScreen.
      if (!mounted || !widget.isLoggedIn()) {
        if (mounted) setState(() => _purchaseInFlight = false);
        return;
      }

      // If all selected products are already owned, skip payment and go straight to practice.
      if (products.every(_isOwned)) {
        setState(() => _purchaseInFlight = false);
        await _markOnboardingComplete();
        if (!mounted) return;
        await DioClient().clearCache();
        BcdCache.instance.invalidate();
        await BcdCache.instance.ensureLoaded();
        if (!mounted) return;
        final rawCategory = _resolveCategoryForProducts(products);
        final targetCategory = rawCategory != null
            ? (Map<String, dynamic>.from(rawCategory)..['is_subscribed'] = true)
            : null;
        _navigateToMainAndCategory(Navigator.of(context), targetCategory);
        return;
      }
    } // end if (widget.isLoggedIn())

    // If not logged in, ask whether the user wants to sign in or buy as a guest.
    // Either way the purchase proceeds — registration is never mandatory.
    if (!widget.isLoggedIn()) {
      final choice = await _showPrePurchaseSheet();
      if (!mounted) return;

      if (choice == null) {
        // User dismissed — cancel purchase.
        setState(() => _purchaseInFlight = false);
        return;
      }

      if (choice == _PrePurchaseChoice.signIn) {
        final authed = await widget.showAuthSheet(
          context,
          title: Translations.of(context).onb_signin_to_purchase_title,
          subtitle: Translations.of(context).onb_signin_to_purchase_subtitle,
          required: false,
        );
        if (!mounted) return;
        if (!authed) {
          // User explicitly chose "Sign In" but dismissed without logging in.
          // Cancel the purchase — do not silently fall back to guest.
          setState(() => _purchaseInFlight = false);
          return;
        }
      } else {
        // Guest path — create a silent guest session.
        try {
          await ApiService().guestLogin();
        } catch (e) {
          debugPrint('[Onboarding] guest login before purchase failed: $e');
          if (mounted) setState(() => _purchaseInFlight = false);
          return;
        }
      }

      if (!mounted) return;
    }

    await _saveProgressPrefs();
    if (!mounted) return;

    // Strip already-owned products from the purchase list so the backend does
    // not reject the payment intent when a bundle contains a pre-owned item.
    final unpurchased = widget.isLoggedIn()
        ? products.where((p) => !_isOwned(p)).toList()
        : products;
    if (unpurchased.isEmpty) {
      setState(() => _purchaseInFlight = false);
      return;
    }

    try {
      SubscriptionSuccessResult? result;
      try {
        result = await widget.processPayment(context, unpurchased);
      } catch (e) {
        debugPrint('[Onboarding] payment flow failed: $e');
        return;
      }
      if (result == null || !mounted) {
        if (mounted) setState(() => _purchaseInFlight = false);
        return;
      }

      // Payment succeeded. If backend verify was deferred during the purchase
      // (e.g. transient network error), retry it now so the subscription
      // activates before navigating to the main screen.
      if (await IAPService.instance.hasDeferredReceipt()) {
        try {
          await IAPService.instance.verifyDeferredReceipt();
        } catch (e) {
          debugPrint('[Onboarding] deferred receipt retry failed: $e');
        }
      }

      await _markOnboardingComplete();
      if (!mounted) return;

      await widget.postPurchase(context, result, products);
    } finally {
      if (mounted) setState(() => _purchaseInFlight = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              currentStep: _currentStep,
              totalSteps: _totalSteps,
              onClose: _saveAndExit,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  // Step 1: Choose Your Category
                  _CategoryPage(
                    products: _products,
                    loading: _loadingProducts,
                    selectedProducts: _selectedProducts,
                    onToggle: (product) => setState(() {
                      if (!kIsWeb && Platform.isIOS) {
                        _selectedProducts
                          ..clear()
                          ..add(product);
                      } else if (_selectedProducts.contains(product)) {
                        _selectedProducts.remove(product);
                      } else {
                        _selectedProducts.add(product);
                      }
                    }),
                    onBack: null,
                    onNext: _selectedProducts.isEmpty ? null : _goNext,
                  ),
                  // Step 2: Exam date
                  _ExamDatePage(
                    selectedDateOption: _selectedDateOption,
                    examDeadline: _examDeadline,
                    onDateSelect: (opt, date) => setState(() {
                      _selectedDateOption = opt;
                      _examDeadline = date;
                    }),
                    onCustomDate: _pickCustomDate,
                    onBack: _goBack,
                    onNext: _goNext,
                  ),
                  // Step 3: Weekly goal
                  _WeeklyGoalPage(
                    selectedWeekdays: _selectedWeekdays,
                    onWeekdayToggle: (day) => setState(() {
                      if (_selectedWeekdays.contains(day)) {
                        if (_selectedWeekdays.length > 1) {
                          _selectedWeekdays = Set.from(_selectedWeekdays)
                            ..remove(day);
                        }
                      } else {
                        _selectedWeekdays = Set.from(_selectedWeekdays)
                          ..add(day);
                      }
                    }),
                    onBack: _goBack,
                    onNext: _goNext,
                  ),
                  // Step 4: Pricing + "Start for free" guest path (all platforms).
                  _PlanPage(
                    products: _selectedProducts,
                    purchasing: _purchaseInFlight,
                    isOwnedFn: _isOwned,
                    isLoggedIn: widget.isLoggedIn(),
                    onPurchaseOne: _purchaseInFlight
                        ? null
                        : (p) => _handlePurchaseTap(only: p),
                    onPurchaseAll:
                        _selectedProducts.isEmpty || _purchaseInFlight
                            ? null
                            : _handlePurchaseTap,
                    onBack: _goBack,
                    onStartFree: _purchaseInFlight ? null : _handleStartFree,
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

// ─── Top bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.currentStep,
    required this.totalSteps,
    required this.onClose,
  });

  final int currentStep;
  final int totalSteps;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Hero(
            tag: 'brand-bolt',
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.bolt,
                  color: cs.onSecondaryContainer,
                  size: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                t.onb_top_bar_title,
                style: GoogleFonts.lexend(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: cs.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Step progress dots
          Row(
            children: List.generate(totalSteps + 1, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(left: 6),
                width: 28,
                height: 8,
                decoration: BoxDecoration(
                  color: i <= currentStep
                      ? cs.primary
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClose,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.close_rounded, color: cs.outline, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared step header (Step X of 3 + headline) ─────────────────────────────

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.stepLabel,
    required this.headlinePlain,
    required this.headlineItalic,
  });

  final String stepLabel;
  final String headlinePlain;
  final String headlineItalic;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stepLabel.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
            color: cs.outline,
          ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: RichText(
            maxLines: 1,
            text: TextSpan(
              style: GoogleFonts.lexend(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                height: 1.2,
              ),
              children: [
                TextSpan(text: headlinePlain),
                TextSpan(
                  text: headlineItalic,
                  style: GoogleFonts.lexend(
                    fontStyle: FontStyle.italic,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Shared CTA button (pill-shaped, full width) ──────────────────────────────

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          disabledBackgroundColor: cs.primary.withValues(alpha: 0.28),
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        child: Text(
          label,
          style: GoogleFonts.lexend(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── Shared back + next button row ────────────────────────────────────────────

class _NavRow extends StatelessWidget {
  const _NavRow(
      {required this.onBack, required this.onNext, required this.nextLabel});

  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        if (onBack != null) ...[
          SizedBox(
            height: 56,
            child: OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: cs.outlineVariant),
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(14),
              ),
              child:
                  Icon(Icons.arrow_back_rounded, color: cs.onSurface, size: 20),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(child: _PrimaryButton(label: nextLabel, onPressed: onNext)),
      ],
    );
  }
}

// ─── Step 1: Exam Date ────────────────────────────────────────────────────────

enum _DateOption { threeMonths, sixMonths, twelveMonths, custom }

class _ExamDatePage extends StatelessWidget {
  const _ExamDatePage({
    required this.selectedDateOption,
    required this.examDeadline,
    required this.onDateSelect,
    required this.onCustomDate,
    required this.onBack,
    required this.onNext,
  });

  final _DateOption selectedDateOption;
  final DateTime examDeadline;
  final void Function(_DateOption, DateTime) onDateSelect;
  final VoidCallback onCustomDate;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();

    final months = t.onb_months;
    final dateOptions = [
      (
        label: '3',
        sub: months,
        opt: _DateOption.threeMonths,
        date: DateTime(now.year, now.month + 3, now.day)
      ),
      (
        label: '6',
        sub: months,
        opt: _DateOption.sixMonths,
        date: DateTime(now.year, now.month + 6, now.day)
      ),
      (
        label: '12',
        sub: months,
        opt: _DateOption.twelveMonths,
        date: DateTime(now.year, now.month + 12, now.day)
      ),
    ];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StepHeader(
                  stepLabel: t.onb_step_of
                      .replaceAll('{current}', '2')
                      .replaceAll('{total}', '4'),
                  headlinePlain: t.onb_step2_plain,
                  headlineItalic: t.onb_step2_italic,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        color: cs.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      t.onb_exam_date_title,
                      style: GoogleFonts.lexend(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    for (final item in dateOptions) ...[
                      Expanded(
                        child: _DateCard(
                          number: item.label,
                          sub: item.sub,
                          selected: selectedDateOption == item.opt,
                          onTap: () => onDateSelect(item.opt, item.date),
                        ),
                      ),
                      if (item != dateOptions.last) const SizedBox(width: 10),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: onCustomDate,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selectedDateOption == _DateOption.custom
                          ? cs.primaryContainer.withValues(alpha: 0.3)
                          : cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: selectedDateOption == _DateOption.custom
                          ? Border.all(color: cs.primary, width: 2)
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          size: 16,
                          color: selectedDateOption == _DateOption.custom
                              ? cs.primary
                              : cs.outline,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          selectedDateOption == _DateOption.custom
                              ? '${examDeadline.day}/${examDeadline.month}/${examDeadline.year}'
                              : t.onb_custom_date,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: selectedDateOption == _DateOption.custom
                                ? cs.primary
                                : cs.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _DeadlineBanner(deadline: examDeadline),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: _NavRow(
            onBack: onBack,
            onNext: onNext,
            nextLabel: t.onb_continue,
          ),
        ),
      ],
    );
  }
}

// ─── Step 2: Weekly Goal ──────────────────────────────────────────────────────

class _WeeklyGoalPage extends StatelessWidget {
  const _WeeklyGoalPage({
    required this.selectedWeekdays,
    required this.onWeekdayToggle,
    required this.onBack,
    required this.onNext,
  });

  final Set<int> selectedWeekdays;
  final ValueChanged<int> onWeekdayToggle;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;

    const weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StepHeader(
                  stepLabel: t.onb_step_of
                      .replaceAll('{current}', '3')
                      .replaceAll('{total}', '4'),
                  headlinePlain: t.onb_step3_plain,
                  headlineItalic: t.onb_step3_italic,
                ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flash_on_rounded,
                              color: cs.secondary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            t.onb_weekly_goal_title,
                            style: GoogleFonts.lexend(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t.onb_weekly_goal_sub,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(7, (i) {
                          final selected = selectedWeekdays.contains(i);
                          return _WeekdayToggle(
                            letter: weekdayLetters[i],
                            selected: selected,
                            onTap: () => onWeekdayToggle(i),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: _NavRow(
            onBack: onBack,
            onNext: onNext,
            nextLabel: t.onb_continue,
          ),
        ),
      ],
    );
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({
    required this.number,
    required this.sub,
    required this.selected,
    required this.onTap,
  });

  final String number;
  final String sub;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: selected
              ? cs.primaryContainer.withValues(alpha: 0.2)
              : cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? cs.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              number,
              style: GoogleFonts.lexend(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: selected ? cs.primary : cs.onSurface,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: selected ? cs.primary : cs.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekdayToggle extends StatelessWidget {
  const _WeekdayToggle({
    required this.letter,
    required this.selected,
    required this.onTap,
  });

  final String letter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            letter,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: cs.outline,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? cs.primary : cs.surfaceContainerHighest,
              border: selected
                  ? null
                  : Border.all(color: cs.outlineVariant, width: 1),
            ),
            child: Center(
              child: Text(
                letter,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? cs.onPrimary : cs.outline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeadlineBanner extends StatelessWidget {
  const _DeadlineBanner({required this.deadline});

  final DateTime deadline;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final daysLeft = deadline.difference(DateTime.now()).inDays;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.flag_rounded, color: cs.primary, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${deadline.day}/${deadline.month}/${deadline.year}',
                style: GoogleFonts.lexend(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              Text(
                Translations.of(context).dash_days_remaining.replaceAll(
                      '{n}',
                      '$daysLeft',
                    ),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Step 1: Choose Your Category ────────────────────────────────────────────

class _CategoryPage extends StatelessWidget {
  const _CategoryPage({
    required this.products,
    required this.loading,
    required this.selectedProducts,
    required this.onToggle,
    required this.onBack,
    required this.onNext,
  });

  final List<Map<String, dynamic>> products;
  final bool loading;
  final List<Map<String, dynamic>> selectedProducts;
  final ValueChanged<Map<String, dynamic>> onToggle;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            stepLabel: t.onb_step_of
                .replaceAll('{current}', '1')
                .replaceAll('{total}', '4'),
            headlinePlain: t.onb_step1_plain,
            headlineItalic: t.onb_step1_italic,
          ),
          const SizedBox(height: 28),
          Expanded(
            child: loading
                ? const _CategoryShimmer()
                : products.isEmpty
                    ? Center(
                        child: Text(
                          t.onb_no_exams,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14),
                        ),
                      )
                    : ListView.separated(
                        itemCount: products.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _CategoryCard(
                          product: products[i],
                          selected: selectedProducts.contains(products[i]),
                          featured: i == 1 && products.length >= 3,
                          onTap: () => onToggle(products[i]),
                        ),
                      ),
          ),
          const SizedBox(height: 16),
          _NavRow(
            onBack: onBack,
            onNext: onNext,
            nextLabel: t.onb_continue,
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.product,
    required this.selected,
    required this.featured,
    required this.onTap,
  });

  final Map<String, dynamic> product;
  final bool selected;
  final bool featured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;
    final title = product['name']?.toString().trim().isNotEmpty == true
        ? product['name'].toString()
        : t.onb_no_plan_selected;
    final icon = _iconForProduct(product);

    final bgColor = selected
        ? cs.primary
        : featured
            ? cs.primaryContainer.withValues(alpha: 0.45)
            : cs.surfaceContainerHighest;
    final fgColor = selected ? cs.onPrimary : cs.onSurface;
    final iconColor = selected
        ? cs.onPrimary
        : featured
            ? cs.onPrimaryContainer
            : cs.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 110,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: featured && !selected
              ? Border.all(color: cs.surfaceContainerLowest, width: 3)
              : null,
          boxShadow: featured && !selected
              ? [
                  BoxShadow(
                    color: cs.onSurface.withValues(alpha: 0.06),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: selected
                    ? cs.onPrimary.withValues(alpha: 0.15)
                    : cs.surfaceContainerLowest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: fgColor,
                      height: 1.2,
                    ),
                  ),
                  if (featured && !selected)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        t.onb_most_popular,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: cs.onPrimary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded, color: cs.primary, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryShimmer extends StatelessWidget {
  const _CategoryShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[200]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[50]!,
      child: Column(
        children: List.generate(
          4,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Step 4: Choose Your Plan (pricing tiers + guest path) ───────────────────

class _PlanPage extends StatelessWidget {
  const _PlanPage({
    required this.products,
    required this.purchasing,
    required this.isOwnedFn,
    required this.isLoggedIn,
    required this.onPurchaseOne,
    required this.onPurchaseAll,
    required this.onBack,
    required this.onStartFree,
  });

  final List<Map<String, dynamic>> products;
  final bool purchasing;
  final bool Function(Map<String, dynamic>) isOwnedFn;
  final bool isLoggedIn;
  final void Function(Map<String, dynamic>)? onPurchaseOne;
  final VoidCallback? onPurchaseAll;
  final VoidCallback onBack;
  final VoidCallback? onStartFree;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;
    final unownedProducts = products.where((p) => !isOwnedFn(p)).toList();
    final isBundle = unownedProducts.length > 1;
    final currency = products.isNotEmpty
        ? products.first['currency']?.toString() ?? 'SEK'
        : 'SEK';
    final total = unownedProducts.fold<double>(0.0, (sum, p) {
      final s = p['price']?.toString().replaceAll(',', '.').trim() ?? '';
      return sum + (double.tryParse(s) ?? 0.0);
    });

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StepHeader(
                  stepLabel: t.onb_step_of
                      .replaceAll('{current}', '4')
                      .replaceAll('{total}', '4'),
                  headlinePlain: t.onb_step4_plain,
                  headlineItalic: t.onb_step4_italic,
                ),
                const SizedBox(height: 6),
                Text(
                  t.onb_step4_subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),
                if (products.isEmpty)
                  Center(
                    child: Text(
                      t.onb_no_plan_selected,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14),
                    ),
                  )
                else
                  Column(
                    children: [
                      for (int i = 0; i < products.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _PlanTierCard(
                            product: products[i],
                            featured: i == 0,
                            purchasing: purchasing,
                            owned: isOwnedFn(products[i]),
                            onBuy: onPurchaseOne == null
                                ? null
                                : () => onPurchaseOne!(products[i]),
                          ),
                        ),
                    ],
                  ),
                if (isBundle) ...[
                  const SizedBox(height: 4),
                  _BundleRow(total: total, currency: currency),
                  const SizedBox(height: 16),
                  _PrimaryButton(
                    label: t.onb_buy_bundle.replaceAll('{price}',
                        '${(total * 0.8).toStringAsFixed(2)} $currency'),
                    onPressed: onPurchaseAll,
                  ),
                ],
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    t.onb_free_trial,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      color: cs.outline,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: cs.outlineVariant)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        Translations.of(context).auth_or,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: cs.outline,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: cs.outlineVariant)),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: purchasing ? null : onStartFree,
                    style: TextButton.styleFrom(
                      foregroundColor: cs.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      isLoggedIn ? t.onb_skip_for_now : t.onb_start_free,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: _NavRow(
            onBack: onBack,
            onNext: null,
            nextLabel: t.onb_continue,
          ),
        ),
      ],
    );
  }
}

class _PlanTierCard extends StatelessWidget {
  const _PlanTierCard({
    required this.product,
    required this.featured,
    required this.purchasing,
    required this.owned,
    required this.onBuy,
  });

  final Map<String, dynamic> product;
  final bool featured;
  final bool purchasing;
  final bool owned;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;
    final title = product['name']?.toString().trim().isNotEmpty == true
        ? product['name'].toString()
        : t.onb_no_plan_selected;
    final price = _formatProductPrice(product, context);
    final duration = _formatProductDuration(product);

    if (featured) {
      // Dark highlighted "Best Value" card
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: cs.inverseSurface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: cs.primary, width: 3),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.15),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  title,
                  style: GoogleFonts.lexend(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: cs.onInverseSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  price,
                  style: GoogleFonts.lexend(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: cs.inversePrimary,
                    height: 1,
                  ),
                ),
                if (duration != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      duration,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.secondaryContainer,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                _PlanFeatureRow(
                  label: t.onb_feature_mock_exams,
                  color: cs.secondaryContainer,
                  textColor: cs.onInverseSurface.withValues(alpha: 0.9),
                ),
                const SizedBox(height: 10),
                _PlanFeatureRow(
                  label: t.onb_feature_progress_tracking,
                  color: cs.secondaryContainer,
                  textColor: cs.onInverseSurface.withValues(alpha: 0.9),
                ),
                const SizedBox(height: 10),
                _PlanFeatureRow(
                  label: t.onb_feature_explanations,
                  color: cs.secondaryContainer,
                  textColor: cs.onInverseSurface.withValues(alpha: 0.9),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: purchasing ? null : onBuy,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          owned ? const Color(0xFF059669) : cs.primary,
                      foregroundColor: cs.onPrimary,
                      disabledBackgroundColor:
                          cs.primary.withValues(alpha: 0.3),
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    child: purchasing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: AppLoadingIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            owned ? t.bcd_start_practice : t.onb_get_best_deal,
                            style: GoogleFonts.lexend(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          // BEST VALUE badge
          Positioned(
            top: -14,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: [
                    BoxShadow(
                      color: cs.onSurface.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  t.onb_best_value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: cs.onSecondaryContainer,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Standard non-featured card
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: cs.surfaceContainerHighest, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.lexend(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            price,
            style: GoogleFonts.lexend(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
              height: 1,
            ),
          ),
          if (duration != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                duration,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: cs.outline,
                ),
              ),
            ),
          const SizedBox(height: 20),
          _PlanFeatureRow(
            label: t.onb_feature_mock_exams,
            color: cs.primary,
            textColor: cs.onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          _PlanFeatureRow(
            label: t.onb_feature_progress_tracking,
            color: cs.primary,
            textColor: cs.onSurfaceVariant,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: owned
                ? ElevatedButton(
                    onPressed: purchasing ? null : onBuy,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    child: purchasing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: AppLoadingIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            t.bcd_start_practice,
                            style: GoogleFonts.lexend(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                  )
                : OutlinedButton(
                    onPressed: purchasing ? null : onBuy,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: cs.primary, width: 2),
                      shape: const StadiumBorder(),
                      foregroundColor: cs.primary,
                    ),
                    child: purchasing
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: AppLoadingIndicator(
                              strokeWidth: 2,
                              color: cs.primary,
                            ),
                          )
                        : Text(
                            t.onb_choose_plan,
                            style: GoogleFonts.lexend(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PlanFeatureRow extends StatelessWidget {
  const _PlanFeatureRow({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.check_circle_rounded, color: color, size: 18),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

class _BundleRow extends StatelessWidget {
  const _BundleRow({required this.total, required this.currency});

  final double total;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;
    final bundlePrice = total * 0.8;
    final savings = total * 0.2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.secondaryContainer, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_offer_rounded, size: 18, color: cs.secondary),
              const SizedBox(width: 8),
              Text(
                t.onb_bundle_discount_title,
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cs.secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '–20%',
                  style: GoogleFonts.lexend(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: cs.onSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${t.onb_bundle_saving.replaceAll('{amount}', '${savings.toStringAsFixed(2)} $currency')} · ',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                ),
              ),
              Text(
                '${total.toStringAsFixed(2)} $currency',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: cs.outline,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const Spacer(),
              Text(
                '${bundlePrice.toStringAsFixed(2)} $currency',
                style: GoogleFonts.lexend(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: cs.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

IconData _iconForProduct(Map<String, dynamic> product) {
  final name = (product['name']?.toString() ?? '').toLowerCase();
  if (name.contains('motorcykel') ||
      name.contains(' mc ') ||
      name.startsWith('mc ')) {
    return Icons.two_wheeler_rounded;
  }
  if (name.contains('buss')) return Icons.directions_bus_rounded;
  if (name.contains('lastbil')) return Icons.local_shipping_rounded;
  if (name.contains('åkeri') || name.contains('gods')) {
    return Icons.warehouse_rounded;
  }
  if (name.contains('b-körkort') || name.contains('personbil')) {
    return Icons.directions_car_rounded;
  }
  if (name.contains('taxi')) return Icons.local_taxi_rounded;
  if (name.contains('vägmärke')) return Icons.signpost_rounded;
  return Icons.workspace_premium_rounded;
}

String _formatProductPrice(Map<String, dynamic> product, BuildContext context) {
  final price = product['price']?.toString().trim() ?? '';
  final currency = product['currency']?.toString().trim() ?? '';
  if (price.isEmpty && currency.isEmpty) {
    return Translations.of(context).onb_price_unavailable;
  }
  if (price.isEmpty) return currency;
  if (currency.isEmpty) return price;
  return '$price $currency';
}

String? _formatProductDuration(Map<String, dynamic> product) {
  final rawDuration = product['duration_days'];
  final days = rawDuration is num
      ? rawDuration.toInt()
      : int.tryParse('${rawDuration ?? ''}');
  if (days == null || days <= 0) return null;
  if (days >= 365) return '${(days / 365).round()} year access';
  if (days >= 30) return '${(days / 30).round()} months access';
  return days == 1 ? '1 day' : '$days days';
}

// ─── Pre-purchase account choice ─────────────────────────────────────────────

enum _PrePurchaseChoice { signIn, guest }

class _PrePurchaseSheet extends StatelessWidget {
  const _PrePurchaseSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark ? cs.surface : theme.scaffoldBackgroundColor;
    final t = Translations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 0, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Text(
            t.onb_pre_purchase_title,
            style: GoogleFonts.lexend(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t.onb_pre_purchase_subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Sign In — gradient button
          AppButton(
            label: t.onb_pre_purchase_sign_in,
            height: 54,
            onPressed: () => Navigator.pop(context, _PrePurchaseChoice.signIn),
          ),
          const SizedBox(height: 16),
          // Continue as Guest — text link
          GestureDetector(
            onTap: () => Navigator.pop(context, _PrePurchaseChoice.guest),
            child: Text(
              t.onb_pre_purchase_guest,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
