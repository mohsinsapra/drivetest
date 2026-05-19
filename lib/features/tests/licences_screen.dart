import 'package:taxi_exam_app/core/services/payment_coordinator.dart';
import 'package:taxi_exam_app/core/widgets/adaptive_refresh_indicator.dart';
import 'package:taxi_exam_app/core/widgets/app_button.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'dart:convert';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/services/analytics_service.dart';
import 'package:taxi_exam_app/core/widgets/category_card_widget.dart';
import 'package:taxi_exam_app/core/widgets/licence_type_card_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taxi_exam_app/core/widgets/test_option_card_widget.dart';
import 'package:taxi_exam_app/features/tests/custom_test_screen.dart';
import 'package:taxi_exam_app/features/tests/saved_questions_preview_screen.dart';
import 'package:taxi_exam_app/features/tests/test_screen.dart';
import 'package:taxi_exam_app/core/widgets/snackbar.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class LicenceTypesScreen extends StatefulWidget {
  const LicenceTypesScreen({super.key});

  @override
  State<LicenceTypesScreen> createState() => _LicenceTypesScreenState();
}

class _LicenceTypesScreenState extends State<LicenceTypesScreen> {
  final ApiService _apiService = ApiService();
  final AnalyticsService _analyticsService = AnalyticsService();

  // Data
  List<dynamic> licenseTypes = [];
  List<dynamic> categories = [];

  // UI state
  bool isLoading = false;
  bool isShowingCategories = false;
  bool isShowingTestOptions = false;

  Map<String, dynamic>? selectedLicenseType;
  Map<String, dynamic>? selectedCategory;

  // Confetti
  late ConfettiController _confettiControllerTop;
  late ConfettiController _confettiControllerBottom;
  late ConfettiController _confettiControllerLeft;
  late ConfettiController _confettiControllerRight;

  // YouTube
  late YoutubePlayerController _controller;
  // ignore: unused_field
  late PlayerState _playerState;
  // ignore: unused_field
  late YoutubeMetaData _videoMetaData;
  late TextEditingController _idController;
  late TextEditingController _seekToController;

  @override
  void initState() {
    super.initState();
    _loadLicenseTypes();
    _initializeStripe();

    _controller = YoutubePlayerController(
      initialVideoId: YoutubePlayer.convertUrlToId(
          'https://www.youtube.com/watch?v=XjspPudEbmc&t=1s')!,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        controlsVisibleAtStart: true,
        enableCaption: true,
        forceHD: false,
        useHybridComposition: true,
      ),
    );

    _idController = TextEditingController();
    _seekToController = TextEditingController();
    _videoMetaData = const YoutubeMetaData();
    _playerState = PlayerState.unknown;

    _confettiControllerTop =
        ConfettiController(duration: const Duration(seconds: 1));
    _confettiControllerBottom =
        ConfettiController(duration: const Duration(seconds: 1));
    _confettiControllerLeft =
        ConfettiController(duration: const Duration(seconds: 1));
    _confettiControllerRight =
        ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void deactivate() {
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _confettiControllerTop.dispose();
    _confettiControllerBottom.dispose();
    _confettiControllerLeft.dispose();
    _confettiControllerRight.dispose();
    _controller.dispose();
    _idController.dispose();
    _seekToController.dispose();
    super.dispose();
  }

  /* -------------------------------------------------------------------------- */
  /*                                 API CALLS                                 */
  /* -------------------------------------------------------------------------- */

  // Cache TTLs
  static const _licenceTtl = Duration(hours: 24);
  static const _categoryTtl = Duration(hours: 1);

