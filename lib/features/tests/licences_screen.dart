import 'dart:io';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/services/analytics_service.dart';
import 'package:taxi_exam_app/core/widgets/category_card_widget.dart';
import 'package:taxi_exam_app/core/widgets/licence_type_card_widget.dart';
import 'package:taxi_exam_app/core/widgets/test_option_card_widget.dart';
import 'package:taxi_exam_app/features/payment/payment_method_sheet.dart';
import 'package:taxi_exam_app/features/tests/custom_test_screen.dart';
import 'package:taxi_exam_app/features/tests/test_screen.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:vibration/vibration.dart';

// import '../widgets/license_type_card_widget.dart';
// import '../widgets/category_card.dart';
// import '../widgets/test_option_card.dart';

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
  late PlayerState _playerState;
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

  Future<void> _loadLicenseTypes() async {
    setState(() => isLoading = true);
    try {
      final licenses = await _apiService.fetchLicenses();

      if (!mounted) return;
      setState(() => licenseTypes = licenses);
      setState(() => isLoading = false);
    } catch (e) {
      _showSnackBar('Error fetching license types: $e');
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadCategories(String licenceTypeId) async {
    setState(() => isLoading = true);
    try {
      final fetchedCategories =
          await _apiService.fetchCategories(licenceTypeId);
      if (!mounted) return;
      setState(() {
        categories = fetchedCategories;
        isShowingCategories = true;
      });
      setState(() => isLoading = false);
    } catch (e) {
      _showSnackBar('Error fetching categories: $e');
    } finally {
      setState(() => isLoading = false);
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
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                // Track when user cancels purchase
                _analyticsService.logPurchaseCancelled(
                  licenceId: selectedLicenseType?['licence_id'] ?? '',
                  categoryId: selectedCategory?['category_id'] ?? '',
                );
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
            ElevatedButton(
              child: const Text('Buy Now'),
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
                _openPaymentMethodSheet(); // Proceed to payment
              },
            ),
          ],
        );
      },
    );
  }

  // Updated initiatePayment function with paymentMethod parameter
  Future<void> initiatePayment(int amount, String paymentMethod) async {
    try {
      // Step 1: Create Payment Intent

      String clientSecret = await _apiService.createPaymentIntent(
          amount,
          paymentMethod,
          selectedLicenseType?['licence_id'],
          selectedCategory?['category_id']);

      // Step 2: Confirm Payment
      await processPayment(clientSecret);

      // Step 3: Update the category subscription status
      setState(() {
        if (selectedCategory != null) {
          selectedCategory!['is_subscribed'] = true;
          isShowingTestOptions = true;
        }
      });

      // Step 4: Track successful purchase
      await _analyticsService.logPurchaseSuccess(
        licenceId: selectedLicenseType?['licence_id'] ?? '',
        licenceName: selectedLicenseType?['name'] ?? '',
        categoryId: selectedCategory?['category_id'] ?? '',
        categoryName: selectedCategory?['name'] ?? '',
        amount: amount / 100.0, // Convert cents to currency
        currency: 'SEK',
        transactionId: DateTime.now().millisecondsSinceEpoch.toString(),
      );

      // Step 5: Trigger Vibration
      await _triggerVibration();
      _confettiControllerLeft.play();
      _confettiControllerBottom.play();
      _confettiControllerTop.play();

      _confettiControllerRight.play();
      // Step 6: Show Success SnackBar
      _showSnackBar('Payment successful');
    } catch (e) {
      // Track failed purchase
      await _analyticsService.logPurchaseFailure(
        licenceId: selectedLicenseType?['licence_id'] ?? '',
        categoryId: selectedCategory?['category_id'] ?? '',
        errorMessage: e.toString(),
      );

      // Handle errors (e.g., show error message to user)
      _showSnackBar('Payment failed: $e');
    }
  }

  // Function to open the Payment Method Modal Bottom Sheet
  void _openPaymentMethodSheet() {
    // Track when payment method sheet is opened
    _analyticsService.logPaymentMethodSheetOpened(
      licenceId: selectedLicenseType?['licence_id'] ?? '',
      categoryId: selectedCategory?['category_id'] ?? '',
    );

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return PaymentMethodSheet(
          onSelected: (method) {
            // Track payment method selection
            _analyticsService.logPaymentMethodSelected(
              paymentMethod: method,
              licenceId: selectedLicenseType?['licence_id'] ?? '',
              categoryId: selectedCategory?['category_id'] ?? '',
            );

            Navigator.pop(context); // Close the bottom sheet
            // Initiate payment with the selected method
            initiatePayment(10000, method);
          },
        );
      },
    );
  }

  Future<void> _triggerVibration() async {
    if (Platform.isIOS) {
      for (int i = 0; i < 3; i++) {
        // Number of repetitions
        HapticFeedback.mediumImpact();
        await Future.delayed(
            const Duration(milliseconds: 100)); // Delay between feedbacks
      }
    } else if (Platform.isAndroid) {
      // Use Vibration package for Android
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        Vibration.vibrate(duration: 500); // Vibrate for 500 milliseconds
      }
    }
  }

  Future<void> processPayment(String clientSecret) async {
    try {
      // Initialize the PaymentSheet with the required parameters
      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Drive Test',
          // Optional: Configure Apple Pay
          applePay: const stripe.PaymentSheetApplePay(
            merchantCountryCode: 'SV', // Replace with your country code
          ),
          // Optional: Configure Google Pay
          googlePay: const stripe.PaymentSheetGooglePay(
            merchantCountryCode: 'SV', // Replace with your country code
            testEnv: true, // Set to false in production
            // existingPaymentMethodRequired: false,
          ),
          style: ThemeMode
              .light, // Choose between ThemeMode.light or ThemeMode.dark
          // Optional: Customize the appearance
          // appearance: PaymentSheetAppearance(
          //   colors: PaymentSheetAppearanceColors(
          //     primary: Colors.blue,
          //   ),
          // ),
        ),
      );

      // Present the PaymentSheet to the user
      await stripe.Stripe.instance.presentPaymentSheet();
    } catch (e) {
      // Handle Stripe-specific errors
      if (e is stripe.StripeException) {
        print('Payment canceled or failed: ${e.error.localizedMessage}');
        _showSnackBar('Payment failed: ${e.error.localizedMessage}');
      } else {
        // Handle other types of errors
        print('Payment failed: $e');
        _showSnackBar('Payment failed: $e');
      }
      throw e; // Re-throw the exception if you need to handle it further up the call stack
    }
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
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (isShowingTestOptions)
            _buildTestOptionsView()
          else if (isShowingCategories)
            _buildCategoriesView()
          else
            _buildLicenseTypesView(),
          _buildConfettiOverlays(),
        ],
      ),
    );
  }

  /* ----------------------------- Sub‑Views ------------------------------ */

  Widget _buildLicenseTypesView() {
    return RefreshIndicator(
      onRefresh: _loadLicenseTypes,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
        child: GridView.builder(
          itemCount: licenseTypes.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) {
            final licenseType = licenseTypes[index];
            return LicenseTypeCard(
              licenseType: licenseType,
              onTap: () => _onLicenseTypePressed(licenseType),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoriesView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return CategoryCard(
          category: category,
          onTap: () => {_onCategoryPressed(category)},
        );
      },
    );
  }

  Widget _buildTestOptionsView() {
    final List<Map<String, dynamic>> testOptions = [
      {
        'label': 'Start Practice Test',
        'icon': LucideIcons.playCircle,
        'color': Colors.blueAccent,
        'onPressed': () async {
          setState(() => isLoading = true);
          final fetchedQuestions = await _apiService.fetchQuestions(
            selectedLicenseType?['licence_id'],
            selectedCategory?['category_id'],
          );
          if (!mounted) return;
          setState(() => isLoading = false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Testscreen(
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
            MaterialPageRoute(
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
        'icon': LucideIcons.bookmark,
        'color': Colors.purpleAccent,
        'onPressed': () =>
            _showSnackBar('Saved Questions for ${selectedCategory?['name']}'),
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
        return TestOptionCard(
          label: option['label'],
          icon: option['icon'],
          color: option['color'],
          onTap: option['onPressed'],
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

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
