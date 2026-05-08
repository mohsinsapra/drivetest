# Changelog

All notable changes to DriveTest app will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!-- markdownlint-disable MD024 -->

## [Unreleased]

### Added
-

### Changed
-

### Fixed
-

---

## [1.0.5+171] - 2026-05-08

### Added
- Apple Sign-In in auth bottom sheet (iOS/macOS); shown before Google per Apple Guideline 4.8
- `IAPService.restore()` + `restoredProductIds` broadcast stream for StoreKit purchase restoration
- "Restore Purchases" flow in onboarding: triggers StoreKit restore, polls backend, navigates to app if active subscription found
- Owned-product shortcut in onboarding: if all selected products are already purchased, skip payment and go directly to the app
- `isCategoryFree` flag propagated from BCD cache through category hub to tests list — unlocks all tests for free categories
- Numbered test cards in BCD tests list
- New localization strings: `bcd_start_practice`, `onb_restore_initiated` (EN + SV)
- Debug-mode auto-fill for login credentials in `AuthScreen`

### Changed
- **iOS App Store compliance (Guideline 3.1.1):** products without a StoreKit IAP ID are now blocked on iOS instead of falling through to Stripe; Apple Pay via Stripe removed from payment method sheet on iOS
- Default feature flags flipped: `show_legacy_tests` defaults to `false`, `show_bcd_tests` defaults to `true`
- Auth bottom sheet redesigned: gradient pill buttons (matching `AuthScreen`), `AnimatedContainer` text fields with border feedback, themed error banner
- BCD category hub tile colours now use `ColorScheme` tokens instead of hardcoded hex values
- Subscription banners use `tertiaryContainer`/`tertiary` theme colours instead of hardcoded amber
- BCD cache stores `subscription_product`, `test_count`, and `attempt_count` per category
- Onboarding: if the user is already logged in, the "Sign in" CTA navigates to `MainScreen` instead of `AuthScreen`
- Onboarding product filter excludes free and inactive products
- Shimmer loading skeleton uses `ColorScheme` surface tokens

### Fixed
- IAP purchase handler now guards `_pendingCompleter != null` before resolving, preventing a crash when a StoreKit restore event arrives during an active buy flow

---
---

## [1.0.4+170] - 2026-05-08

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.3+169] - 2026-05-07

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.3+165] - 2026-05-06

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.3+163] - 2026-05-06

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.3+161] - 2026-05-05

### Added
- Unified `PaywallSheet` — single product-selection bottom sheet used across all payment entry points
- `PaymentCoordinator` service — centrally routes purchases to Apple IAP (iOS) or Stripe (Android/Web) and shows the success overlay automatically
- Apple In-App Purchase support via `IAPService` — iOS users pay through the App Store for BCD subscriptions with `iap_product_id`

### Changed
- All four payment entry points (BCD Category Hub, BCD Subscriptions, Licences, Onboarding) now use `PaymentCoordinator` instead of duplicated Stripe/IAP logic
- iOS purchases automatically route to Apple IAP when the product has an `iap_product_id`; Android and Web always use Stripe

### Fixed
- Removed ~600 lines of duplicated payment code spread across four screens

---
---

## [1.0.3+157] - 2026-05-03

### Added
- Shared Stripe configuration helpers plus regression tests for bootstrap key resolution, mobile payment setup, and typed Hive notification-box cleanup

### Changed
- Centralized Stripe publishable-key resolution into a shared config helper and moved native `applySettings()` to the mobile payment path instead of app bootstrap

### Fixed
- Separate loading indicators for Google and Apple sign-in buttons so only the tapped button shows a spinner
- Separate loading indicators per subscription plan card in paywall sheet and subscriptions screen so only the tapped plan shows a spinner
- iOS startup no longer hits a Stripe initialization error when `.env` is missing or dotenv was never initialized
- iOS startup no longer risks a white-screen hang from calling Stripe settings application during app bootstrap on native platforms
- User-session cleanup now clears already-open typed Hive boxes correctly, including the notifications box
- Logout/cache cleanup no longer instantiates `BcdCache` just to invalidate it

---
---

## [1.0.3+154] - 2026-05-03

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.3+152] - 2026-05-03

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.3+151] - 2026-05-03

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.3+150] - 2026-05-03

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.3+149] - 2026-05-03

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.3+148] - 2026-05-03

