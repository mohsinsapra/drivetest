import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/api/dio_client.dart';
import 'package:taxi_exam_app/core/models/option.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/features/splash/splash_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:taxi_exam_app/main_screen.dart';
import 'package:upgrader/upgrader.dart';
import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:clarity_web/clarity_web.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/models/test_attempt.dart';
import 'package:taxi_exam_app/features/dashboard/models/exam_node.dart';
import 'package:taxi_exam_app/features/dashboard/models/subscribed_exam.dart';
import 'package:taxi_exam_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:taxi_exam_app/features/dashboard/repository/hive_dashboard_repository.dart';
import 'package:taxi_exam_app/core/services/navigation_service.dart';
import 'package:taxi_exam_app/core/providers/theme_provider.dart';
import 'package:taxi_exam_app/core/providers/font_provider.dart';
import 'package:taxi_exam_app/core/providers/notification_provider.dart';
import 'package:taxi_exam_app/core/services/session_validation_service.dart';
import 'package:taxi_exam_app/core/services/user_cache_service.dart';
import 'package:taxi_exam_app/core/models/local_notification.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/services/streak_notification_service.dart';
import 'package:taxi_exam_app/features/streak/streak_settings_provider.dart';
import 'package:taxi_exam_app/core/config/stripe_config.dart';

void main() async {
  const sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue:
        'https://32d4a7e8f8033e788074ecf90ad55f2a@o4511088769564672.ingest.de.sentry.io/4511202750038096',
  );

  await SentryFlutter.init(
    (options) {
      options.dsn = sentryDsn;
      options.tracesSampleRate = kReleaseMode ? 0.2 : 1.0;
      // Only inject sentry-trace / baggage headers on requests to the
      // production host. Without this, the CORS preflight for the dev
      // server (192.168.x.x) is rejected because it doesn't whitelist
      // those headers.
      options.tracePropagationTargets
        ..clear()
        ..add('taxiexam.hayatpoetry.com');
      options.environment = kReleaseMode
          ? (kIsWeb
              ? 'production-web'
              : Platform.isAndroid
                  ? 'production-android'
                  : 'production-ios')
          : (kIsWeb
              ? 'debug-web'
              : Platform.isAndroid
                  ? 'debug-android'
                  : 'debug-ios');
      // Drop known Flutter CanvasKit engine bug: WebGL context loss fires
      // onContextLost before _handledContextLostEvent is initialised.
      // The browser recovers the GL context automatically — not actionable.
      options.beforeSend = (event, hint) {
        final msg = event.throwable?.toString() ?? '';
        if (msg.contains('_handledContextLostEvent')) return null;
        // Session-validation timeouts are caught and swallowed by _runValidation;
        // sentry_dio captures them at the Dio layer before the catch block runs.
        if (msg.contains('Failed to fetch current user') &&
            msg.contains('receive timeout')) {
          return null;
        }
        return event;
      };
    },
    appRunner: _appMain,
  );
}