  Future<void> _loadLicenseTypes() async {
    // 1. Try cache first — show immediately, no loading indicator
    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString('cache_licences');
    final cachedAt = prefs.getInt('cache_licences_at') ?? 0;
    final isFresh = DateTime.now().millisecondsSinceEpoch - cachedAt <
        _licenceTtl.inMilliseconds;

    if (cachedJson != null && isFresh) {
      final cached = (jsonDecode(cachedJson) as List).cast<dynamic>();
      if (mounted) setState(() => licenseTypes = cached);
      return; // fresh cache — skip network call entirely
    }

    // 2. Cache stale or missing — fetch from network
    if (mounted) setState(() => isLoading = true);
    try {
      final licenses = await _apiService.fetchLicenses();
      if (!mounted) return;
      // Persist to cache
      await prefs.setString('cache_licences', jsonEncode(licenses));
      await prefs.setInt(
          'cache_licences_at', DateTime.now().millisecondsSinceEpoch);
      setState(() => licenseTypes = licenses);
    } catch (e) {
      if (!mounted) return;
      // Fall back to stale cache if available
      if (cachedJson != null) {
        setState(() =>
            licenseTypes = (jsonDecode(cachedJson) as List).cast<dynamic>());
      } else {
        showAppSnackBar('Error fetching license types. Please try again.',
            type: SnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loadCategories(String licenceTypeId) async {
    // 1. Try cache first
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'cache_categories_$licenceTypeId';
    final cacheAtKey = 'cache_categories_at_$licenceTypeId';
    final cachedJson = prefs.getString(cacheKey);
    final cachedAt = prefs.getInt(cacheAtKey) ?? 0;
    final isFresh = DateTime.now().millisecondsSinceEpoch - cachedAt <
        _categoryTtl.inMilliseconds;

    if (cachedJson != null && isFresh) {
      final cached = (jsonDecode(cachedJson) as List).cast<dynamic>();
      if (mounted) {
        setState(() {
          categories = cached;
          isShowingCategories = true;
        });
      }
      return;
    }

    // 2. Fetch from network
    if (mounted) setState(() => isLoading = true);
    try {
      final fetched = await _apiService.fetchCategories(licenceTypeId);
      if (!mounted) return;
      await prefs.setString(cacheKey, jsonEncode(fetched));
      await prefs.setInt(cacheAtKey, DateTime.now().millisecondsSinceEpoch);
      setState(() {
        categories = fetched;
        isShowingCategories = true;
      });
    } catch (e) {
      if (!mounted) return;
      if (cachedJson != null) {
        setState(() {
          categories = (jsonDecode(cachedJson) as List).cast<dynamic>();
          isShowingCategories = true;
        });
      } else {
        showAppSnackBar('Error fetching categories. Please try again.',
            type: SnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                               USER ACTIONS                                */
  /* -------------------------------------------------------------------------- */

  void _onLicenseTypePressed(dynamic licenseType) {
    setState(() {
      selectedLicenseType = licenseType;
    });
    _loadCategories(licenseType['licence_id']);
  }

  void _onCategoryPressed(dynamic category) {
    if (category['is_subscribed'] == false && category['name'] != 'Karta') {
      setState(() => selectedCategory = category);
      // Track when subscription dialog is shown
      _analyticsService.logSubscriptionDialogShown(
        licenceId: selectedLicenseType?['licence_id'] ?? '',
        categoryId: category['category_id'] ?? '',
        categoryName: category['name'] ?? '',
      );
      _showSubscriptionDialog();
      return;
    }
    setState(() {
      selectedCategory = category;
      isShowingTestOptions = true;
    });
  }

  void _goBack() {
    if (isShowingTestOptions) {
      setState(() {
        isShowingTestOptions = false;
        selectedCategory = null;
      });
    } else if (isShowingCategories) {
      setState(() {
        isShowingCategories = false;
        selectedLicenseType = null;
        categories = [];
      });
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                                PAYMENT                                     */
  /* -------------------------------------------------------------------------- */

  Future<void> _initializeStripe() async {
    // TODO: Add your Stripe publishable key initialization here if needed.
  }

  // The rest of the payment‑related helper methods remain unchanged ----------------
  // (processPayment, initiatePayment, _openPaymentMethodSheet, etc.)

  // Function to show the Subscription Confirmation Dialog
  Future<void> _showSubscriptionDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Subscription Required'),
          content: const Text(
              'You do not have an active subscription for this category. Please purchase a one-month subscription for 100 kr to proceed.'),
          actions: <Widget>[
            AppTextButton(
              label: Translations.of(context).cancel,
              onPressed: () {
                // Track when user cancels purchase
                _analyticsService.logPurchaseCancelled(
                  licenceId: selectedLicenseType?['licence_id'] ?? '',
                  categoryId: selectedCategory?['category_id'] ?? '',
                );
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
            AppFilledButton(
              label: Translations.of(context).btn_buy_now,
              onPressed: () {
                // Track Buy Now button click
                _analyticsService.logBuyNowClick(
                  licenceId: selectedLicenseType?['licence_id'] ?? '',
                  licenceName: selectedLicenseType?['name'] ?? '',
                  categoryId: selectedCategory?['category_id'] ?? '',
                  categoryName: selectedCategory?['name'] ?? '',
                );

                // Track purchase attempt
                _analyticsService.logPurchaseAttempt(
                  licenceId: selectedLicenseType?['licence_id'] ?? '',
                  licenceName: selectedLicenseType?['name'] ?? '',
                  categoryId: selectedCategory?['category_id'] ?? '',
                  categoryName: selectedCategory?['name'] ?? '',
                  amount: 100.0,
                  currency: 'SEK',
                );

                Navigator.of(context).pop(); // Dismiss the dialog
                _initiatePayment(); // Proceed to payment
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _initiatePayment() async {
    _analyticsService.logPaymentMethodSheetOpened(
      licenceId: selectedLicenseType?['licence_id'] ?? '',
      categoryId: selectedCategory?['category_id'] ?? '',
    );
    final licenceName = selectedLicenseType?['name']?.toString() ?? '';
    final categoryName = selectedCategory?['name']?.toString() ?? '';
    final subtitle =
        [licenceName, categoryName].where((s) => s.isNotEmpty).join(' — ');

    final result = await PaymentCoordinator.show(
      context,
      products: [
        {
          'name': subtitle,
          'price': '100',
          'currency': 'SEK',
          'duration_days': 365,
          'is_active': true
        }
      ],
      createStripeIntent: (_) => _apiService.createPaymentIntent(
        10000,
        'card',
        selectedLicenseType?['licence_id'],
        selectedCategory?['category_id'],
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      if (selectedCategory != null) {
        selectedCategory!['is_subscribed'] = true;
        isShowingTestOptions = true;
      }
    });

    final licenceId = selectedLicenseType?['licence_id']?.toString();
    if (licenceId != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cache_categories_$licenceId');
      await prefs.remove('cache_categories_at_$licenceId');
    }

    await _analyticsService.logPurchaseSuccess(
      licenceId: selectedLicenseType?['licence_id'] ?? '',
      licenceName: licenceName,
      categoryId: selectedCategory?['category_id'] ?? '',
      categoryName: categoryName,
      amount: 100.0,
      currency: 'SEK',
      transactionId: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                                 UI BUILD                                  */
  /* -------------------------------------------------------------------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isShowingTestOptions
              ? (selectedCategory?['name'] ?? 'Test Options')
              : isShowingCategories
                  ? (selectedLicenseType?['name'] ?? 'Categories')
                  : 'Licence Types',
        ),
        leading: (isShowingCategories || isShowingTestOptions)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBack,
              )
            : null,
      ),
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.03, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                    parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              ),
            ),
            child: isLoading
                ? _buildLoadingShimmer()
                : isShowingTestOptions
                    ? KeyedSubtree(
                        key: const ValueKey('testOptions'),
                        child: _buildTestOptionsView())
                    : isShowingCategories
                        ? KeyedSubtree(
                            key: const ValueKey('categories'),
                            child: _buildCategoriesView())
                        : KeyedSubtree(
                            key: const ValueKey('licences'),
                            child: _buildLicenseTypesView()),
          ),
          _buildConfettiOverlays(),
        ],
      ),
    );
  }

  /* ----------------------------- Sub‑Views ------------------------------ */

  Widget _buildLoadingShimmer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      key: const ValueKey('loading'),
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade50,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Center(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: List.generate(
              6,
              (_) => Container(
                width: 180,
                height: 240,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLicenseTypesView() {
    const double tileWidth = 180;
    const double tileHeight = 240;

    return AdaptiveRefreshIndicator(
      onRefresh: _loadLicenseTypes,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: licenseTypes.asMap().entries.map((e) {
                  final licenseType = e.value;
                  return _LicenceStaggeredItem(
                    index: e.key,
                    child: SizedBox(
                      width: tileWidth,
                      height: tileHeight,
                      child: LicenseTypeCard(
                        licenseType: licenseType,
                        onTap: () => _onLicenseTypePressed(licenseType),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _LicenceStaggeredItem(
          index: index,
          child: CategoryCard(
            category: category,
            onTap: () => _onCategoryPressed(category),
          ),
        );
      },
    );
  }

  Widget _buildTestOptionsView() {
    Future<void> openSavedQuestions() async {
      setState(() => isLoading = true);
      try {
        final saved = await _apiService.fetchSavedQuestionsResolved(
          scopeType: 'legacy',
          licenceId: selectedLicenseType?['licence_id'],
          categoryId: selectedCategory?['category_id'],
        );

        if (!mounted) return;
        if (saved.isEmpty) {
          showAppSnackBar('No saved questions found in this category.');
          return;
        }
        Navigator.push(
          context,
          AppPageRoute(
            builder: (_) => SavedQuestionsPreviewScreen(
              questions: saved,
              licenceId: selectedLicenseType?['licence_id'],
              categoryId: selectedCategory?['category_id'],
              licenceName: selectedLicenseType?['name'],
              categoryName: selectedCategory?['name'] ?? 'Saved Questions',
            ),
          ),
        );
      } catch (_) {
        if (mounted) {
          showAppSnackBar('Failed to load saved questions.',
              type: SnackBarType.error);
        }
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }

    final List<Map<String, dynamic>> testOptions = [
      {
        'label': 'Start Practice Test',
        'icon': LucideIcons.playCircle,
        'color': Colors.blueAccent,
        'onPressed': () async {
          setState(() => isLoading = true);
          final prefs = await SharedPreferences.getInstance();
          final randomize = prefs.getBool('randomize') ?? true;
          final shuffleOnDevice = prefs.getBool('shuffleOnDevice') ?? false;
          final fetchedQuestions = await _apiService.fetchQuestions(
            selectedLicenseType?['licence_id'],
            selectedCategory?['category_id'],
            randomize: randomize,
          );
          if (shuffleOnDevice) {
            fetchedQuestions.shuffle(Random());
          }
          if (!mounted) return;
          setState(() => isLoading = false);
          Navigator.push(
            context,
            AppPageRoute(
              builder: (_) => TestscreenWrapper(
                questions: fetchedQuestions,
                instantMarking: true,
                licenceId: selectedLicenseType?['licence_id'],
                categoryId: selectedCategory?['category_id'],
                licenceName: selectedLicenseType?['name'],
                categoryName: selectedCategory?['name'],
              ),
            ),
          );
        },
      },
      {
        'label': 'Custom Test',
        'icon': LucideIcons.settings,
        'color': Colors.orangeAccent,
        'onPressed': () async {
          if (!mounted) return;
          Navigator.push(
            context,
            AppPageRoute(
              builder: (_) => CreateCustomTestScreen(
                licenceId: selectedLicenseType?['licence_id'],
                categoryId: selectedCategory?['category_id'],
                categoryName: selectedCategory?['name'],
              ),
            ),
          );
        },
      },
      {
        'label': 'Saved Questions',
        'icon': LucideIcons.bookOpenCheck,
        'color': Colors.teal,
        'onPressed': openSavedQuestions,
      },
    ];

    if (selectedCategory?['name'] == 'Karta') {
      return YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.blueAccent,
        topActions: <Widget>[
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              _controller.metadata.title,
              style: const TextStyle(color: Colors.white, fontSize: 18.0),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: testOptions.length,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, index) {
        final option = testOptions[index];
        return _LicenceStaggeredItem(
          index: index,
          child: TestOptionCard(
            label: option['label'],
            icon: option['icon'],
            color: option['color'],
            onTap: option['onPressed'],
          ),
        );
      },
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                                WIDGETS                                     */
  /* -------------------------------------------------------------------------- */

  Widget _buildConfettiOverlays() {
    return Stack(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiControllerTop,
            blastDirectionality: BlastDirectionality.explosive,
            blastDirection: pi / 2,
            emissionFrequency: 0.05,
            numberOfParticles: 10,
            maxBlastForce: 25,
            minBlastForce: 10,
            gravity: 0.2,
            shouldLoop: false,
            createParticlePath: createRandomShape,
            colors: const [
              Colors.red,
              Colors.blue,
              Colors.green,
              Colors.orange,
              Colors.purple,
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: ConfettiWidget(
            confettiController: _confettiControllerBottom,
            blastDirectionality: BlastDirectionality.explosive,
            blastDirection: -pi / 2,
            emissionFrequency: 0.05,
            numberOfParticles: 10,
            maxBlastForce: 25,
            minBlastForce: 10,
            gravity: 0.2,
            shouldLoop: false,
            createParticlePath: createRandomShape,
            colors: const [
              Colors.red,
              Colors.blue,
              Colors.green,
              Colors.orange,
              Colors.purple,
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: ConfettiWidget(
            confettiController: _confettiControllerLeft,
            blastDirectionality: BlastDirectionality.explosive,
            blastDirection: 0,
            emissionFrequency: 0.05,
            numberOfParticles: 10,
            maxBlastForce: 25,
            minBlastForce: 10,
            gravity: 0.2,
            shouldLoop: false,
            createParticlePath: createRandomShape,
            colors: const [
              Colors.red,
              Colors.blue,
              Colors.green,
              Colors.orange,
              Colors.purple,
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: ConfettiWidget(
            confettiController: _confettiControllerRight,
            blastDirectionality: BlastDirectionality.explosive,
            blastDirection: pi,
            emissionFrequency: 0.05,
            numberOfParticles: 10,
            maxBlastForce: 25,
            minBlastForce: 10,
            gravity: 0.2,
            shouldLoop: false,
            createParticlePath: createRandomShape,
            colors: const [
              Colors.red,
              Colors.blue,
              Colors.green,
              Colors.orange,
              Colors.purple,
            ],
          ),
        ),
      ],
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                          CONFETTI SHAPE HELPERS                            */
  /* -------------------------------------------------------------------------- */

  Path createRandomShape(Size size) {
    final random = Random();
    int shapeType = random.nextInt(4);

    Size smallSize = Size(size.width * 0.5, size.height * 0.5);
    switch (shapeType) {
      case 0:
        return _drawStar(smallSize);
      case 1:
        return _drawCircle(smallSize);
      case 2:
        return _drawTriangle(smallSize);
      case 3:
        return _drawDiamond(smallSize);
      default:
        return _drawCircle(smallSize);
    }
  }

  Path _drawStar(Size size) {
    double cx = size.width / 2;
    double cy = size.height / 2;
    double outerRadius = min(size.width, size.height) / 2;
    double innerRadius = outerRadius / 2.5;
    Path path = Path();
    double angle = pi / 5;

    for (int i = 0; i < 10; i++) {
      double r = (i % 2 == 0) ? outerRadius : innerRadius;
      double x = cx + r * cos(i * angle - pi / 2);
      double y = cy + r * sin(i * angle - pi / 2);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  Path _drawCircle(Size size) {
    return Path()..addOval(Rect.fromLTWH(0, 0, size.width, size.height));
  }

  Path _drawTriangle(Size size) {
    Path path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  Path _drawDiamond(Size size) {
    Path path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(0, size.height / 2);
    path.close();
    return path;
  }

  /* -------------------------------------------------------------------------- */
  /*                              UTILITIES                                     */
  /* -------------------------------------------------------------------------- */
}

// ─── Staggered entrance for licence/category/option items ────────────────────

class _LicenceStaggeredItem extends StatefulWidget {
  final int index;
  final Widget child;
  const _LicenceStaggeredItem({required this.index, required this.child});

  @override
  State<_LicenceStaggeredItem> createState() => _LicenceStaggeredItemState();
}

class _LicenceStaggeredItemState extends State<_LicenceStaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.95, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.index * 35), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: ScaleTransition(scale: _scale, child: widget.child),
          ),
        ),
      );
}