### Added
- **Streak notification reminders** — scheduled local notifications fire on each selected practice day at a random morning (08:00–10:00) and evening (19:00–21:00) time; times are generated once and persisted so they remain stable across restarts
- `StreakNotificationService` — manages notification scheduling, permission requests, and per-weekday cancel/reschedule via `flutter_local_notifications`
- `StreakSettingsProvider` — `ChangeNotifier` that persists weekly practice-day selection and exposes it app-wide; weekly goal synced to `DashboardProvider` on startup and on every change
- `StreakSettingsScreen` — UI for configuring practice days and viewing scheduled notification times
- Android monochrome notification icon (`res/drawable/ic_notification.xml`) — white bell on transparent background, replaces launcher icon as the small notification icon to comply with Android 5+ requirements
- `RECEIVE_BOOT_COMPLETED` permission on Android — allows streak notifications to be rescheduled after device reboot

### Changed
- Sentry `tracePropagationTargets` restricted to the production host (`taxiexam.hayatpoetry.com`) — prevents CORS preflight rejection on the local dev server caused by injected `sentry-trace`/`baggage` headers

### Fixed
- Duplicate `as tz` import alias in `StreakNotificationService` — `timezone/data/latest_all.dart` renamed to `tz_data` to resolve the conflict with `timezone/timezone.dart`
- Added `mounted` guard in `OnboardingScreen` before showing the subscription success overlay — prevents a `setState` call after widget disposal

---
---

## [1.0.3+124] - 2026-05-02

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.3+123] - 2026-05-02

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.3+123] - 2026-05-02

### Added
- New pass/fail result screen with animated circular score progress, PASSED/FAILED pill, correct/wrong/skipped stats row, and per-question review list
- Result dialog redesigned as a themed modal with colored header, trophy/sad icon, large score %, and PASSED/FAILED badge

### Changed
- Tutorial hint cards (swipe left/right, press & hold) now use the theme primary color as background with white text — no more plain white cards
- Tutorial completion overlay elements now animate in separately (icon → title → body → subtitle → button) with staggered slide-up + fade transitions
- Tutorial completion overlay is now properly centered on screen (was broken inside ScrollView)
- `_calculateResult()` refactored to delegate to new `_computeScorePercent()` helper; score is now passed to the result dialog

### Fixed
- Yellow double-underline on all tutorial overlay text — caused by `Text` widgets having no `Material` ancestor in `OverlayEntry` builders; fixed by wrapping each overlay in `Material(color: Colors.transparent)`

---

## [1.0.3+122] - 2026-05-01

### Added
- Haptic/vibration feedback on login and logout
- Haptic/vibration feedback on wrong answer when instant-check mode is active
- Haptic/vibration feedback on test pass (celebration pattern) and test fail
- Web vibration support via `navigator.vibrate()` for mobile browsers (Chrome on Android)

### Changed
- Vibration now uses both `HapticFeedback` and the `Vibration` package on Android for maximum device coverage (tablets and phones)
- Bumped `vibration` package to 3.1.8

### Fixed
- Vibrations were silently skipped on web (package had no web plugin); now handled via js_interop
- Fixed iOS CocoaPods conflict: Firebase/CoreOnly version mismatch between Podfile.lock (12.4.0) and firebase_core plugin (12.9.0); resolved by regenerating Podfile.lock

---
---

## [1.0.3+121] - 2026-04-30

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.3+120] - 2026-04-30

### Added
- Nav bar loading state: a single animated spinner pill replaces the nav tabs while tab-visibility flags are being fetched from the backend on app start

### Changed
- Splash-to-screen transition duration reduced from 800 ms to 400 ms; curve changed from `easeOutExpo` to `easeOutCubic` for a snappier, non-dragging feel
- Auth screen ambient background animation deferred by 450 ms so it no longer competes with the incoming slide transition
- `MainScreen` and `HomeScreen` heavy init work (API calls, Hive opens) moved into `addPostFrameCallback` so they fire after the first frame rather than during the route transition
- FCM `NotificationService.deregister()` on logout and `NotificationService.init()` after login are now fire-and-forget (`.ignore()`) — `getToken()` has no native timeout and was blocking both flows indefinitely

### Fixed
- Logout button stuck in loading state indefinitely — `NotificationService.deregister()` was awaited on the logout path; `_messaging.getToken()` inside it could hang forever with no timeout
- Google login showed success toast but stayed on auth screen loading — `NotificationService.init()` was awaited for up to 6 seconds before navigation was triggered
- Added `finally` block to logout sheet so `_isLoading` always resets to `false` if the widget remains mounted after navigation

---
---

## [1.0.3+119] - 2026-04-29

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.3+118] - 2026-04-29

### Added
-

### Changed
-

### Fixed
- Navigation vibration now uses the `vibration` package on Android and supported mobile browsers, keeps `HapticFeedback.selectionClick()` on native iOS, and adds the missing Android `VIBRATE` permission
- Navigation vibration on iOS browsers remains limited by browser support for the Web Vibration API

---
---