Future<void> _appMain() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Round 1: Firebase + DioClient + Hive + Clarity are fully independent.
  // Run them all in parallel instead of sequentially.
  final firebaseFuture = kIsWeb
      ? Firebase.initializeApp(
          options: const FirebaseOptions(
          apiKey: String.fromEnvironment('FIREBASE_API_KEY',
              defaultValue: 'AIzaSyCNHfjgw5mcgg5d7NayRluVTXwHPlpoGWM'),
          authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN',
              defaultValue: 'drive-test-a4f94.firebaseapp.com'),
          projectId: String.fromEnvironment('FIREBASE_PROJECT_ID',
              defaultValue: 'drive-test-a4f94'),
          storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET',
              defaultValue: 'drive-test-a4f94.firebasestorage.app'),
          messagingSenderId: String.fromEnvironment(
              'FIREBASE_MESSAGING_SENDER_ID',
              defaultValue: '640394192831'),
          appId: String.fromEnvironment('FIREBASE_APP_ID',
              defaultValue: '1:640394192831:web:2f7c45b3bae1a15f1a630a'),
          measurementId: String.fromEnvironment('FIREBASE_MEASUREMENT_ID',
              defaultValue: 'G-2Y166BG2F3'),
        ))
      : Firebase.initializeApp();

  final clarityFuture = kIsWeb
      ? ClarityWeb.instance
          .initClarityWeb('u3wxqg5xo0')
          .then((_) => ClarityWeb.instance.setIsCanvasMirrorActive(false))
      : Future<void>.value();

  await Future.wait([
    firebaseFuture,
    clarityFuture,
    DioClient().init(),
    Hive.initFlutter(),
  ]);

  // Hive adapters are synchronous and must follow Hive.initFlutter()
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TestAttemptAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(QuestionAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(OptionAdapter());
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(LocalNotificationAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(SubscribedExamAdapter());
  }
  if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(ExamNodeAdapter());
  final notificationProvider = await NotificationProvider.create();
  final dashboardProvider =
      DashboardProvider(repository: HiveDashboardRepository());
  final streakSettingsProvider = StreakSettingsProvider();
  await streakSettingsProvider.load();
  StreakNotificationService.init().ignore();
  final sessionValidationObserver = SessionValidationLifecycleObserver(
    SessionValidationService(
      isAuthenticated: () => DioClient().accessToken != null,
      fetchCurrentUser: () => ApiService().fetchCurrentUser().then((_) {}),
      minInterval: kReleaseMode
          ? const Duration(seconds: 30)
          : const Duration(seconds: 5),
    ),
  )..attach();

  // Wire up provider reset so both logout paths (explicit + 401 auto-logout)
  // wipe in-memory state before the next user's session starts.
  UserCacheService.onProviderReset = () async {
    dashboardProvider.reset();
    await notificationProvider.clearAll();
  };

  // Keep DashboardProvider's weeklyGoal in sync with StreakSettingsProvider.
  dashboardProvider.setWeeklyGoal(streakSettingsProvider.weeklyGoal);
  streakSettingsProvider.addListener(() {
    dashboardProvider.setWeeklyGoal(streakSettingsProvider.weeklyGoal);
  });

  // ── Round 2: SharedPreferences + dotenv/Stripe are independent of each
  // other — run them in parallel.
  late SharedPreferences prefs;
  await Future.wait([
    SharedPreferences.getInstance().then((p) => prefs = p),
    _initEnvAndStripe(),
  ]);

  // Restore saved locale, falling back to system language
  try {
    final savedLang = prefs.getString('language');
    if (savedLang != null) {
      LocaleSettings.setLocale(savedLang == 'sv' ? AppLocale.sv : AppLocale.en);
    } else {
      final systemLang = WidgetsBinding
          .instance.platformDispatcher.locale.languageCode
          .toLowerCase();
      LocaleSettings.setLocale(
          systemLang == 'sv' ? AppLocale.sv : AppLocale.en);
    }
  } catch (e) {
    debugPrint('Locale init error: $e');
  }

  runApp(
    ClarityWidget(
      clarityConfig:
          ClarityConfig(projectId: 'u3uu96m9ip', logLevel: LogLevel.None),
      app: TranslationProvider(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => MainScreenProvider()),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => FontProvider()),
            ChangeNotifierProvider<NotificationProvider>.value(
                value: notificationProvider),
            ChangeNotifierProvider<DashboardProvider>.value(
                value: dashboardProvider),
            ChangeNotifierProvider<StreakSettingsProvider>.value(
                value: streakSettingsProvider),
          ],
          child: MyApp(sessionValidationObserver: sessionValidationObserver),
        ),
      ),
    ),
  );
}

