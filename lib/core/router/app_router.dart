// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/router/route_args.dart';
import 'package:taxi_exam_app/core/router/route_names.dart';
import 'package:taxi_exam_app/features/auth/auth_screen.dart';
import 'package:taxi_exam_app/features/auth/forgot_password_screen.dart';
import 'package:taxi_exam_app/features/auth/reset_password_screen.dart';
import 'package:taxi_exam_app/features/auth/verify_code_screen.dart';
import 'package:taxi_exam_app/features/bcd/bcd_category_hub_screen.dart';
import 'package:taxi_exam_app/features/bcd/bcd_document_viewer_screen.dart';
import 'package:taxi_exam_app/features/bcd/bcd_licences_screen.dart';
import 'package:taxi_exam_app/features/bcd/bcd_screen.dart';
import 'package:taxi_exam_app/features/bcd/bcd_sub_category_screen.dart';
import 'package:taxi_exam_app/features/bcd/bcd_subscriptions_screen.dart';
import 'package:taxi_exam_app/features/bcd/bcd_test_screen.dart';
import 'package:taxi_exam_app/features/bcd/bcd_traffic_signs_screen.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';
import 'package:taxi_exam_app/features/home/attempt_detail_screen.dart';
import 'package:taxi_exam_app/features/home/home_screen.dart';
import 'package:taxi_exam_app/features/intro/intro_screen.dart';
import 'package:taxi_exam_app/features/profile/edit_profile_screen.dart';
import 'package:taxi_exam_app/features/profile/profile_screen.dart';
import 'package:taxi_exam_app/features/profile/stats_screen.dart';
import 'package:taxi_exam_app/features/splash/splash_screen.dart';
import 'package:taxi_exam_app/features/support/help_screen.dart';
import 'package:taxi_exam_app/features/tests/custom_test_screen.dart';
import 'package:taxi_exam_app/features/tests/licences_screen.dart';
import 'package:taxi_exam_app/features/tests/result_screen.dart';
import 'package:taxi_exam_app/features/tests/saved_questions_preview_screen.dart';
import 'package:taxi_exam_app/features/tests/test_screen.dart';
import 'package:taxi_exam_app/main_screen.dart';
import 'package:taxi_exam_app/settings/settings.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildAppRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    redirect: _authGuard,
    routes: [
      // ── Splash / Intro / Auth ──────────────────────────────────────────
      GoRoute(
        path: Routes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.intro,
        builder: (_, __) => const IntroScreen(),
      ),
      GoRoute(
        path: Routes.auth,
        builder: (_, __) => const AuthScreen(),
        routes: [
          GoRoute(
            path: 'forgot',
            builder: (_, __) => const ForgotPasswordScreen(),
          ),
          GoRoute(
            path: 'verify',
            builder: (context, state) {
              final email = state.extra as String? ?? '';
              return VerifyCodeScreen(email: email);
            },
          ),
          GoRoute(
            path: 'reset',
            builder: (context, state) {
              final args = state.extra as Map<String, dynamic>?;
              final email = args?['email'] as String? ?? '';
              final resetCode = args?['resetCode'] as String? ?? '';
              return ResetPasswordScreen(email: email, resetCode: resetCode);
            },
          ),
        ],
      ),

      // ── Shell (bottom nav) ─────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.home, builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.tests,
                builder: (_, __) => const LicenceTypesScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.bcd, builder: (_, __) => const BCDScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.profile,
                builder: (_, __) => const ProfileScreen()),
          ]),
        ],
      ),

      // ── Profile stack (above shell) ────────────────────────────────────
      GoRoute(
          path: Routes.profileEdit,
          builder: (_, __) => const EditProfileScreen()),
      GoRoute(
          path: Routes.profileStats,
          builder: (_, __) => const StatsScreen()),
      GoRoute(
          path: Routes.settings,
          builder: (_, __) => const SettingsScreen()),
      GoRoute(path: Routes.help, builder: (_, __) => const HelpScreen()),

      // ── Home stack ─────────────────────────────────────────────────────
      GoRoute(
        path: Routes.attempt,
        builder: (context, state) {
          final attempt = state.extra as TestAttempt?;
          if (attempt == null) return const HomeScreen();
          return AttemptDetailScreen(attempt: attempt);
        },
      ),

      // ── Test stack (extra-only) ────────────────────────────────────────
      GoRoute(
        path: Routes.test,
        builder: (context, state) {
          final args = state.extra as TestScreenArgs?;
          if (args == null) return const LicenceTypesScreen();
          return Testscreen(
            questions: args.questions,
            instantMarking: args.instantMarking,
            licenceId: args.licenceId,
            categoryId: args.categoryId,
            licenceName: args.licenceName,
            categoryName: args.categoryName,
            initialQuestionIndex: args.initialQuestionIndex,
            userSelections: args.userSelections,
            isReviewMode: args.isReviewMode,
            isTimed: args.isTimed,
            timeLimitMinutes: args.timeLimitMinutes,
            passScorePercent: args.passScorePercent,
            resumeTestId: args.resumeTestId,
            bcdCategoryId: args.bcdCategoryId,
            bcdTestId: args.bcdTestId,
            initiallySavedQuestionIds: args.initiallySavedQuestionIds,
          );
        },
      ),
      GoRoute(
        path: Routes.result,
        builder: (context, state) {
          final args = state.extra as ResultScreenArgs?;
          if (args == null) return const LicenceTypesScreen();
          return ResultScreen(
            questions: args.questions,
            userSelections: Map<int, String>.from(args.userSelections),
            licenceId: args.licenceId,
            categoryId: args.categoryId,
            hasPassed: args.hasPassed,
          );
        },
      ),
      GoRoute(
        path: Routes.testsCustom,
        builder: (context, state) {
          final args = state.extra as CustomTestScreenArgs?;
          if (args == null) return const LicenceTypesScreen();
          return CreateCustomTestScreen(
            licenceId: args.licenceId,
            categoryId: args.categoryId,
            categoryName: args.categoryName,
          );
        },
      ),
      GoRoute(
        path: Routes.testsSaved,
        builder: (context, state) {
          final args = state.extra as SavedQuestionsArgs?;
          if (args == null) return const LicenceTypesScreen();
          return SavedQuestionsPreviewScreen(
            questions: args.questions,
            licenceId: args.licenceId,
            categoryId: args.categoryId,
            licenceName: args.licenceName,
            categoryName: args.categoryName,
            bcdCategoryId: args.bcdCategoryId,
          );
        },
      ),

      // ── BCD stack ──────────────────────────────────────────────────────
      GoRoute(
          path: Routes.bcdLicences,
          builder: (_, __) => const BCDLicencesScreen()),
      GoRoute(
          path: Routes.bcdSigns,
          builder: (_, __) => const BCDTrafficSignsScreen()),
      GoRoute(
          path: Routes.bcdSubscriptions,
          builder: (_, __) => const BCDSubscriptionsScreen()),
      GoRoute(
        path: Routes.bcdCategory,
        builder: (context, state) {
          final category = state.extra as Map<String, dynamic>?;
          if (category == null) return const BCDScreen();
          return BCDCategoryHubScreen(category: category);
        },
      ),
      GoRoute(
        path: Routes.bcdSubcategory,
        builder: (context, state) {
          final category = state.extra as Map<String, dynamic>?;
          if (category == null) return const BCDScreen();
          return BCDSubCategoryScreen(parentCategory: category);
        },
      ),
      GoRoute(
        path: Routes.bcdTest,
        builder: (context, state) {
          final args = state.extra as BcdTestScreenArgs?;
          if (args == null) return const BCDScreen();
          return BCDTestScreen(
            testId: args.testId,
            testName: args.testName,
            passScore: args.passScore,
            timeLimit: args.timeLimit,
            parentCategoryName: args.parentCategoryName,
            parentCategoryBcdId: args.parentCategoryBcdId,
          );
        },
      ),
      GoRoute(
        path: Routes.bcdDoc,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;
          if (args == null) return const BCDScreen();
          return BCDDocumentViewerScreen(
            title: args['title'] as String,
            url: args['url'] as String,
          );
        },
      ),
    ],
  );
}

/// Redirect unauthenticated users to /auth.
/// Splash and intro routes are always allowed.
Future<String?> _authGuard(BuildContext context, GoRouterState state) async {
  final loc = state.matchedLocation;
  final isPublic = loc == Routes.splash ||
      loc == Routes.intro ||
      loc.startsWith('/auth');
  if (isPublic) return null;

  final prefs = await SharedPreferences.getInstance();
  final hasToken = (prefs.getString('access_token') ?? '').isNotEmpty;
  if (!hasToken) return Routes.auth;
  return null;
}