## [1.0.3+117] - 2026-04-29

### Added
- Tutorial to guide users through the translation process (select language, peek at original text, navigate between questions)
- New localization strings for tutorial steps in English and Swedish
- New launcher icon foreground assets in multiple resolutions for adaptive icons

### Changed
- Batch attempt history panel now shows at most 3 most recent attempts and removes the inner bordered container for a cleaner layout
- Updated launcher icon configuration to use the new foreground asset for adaptive icons
- Refactored screens to use `TestscreenWrapper` for consistency in navigation

### Fixed
- Duplicate notifications prevented within a short time frame

---
---

## [1.0.3+116] - 2026-04-29

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.3+115] - 2026-04-29

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.3+114] - 2026-04-19

### Added
-

### Changed
- `_BatchRow` refactored into a self-contained expandable card (matching `_CategoryListItem` style) with `AnimatedContainer`, `ClipRRect`, `AnimatedSize`, and `AnimatedRotation` chevron — attempts now expand visually inside their own batch card
- Batch rows in category list and 2-layer exam view now rendered as individual padded cards instead of a shared grouped container
- Removed `isLast`/divider logic from `_BatchRow` in favour of gap-based spacing between cards

### Fixed
-

---
---

## [1.0.3+113] - 2026-04-18

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.3+112] - 2026-04-18

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.3+111] - 2026-04-18

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.3+110] - 2026-04-18

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.3+109] - 2026-04-18

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.3+108] - 2026-04-17

### Added
- **Kinetic Onboarding Experience** — a completely redesigned 4-step onboarding flow featuring product selection, plan tiers/pricing, and integrated Stripe payments. Includes custom animations, shimmering loading states, and a celebratory success overlay.
- **Nordic Kinetic Design System** — major theme overhaul for both light and dark modes. Dark mode now uses a "midnight ink" palette (`#09082F`) with vibrant Swedish blue/yellow accents and refined `GoogleFonts` (Lexend and Plus Jakarta Sans) typography.
- **Direct Stripe Bundle Payments** — support for purchasing multiple BCD products as a bundle with 20% savings and immediate backend payment confirmation.
- **User Cache & Storage Services** — new `UserCacheService` and `AppStorage` for robust local data management, including automatic cache wiping on logout or session expiry.
- **Onboarding Verification** — new widget tests to ensure the reliability of the multi-step onboarding and payment flow.
- **Auth Bottom Sheet** — new reusable authentication component for streamlined login/signup entry points.

### Changed
- **Auth Screen Overhaul** — modernized login/signup flow with state-based view navigation (landing, login, signup) and improved inline validation. Removed the legacy `TabController` dependency.
- **Splash Screen Transition** — replaced the fade-out effect with a premium slide-up transition from bottom to top; uses `Curves.easeOutExpo` and increased duration (800ms) for a more kinetic and modern feel.
- **Dashboard & API Optimization** — `fetchCurrentUser` now seeds the `BcdCache` directly from the user response dashboard tree, significantly reducing redundant API calls during app startup.
- **Main Screen Navigation** — replaced the `PageView` with an `IndexedStack` for instant tab switching and improved state preservation; removed complex index mapping and manual keep-alive logic.
- **Global Reset Flow** — enhanced logout logic to ensure all user-specific data (BCD cache, Hive boxes, in-memory providers) is reset before the next session starts.
- **Dependency Updates** — added `google_fonts`, `shimmer`, and `collection` packages for improved UI/UX and data handling.

### Fixed
- **Navigation Reliability** — improved tab switching and redirect logic when user permissions or visibility flags change dynamically.
- **Theme Consistency** — fixed multiple hardcoded colors to properly resolve using the new Nordic Kinetic Design System tokens in both themes.

---
---

## [1.0.3+107] - 2026-04-16

### Added
- **Exam Progress Dashboard** — new full-featured dashboard screen with exam overview cards, category/batch progress, weekly streak, and smart insights
- Dashboard is now the default landing screen (home icon); legacy Home screen only shown when `show_legacy_tests` is enabled on the user's account
- Notification bell with unread badge added to the dashboard AppBar
- Collapsible category sections in the 3-layer exam view — tap a category header to fold/unfold its batches into a single unified card
- "Continue" banner on the dashboard now shows the last attempted test and launches it when tapped
- All dashboard UI strings fully localised in English and Swedish

### Changed
- Progress tab moved to first position in the nav bar and given the home icon
- Legacy Home tab and Tests tab are now hidden unless `show_legacy_tests` is enabled from the backend
- "Continue" suggestion logic updated: now shows the **most recently attempted** batch instead of the next untouched one
- Nav fallback on tab removal redirects to Progress instead of Home