// Loads .env files then configures Stripe. Sequential internally (local
// overrides must be read before base .env), but runs in parallel with
// SharedPreferences in _appMain round 2.
Future<void> _initEnvAndStripe() async {
  try {
    // On web, --dart-define injects all values; skip dotenv to avoid 404s.
    if (!kIsWeb) {
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
    }
    await initializeStripe(
      defineValue: const String.fromEnvironment('STRIPE_PUBLISHABLE_KEY'),
      dotenvValue: readStripePublishableKeySafely(() => dotenv.env),
      isReleaseMode: kReleaseMode,
      assignPublishableKey: (key) => Stripe.publishableKey = key,
      applySettings: Stripe.instance.applySettings,
      shouldApplySettings: kIsWeb,
      log: debugPrint,
    );
  } catch (e) {
    debugPrint('Env/Stripe init error: $e');
  }
}

// ── Nordic Kinetic Design System – dark theme ──────────────────────────────
// Derived from the same token set: surfaces shift to midnight ink,
// accents stay vibrant (blue primary, yellow secondary, orange tertiary).
ThemeData buildDarkTheme(String font) => ThemeData(
      fontFamily: font,
      textTheme: TextTheme(
        bodyLarge: TextStyle(fontFamily: font),
        bodyMedium: TextStyle(fontFamily: font),
        titleLarge: TextStyle(fontFamily: font),
      ),
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        // Primary – Swedish blue (lighter in dark mode for contrast)
        primary: Color(0xFF6A89FF), // inverse-primary used as dark primary
        primaryContainer: Color(0xFF002278), // on-primary-fixed-variant
        onPrimary: Color(0xFF000000),
        onPrimaryContainer: Color(0xFF829BFF),
        // Secondary – Swedish yellow (unchanged, still pops)
        secondary: Color(0xFFEFC900), // secondary-fixed-dim
        secondaryContainer: Color(0xFF665500),
        onSecondary: Color(0xFF453900),
        onSecondaryContainer: Color(0xFFFFD709),
        // Tertiary – orange
        tertiary: Color(0xFFFF7F36), // tertiary-fixed-dim
        tertiaryContainer: Color(0xFF642600),
        onTertiary: Color(0xFF2F0E00),
        onTertiaryContainer: Color(0xFFFF955E),
        // Surface hierarchy (inverted — midnight ink base)
        surface: Color(0xFF09082F), // inverse-surface as dark base
        onSurface: Color(0xFF9999C6), // inverse-on-surface
        surfaceContainerHighest: Color(0xFF1E1D45),
        onSurfaceVariant: Color(0xFF7B7CAC),
        // Outline
        outline: Color(0xFF575881),
        outlineVariant: Color(0xFF363660),
        // Error
        error: Color(0xFFF74B6D), // error-container as dark error
        onError: Color(0xFF510017),
        errorContainer: Color(0xFFA70138),
        onErrorContainer: Color(0xFFFFEFEF),
        // Inverse (flip back to light tokens)
        inverseSurface: Color(0xFFF8F5FF),
        onInverseSurface: Color(0xFF2A2B51),
        inversePrimary: Color(0xFF0049E6),
        scrim: Color(0xFF000000),
        shadow: Color(0xFF000000),
      ),
      scaffoldBackgroundColor: const Color(0xFF09082F),
      cardColor: const Color(0xFF12113A),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF12113A),
        labelStyle: TextStyle(color: const Color(0xFF575881), fontFamily: font),
        hintStyle: TextStyle(color: const Color(0xFF363660), fontFamily: font),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x26363660), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x26363660), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x666A89FF), width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF09082F),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF9999C6)),
        titleTextStyle: TextStyle(
          color: const Color(0xFF9999C6),
          fontSize: 20,
          fontFamily: font,
          fontWeight: FontWeight.w600,
        ),
        toolbarTextStyle: TextStyle(
          color: const Color(0xFF9999C6),
          fontSize: 18,
          fontFamily: font,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6A89FF),
          foregroundColor: const Color(0xFF000000),
          shape: const StadiumBorder(),
          elevation: 0,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: Color(0xFF6A89FF),
        unselectedItemColor: Color(0xFF575881),
        backgroundColor: Color(0xFF09082F),
        elevation: 0,
      ),
      dividerColor: Colors.transparent,
    );

