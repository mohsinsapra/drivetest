import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/features/intro/intro_screen.dart';
import 'package:taxi_exam_app/features/auth/auth_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  await dotenv.load();
  Stripe.publishableKey = 'pk_test_on1dP7jlAmwx5V1vG02ktjF200G4XQHemE';
  Stripe.merchantIdentifier =
      'merchant.com.yourapp.identifier'; // Required for Apple Pay
  Stripe.urlScheme = 'your-url-scheme'; // Required for certain payment methods

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isOnboardingComplete(),
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
        return MaterialApp(
          home: SafeArea(
            child: snapshot.data! ? const AuthScreen() : const IntroScreen(),
          ),
        );
      },
    );
  }

  Future<bool> _isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_complete') ?? false;
  }
}