### Fixed
- `testAttempts` Hive box is now opened on-demand in `DashboardProvider` — fixes zero-attempt stats on web (page refresh) and mobile cold-start when the Home tab had never been visited
- BCD category tree (`BcdCache`) uses a `Completer` to deduplicate parallel fetch calls — prevents redundant API requests on simultaneous screen loads

---
---

## [1.0.3+106] - 2026-04-16

### Added
- **Exam Progress Dashboard** — new full-featured dashboard screen with exam overview cards, category/batch progress, weekly streak, and smart insights
- Dashboard is now the default landing screen (home icon); legacy Home screen only shown when `show_legacy_tests` is enabled on the user's account
- Notification bell with unread badge added to the dashboard AppBar
- Collapsible category sections in the 3-layer exam view — tap a category header to fold/unfold its batches into a single unified card
- "Continue" banner on the dashboard now shows the last attempted test and launches it when tapped
- All dashboard UI strings fully localised in English and Swedish

### Changed
- Progress tab moved to first position in the nav bar and given the home icon
- Legacy Home tab and Tests tab are now hidden unless `show_legacy_tests` is enabled from the backend
- "Continue" suggestion logic updated: now shows the **most recently attempted** batch instead of the next untouched one
- Nav fallback on tab removal redirects to Progress instead of Home

### Fixed
- `testAttempts` Hive box is now opened on-demand in `DashboardProvider` — fixes zero-attempt stats on web (page refresh) and mobile cold-start when the Home tab had never been visited
- BCD category tree (`BcdCache`) uses a `Completer` to deduplicate parallel fetch calls — prevents redundant API requests on simultaneous screen loads

---
---

## [1.0.3+105] - 2026-04-15

### Added

- Tap and hold on any translation key toggles between English and Swedish instantly in-app (Settings > Language must be set to "System" or "English/Swedish")

-

### Changed
-

### Fixed
- Fixed splash screen occasionally getting stuck on app startup
- Enhanced snackbar error handling and add new features in various screens

---
---

## [1.0.3+105] - 2026-04-15

### Added

- Tap and hold on any translation key toggles between English and Swedish instantly in-app (Settings > Language must be set to "System" or "English/Swedish")

-

### Changed
-

### Fixed
- Fixed splash screen occasionally getting stuck on app startup
-

---
---

## [1.0.3+104] - 2026-04-15

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.3+103] - 2026-04-15

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.3+102] - 2026-04-15

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.3+101] - 2026-04-15

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.3+100] - 2026-04-13

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.3+99] - 2026-04-13

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.3+98] - 2026-04-13

### Added
- Firebase Cloud Messaging integration for Android and web, including device token register/deregister with backend
- Notifications center screen with local notification history, unread state, mark-all-read, and clear-all actions
- Android 13+ runtime notification permission (`POST_NOTIFICATIONS`)

### Changed
- App startup now initializes notification persistence via Hive and registers notification provider globally
- Web build/runtime flow now relies on Flutter Firebase initialization only (removed duplicate manual init from `web/index.html`)
- Android build config now resolves NDK version from local properties (`android.ndkVersion` fallback to `flutter.ndkVersion`)

### Fixed
- Duplicate notification handling caused by repeated NotificationService listener initialization across auth/splash flows
- Potential duplicate push sends by deduplicating tokens server-side and avoiding duplicate active token ownership across users

---
---

## [1.0.3+97] - 2026-04-13

### Added
- Firebase Cloud Messaging integration for Android and web, including device token register/deregister with backend
- Notifications center screen with local notification history, unread state, mark-all-read, and clear-all actions
- Android 13+ runtime notification permission (`POST_NOTIFICATIONS`)

### Changed
- App startup now initializes notification persistence via Hive and registers notification provider globally
- Web build/runtime flow now relies on Flutter Firebase initialization only (removed duplicate manual init from `web/index.html`)
- Android build config now resolves NDK version from local properties (`android.ndkVersion` fallback to `flutter.ndkVersion`)

### Fixed
- Duplicate notification handling caused by repeated NotificationService listener initialization across auth/splash flows
- Potential duplicate push sends by deduplicating tokens server-side and avoiding duplicate active token ownership across users

---
---

## [1.0.3+96] - 2026-04-13

### Added
- Firebase Cloud Messaging integration for Android and web, including device token register/deregister with backend
- Notifications center screen with local notification history, unread state, mark-all-read, and clear-all actions
- Android 13+ runtime notification permission (`POST_NOTIFICATIONS`)

### Changed
- App startup now initializes notification persistence via Hive and registers notification provider globally
- Web build/runtime flow now relies on Flutter Firebase initialization only (removed duplicate manual init from `web/index.html`)
- Android build config now resolves NDK version from local properties (`android.ndkVersion` fallback to `flutter.ndkVersion`)

