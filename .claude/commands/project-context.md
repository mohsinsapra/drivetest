# TaxiQuiz App — Full Project Context

You are working on **TaxiQuiz** (`taxi_exam_app`), a Flutter app for Swedish taxi licence exam preparation.

## App Identity
- **Package name**: `taxi_exam_app`
- **Version**: 1.0.2+18
- **Platforms**: iOS, Android, Web
- **Backend**: Django REST API via DioClient (JWT auth, refresh tokens)
- **Analytics**: Microsoft Clarity (`clarity_flutter`), Firebase Analytics

---

## Tech Stack

| Concern | Package |
|---|---|
| State management | `provider ^6.1.2` |
| HTTP / auth | `dio ^5.3.0` + custom `DioClient` (singleton, JWT interceptor) |
| Local storage (offline) | `hive ^2.2.3` + `hive_flutter` |
| Preferences | `shared_preferences ^2.5.3` |
| Charts | `fl_chart ^1.0.0` |
| Localization | `slang ^4.2.1` + `slang_flutter ^4.2.0` |
| Payments | `flutter_stripe ^11.3.0` + `flutter_stripe_web ^6.5.1` |
| Loading skeleton | `shimmer ^3.0.0` |
| Auto-update prompt | `upgrader ^11.4.0` |
| Firebase | `firebase_core ^4.2.1`, `firebase_analytics ^12.0.4` |
| Clarity | `clarity_flutter ^1.6.0` |

---

## Key File Map

### Entry & Navigation
- `lib/main.dart` — App bootstrap: Firebase init (web uses `--dart-define`, mobile uses config files), Hive adapters, dotenv, Stripe key, locale restore, `runApp` tree: `ClarityWidget → TranslationProvider → MultiProvider([MainScreenProvider, ThemeProvider]) → MyApp`
- `lib/main_screen.dart` — Bottom nav shell (`MainScreen` + `MainScreenProvider`). Revolut-style floating pill nav bar, 3 tabs: Home, Tests, Profile.

### Screens
- `lib/features/home/home_screen.dart` — Dashboard: shimmer loading state, quick stats (pass/fail/total/in-progress), line chart (weekly/monthly), pie chart (by category), recent activity list, in-progress tests. Uses `Translations t` for all strings. Uses `Theme.of(context).colorScheme.surface` (not hardcoded white) for dark mode support.
- `lib/features/tests/licences_screen.dart` — Test category/licence picker
- `lib/features/tests/test_screen.dart` — Active quiz screen
- `lib/features/tests/custom_test_screen.dart` — Custom test builder
- `lib/features/tests/result_screen.dart` — Post-test results
- `lib/features/auth/auth_screen.dart` — Auth gate (login/signup)
- `lib/features/auth/login_screen.dart`
- `lib/features/auth/signup_screen.dart`
- `lib/features/auth/forgot_password_screen.dart`
- `lib/features/auth/verify_code_screen.dart`
- `lib/features/auth/reset_password_screen.dart`
- `lib/features/home/attempt_detail_screen.dart` — Detail view of a past attempt
- `lib/features/profile/profile_screen.dart` — Profile with animated avatar/tiles, logout bottom sheet, settings shortcut. Uses slang translations.
- `lib/features/support/help_screen.dart` — Help/support screen
- `lib/features/payment/payment_method_sheet.dart` — Stripe payment bottom sheet
- `lib/settings/settings.dart` — Settings: dark mode toggle, language picker (EN/SV chips), timed test, instant marking, num questions slider+input, include saved questions toggle, version info. Uses `ThemeProvider` + slang.

### Providers
- `lib/core/providers/theme_provider.dart` — `ThemeProvider extends ChangeNotifier`. Persists dark/light mode in SharedPreferences key `dark_mode`. `toggle()` flips and saves. `isDark` getter.

### API
- `lib/core/api/dio_client.dart` — Singleton. JWT access + refresh tokens. Auto-refresh interceptor. `init()`, `reloadTokens()`, `logout()`.
- `lib/core/api/api_service.dart` — REST calls: `fetchCurrentUser()`, `fetchAttempts()`, `logout()`, etc.

