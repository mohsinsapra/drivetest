import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:taxi_exam_app/core/api/dio_client.dart';
import 'package:taxi_exam_app/core/models/option.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/features/intro/intro_screen.dart';
import 'package:taxi_exam_app/features/auth/auth_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:taxi_exam_app/main_screen.dart';

import 'core/models/test_attempt.dart';

void main() async {
  // WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  Stripe.publishableKey = 'pk_test_on1dP7jlAmwx5V1vG02ktjF200G4XQHemE';
  Stripe.merchantIdentifier =
      'merchant.com.yourapp.identifier'; // Required for Apple Pay
  Stripe.urlScheme = 'your-url-scheme'; // Required for certain payment methods

  await DioClient().init(); // Initialize DioClient and load tokens.

  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(TestAttemptAdapter());
  Hive.registerAdapter(QuestionAdapter());
  Hive.registerAdapter(OptionAdapter());

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  final customTheme = ThemeData(
    colorScheme: const ColorScheme(
      primary: Color.fromARGB(255, 39, 121, 188), // Custom primary color
      primaryContainer: Color(0xFF2779BC), // A slightly darker shade (optional)
      secondary: Colors.green, // Secondary color
      secondaryContainer: Colors.greenAccent, // A slightly darker/lighter shade
      surface: Colors.white,
      background: Colors.white,
      error: Colors.red,
      onPrimary: Colors.white, // Text color on primary
      onSecondary: Colors.white, // Text color on secondary
      onSurface: Colors.black,
      onBackground: Colors.black,
      onError: Colors.white,
      brightness: Brightness.light,
    ),
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0, // Remove shadow for flat design
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(color: Colors.black, fontSize: 20),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: Color.fromARGB(255, 39, 121, 188), // Flat button color
      textTheme: ButtonTextTheme.primary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 39, 121, 188),
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Color.fromARGB(255, 39, 121, 188),
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
    ),
  );
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
          return MaterialApp(
            theme: customTheme,
            debugShowCheckedModeBanner: false, // Remove the debug banner
            home: const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        bool onboardingComplete = snapshot.data!['onboardingComplete']!;
        bool isAuthenticated = snapshot.data!['isAuthenticated']!;

        // Decide which screen to show based on onboarding and authentication
        Widget home;
        if (!onboardingComplete) {
          home = const IntroScreen();
        } else if (!isAuthenticated) {
          home =
              const AuthScreen(); // Replace with your main authenticated screen if needed
        } else {
          home = const MainScreen();
        }

        return MaterialApp(
          theme: customTheme,
          home: home,
          debugShowCheckedModeBanner: false, // Remove the debug banner
        );
      },
    );
  }
}