### Fixed
- Duplicate notification handling caused by repeated NotificationService listener initialization across auth/splash flows
- Potential duplicate push sends by deduplicating tokens server-side and avoiding duplicate active token ownership across users

---
---

## [1.0.3+95] - 2026-04-13

### Added
- Firebase Cloud Messaging integration for Android and web, including device token register/deregister with backend
- Notifications center screen with local notification history, unread state, mark-all-read, and clear-all actions
- Android 13+ runtime notification permission (`POST_NOTIFICATIONS`)

### Changed
- App startup now initializes notification persistence via Hive and registers notification provider globally
- Web build/runtime flow now relies on Flutter Firebase initialization only (removed duplicate manual init from `web/index.html`)
- Android build config now resolves NDK version from local properties (`android.ndkVersion` fallback to `flutter.ndkVersion`)

### Fixed
- Duplicate notification handling caused by repeated NotificationService listener initialization across auth/splash flows
- Potential duplicate push sends by deduplicating tokens server-side and avoiding duplicate active token ownership across users

---
---

## [1.0.3+94] - 2026-04-13

### Added
-

### Changed
- BCD category and subcategory lists now sort subscribed items first; shared the sorting logic in a common utility to keep both screens consistent

### Fixed
-

---
---

## [1.0.3+93] - 2026-04-13

### Added
-

### Changed
- Test randomization is now controlled from Settings: standard practice tests read the saved `Randomize Questions` and `Shuffle Question Order` preferences, and BCD test launches respect `Shuffle Question Order`

### Fixed
-

---
---

## [1.0.3+92] - 2026-04-13

### Added
- GoRouter (`go_router ^17`) with deep-link URL for every screen; replaced `beamer`
- `lib/core/router/app_router.dart` — `StatefulShellRoute.indexedStack` for 4 persistent tab branches (Home, Tests, BCD, Profile) with full route tree; `parentNavigatorKey: rootNavigatorKey` on immersive screens (test run, result, BCD test, custom test, attempt detail) so the floating nav pill is hidden during active test sessions
- `lib/core/router/auth_notifier.dart` — singleton `AuthNotifier` / `AuthStatus` enum drives GoRouter `refreshListenable` redirect; eliminates `NavigationService.navigatorKey` for auth-state navigation
- `lib/core/router/route_names.dart` — typed route path constants (`Routes.home`, `Routes.bcdTestsListPath()`, `Routes.testCustomPath()`, etc.)
- `lib/core/router/route_args.dart` — typed arg classes (`TestScreenArgs`, `ResultScreenArgs`, `SavedQuestionsArgs`, `BCDTestsListArgs`, `BCDCategoryArgs`, `BCDTestScreenArgs`) for `extra`-based params
- `lib/features/bcd/bcd_tests_list_screen.dart` — stand-alone routable `BCDTestsListScreen` extracted from the private class in the category hub; route `/bcd/exams/:categoryId/tests`
- `lib/features/bcd/bcd_documents_screen.dart` — stand-alone routable `BCDDocumentsScreen`; route `/bcd/exams/:categoryId/docs`
- `lib/features/bcd/bcd_checklists_screen.dart` — stand-alone routable `BCDChecklistsScreen`; route `/bcd/exams/:categoryId/checklists`
- Complete BCD deep-link URL tree: `/bcd`, `/bcd/exams`, `/bcd/exams/:id`, `/bcd/exams/:id/sub`, `/bcd/exams/:id/tests`, `/bcd/exams/:id/test/:testId`, `/bcd/exams/:id/docs`, `/bcd/exams/:id/checklists`, `/bcd/exams/:id/stats`, `/bcd/exams/:id/saved`, `/bcd/signs`, `/bcd/subscriptions`
- Complete Legacy Tests deep-link URL tree: `/tests`, `/tests/:licenceId/:categoryId`, `/tests/:licenceId/:categoryId/result`, `/tests/:licenceId/:categoryId/saved`, `/tests/:licenceId/:categoryId/custom`
- `MainShell` widget replaces `MainScreen`; bridges `StatefulNavigationShell.goBranch()` with `MainScreenProvider` so `HomeScreen`'s tab listener still fires

### Changed
- `MyApp` migrated from `MaterialApp` to `MaterialApp.router` with `routerConfig: AppRouter.router`
- `BCDCategoryHubScreen` navigation uses `context.push()` with typed route args for all hub tiles (tests, docs, checklists, traffic signs, stats, saved questions, practice)
- All `showDialog` and `showModalBottomSheet` calls across shell-branch screens now pass `useRootNavigator: true` — fixes overlays rendering behind the floating nav pill
- Dead private screen classes (`_BCDTestsListScreen`, `_BCDDocumentsScreen`, `_BCDChecklistsScreen`, `_TestCard`, `_Chip`, `_TestsSubscriptionBanner`) removed from `bcd_category_hub_screen.dart` after extraction to standalone files