// ── Nordic Kinetic Design System – light theme ─────────────────────────────
ThemeData buildLightTheme(String font) => ThemeData(
      fontFamily: font,
      textTheme: TextTheme(
        bodyLarge: TextStyle(fontFamily: font),
        bodyMedium: TextStyle(fontFamily: font),
        titleLarge: TextStyle(fontFamily: font),
      ),
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        // Primary – Swedish blue
        primary: Color(0xFF0049E6),
        primaryContainer: Color(0xFF829BFF),
        onPrimary: Color(0xFFF2F1FF),
        onPrimaryContainer: Color(0xFF001A63),
        // Secondary – Swedish yellow
        secondary: Color(0xFF6C5A00),
        secondaryContainer: Color(0xFFFFD709),
        onSecondary: Color(0xFFFFF2CD),
        onSecondaryContainer: Color(0xFF5B4B00),
        // Tertiary – energetic orange
        tertiary: Color(0xFF9B3F00),
        tertiaryContainer: Color(0xFFFF955E),
        onTertiary: Color(0xFFFFF0EA),
        onTertiaryContainer: Color(0xFF562000),
        // Surface hierarchy
        surface: Color(0xFFF8F5FF),
        onSurface: Color(0xFF2A2B51),
        surfaceContainerHighest: Color(0xFFDBD9FF),
        onSurfaceVariant: Color(0xFF575881),
        // Outline
        outline: Color(0xFF73739E),
        outlineVariant: Color(0xFFA9A9D7),
        // Error
        error: Color(0xFFB41340),
        onError: Color(0xFFFFEFEF),
        errorContainer: Color(0xFFF74B6D),
        onErrorContainer: Color(0xFF510017),
        // Inverse
        inverseSurface: Color(0xFF09082F),
        onInverseSurface: Color(0xFF9999C6),
        inversePrimary: Color(0xFF6A89FF),
        scrim: Color(0xFF000000),
        shadow: Color(0xFF000000),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F5FF),
      cardColor: const Color(0xFFFFFFFF),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
        labelStyle: TextStyle(color: const Color(0xFF73739E), fontFamily: font),
        hintStyle: TextStyle(color: const Color(0xFFA9A9D7), fontFamily: font),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x26A9A9D7), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x26A9A9D7), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x6673739E), width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF8F5FF),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF2A2B51)),
        titleTextStyle: TextStyle(
          color: const Color(0xFF2A2B51),
          fontSize: 20,
          fontFamily: font,
          fontWeight: FontWeight.w600,
        ),
        toolbarTextStyle: TextStyle(
          color: const Color(0xFF2A2B51),
          fontSize: 18,
          fontFamily: font,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0049E6),
          foregroundColor: const Color(0xFFF2F1FF),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(9999)),
          ),
          elevation: 0,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: Color(0xFF0049E6),
        unselectedItemColor: Color(0xFF73739E),
        backgroundColor: Color(0xFFF8F5FF),
        elevation: 0,
      ),
      dividerColor: Colors.transparent,
    );

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.sessionValidationObserver});

  final SessionValidationLifecycleObserver sessionValidationObserver;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void dispose() {
    widget.sessionValidationObserver.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final fontProvider = Provider.of<FontProvider>(context);
    final locale = InheritedLocaleData.of<AppLocale, Translations>(context)
        .locale
        .flutterLocale;
    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      locale: locale,
      theme: buildLightTheme(fontProvider.fontFamily),
      darkTheme: buildDarkTheme(fontProvider.fontFamily),
      themeMode: themeProvider.themeMode,
      debugShowCheckedModeBanner: false,
      home: UpgradeAlert(
        showIgnore: false,
        showLater: true,
        child: const SplashScreen(),
      ),
    );
  }
}
