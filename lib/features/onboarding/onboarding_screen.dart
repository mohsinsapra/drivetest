import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/api/dio_client.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/services/bcd_cache.dart';
import 'package:taxi_exam_app/core/services/stripe_payment_service.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'package:taxi_exam_app/features/auth/auth_bottom_sheet.dart';
import 'package:taxi_exam_app/features/auth/auth_screen.dart';
import 'package:taxi_exam_app/features/bcd/bcd_category_hub_screen.dart';
import 'package:taxi_exam_app/features/bcd/bcd_sub_category_screen.dart';
import 'package:taxi_exam_app/features/payment/subscription_success_overlay.dart';
import 'package:taxi_exam_app/main_screen.dart';

typedef OnboardingLoadProducts = Future<List<Map<String, dynamic>>> Function();
typedef OnboardingIsLoggedIn = bool Function();
typedef OnboardingAuthSheet = Future<bool> Function(BuildContext context);
typedef OnboardingPayment = Future<void> Function(
  BuildContext context,
  List<Map<String, dynamic>> products,
);
typedef OnboardingSuccessOverlay = Future<SubscriptionSuccessResult?> Function(
  BuildContext context,
  List<Map<String, dynamic>> products,
);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    this.loadProducts = _defaultLoadProducts,
    this.isLoggedIn = _defaultIsLoggedIn,
    this.showAuthSheet = _defaultShowAuthSheet,
    this.processPayment = _defaultProcessPayment,
    this.showSuccessOverlay = _defaultShowSuccessOverlay,
  });

  final OnboardingLoadProducts loadProducts;
  final OnboardingIsLoggedIn isLoggedIn;
  final OnboardingAuthSheet showAuthSheet;
  final OnboardingPayment processPayment;
  final OnboardingSuccessOverlay showSuccessOverlay;

  static Future<List<Map<String, dynamic>>> _defaultLoadProducts() async {
    final raw = await ApiService().fetchBCDSubscriptionProducts();
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  static Future<bool> _defaultShowAuthSheet(BuildContext context) async {
    if (DioClient().accessToken != null) return true;
    return showAuthBottomSheet(context);
  }

  static bool _defaultIsLoggedIn() => DioClient().accessToken != null;

  static Future<void> _defaultProcessPayment(
    BuildContext context,
    List<Map<String, dynamic>> products,
  ) async {
    final api = ApiService();
    final currency = products.first['currency']?.toString() ?? 'SEK';
    String? capturedIntentId;

    if (products.length == 1) {
      final product = products.first;
      await processStripePayment(
        context,
        createIntent: () async {
          final secret = await api.createBCDPaymentIntent(product['id'] as int);
          capturedIntentId = secret.split('_secret_').first;
          return secret;
        },
        merchantName: 'Drive Test',
        subtitle: product['name']?.toString() ?? 'Subscription',
        displayAmount: product['price']?.toString() ?? '',
        currency: currency,
      );
    } else {
      final productIds = products.map((p) => p['id'] as int).toList();
      final total = _sumPrices(products);
      final names = products
          .map((p) => p['name']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .join(' + ');
      await processStripePayment(
        context,
        createIntent: () async {
          final secret = await api.createBCDBundlePaymentIntent(productIds);
          capturedIntentId = secret.split('_secret_').first;
          return secret;
        },
        merchantName: 'Drive Test',
        subtitle: names,
        displayAmount: total.toStringAsFixed(2),
        currency: currency,
      );
    }

    if (capturedIntentId != null) {
      try {
        await api.confirmBCDPayment(capturedIntentId!);
      } catch (_) {}
    }
  }

  static Future<SubscriptionSuccessResult?> _defaultShowSuccessOverlay(
    BuildContext context,
    List<Map<String, dynamic>> products,
  ) async {
    final currency = products.first['currency']?.toString() ?? 'SEK';
    final name = products.length == 1
        ? products.first['name']?.toString() ?? 'Subscription'
        : products
            .map((p) => p['name']?.toString() ?? '')
            .where((n) => n.isNotEmpty)
            .join(' & ');
    final totalPrice = products.length == 1
        ? products.first['price']?.toString() ?? ''
        : _sumPrices(products).toStringAsFixed(2);
    final maxDays = products.fold<int>(0, (max, p) {
      final d = (p['duration_days'] as num?)?.toInt() ?? 0;
      return d > max ? d : max;
    });
    final duration = maxDays <= 0
        ? null
        : maxDays >= 365
            ? '${(maxDays / 365).round()} year'
            : maxDays >= 30
                ? '${(maxDays / 30).round()} months'
                : '$maxDays days';
    return showSubscriptionSuccess(
      context,
      productName: name,
      duration: duration,
      amount: totalPrice,
      currency: currency,
    );
  }

  static double _sumPrices(List<Map<String, dynamic>> products) =>
      products.fold(0.0, (sum, p) {
        final s = p['price']?.toString().replaceAll(',', '.').trim() ?? '';
        return sum + (double.tryParse(s) ?? 0.0);
      });

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

  // Step 0 — exam date
  DateTime? _examDeadline;
  _DateOption? _selectedDateOption;

  // Step 0 — weekday study schedule (0=Mon … 6=Sun), default Mon–Fri
  Set<int> _selectedWeekdays = {0, 1, 2, 3, 4};

  @override
  void initState() {
    super.initState();
    _fetchProductsInBackground();
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
      if (_examDeadline != null) {
        await prefs.setString(
            'exam_deadline', _examDeadline!.toIso8601String());
      }
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
      AppPageRoute(builder: (_) => const AuthScreen()),
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

  Future<void> _handlePurchaseTap({Map<String, dynamic>? only}) async {
    final products = only != null
        ? [only]
        : List<Map<String, dynamic>>.from(_selectedProducts);
    if (products.isEmpty || !mounted || _purchaseInFlight) return;

    setState(() => _purchaseInFlight = true);

    if (!widget.isLoggedIn()) {
      final authed = await widget.showAuthSheet(context);
      if (!authed || !mounted) {
        if (mounted) setState(() => _purchaseInFlight = false);
        return;
      }
    }

    await _saveProgressPrefs();
    if (!mounted) return;

    try {
      try {
        await widget.processPayment(context, products);
      } on stripe.StripeException catch (e) {
        if (!mounted) return;
        final msg = e.error.localizedMessage ?? '';
        if (!msg.toLowerCase().contains('cancel')) {
          showAppSnackBar(msg, type: SnackBarType.error);
        }
        return;
      } catch (_) {
        if (!mounted) return;
        showAppSnackBar(
          Translations.of(context).bcd_payment_failed,
          type: SnackBarType.error,
        );
        return;
      }

      await _markOnboardingComplete();
      if (!mounted) return;

      await DioClient().clearCache();
      BcdCache.instance.invalidate();
      await BcdCache.instance.ensureLoaded();

      if (!mounted) return;

      SubscriptionSuccessResult? result;
      try {
        result = await widget.showSuccessOverlay(context, products);
      } catch (_) {}

      if (!mounted) return;

      final navigator = Navigator.of(context);
      Map<String, dynamic>? targetCategory;
      if (result == SubscriptionSuccessResult.startTests) {
        for (final p in products) {
          final categoryBcdIds = p['category_bcd_ids'] as List<dynamic>?;
          final targetBcdId = categoryBcdIds?.firstOrNull;
          if (targetBcdId != null) {
            final targetBcdIdStr = targetBcdId.toString();
            targetCategory = BcdCache.instance.categories.firstWhereOrNull(
              (c) => c['bcd_id']?.toString() == targetBcdIdStr,
            );
            if (targetCategory != null) break;
          }
        }
      }

      navigator
          .pushReplacement(AppPageRoute(builder: (_) => const MainScreen()));

      if (targetCategory != null) {
        final hasChildren = targetCategory['has_children'] == true;
        final route = hasChildren
            ? AppPageRoute(
                builder: (_) =>
                    BCDSubCategoryScreen(parentCategory: targetCategory!),
              )
            : AppPageRoute(
                builder: (_) => BCDCategoryHubScreen(category: targetCategory!),
              );
        navigator.push(route);
      }
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
                      if (_selectedProducts.contains(product)) {
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
                  // Step 4: Choose Your Plan
                  _PlanPage(
                    products: _selectedProducts,
                    purchasing: _purchaseInFlight,
                    onPurchaseOne: _purchaseInFlight
                        ? null
                        : (p) => _handlePurchaseTap(only: p),
                    onPurchaseAll:
                        _selectedProducts.isEmpty || _purchaseInFlight
                            ? null
                            : () => _handlePurchaseTap(),
                    onBack: _goBack,
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
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
      child: Row(
        children: [
          Text(
            t.onb_top_bar_title,
            style: GoogleFonts.lexend(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: cs.primary,
            ),
          ),
          const Spacer(),
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
        RichText(
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

  final _DateOption? selectedDateOption;
  final DateTime? examDeadline;
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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
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
              Icon(Icons.calendar_today_rounded, color: cs.primary, size: 20),
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
                    selectedDateOption == _DateOption.custom &&
                            examDeadline != null
                        ? '${examDeadline!.day}/${examDeadline!.month}/${examDeadline!.year}'
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
          if (examDeadline != null) ...[
            const SizedBox(height: 16),
            _DeadlineBanner(deadline: examDeadline!),
          ],
          const SizedBox(height: 32),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
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
                    Icon(Icons.flash_on_rounded, color: cs.secondary, size: 20),
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
          const SizedBox(height: 32),
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

// ─── Step 2: Choose Your Plan (pricing tiers) ─────────────────────────────────

class _PlanPage extends StatelessWidget {
  const _PlanPage({
    required this.products,
    required this.purchasing,
    required this.onPurchaseOne,
    required this.onPurchaseAll,
    required this.onBack,
  });

  final List<Map<String, dynamic>> products;
  final bool purchasing;
  final void Function(Map<String, dynamic>)? onPurchaseOne;
  final VoidCallback? onPurchaseAll;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isBundle = products.length > 1;
    final currency = products.isNotEmpty
        ? products.first['currency']?.toString() ?? 'SEK'
        : 'SEK';
    final total = products.fold<double>(0.0, (sum, p) {
      final s = p['price']?.toString().replaceAll(',', '.').trim() ?? '';
      return sum + (double.tryParse(s) ?? 0.0);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
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
              label: t.onb_buy_bundle.replaceAll(
                  '{price}', '${(total * 0.8).toStringAsFixed(2)} $currency'),
              onPressed: onPurchaseAll,
            ),
          ],
          const SizedBox(height: 20),
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
          const SizedBox(height: 20),
          _NavRow(
            onBack: onBack,
            onNext: null,
            nextLabel: t.onb_continue,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {},
              child: Text(
                t.onb_restore_purchases,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: cs.outline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanTierCard extends StatelessWidget {
  const _PlanTierCard({
    required this.product,
    required this.featured,
    required this.purchasing,
    required this.onBuy,
  });

  final Map<String, dynamic> product;
  final bool featured;
  final bool purchasing;
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
                      backgroundColor: cs.primary,
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
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            t.onb_get_best_deal,
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
            child: OutlinedButton(
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
                      child: CircularProgressIndicator(
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