### Fixed
- Floating nav pill rendering on top of dialogs and bottom sheets (logout confirmation, paywall, feedback, delete-test dialogs) — fixed with `useRootNavigator: true`
- Floating nav pill visible during active test sessions (test screen, BCD test screen, result screen) — fixed with `parentNavigatorKey: rootNavigatorKey` on immersive routes
- `BCDTestsListScreen` passed `_BCDTestArgsImpl` as route `extra` but router cast to `BCDTestScreenArgs` — replaced with `BCDTestScreenArgs` directly

---
---

## [1.0.3+91] - 2026-04-12

### Added
- Home screen: 5-minute backend sync cache via `HomeDataCache` — tab switches within the window use local Hive only; pull-to-refresh or returning from a test forces an immediate re-sync
- Home screen: pull-to-refresh (drag down) triggers a forced backend sync
- Bottom nav: drag-to-scrub gesture — slide finger across the pill to switch tabs live; indicator and icons follow the finger instantly
- Bottom nav: magnifying glass effect during drag — active icon scales to 1.45×, neighbours to 1.15×, indicator bubble expands and gets a primary-color glow
- Settings: three-way theme selector (System / Light / Dark) replaces the dark mode toggle switch; System is the new default
- Settings: app language defaults to device system locale when no preference is saved
- Help & Support screen: all strings localized (20 new EN + SV translation keys)

### Changed
- `HomeDataCache.invalidate()` is called whenever a test attempt is saved so the home screen always re-syncs after an exam
- Bottom nav: active icon uses `colorScheme.primary`, inactive uses `onSurface` at 40% opacity
- Bottom nav: indicator background is dark-mode aware (white 12% opacity in dark, grey.shade100 in light)
- `ThemeProvider` migrated from bool to string persistence (`'system'`/`'light'`/`'dark'`) with backward-compat migration of old bool key

### Fixed
-

---
---

## [1.0.3+90] - 2026-04-12

### Added
-

### Changed
- Dark mode: selected option tile background increased to 25% opacity primary blue (was 10%) for clear visibility
- Dark mode: selected option tile border increased to 2px primary blue
- Dark mode: selected option text uses `onSurface` (white) instead of primary blue — readable on blue-tinted background
- Dark mode: replaced all `Theme.of(context).primaryColor` with `colorScheme.primary` across option tile, test screen, progress header, and navigation controls — fixes incorrect color resolution in Material 3
- Test screen: timer pill and language picker pill backgrounds and borders use `colorScheme.primary` tint to match the progress bar color
- Test screen: timer icon and language icon use `colorScheme.primary` color

### Fixed
-

---
---

## [1.0.3+89] - 2026-04-12

### Added
- Font selection in Settings: users can switch between NudMoto and Inter; preference persists via SharedPreferences and applies immediately app-wide
- Inter font asset bundled (`assets/fonts/Inter.otf`)
- `FontProvider` (ChangeNotifier) with unit tests for default value, persistence, and listener notification
- Localization for all BCD screens: categories list, sub-categories, tests list, subscriptions, traffic signs, and test loader — all user-visible strings now use translation keys (EN + SV)
- New translation keys: `bcd_categories`, `bcd_subscribed`, `bcd_free_label`, `bcd_questions_label`, `bcd_pass_label`, `bcd_plans_tab`, `bcd_my_subscriptions_tab`, `bcd_expires`, `bcd_previous`, `bcd_next`, `bcd_view`, and 25+ more
- Test screen: tapping the timer pill toggles time visibility; hidden state shows a clock-off icon instead of the countdown

