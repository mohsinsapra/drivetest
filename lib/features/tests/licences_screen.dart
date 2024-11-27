// features/tests/licence_types_screen.dart

import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/features/tests/custom_test_screen.dart';
import 'package:taxi_exam_app/features/tests/test_screen.dart';
import 'package:taxi_exam_app/features/payment/payment_method_sheet.dart'; // Import the PaymentMethodSheet
import 'package:flutter_stripe/flutter_stripe.dart';

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

  @override
  void initState() {
    super.initState();
    _loadLicenseTypes();
    _initializeStripe();
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
      // Show the Payment Method Modal Bottom Sheet
      setState(() {
        selectedCategory = category;
      });
      _openPaymentMethodSheet();
      return;
    }

    setState(() {
      selectedCategory = category;
      isShowingTestOptions = true;
    });
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
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Taxi Exam App',
          // Optional: Configure Apple Pay
          applePay: const PaymentSheetApplePay(
            merchantCountryCode: 'SV', // Replace with your country code
          ),
          // Optional: Configure Google Pay
          googlePay: const PaymentSheetGooglePay(
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
      await Stripe.instance.presentPaymentSheet();

      // If the payment is successful, execute the following
      print('Payment successful');
      _showSnackBar('Payment successful');

      // Optionally, update the category subscription status
      setState(() {
        if (selectedCategory != null) {
          selectedCategory!['is_subscribed'] = true;
          isShowingTestOptions = true;
        }
      });
    } catch (e) {
      // Handle Stripe-specific errors
      if (e is StripeException) {
        print('Payment canceled or failed: ${e.error.localizedMessage}');
        _showSnackBar('Payment failed: ${e.error.localizedMessage}');
      } else {
        // Handle other types of errors
        print('Payment failed: $e');
        // _showSnackBar('Payment failed: $e');
      }
      throw e; // Re-throw the exception if you need to handle it further up the call stack
    }
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

      // Step 3: Show success message
      _showSnackBar('Payment successful');

      // Optionally, update the category subscription status
      setState(() {
        if (selectedCategory != null) {
          selectedCategory!['is_subscribed'] = true;
          isShowingTestOptions = true;
        }
      });
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : isShowingTestOptions
              ? _buildTestOptionsView()
              : isShowingCategories
                  ? _buildCategoriesView()
                  : _buildLicenseTypesView(),
    );
  }

  Widget _buildLicenseTypesView() {
    return RefreshIndicator(
      onRefresh: _loadLicenseTypes,
      child: ListView.builder(
        itemCount: licenseTypes.length,
        itemBuilder: (context, index) {
          final licenseType = licenseTypes[index];
          return Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ElevatedButton(
              onPressed: () => _onLicenseTypePressed(licenseType),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: Text(
                licenseType['name'],
                style: const TextStyle(fontSize: 16),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesView() {
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: ElevatedButton(
            onPressed: () => _onCategoryPressed(category),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              minimumSize:
                  const Size(double.infinity, 48), // Ensure consistent width
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    category['name'],
                    style: const TextStyle(fontSize: 16),
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis, // Handle long text gracefully
                  ),
                  Icon(
                    category['is_subscribed'] == false
                        ? Icons.lock
                        : Icons.lock_open,
                    size: 20,
                  ),
                ],
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
        'onPressed': () async {
          final fetchedQuestions = await _apiService.fetchQuestions(
              selectedLicenseType?['licence_id'],
              selectedCategory?['category_id']);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Testscreen(
                  questions: fetchedQuestions, // List of questions from API
                  instantMarking: true, // Enable or disable instant marking
                  licenceId: selectedLicenseType?['licence_id'],
                  categoryId: selectedCategory?['category_id']),
            ),
          );
        },
      },
      {
        'label': 'Create custom Test',
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
        'onPressed': () {
          _showSnackBar('Saved Questions for ${selectedCategory?['name']}');
        },
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: testOptions.length,
      itemBuilder: (context, index) {
        final option = testOptions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
            ),
            onPressed: option['onPressed'],
            child: Text(
              option['label'],
              style: const TextStyle(fontSize: 16),
            ),
          ),
        );
      },
    );
  }
}