### Models (Hive)
- `lib/core/models/test_attempt.dart` + `.g.dart` — Hive adapter 0, stores past test attempts offline
- `lib/core/models/question.dart` + `.g.dart` — Hive adapter 1
- `lib/core/models/option.dart` + `.g.dart` — Hive adapter 2

### Widgets
- `lib/core/widgets/category_pie_chart_widget.dart` — **Interactive** `StatefulWidget`. Tap a slice to highlight (radius 72), show % inside. Unselected slices ≥14% show %. Center donut shows total or tapped category detail. Uses `AnimatedDefaultTextStyle` (NOT `AnimatedSwitcher` — avoids duplicate key crash). `PieTouchData` only handles `FlTapUpEvent`.
- `lib/core/widgets/attempt_spark_widget.dart` — **Interactive scrubber** line chart. Drag finger along line to show tooltip (count + date). No static dots. Dashed vertical indicator line + white-bordered dot on touch only. `touchSpotThreshold: 44`, `handleBuiltInTouches: true`.
- `lib/core/widgets/attempt_tabs_widget.dart` — Tab switcher for weekly/monthly chart view
- `lib/core/widgets/attempt_group_card.dart` — Groups attempts by date
- `lib/core/widgets/attempt_entry_card.dart` — Single attempt row
- `lib/core/widgets/attempt_spark_widget.dart` — Mini sparkline
- `lib/core/widgets/category_card_widget.dart` — Category selection card
- `lib/core/widgets/licence_type_card_widget.dart` — Licence type card
- `lib/core/widgets/test_option_card_widget.dart` — Test option card
- `lib/core/widgets/question_widget.dart` — Question display
- `lib/core/widgets/option_tile.dart` — Answer option tile
- `lib/core/widgets/navigation_controls.dart` — Prev/Next question buttons
- `lib/core/widgets/question_progress_header.dart` — Question X of N header
- `lib/core/widgets/explanation_widget.dart` — Answer explanation panel
- `lib/core/widgets/snackbar.dart` — `showAppSnackBar(String msg)` global helper using `NavigationService.navigatorKey`
- `lib/core/widgets/progress_card.dart` — Progress indicator card
- `lib/core/widgets/tts_button.dart` — Text-to-speech button
- `lib/core/widgets/user_header_widget.dart` — User avatar/name header
- `lib/core/widgets/test_dialogs.dart` — Confirm/info dialogs for tests

### Services
- `lib/core/services/navigation_service.dart` — `NavigationService.navigatorKey` for global navigation
- `lib/core/services/saved_questions_service.dart` — Save/unsave questions
- `lib/core/services/version_service.dart` — Reads app version, build number, git info
- `lib/core/services/tts_service.dart` — Text-to-speech
- `lib/core/services/analytics_service.dart` — Firebase Analytics wrapper