### Changed
- Default app font changed from NudMoto to Inter
- Theme builder refactored into `buildLightTheme(font)` / `buildDarkTheme(font)` functions so font selection propagates through the entire app via `ThemeData`
- Removed all hardcoded `fontFamily: 'NudMoto'` overrides from `auth_screen.dart`, `forgot_password_screen.dart`, and `question_widget.dart`
- BCD test attempt screen timer and instant-marking can now be toggled mid-test via the three-dots menu
- Popup menu divider replaced with a lighter grey `Divider` (was too dark)
- BCD category hub tiles now have distinct per-tile colors (emerald, indigo, amber, red, violet, sky blue, pink)
- Dark mode: scaffold and AppBar backgrounds now theme-driven across all screens (removed all hardcoded `Colors.white` / `Colors.grey[50]`)
- Dark mode: dark theme palette updated — scaffold `#121212`, card `#242424`, surface `#1E1E1E`, AppBar/bottom nav `#1A1A1A`, divider `#3A3A3A` for improved contrast
- Dark mode: option tiles use brightness-aware border (`Colors.white` 15% opacity) and card background instead of hardcoded light colors
- Dark mode: question progress header pill uses semi-transparent white overlay and border in dark mode; light mode uses `Colors.grey.shade200` border (subtle)
- Dark mode: BCD hub tile labels ("Practice", "Tests", etc.) use `colorScheme.onSurface` instead of hardcoded `Colors.black87`
- Dark mode: BCD hub tile background is `cardColor` in dark mode instead of tinted pastel (prevents green/indigo/red tint bleed)
- Dark mode: all `Colors.X.shade50` pastel backgrounds replaced with `Colors.X.withValues(alpha: 0.12)` for universal light/dark compatibility
- Dark mode: shimmer skeletons use dark-mode-aware base/highlight colors across home, BCD, and tests screens
- Dark mode: navigation controls, attempt cards, progress cards, licence type cards, attempt group chips all use theme-aware colors
- Dark mode: stats screen — all white card containers, borders, icon backgrounds, and scaffold color use theme values
- Dark mode: BCD traffic signs screen — AppBar, nav arrows, sign cards use theme colors
- Dark mode: settings screen — font and language icon containers use opacity-based backgrounds in dark mode
- Dark mode: question text, back arrow, more-vert icon, timer pill, and explanation box in test screen are all theme-aware
- Dark mode: expandable explanation widget icon uses `colorScheme.onSurface` (was hardcoded `Colors.black`)
- Dark mode: question navigation bottom sheet and main tab bar use `cardColor`
- Light mode: pill borders (progress header, timer, language picker) use `Colors.grey.shade200` — was too dark with `dividerColor`

### Fixed
- `bcd_subscribe_access` translation invocation error (slang generated getter, not function) — resolved with `.replaceAll('{name}', categoryName)`
- Dark mode: home screen quick stats, activity items, BCD badges, licence tab backgrounds, and pie chart labels all fixed
- Dark mode: question navigation sheet items in test screen no longer show white `Colors.grey[50]` background

---
---
---
---
---
---

## [1.0.3+84] - 2026-04-11

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.3+83] - 2026-04-11

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.3+82] - 2026-04-03

### Added

- Admin backend info panel in Settings (branch, commit, deploy date, debug mode) — visible to admin users only
- Demo account protection: username and email fields are locked in Edit Profile with a warning banner
- Human-readable deploy date in admin backend info panel

### Changed

- Deploy commit now includes Play Store release notes alongside pubspec.yaml and CHANGELOG.md
- Single git commit at end of deploy-all instead of one per platform

### Fixed

-

---
---

## [1.0.3+81] - 2026-04-03

### Added

- **Admin backend info panel**: Admin users see a "Backend Info" section in Settings showing live backend status, debug mode, branch, commit hash, deploy date, author, and commit message — fetched from `GET /api/version/`.
- **Demo account username/email lock**: Edit Profile screen shows a warning banner and makes username/email fields read-only (with lock icon) for demo accounts. Save Changes button is also disabled.
- **Human-readable deploy date**: "Last Deploy" in the admin backend info panel is formatted as local date/time (e.g. "Apr 3, 2025 2:15 PM") instead of a raw ISO 8601 string.

### Changed

-

### Fixed

-

---
---

## [1.0.3+80] - 2026-04-03

### Added

-

### Changed

-

### Fixed

-

---

## [1.0.3+79] - 2026-04-02

### Added

- Edit Profile screen with update profile fields, conditional set-password section, and delete-account action
- Backend support for profile update (`PATCH /api/user/self/`) and set password (`POST /api/user/set-password/`)
- Backend `is_first_login` flag in auth responses (`/api/token/` and `/api/user/google-auth/`)
- Localized auth greeting keys for first-time login, returning login, and deleted-account welcome-back messaging

### Changed

- Account deletion switched back to hard delete path (removes user and user-linked data)
- Auth greetings now use backend `is_first_login` instead of device-local first-run tracking
- All auth greeting/snackbar texts moved to translation files (English + Swedish)
- Auth notification phrases shortened for compact display in top toast

### Fixed

- Profile -> Edit Profile navigation reliability improved after fresh login/signup sessions
- Auth/profile API error handling now surfaces backend field validation messages (for example duplicate username)
- Long notification text visibility improved by rendering toast content via multi-line description instead of one-line title

---

## [1.0.3+78] - 2026-04-02

### Added

-

### Changed

- Removed user-facing `BCD` wording from labels and subscription/payment fallbacks in the app UI

