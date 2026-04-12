# Changelog

All notable changes to DriveTest app will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!-- markdownlint-disable MD024 -->

## [Unreleased]

### Added
- Font selection in Settings: users can switch between NudMoto and Inter; preference persists via SharedPreferences and applies immediately app-wide
- Inter font asset bundled (`assets/fonts/Inter.otf`)
- `FontProvider` (ChangeNotifier) with unit tests for default value, persistence, and listener notification
- Localization for all BCD screens: categories list, sub-categories, tests list, subscriptions, traffic signs, and test loader — all user-visible strings now use translation keys (EN + SV)
- New translation keys: `bcd_categories`, `bcd_subscribed`, `bcd_free_label`, `bcd_questions_label`, `bcd_pass_label`, `bcd_plans_tab`, `bcd_my_subscriptions_tab`, `bcd_expires`, `bcd_previous`, `bcd_next`, `bcd_view`, and 25+ more

### Changed
- Default app font changed from NudMoto to Inter
- Theme builder refactored into `buildLightTheme(font)` / `buildDarkTheme(font)` functions so font selection propagates through the entire app via `ThemeData`
- Removed all hardcoded `fontFamily: 'NudMoto'` overrides from `auth_screen.dart`, `forgot_password_screen.dart`, and `question_widget.dart`
- BCD test attempt screen timer and instant-marking can now be toggled mid-test via the three-dots menu
- Popup menu divider replaced with a lighter grey `Divider` (was too dark)
- BCD category hub tiles now have distinct per-tile colors (emerald, indigo, amber, red, violet, sky blue, pink)

### Fixed
- `bcd_subscribe_access` translation invocation error (slang generated getter, not function) — resolved with `.replaceAll('{name}', categoryName)`

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
