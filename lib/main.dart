import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:taxi_exam_app/core/api/dio_client.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/models/option.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/features/intro/intro_screen.dart';
import 'package:taxi_exam_app/features/auth/auth_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:taxi_exam_app/main_screen.dart';
import 'package:upgrader/upgrader.dart';
import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'core/models/test_attempt.dart';
import 'package:taxi_exam_app/core/services/navigation_service.dart';

void main() async {

    final config = ClarityConfig(
    projectId: "u3uu96m9ip",
    logLevel: LogLevel.None // Note: Use "LogLevel.Verbose" value while testing to debug initialization issues.
  );

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  if (kIsWeb) {
    // For web, use build-time environment variables (passed via --dart-define)
    const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY',
      defaultValue: "AIzaSyCNHfjgw5mcgg5d7NayRluVTXwHPlpoGWM");
    const firebaseAuthDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN',
      defaultValue: "drive-test-a4f94.firebaseapp.com");
    const firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID',
      defaultValue: "drive-test-a4f94");
    const firebaseStorageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET',
      defaultValue: "drive-test-a4f94.firebasestorage.app");
    const firebaseMessagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID',
      defaultValue: "640394192831");
    const firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID',
      defaultValue: "1:640394192831:web:2f7c45b3bae1a15f1a630a");
    const firebaseMeasurementId = String.fromEnvironment('FIREBASE_MEASUREMENT_ID',
      defaultValue: "G-2Y166BG2F3");

    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: firebaseApiKey,
        authDomain: firebaseAuthDomain,
        projectId: firebaseProjectId,
        storageBucket: firebaseStorageBucket,
        messagingSenderId: firebaseMessagingSenderId,
        appId: firebaseAppId,
        measurementId: firebaseMeasurementId,
      ),
    );
  } else {
    // For mobile, use the config files (google-services.json / GoogleService-Info.plist)
    await Firebase.initializeApp();
  }

  await DioClient().init();

  // Hive must always init — runs before any try/catch so web storage works too
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TestAttemptAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(QuestionAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(OptionAdapter());

  try {
    if (kIsWeb) {
      // For web, load from .env - try different paths
      try {
        await dotenv.load(fileName: ".env");
      } catch (e) {
        print('Failed to load .env: $e');
        // Set default values for web
        dotenv.env['STRIPE_PUBLISHABLE_KEY'] = 'pk_live_51QSEQxLdbibfvPzFVwe3hE5seqcH1wQigVXOW60o9KWurHg8ewRFtpekd0c4R16UaiAa51mDZ3MDJFCmIzIRX56i00rZyQBtdD';
        dotenv.env['ENCRYPTION_PASSPHRASE'] = 'this_is_the_project_for_taxi';
      }
    } else {
      // Load .env for mobile/desktop
      await dotenv.load();
    }

    Stripe.publishableKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY').isNotEmpty
        ? const String.fromEnvironment('STRIPE_PUBLISHABLE_KEY')
        : dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';

    await Upgrader.clearSavedSettings();
  } catch (e) {
    print('Initialization error: $e');
    // Continue with basic initialization
  }

  runApp(
    ClarityWidget(
    clarityConfig: config,
    app: MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MainScreenProvider()),
      ],
      child: MyApp(),
    ),
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


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Combined initialization to check onboarding and authentication
  Future<Map<String, bool>> _initializeApp() async {
    try {
      debugPrint('_initializeApp - Starting initialization');

      final prefs = await SharedPreferences.getInstance();
      bool onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

      debugPrint('_initializeApp - SharedPreferences loaded');

      // DioClient is already initialized in main(), just reload tokens
      await DioClient().reloadTokens();

      debugPrint('_initializeApp - DioClient initialized');

      // Check if tokens exist
      bool hasTokens = DioClient().refreshToken != null && DioClient().accessToken != null;
      bool isAuthenticated = false;

      // If tokens exist, verify they're valid by trying to fetch user data
      if (hasTokens) {
        debugPrint('_initializeApp - Tokens found, verifying authentication...');
        try {
          final apiService = ApiService();
          await apiService.fetchCurrentUser();
          isAuthenticated = true;
          debugPrint('_initializeApp - Authentication verified successfully');
        } catch (e) {
          debugPrint('_initializeApp - Authentication verification failed: $e');
          // If fetching user fails, clear the invalid tokens
          await DioClient().logout();
          debugPrint('_initializeApp - Invalid tokens cleared');
          isAuthenticated = false;
        }
      } else {
        debugPrint('_initializeApp - No tokens found');
      }

      // Debug logging
      debugPrint('_initializeApp - Onboarding complete: $onboardingComplete');
      debugPrint('_initializeApp - Is authenticated: $isAuthenticated');

      final result = {
        'onboardingComplete': onboardingComplete,
        'isAuthenticated': isAuthenticated,
      };

      debugPrint('_initializeApp - Completed successfully');
      return result;
    } catch (e) {
      debugPrint('_initializeApp - Error: $e');
      // Return default values on error
      return {
        'onboardingComplete': false,
        'isAuthenticated': false,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      theme: customTheme,
      debugShowCheckedModeBanner: false, // Remove the debug banner
      home: UpgradeAlert(
        showIgnore: false,
        showLater: true,
        // upgrader: Upgrader(
        //   debugLogging: true,
        //   debugDisplayAlways: true, // Force display for testing
        // ),
        child: FutureBuilder<Map<String, bool>>(
          future: _initializeApp(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Text('Error during initialization: ${snapshot.error}'),
                ),
              );
            }

            final data = snapshot.data!;
            final onboardingComplete = data['onboardingComplete'] ?? false;
            final isAuthenticated = data['isAuthenticated'] ?? false;

            if (!onboardingComplete) {
              return const IntroScreen();
            } else if (!isAuthenticated) {
              return const AuthScreen();
            } else {
              return const MainScreen();
            }
          },
        ),
      ),
    );
  }
}