### Fixed

- Prevented `BCD` from reappearing in subscription fallback titles

---

## [1.0.3+77] - 2026-04-02

### Added

- Success toast notification after login (username/password and Google sign-in)
- Success toast notification after logout
- Global snackbar queue cap to keep at most 3 toast notifications visible at once

### Changed

- Centralized snackbar helper now tracks active toast items and removes the oldest toast when the visible limit is reached

### Fixed

-

---

## [1.0.3+76] - 2026-04-02

### Added

-

### Changed

-

### Fixed

-

---

## [1.0.3+75] - 2026-04-02

### Added

-

### Changed

-

### Fixed

- Clear `testAttempts` Hive box on logout before closing/deleting Hive to prevent previous user's exam attempts from showing on web (where `deleteFromDisk()` is unreliable)

---

## [1.0.3+74] - 2026-04-01

### Added

-

### Changed

-

### Fixed

-

---

## [1.0.3+73] - 2026-03-31

### Added

- Full-screen purchase success modal after subscription confirmation, including localized primary/secondary actions: "Start Tests" and "Back to home"
- New localization keys in English and Swedish for purchase success title and CTA labels

### Changed

- Purchase success UX redesigned from an auto-dismissing bottom sheet to a guided full-screen flow with fade/scale animations and decorative celebratory visuals
- Auth validation refactored to use consistent inline, field-level errors for both login and signup with live error clearing while typing
- Auth header controls polished with a pill-style language/theme switcher for cleaner visual hierarchy
- Updated `web` dependency from `^1.0.0` to `^1.1.1`

### Fixed

- Signup error handling now maps server-side field errors into the same inline UI used by client-side validation for consistent feedback

---

## [1.0.3+72] - 2026-03-31

### Added

-

### Changed

-

### Fixed

-

---

## [1.0.3+71] - 2026-03-31

### Added

-

### Changed

-

### Fixed

-

---

## [1.0.3+70] - 2026-03-31

### Added

-

### Changed

-

### Fixed

-

---

## [1.0.3+69] - 2026-03-31

### Added

- Google Sign-In (express login) button on the auth screen — one-tap login via Google account
- Forgot password screen with email-based reset instructions, back-to-login navigation, and success/error feedback
- Show/hide password toggle on login and signup fields
- Tab-based login/signup UI within a single auth screen; tabs animate to signup on successful registration
- 14 new localization keys in English and Swedish covering Google button label, tab labels ("Log in" / "Sign up"), show/hide password, and the full forgot-password flow

### Changed

- Auth flow consolidated: separate `LoginScreen` and `SignupScreen` replaced by a unified tabbed `AuthScreen`, reducing navigation stack depth
- Auth screen replaced Lottie welcome animation with app icon; layout is now responsive (scales down gracefully on shorter screens, minimum 0.78× factor)
- Field containers use theme-aware backgrounds (dark: card colour, light: tinted surface) instead of hard-coded white
- Replaced `page_transition` package navigation with `AppPageRoute` for auth-screen transitions
- Removed tooltip text from the dark-mode toggle button in the auth header

---

## [1.0.3+68] - 2026-03-29

### Added

-

### Changed

-

### Fixed

-

---

## [1.0.3+67] - 2026-03-29

### Added

-

### Changed

-

### Fixed

-

---

## [1.0.3+66] - 2026-03-29

### Changed

- Bug fixes and improvements

---

## [1.0.2+19] - 2026-03-27

### Added

- Traffic signs redesigned with modern card UI, image slider with dot indicators, and swipe navigation
- Traffic sign detail view with per-sign image viewer, progress bar, and prev/next navigation

### Changed

- Categories page no longer reloads on back navigation — scroll position is preserved
- Categories animate only on first load; returning feels instant
- Pull-to-refresh on categories page; auto-refreshes silently every hour

### Fixed

- Traffic sign images returning 404 due to double path prefix in database
- Lottie animations on web returning 404 (wrong asset path)

---

## [1.0.0+1] - 2025-01-10

### Added

- Firebase Analytics integration for purchase tracking
- Analytics events for Buy Now button clicks
- Complete purchase funnel tracking (dialog shown, payment method selected, success/failure)
- User behavior monitoring for subscription flow

### Changed

- Updated Firebase dependencies (firebase_core, firebase_analytics)
- Removed AD_ID permission to comply with Google Play requirements

### Fixed

- Google Play Console AD_ID permission declaration error

---

<!-- Template for new releases:

## [VERSION] - YYYY-MM-DD

### Added

- New features

### Changed

- Changes in existing functionality

### Removed

- Now removed features

### Fixed

- Bug fixes

### Security

- Security fixes

-->
