import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
import 'package:upgrader/upgrader.dart';

import 'core/models/test_attempt.dart';

void main() async {
  // WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
  Stripe.merchantIdentifier =
      'merchant.com.yourapp.identifier'; // Required for Apple Pay
  Stripe.urlScheme = 'your-url-scheme'; // Required for certain payment methods

  await DioClient().init(); // Initialize DioClient and load tokens.

  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(TestAttemptAdapter());
  Hive.registerAdapter(QuestionAdapter());
  Hive.registerAdapter(OptionAdapter());
  await Upgrader.clearSavedSettings();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MainScreenProvider()),
      ],
      child: MyApp(),
    ),
  );
}

final customTheme = ThemeData(
  fontFamily: 'NudMoto',
  textTheme: TextTheme(
    bodyLarge: TextStyle(fontFamily: 'NudMoto'),
    bodyMedium: TextStyle(fontFamily: 'NudMoto'),
    titleLarge: TextStyle(fontFamily: 'NudMoto'),
  ),
  
  colorScheme: const ColorScheme(
    primary: Color.fromARGB(255, 39, 121, 188),
    primaryContainer: Color(0xFF2779BC),
    secondary: Colors.green,
    secondaryContainer: Colors.greenAccent,
    surface: Colors.white,
    background: Colors.white,
    error: Colors.red,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.black,
    onBackground: Colors.black,
    onError: Colors.white,
    brightness: Brightness.light,
  ),
  inputDecorationTheme: InputDecorationTheme(
    fillColor: Color(0xFF757575),
    labelStyle: const TextStyle(
      color: Color(0xFF757575), // Soft grey for label text
      fontFamily: 'NudMoto',
    ),
    hintStyle: const TextStyle(
      color: Color(0xFF9E9E9E), // Lighter grey for hint text
      fontFamily: 'NudMoto',
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFFBDBDBD), // Lighter grey
        width: 0.5, // Thinner border
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFFBDBDBD), // Lighter grey
        width: 0.5,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFF2779BC), // Use primary color for focus
        width: 1,
      ),
    ),
  ),
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.black),
    titleTextStyle: TextStyle(
      color: Colors.black,
      fontSize: 20,
      fontFamily: 'NudMoto',
      fontWeight: FontWeight.w600,
    ),
    toolbarTextStyle: TextStyle(
      color: Colors.black,
      fontSize: 18,
      fontFamily: 'NudMoto',
    ),
  ),
  buttonTheme: const ButtonThemeData(
    buttonColor: Color.fromARGB(255, 201, 160, 11),
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Combined initialization to check onboarding and authentication
  Future<Map<String, bool>> _initializeApp() async {
    final prefs = await SharedPreferences.getInstance();
    bool onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    String? refreshToken = prefs.getString('refreshToken');
    String? accessToken = prefs.getString('accessToken');
    if (accessToken != null) {
      DioClient().accessToken = accessToken;
    }
    if (refreshToken != null) {
      DioClient().refreshToken = refreshToken;
    }

    bool isAuthenticated = DioClient().refreshToken != null;

    return {
      'onboardingComplete': onboardingComplete,
      'isAuthenticated': isAuthenticated,
    };
  }

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
        showIgnore: false,
        showLater: false,
        child: FutureBuilder<Map<String, bool>>(
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
        ));
  }
}
