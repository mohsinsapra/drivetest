import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/api/dio_client.dart';
import 'package:taxi_exam_app/features/intro/intro_screen.dart';
import 'package:taxi_exam_app/features/auth/auth_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  // WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  Stripe.publishableKey = 'pk_test_on1dP7jlAmwx5V1vG02ktjF200G4XQHemE';
  Stripe.merchantIdentifier =
      'merchant.com.yourapp.identifier'; // Required for Apple Pay
  Stripe.urlScheme = 'your-url-scheme'; // Required for certain payment methods

  await DioClient().init(); // Initialize DioClient and load tokens.

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Combined initialization to check onboarding and authentication
  Future<Map<String, bool>> _initializeApp() async {
    final prefs = await SharedPreferences.getInstance();
    bool onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    bool isAuthenticated = DioClient().refreshToken != null;

    return {
      'onboardingComplete': onboardingComplete,
      'isAuthenticated': isAuthenticated,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, bool>>(
      future: _initializeApp(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        bool onboardingComplete = snapshot.data!['onboardingComplete']!;
        bool isAuthenticated = snapshot.data!['isAuthenticated']!;

        // Decide which screen to show based on onboarding and authentication
        if (!onboardingComplete) {
          return const MaterialApp(
            home: IntroScreen(),
          );
        } else if (isAuthenticated) {
          return const MaterialApp(
            home: AuthScreen(), // Replace with your main authenticated screen
          );
        } else {
          return const MaterialApp(
            home: AuthScreen(), // Navigate to AuthScreen for login
          );
        }
      },
    );
  }
}
