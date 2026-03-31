import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:taxi_exam_app/core/api/dio_client.dart';
import 'package:taxi_exam_app/core/models/option.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/features/splash/splash_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:taxi_exam_app/main_screen.dart';
import 'package:upgrader/upgrader.dart';
import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/models/test_attempt.dart';
import 'package:taxi_exam_app/core/services/navigation_service.dart';
import 'package:taxi_exam_app/core/providers/theme_provider.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';

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
    // Load .env.local first (test keys). If it exists, its values are passed as
    // mergeWith when loading .env — mergeWith lines are appended LAST so they
    // win over file lines, meaning .env.local values always override .env.
    // In production .env.local is not bundled, so the catch is hit and we fall
    // back to plain .env (prod keys).
    Map<String, String> localOverrides = {};
    try {
      await dotenv.load(fileName: '.env.local');
      localOverrides = Map<String, String>.from(dotenv.env);
    } catch (_) {}
    try {
      await dotenv.load(fileName: '.env', mergeWith: localOverrides);
    } catch (e) {
      debugPrint('Failed to load .env: $e');
    }

    // dart-define values (CI / release builds) take final precedence
    const stripeKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
    final publishableKey = stripeKey.isNotEmpty
        ? stripeKey
        : dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
    Stripe.publishableKey = publishableKey;
    // flutter_stripe_web requires applySettings() to initialise Stripe.js
    if (kIsWeb) {
      await Stripe.instance.applySettings();
    }

    await Upgrader.clearSavedSettings();

    // Restore saved locale
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('language') ?? 'en';
    LocaleSettings.setLocale(
        savedLang == 'sv' ? AppLocale.sv : AppLocale.en);
  } catch (e) {
    debugPrint('Initialization error: $e');
  }

  runApp(
    ClarityWidget(
      clarityConfig: config,
      app: TranslationProvider(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => MainScreenProvider()),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: MyApp(),
        ),
      ),
    ),
  );
}

final darkTheme = ThemeData(
  fontFamily: 'NudMoto',
  brightness: Brightness.dark,
  colorScheme: const ColorScheme(
    primary: Color(0xFF5AADFF),
    primaryContainer: Color(0xFF2779BC),
    secondary: Colors.green,
    secondaryContainer: Colors.greenAccent,
    surface: Color(0xFF1C1C1E),
    error: Colors.redAccent,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.white,
    onError: Colors.white,
    brightness: Brightness.dark,
  ),
  scaffoldBackgroundColor: const Color(0xFF0F0F0F),
  cardColor: const Color(0xFF1C1C1E),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1C1C1E),
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontFamily: 'NudMoto',
      fontWeight: FontWeight.w600,
    ),
    toolbarTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontFamily: 'NudMoto',
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    labelStyle: const TextStyle(color: Color(0xFF9E9E9E), fontFamily: 'NudMoto'),
    hintStyle: const TextStyle(color: Color(0xFF757575), fontFamily: 'NudMoto'),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF3A3A3C), width: 0.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF3A3A3C), width: 0.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF5AADFF), width: 1),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF5AADFF),
      foregroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
      ),
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedItemColor: Color(0xFF5AADFF),
    unselectedItemColor: Colors.grey,
    backgroundColor: Color(0xFF1C1C1E),
  ),
  dividerColor: const Color(0xFF2C2C2E),
);

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
    error: Colors.red,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.black,
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final locale = InheritedLocaleData.of<AppLocale, Translations>(context)
        .locale
        .flutterLocale;
    return ToastificationWrapper(
      config: const ToastificationConfig(itemWidth: 320),
      child: MaterialApp(
        navigatorKey: NavigationService.navigatorKey,
        locale: locale,
        theme: customTheme,
        darkTheme: darkTheme,
        themeMode: themeProvider.themeMode,
        debugShowCheckedModeBanner: false,
        home: UpgradeAlert(
          showIgnore: false,
          showLater: true,
          child: const SplashScreen(),
        ),
      ),
    );
  }
}
