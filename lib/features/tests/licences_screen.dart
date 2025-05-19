// features/tests/licence_types_screen.dart

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/features/tests/custom_test_screen.dart';
import 'package:taxi_exam_app/features/tests/test_screen.dart';
import 'package:taxi_exam_app/features/payment/payment_method_sheet.dart'; // Import the PaymentMethodSheet
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:vibration/vibration.dart';
import 'dart:math'; // For pi and shapes

class LicenceTypesScreen extends StatefulWidget {
  const LicenceTypesScreen({super.key});

  @override
  State<LicenceTypesScreen> createState() => _LicenceTypesScreenState();
}

class _LicenceTypesScreenState extends State<LicenceTypesScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> licenseTypes = [];
  List<dynamic> categories = [];
  bool isLoading = false;
  bool isShowingCategories = false;
  bool isShowingTestOptions = false;
  Map<String, dynamic>? selectedLicenseType;
  Map<String, dynamic>? selectedCategory;

  // ConfettiControllers for multiple directions
  late ConfettiController _confettiControllerTop;
  late ConfettiController _confettiControllerBottom;
  late ConfettiController _confettiControllerLeft;
  late ConfettiController _confettiControllerRight;

  @override
  void initState() {
    super.initState();
    _loadLicenseTypes();
    _initializeStripe();

    // Initialize ConfettiControllers with a short duration
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
  void dispose() {
    _confettiControllerTop.dispose();
    _confettiControllerBottom.dispose();
    _confettiControllerLeft.dispose();
    _confettiControllerRight.dispose();
    super.dispose();
  }

  // Initialize Stripe
  void _initializeStripe() {
    // Ensure you have set Stripe.publishableKey in main.dart
    // Additional configurations can be added here if needed
  }

  Future<void> _loadLicenseTypes() async {
    setState(() {
      isLoading = true;
    });

    try {
      final licenses = await _apiService.fetchLicenses();
      if (!mounted) return;
      setState(() {
        licenseTypes = licenses;
      });
    } catch (e) {
      _showSnackBar('Error fetching license types: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadCategories(String licenceTypeId) async {
    setState(() {
      isLoading = true;
    });

    try {
      final fetchedCategories =
          await _apiService.fetchCategories(licenceTypeId);
      if (!mounted) return;
      setState(() {
        categories = fetchedCategories;
        isShowingCategories = true;
      });
    } catch (e) {
      _showSnackBar('Error fetching categories: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onLicenseTypePressed(dynamic licenseType) {
    setState(() {
      selectedLicenseType = licenseType;
    });
    _loadCategories(licenseType['licence_id']);
  }

  void _onCategoryPressed(dynamic category) {
    if (category['is_subscribed'] == false) {
      // Show the Subscription Confirmation Dialog
      setState(() {
        selectedCategory = category;
      });
      _showSubscriptionDialog();
      return;
    }

    setState(() {
      selectedCategory = category;
      isShowingTestOptions = true;
    });
  }

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
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
            ElevatedButton(
              child: const Text('Buy Now'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
                _openPaymentMethodSheet(); // Proceed to payment
              },
            ),
          ],
        );
      },
    );
  }

  // Function to open the Payment Method Modal Bottom Sheet
  void _openPaymentMethodSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return PaymentMethodSheet(
          onSelected: (method) {
            Navigator.pop(context); // Close the bottom sheet
            // Initiate payment with the selected method
            initiatePayment(10000, method);
          },
        );
      },
    );
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
      if (hasVibrator != null && hasVibrator) {
        Vibration.vibrate(duration: 500); // Vibrate for 500 milliseconds
      }
    }
  }

  // Function to create a random shape for confetti
  Path createRandomShape(Size size) {
    final random = Random();
    int shapeType =
        random.nextInt(4); // 0: Star, 1: Circle, 2: Triangle, 3: Diamond

    // Define a smaller size for the shapes
    Size smallSize = Size(size.width * 0.5, size.height * 0.5);

    switch (shapeType) {
      case 0:
        return drawStar(smallSize);
      case 1:
        return drawCircle(smallSize);
      case 2:
        return drawTriangle(smallSize);
      case 3:
        return drawDiamond(smallSize);
      default:
        return drawStar(smallSize);
    }
  }

  // Shape Path Functions

  // Function to create a star shape
  Path drawStar(Size size) {
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

  // Function to create a circle shape
  Path drawCircle(Size size) {
    return Path()..addOval(Rect.fromLTWH(0, 0, size.width, size.height));
  }

  // Function to create a triangle shape
  Path drawTriangle(Size size) {
    Path path = Path();
    path.moveTo(size.width / 2, 0); // Top center
    path.lineTo(0, size.height); // Bottom left
    path.lineTo(size.width, size.height); // Bottom right
    path.close();
    return path;
  }

  // Function to create a diamond shape
  Path drawDiamond(Size size) {
    Path path = Path();
    path.moveTo(size.width / 2, 0); // Top center
    path.lineTo(size.width, size.height / 2); // Middle right
    path.lineTo(size.width / 2, size.height); // Bottom center
    path.lineTo(0, size.height / 2); // Middle left
    path.close();
    return path;
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

      // Step 5: Trigger Vibration
      await _triggerVibration();
      _confettiControllerLeft.play();
      _confettiControllerBottom.play();
      _confettiControllerTop.play();

      _confettiControllerRight.play();
      // Step 6: Show Success SnackBar
      _showSnackBar('Payment successful');
    } catch (e) {
      // Handle errors (e.g., show error message to user)
      _showSnackBar('Payment failed: $e');
    }
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

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
          // Existing body content
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : isShowingTestOptions
                  ? _buildTestOptionsView()
                  : isShowingCategories
                      ? _buildCategoriesView()
                      : _buildLicenseTypesView(),

          // Confetti Widgets
          // Top-Center Blast
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiControllerTop,
              blastDirectionality: BlastDirectionality.explosive,
              blastDirection: pi / 2, // downward
              emissionFrequency: 0.05,
              numberOfParticles: 10,
              maxBlastForce: 25, // Increased for faster movement
              minBlastForce: 10,
              gravity: 0.2, // Reduced gravity for slower fall
              shouldLoop: false,
              createParticlePath: createRandomShape,
              colors: const [
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.orange,
                Colors.purple
              ],
            ),
          ),

          // Bottom-Center Blast
          Align(
            alignment: Alignment.bottomCenter,
            child: ConfettiWidget(
              confettiController: _confettiControllerBottom,
              blastDirectionality: BlastDirectionality.explosive,
              blastDirection: -pi / 2, // upward
              emissionFrequency: 0.05,
              numberOfParticles: 10,
              maxBlastForce: 25, // Increased for faster movement
              minBlastForce: 10,
              gravity: 0.2, // Reduced gravity for slower fall
              shouldLoop: false,
              createParticlePath: createRandomShape,
              colors: const [
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.orange,
                Colors.purple
              ],
            ),
          ),

          // Left-Center Blast
          Align(
            alignment: Alignment.centerLeft,
            child: ConfettiWidget(
              confettiController: _confettiControllerLeft,
              blastDirectionality: BlastDirectionality.explosive,
              blastDirection: 0, // to the right
              emissionFrequency: 0.05,
              numberOfParticles: 10,
              maxBlastForce: 25, // Increased for faster movement
              minBlastForce: 10,
              gravity: 0.2, // Reduced gravity for slower fall
              shouldLoop: false,
              createParticlePath: createRandomShape,
              colors: const [
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.orange,
                Colors.purple
              ],
            ),
          ),

          // Right-Center Blast
          Align(
            alignment: Alignment.centerRight,
            child: ConfettiWidget(
              confettiController: _confettiControllerRight,
              blastDirectionality: BlastDirectionality.explosive,
              blastDirection: pi, // to the left
              emissionFrequency: 0.05,
              numberOfParticles: 10,
              maxBlastForce: 25, // Increased for faster movement
              minBlastForce: 10,
              gravity: 0.2, // Reduced gravity for slower fall
              shouldLoop: false,
              createParticlePath: createRandomShape,
              colors: const [
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.orange,
                Colors.purple
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseTypesView() {
    return RefreshIndicator(
      onRefresh: _loadLicenseTypes,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
        child: GridView.builder(
          itemCount: licenseTypes.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 columns
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio:
                0.75, // Adjust as needed for taller or wider cards
          ),
          itemBuilder: (context, index) {
            final licenseType = licenseTypes[index];
            return GestureDetector(
              onTap: () => _onLicenseTypePressed(licenseType),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Optional image at the top
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: Image(
                        image: (licenseType['image'] != null &&
                                licenseType['image']
                                    .toString()
                                    .startsWith('http'))
                            ? NetworkImage(licenseType['image'])
                            : const AssetImage('assets/icon/icon.png')
                                as ImageProvider,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset(
                          'assets/icon/icon.png',
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            licenseType['name'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoriesView() {
    return ListView.builder(
      itemCount: categories.length,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemBuilder: (context, index) {
        final category = categories[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _onCategoryPressed(category),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20.0,
                  horizontal: 20.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        category['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    CircleAvatar(
                      backgroundColor: category['is_subscribed'] == false
                          ? Colors.red.withOpacity(0.15)
                          : Colors.green.withOpacity(0.15),
                      radius: 18,
                      child: Icon(
                        category['is_subscribed'] == false
                            ? LucideIcons.lock
                            : LucideIcons.unlock,
                        size: 20,
                        color: category['is_subscribed'] == false
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
          final fetchedQuestions = await _apiService.fetchQuestions(
            selectedLicenseType?['licence_id'],
            selectedCategory?['category_id'],
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Testscreen(
                questions: fetchedQuestions,
                instantMarking: true,
                licenceId: selectedLicenseType?['licence_id'],
                categoryId: selectedCategory?['category_id'],
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
        'onPressed': () {
          _showSnackBar('Saved Questions for ${selectedCategory?['name']}');
        },
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        itemCount: testOptions.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemBuilder: (context, index) {
          final option = testOptions[index];
          return GestureDetector(
            onTap: option['onPressed'],
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          (option['color'] as Color).withOpacity(0.1),
                      radius: 28,
                      child: Icon(
                        option['icon'],
                        color: option['color'],
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      option['label'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
