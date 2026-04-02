# Changelog

All notable changes to DriveTest app will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
-

### Changed
-

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
---

## [1.0.3+75] - 2026-04-02

### Added
-

### Changed
-

### Fixed
- Clear `testAttempts` Hive box on logout before closing/deleting Hive to prevent previous user's exam attempts from showing on web (where `deleteFromDisk()` is unreliable)

---
---

## [1.0.3+74] - 2026-04-01

### Added
-

### Changed
-

### Fixed
-

---
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
---

## [1.0.3+72] - 2026-03-31

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.3+71] - 2026-03-31

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.3+70] - 2026-03-31

### Added
-

### Changed
-

### Fixed
-

---
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
---

## [1.0.3+68] - 2026-03-29

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.3+67] - 2026-03-29

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.3+66] - 2026-03-29

### Changed
- Bug fixes and improvements

---
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

### Deprecated
- Soon-to-be removed features

### Removed
- Now removed features

### Fixed
- Bug fixes

### Security
- Security fixes

-->