### Localization
- `lib/core/localization/strings.i18n.json` — English source (54 strings, slang format)
- `lib/core/localization/strings_sv.i18n.json` — Swedish source (54 strings)
- `lib/core/localization/strings.g.dart` — Slang generated: `AppLocale`, `Translations`, `LocaleSettings`, `TranslationProvider`, `InheritedLocaleData`
- `lib/core/localization/strings_en.g.dart` — Generated English impl (`TranslationsEn`)
- `lib/core/localization/strings_sv.g.dart` — Generated Swedish impl (`TranslationsSv`)
- **Note**: Generated files are hand-maintained (can't run `dart run slang` in CI). When adding strings, update all 4 files manually.

### Utils
- `lib/core/utils/crypto_service.dart` — Encryption/decryption using passphrase from `.env`
- `lib/core/utils/calculate_stats.dart` — Score calculation helpers
- `lib/core/constants/language_options.dart` — Language option constants

---

## Architecture Patterns

### Theme (Dark Mode)
- `ThemeProvider` registered in `MultiProvider` at root
- `MaterialApp` uses `theme: customTheme, darkTheme: darkTheme, themeMode: themeProvider.themeMode`
- **Never use hardcoded colors** for backgrounds/cards — always `Theme.of(context).colorScheme.surface` or `Theme.of(context).scaffoldBackgroundColor`
- Dark theme: scaffold `#0F0F0F`, surface/card `#1C1C1E`, primary `#5AADFF`
- Light theme: scaffold/surface `Colors.white`, primary `Color(0xFF2779BC)`

### Localization (Slang)
- All user-facing strings via `final t = Translations.of(context);` then `t.some_key`
- Switch language: `LocaleSettings.setLocale(AppLocale.en)` + persist to prefs key `language`
- Locale restored in `main()` before `runApp`
- `MyApp.build` reads: `InheritedLocaleData.of<AppLocale, Translations>(context).locale.flutterLocale` and passes to `MaterialApp(locale:)`

### Authentication Flow
- `main.dart` `_initializeApp()`: reload tokens → if tokens exist, call `fetchCurrentUser()` to verify → if fails, `DioClient().logout()` → route to `IntroScreen` / `AuthScreen` / `MainScreen`
- JWT stored in SharedPreferences, managed by `DioClient`

### Offline / Hive
- Test attempts cached in `testAttempts` Hive box
- Always `await Hive.openBox<TestAttempt>('testAttempts')` — box might not be open
- Wrap in try-catch: `async void` without try-catch silently swallows exceptions (caused home page shimmer stuck bug)

### Chart Gotchas (fl_chart 1.x)
- `PieTouchData`: only handle `FlTapUpEvent` to avoid duplicate key crashes from rapid events
- `AnimatedSwitcher` with `ValueKey(_touched)` in pie chart CAUSES duplicate key crash — use `AnimatedDefaultTextStyle` instead
- `LineTouchTooltipData` does NOT have `tooltipRoundedRadius` param in 1.x — remove it
- `getTouchedSpotIndicator` returns list of `TouchedSpotIndicatorData(FlLine, FlDotData)`

---

## String Keys Reference (54 total)

**Common**: `home`, `tests`, `profile`, `welcome_message`, `save`, `cancel`, `delete`, `logout`, `loading`

**Settings**: `settings_title`, `settings_appearance`, `settings_test_prefs`, `settings_timed_test`, `settings_timed_test_sub`, `settings_instant_marking`, `settings_instant_marking_sub`, `settings_num_questions`, `settings_enter_num`, `settings_include_saved`, `settings_include_saved_sub`, `settings_dark_mode`, `settings_dark_mode_sub`, `settings_language`, `settings_language_sub`, `settings_version`, `settings_app_version`, `settings_commit`, `settings_branch`, `settings_last_update`, `settings_date`, `settings_saved`

**Profile**: `profile_student`, `profile_edit`, `profile_stats`, `profile_settings`, `profile_invite`, `profile_help`, `profile_logout_confirm`, `profile_yes_logout`

**Home**: `home_dashboard`, `home_my_progress`, `home_overall_score`, `home_passed`, `home_failed`, `home_total`, `home_in_progress`, `home_recent_activity`, `home_by_category`, `home_this_week`, `home_this_month`, `home_no_attempts`, `home_no_attempts_sub`, `home_take_quiz`, `home_paused`, `home_resume`, `home_attempts`, `home_active`, `home_tests`

---

## SharedPreferences Keys
- `onboarding_complete` (bool) — intro seen
- `dark_mode` (bool) — dark theme preference
- `language` (String) — `'en'` or `'sv'`
- `user` (String) — JSON-encoded user object `{username, email}`
- `isTimed` (bool), `isInstantMarking` (bool), `includeSavedQuestions` (bool), `numberOfQuestions` (int) — test preferences

---

## Known Issues / TODOs (from last session)
- Web payments: needs fixing (Stripe web flow)
- GitHub Actions: Flutter build for Android and web needs fixing
