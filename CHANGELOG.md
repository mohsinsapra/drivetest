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

## [1.3.1+276] - 2026-06-03

### Added
- **Smart Test — Check & Reveal**: Selecting an answer no longer reveals the result instantly. Tap **Check** to see if you were right, then **Next** to move on — giving you a moment to think before the answer is shown.
- **Language button in Smart Test**: The three-dot menu is replaced by a language chip in the top bar (same style as the timer). Tap it to switch the question language.
- **Smart language memory**: The app remembers which language you translate questions to most often. Next time you open a Smart Test or regular Test, that translation is downloaded silently in the background — hold anywhere on the screen to switch to it instantly, no language menu needed.
- **Smarter reminder notifications**: Reminder messages now mention the specific exam you were last studying, so you always know exactly what to pick up. Messages are shown in your app language (Swedish or English).
- **Notification subtitle**: All local reminders now display "DriveTest" as the subtitle on iOS and Android for a cleaner, more polished look.

### Changed
- **Progress bar**: The progress bar in test screens no longer has a border or pill container around it — just a clean, rounded bar. Also slightly taller in Smart Test for better visibility. The bar is always fully rounded at both ends, even at the very start.
- **Long-press gesture area in Smart Test**: The hold-to-translate gesture now works across the entire screen area, not just over the question and options.

### Fixed
- Fixed notifications sometimes showing only the app icon with no text when the exam title was missing — a fallback title is now used.
- Fixed foreground push notifications showing ": message" when the title was empty.

---
---
---

## [1.3.0+275] - 2026-06-03

### Added
- **Smart Test — Check & Reveal**: Selecting an answer no longer reveals the result instantly. Tap **Check** to see if you were right, then **Next** to move on — giving you a moment to think before the answer is shown.
- **Language button in Smart Test**: The three-dot menu is replaced by a language chip in the top bar (same style as the timer). Tap it to switch the question language.
- **Smart language memory**: The app remembers which language you translate questions to most often. Next time you open a Smart Test or regular Test, that translation is downloaded silently in the background — hold anywhere on the screen to switch to it instantly, no language menu needed.
- **Smarter reminder notifications**: Reminder messages now mention the specific exam you were last studying, so you always know exactly what to pick up. Messages are shown in your app language (Swedish or English).
- **Notification subtitle**: All local reminders now display "DriveTest" as the subtitle on iOS and Android for a cleaner, more polished look.

### Changed
- **Progress bar**: The progress bar in test screens no longer has a border or pill container around it — just a clean, rounded bar. Also slightly taller in Smart Test for better visibility. The bar is always fully rounded at both ends, even at the very start.
- **Long-press gesture area in Smart Test**: The hold-to-translate gesture now works across the entire screen area, not just over the question and options.

### Fixed
- Fixed notifications sometimes showing only the app icon with no text when the exam title was missing — a fallback title is now used.
- Fixed foreground push notifications showing ": message" when the title was empty.

---
---

## [1.2.1+274] - 2026-06-01

### Added
- **Activity Reminder Notifications**: After each exam or Smart Learning session, a local notification is scheduled 24 hours later. Notification uses the exam title and a randomised hook phrase (EN/SV). Tapping the notification deep-links directly into the relevant Smart Exam or Test screen.
- **In-App Review prompt**: Requests a store review after the user's first *passed* exam attempt and first *passed* Smart Learning session (reuses the existing 3–5 day throttle logic).
- **Hearts/Lives onboarding guide**: First time a user enters a mock exam with the hearts system enabled, a TutorialCoachMark spotlight highlights the hearts chip and explains the lives mechanic.
- **Upgrade alert moved to Dashboard**: `UpgradeAlert` now wraps `ExamDashboardScreen` instead of `HomeScreen` so update prompts appear at the natural entry point.

### Changed
- Option tile selection-to-result animation no longer bounces; the indicator smoothly scales from the circle to a check/cross with a two-phase shrink-then-grow transition.
- Explanation text on correct-answer tiles now expands with a smooth `ClipRect`+`Align(heightFactor)` animation (900 ms, `easeInOut`) instead of an instant reveal — works reliably on every question in a `PageView`, not just the first.
- Smart Exam chunk card subtitle no longer shows a bullet separator between question count and pass requirement.
- Practice Mistakes card on the Smart Learning category screen no longer shows a solid border outline.

### Fixed
- Fixed `_elements.contains(element)` Flutter assertion crash on option tiles caused by using `SingleTickerProviderStateMixin` with two `AnimationController`s — changed to `TickerProviderStateMixin`.
- Activity reminder notification deep-link payload parsing now uses safe casts (`(num?)?.toInt()`, nullable String guards) to avoid runtime throws on malformed payloads.

---
---
---
---
---
---
---
---
---
---
---

## [1.2.0+273] - 2026-06-01

### Added
- **Activity Reminder Notifications**: After each exam or Smart Learning session, a local notification is scheduled 24 hours later. Notification uses the exam title and a randomised hook phrase (EN/SV). Tapping the notification deep-links directly into the relevant Smart Exam or Test screen.
- **In-App Review prompt**: Requests a store review after the user's first *passed* exam attempt and first *passed* Smart Learning session (reuses the existing 3–5 day throttle logic).
- **Hearts/Lives onboarding guide**: First time a user enters a mock exam with the hearts system enabled, a TutorialCoachMark spotlight highlights the hearts chip and explains the lives mechanic.
- **Upgrade alert moved to Dashboard**: `UpgradeAlert` now wraps `ExamDashboardScreen` instead of `HomeScreen` so update prompts appear at the natural entry point.

### Changed
- Option tile selection-to-result animation no longer bounces; the indicator smoothly scales from the circle to a check/cross with a two-phase shrink-then-grow transition.
- Explanation text on correct-answer tiles now expands with a smooth `ClipRect`+`Align(heightFactor)` animation (900 ms, `easeInOut`) instead of an instant reveal — works reliably on every question in a `PageView`, not just the first.
- Smart Exam chunk card subtitle no longer shows a bullet separator between question count and pass requirement.
- Practice Mistakes card on the Smart Learning category screen no longer shows a solid border outline.

### Fixed
- Fixed `_elements.contains(element)` Flutter assertion crash on option tiles caused by using `SingleTickerProviderStateMixin` with two `AnimationController`s — changed to `TickerProviderStateMixin`.
- Activity reminder notification deep-link payload parsing now uses safe casts (`(num?)?.toInt()`, nullable String guards) to avoid runtime throws on malformed payloads.

---
---
---
---
---
---
---
---
---
---

## [1.1.74+272] - 2026-06-01

### Added
- **Activity Reminder Notifications**: After each exam or Smart Learning session, a local notification is scheduled 24 hours later. Notification uses the exam title and a randomised hook phrase (EN/SV). Tapping the notification deep-links directly into the relevant Smart Exam or Test screen.
- **In-App Review prompt**: Requests a store review after the user's first *passed* exam attempt and first *passed* Smart Learning session (reuses the existing 3–5 day throttle logic).
- **Hearts/Lives onboarding guide**: First time a user enters a mock exam with the hearts system enabled, a TutorialCoachMark spotlight highlights the hearts chip and explains the lives mechanic.
- **Upgrade alert moved to Dashboard**: `UpgradeAlert` now wraps `ExamDashboardScreen` instead of `HomeScreen` so update prompts appear at the natural entry point.

### Changed
- Option tile selection-to-result animation no longer bounces; the indicator smoothly scales from the circle to a check/cross with a two-phase shrink-then-grow transition.
- Explanation text on correct-answer tiles now expands with a smooth `ClipRect`+`Align(heightFactor)` animation (900 ms, `easeInOut`) instead of an instant reveal — works reliably on every question in a `PageView`, not just the first.
- Smart Exam chunk card subtitle no longer shows a bullet separator between question count and pass requirement.
- Practice Mistakes card on the Smart Learning category screen no longer shows a solid border outline.

### Fixed
- Fixed `_elements.contains(element)` Flutter assertion crash on option tiles caused by using `SingleTickerProviderStateMixin` with two `AnimationController`s — changed to `TickerProviderStateMixin`.
- Activity reminder notification deep-link payload parsing now uses safe casts (`(num?)?.toInt()`, nullable String guards) to avoid runtime throws on malformed payloads.

---
---
---
---
---
---
---
---
---

## [1.1.73+271] - 2026-06-01

### Added
- **Activity Reminder Notifications**: After each exam or Smart Learning session, a local notification is scheduled 24 hours later. Notification uses the exam title and a randomised hook phrase (EN/SV). Tapping the notification deep-links directly into the relevant Smart Exam or Test screen.
- **In-App Review prompt**: Requests a store review after the user's first *passed* exam attempt and first *passed* Smart Learning session (reuses the existing 3–5 day throttle logic).
- **Hearts/Lives onboarding guide**: First time a user enters a mock exam with the hearts system enabled, a TutorialCoachMark spotlight highlights the hearts chip and explains the lives mechanic.
- **Upgrade alert moved to Dashboard**: `UpgradeAlert` now wraps `ExamDashboardScreen` instead of `HomeScreen` so update prompts appear at the natural entry point.

### Changed
- Option tile selection-to-result animation no longer bounces; the indicator smoothly scales from the circle to a check/cross with a two-phase shrink-then-grow transition.
- Explanation text on correct-answer tiles now expands with a smooth `ClipRect`+`Align(heightFactor)` animation (900 ms, `easeInOut`) instead of an instant reveal — works reliably on every question in a `PageView`, not just the first.
- Smart Exam chunk card subtitle no longer shows a bullet separator between question count and pass requirement.
- Practice Mistakes card on the Smart Learning category screen no longer shows a solid border outline.

### Fixed
- Fixed `_elements.contains(element)` Flutter assertion crash on option tiles caused by using `SingleTickerProviderStateMixin` with two `AnimationController`s — changed to `TickerProviderStateMixin`.
- Activity reminder notification deep-link payload parsing now uses safe casts (`(num?)?.toInt()`, nullable String guards) to avoid runtime throws on malformed payloads.

---
---
---
---
---
---
---
---

## [1.1.72+270] - 2026-06-01

### Added
- **Activity Reminder Notifications**: After each exam or Smart Learning session, a local notification is scheduled 24 hours later. Notification uses the exam title and a randomised hook phrase (EN/SV). Tapping the notification deep-links directly into the relevant Smart Exam or Test screen.
- **In-App Review prompt**: Requests a store review after the user's first *passed* exam attempt and first *passed* Smart Learning session (reuses the existing 3–5 day throttle logic).
- **Hearts/Lives onboarding guide**: First time a user enters a mock exam with the hearts system enabled, a TutorialCoachMark spotlight highlights the hearts chip and explains the lives mechanic.
- **Upgrade alert moved to Dashboard**: `UpgradeAlert` now wraps `ExamDashboardScreen` instead of `HomeScreen` so update prompts appear at the natural entry point.

### Changed
- Option tile selection-to-result animation no longer bounces; the indicator smoothly scales from the circle to a check/cross with a two-phase shrink-then-grow transition.
- Explanation text on correct-answer tiles now expands with a smooth `ClipRect`+`Align(heightFactor)` animation (900 ms, `easeInOut`) instead of an instant reveal — works reliably on every question in a `PageView`, not just the first.
- Smart Exam chunk card subtitle no longer shows a bullet separator between question count and pass requirement.
- Practice Mistakes card on the Smart Learning category screen no longer shows a solid border outline.

### Fixed
- Fixed `_elements.contains(element)` Flutter assertion crash on option tiles caused by using `SingleTickerProviderStateMixin` with two `AnimationController`s — changed to `TickerProviderStateMixin`.
- Activity reminder notification deep-link payload parsing now uses safe casts (`(num?)?.toInt()`, nullable String guards) to avoid runtime throws on malformed payloads.

---
---
---
---
---
---
---

## [1.1.71+269] - 2026-05-31

### Added
- **Activity Reminder Notifications**: After each exam or Smart Learning session, a local notification is scheduled 24 hours later. Notification uses the exam title and a randomised hook phrase (EN/SV). Tapping the notification deep-links directly into the relevant Smart Exam or Test screen.
- **In-App Review prompt**: Requests a store review after the user's first *passed* exam attempt and first *passed* Smart Learning session (reuses the existing 3–5 day throttle logic).
- **Hearts/Lives onboarding guide**: First time a user enters a mock exam with the hearts system enabled, a TutorialCoachMark spotlight highlights the hearts chip and explains the lives mechanic.
- **Upgrade alert moved to Dashboard**: `UpgradeAlert` now wraps `ExamDashboardScreen` instead of `HomeScreen` so update prompts appear at the natural entry point.

### Changed
- Option tile selection-to-result animation no longer bounces; the indicator smoothly scales from the circle to a check/cross with a two-phase shrink-then-grow transition.
- Explanation text on correct-answer tiles now expands with a smooth `ClipRect`+`Align(heightFactor)` animation (900 ms, `easeInOut`) instead of an instant reveal — works reliably on every question in a `PageView`, not just the first.
- Smart Exam chunk card subtitle no longer shows a bullet separator between question count and pass requirement.
- Practice Mistakes card on the Smart Learning category screen no longer shows a solid border outline.

### Fixed
- Fixed `_elements.contains(element)` Flutter assertion crash on option tiles caused by using `SingleTickerProviderStateMixin` with two `AnimationController`s — changed to `TickerProviderStateMixin`.
- Activity reminder notification deep-link payload parsing now uses safe casts (`(num?)?.toInt()`, nullable String guards) to avoid runtime throws on malformed payloads.

---
---
---
---
---
---

## [1.1.70+268] - 2026-05-31

### Added
- **Activity Reminder Notifications**: After each exam or Smart Learning session, a local notification is scheduled 24 hours later. Notification uses the exam title and a randomised hook phrase (EN/SV). Tapping the notification deep-links directly into the relevant Smart Exam or Test screen.
- **In-App Review prompt**: Requests a store review after the user's first *passed* exam attempt and first *passed* Smart Learning session (reuses the existing 3–5 day throttle logic).
- **Hearts/Lives onboarding guide**: First time a user enters a mock exam with the hearts system enabled, a TutorialCoachMark spotlight highlights the hearts chip and explains the lives mechanic.
- **Upgrade alert moved to Dashboard**: `UpgradeAlert` now wraps `ExamDashboardScreen` instead of `HomeScreen` so update prompts appear at the natural entry point.

### Changed
- Option tile selection-to-result animation no longer bounces; the indicator smoothly scales from the circle to a check/cross with a two-phase shrink-then-grow transition.
- Explanation text on correct-answer tiles now expands with a smooth `ClipRect`+`Align(heightFactor)` animation (900 ms, `easeInOut`) instead of an instant reveal — works reliably on every question in a `PageView`, not just the first.
- Smart Exam chunk card subtitle no longer shows a bullet separator between question count and pass requirement.
- Practice Mistakes card on the Smart Learning category screen no longer shows a solid border outline.

### Fixed
- Fixed `_elements.contains(element)` Flutter assertion crash on option tiles caused by using `SingleTickerProviderStateMixin` with two `AnimationController`s — changed to `TickerProviderStateMixin`.
- Activity reminder notification deep-link payload parsing now uses safe casts (`(num?)?.toInt()`, nullable String guards) to avoid runtime throws on malformed payloads.

---
---
---
---
---

## [1.1.69+267] - 2026-05-31

### Added
- **Activity Reminder Notifications**: After each exam or Smart Learning session, a local notification is scheduled 24 hours later. Notification uses the exam title and a randomised hook phrase (EN/SV). Tapping the notification deep-links directly into the relevant Smart Exam or Test screen.
- **In-App Review prompt**: Requests a store review after the user's first *passed* exam attempt and first *passed* Smart Learning session (reuses the existing 3–5 day throttle logic).
- **Hearts/Lives onboarding guide**: First time a user enters a mock exam with the hearts system enabled, a TutorialCoachMark spotlight highlights the hearts chip and explains the lives mechanic.
- **Upgrade alert moved to Dashboard**: `UpgradeAlert` now wraps `ExamDashboardScreen` instead of `HomeScreen` so update prompts appear at the natural entry point.

### Changed
- Option tile selection-to-result animation no longer bounces; the indicator smoothly scales from the circle to a check/cross with a two-phase shrink-then-grow transition.
- Explanation text on correct-answer tiles now expands with a smooth `ClipRect`+`Align(heightFactor)` animation (900 ms, `easeInOut`) instead of an instant reveal — works reliably on every question in a `PageView`, not just the first.
- Smart Exam chunk card subtitle no longer shows a bullet separator between question count and pass requirement.
- Practice Mistakes card on the Smart Learning category screen no longer shows a solid border outline.

### Fixed
- Fixed `_elements.contains(element)` Flutter assertion crash on option tiles caused by using `SingleTickerProviderStateMixin` with two `AnimationController`s — changed to `TickerProviderStateMixin`.
- Activity reminder notification deep-link payload parsing now uses safe casts (`(num?)?.toInt()`, nullable String guards) to avoid runtime throws on malformed payloads.

---
---
---
---

## [1.1.68+266] - 2026-05-31

### Added
- **Activity Reminder Notifications**: After each exam or Smart Learning session, a local notification is scheduled 24 hours later. Notification uses the exam title and a randomised hook phrase (EN/SV). Tapping the notification deep-links directly into the relevant Smart Exam or Test screen.
- **In-App Review prompt**: Requests a store review after the user's first *passed* exam attempt and first *passed* Smart Learning session (reuses the existing 3–5 day throttle logic).
- **Hearts/Lives onboarding guide**: First time a user enters a mock exam with the hearts system enabled, a TutorialCoachMark spotlight highlights the hearts chip and explains the lives mechanic.
- **Upgrade alert moved to Dashboard**: `UpgradeAlert` now wraps `ExamDashboardScreen` instead of `HomeScreen` so update prompts appear at the natural entry point.

### Changed
- Option tile selection-to-result animation no longer bounces; the indicator smoothly scales from the circle to a check/cross with a two-phase shrink-then-grow transition.
- Explanation text on correct-answer tiles now expands with a smooth `ClipRect`+`Align(heightFactor)` animation (900 ms, `easeInOut`) instead of an instant reveal — works reliably on every question in a `PageView`, not just the first.
- Smart Exam chunk card subtitle no longer shows a bullet separator between question count and pass requirement.
- Practice Mistakes card on the Smart Learning category screen no longer shows a solid border outline.

### Fixed
- Fixed `_elements.contains(element)` Flutter assertion crash on option tiles caused by using `SingleTickerProviderStateMixin` with two `AnimationController`s — changed to `TickerProviderStateMixin`.
- Activity reminder notification deep-link payload parsing now uses safe casts (`(num?)?.toInt()`, nullable String guards) to avoid runtime throws on malformed payloads.

---
---
---

## [1.1.67+265] - 2026-05-31

### Added
- **Activity Reminder Notifications**: After each exam or Smart Learning session, a local notification is scheduled 24 hours later. Notification uses the exam title and a randomised hook phrase (EN/SV). Tapping the notification deep-links directly into the relevant Smart Exam or Test screen.
- **In-App Review prompt**: Requests a store review after the user's first *passed* exam attempt and first *passed* Smart Learning session (reuses the existing 3–5 day throttle logic).
- **Hearts/Lives onboarding guide**: First time a user enters a mock exam with the hearts system enabled, a TutorialCoachMark spotlight highlights the hearts chip and explains the lives mechanic.
- **Upgrade alert moved to Dashboard**: `UpgradeAlert` now wraps `ExamDashboardScreen` instead of `HomeScreen` so update prompts appear at the natural entry point.

### Changed
- Option tile selection-to-result animation no longer bounces; the indicator smoothly scales from the circle to a check/cross with a two-phase shrink-then-grow transition.
- Explanation text on correct-answer tiles now expands with a smooth `ClipRect`+`Align(heightFactor)` animation (900 ms, `easeInOut`) instead of an instant reveal — works reliably on every question in a `PageView`, not just the first.
- Smart Exam chunk card subtitle no longer shows a bullet separator between question count and pass requirement.
- Practice Mistakes card on the Smart Learning category screen no longer shows a solid border outline.

### Fixed
- Fixed `_elements.contains(element)` Flutter assertion crash on option tiles caused by using `SingleTickerProviderStateMixin` with two `AnimationController`s — changed to `TickerProviderStateMixin`.
- Activity reminder notification deep-link payload parsing now uses safe casts (`(num?)?.toInt()`, nullable String guards) to avoid runtime throws on malformed payloads.

---
---

## [1.1.66+264] - 2026-05-31

### Added
- **Smart Learning Feature**: A new structured learning path for BCD tests.
  - Auto-chunking of large question sets into manageable sessions (10-15 questions).
  - Weak Question Pool: Questions answered incorrectly are tracked and re-introduced in subsequent sessions for reinforcement.
  - Mastery Progress: Visual tracking of "Mastered" questions based on passed chunks.
  - Spaced Repetition: Graduating questions from the weak pool after consecutive correct answers.
- **Mock Exam Mode**: Enhanced `Testscreen` with a dedicated "Mock Exam" variant.
  - Conditional Hearts/Lives system (3 hearts) for early mock exam attempts.
  - Game-over state when hearts are depleted, with a specialized summary sheet.
  - Clean UI: Hides standard test controls (translation, feedback, timer toggles) in mock mode to simulate a real exam.
- **New Dashboard Components**:
  - `SmartJourneySection`: A visual progression map for the Smart Learning path.
  - Updated `PerformanceInsightCard` and `WeeklyStreakSection` for better visual consistency.
- **Testing**:
  - Added comprehensive widget tests for the new Mock Exam header and hearts behavior.
  - Unit tests for `SmartProgressService`, `SmartSessionBuilder`, and `SmartUtils`.

### Changed
- Refactored `Testscreen` to support modular headers and "Real-exam" constraints.
- Optimized `ApiService` with support for paginated and ID-specific question fetching.
- Enhanced question navigation grid with "Answered" count summary.
- Improved localized string support for Smart Learning feedback.

### Fixed
- Fixed layout overflows in dashboard carousels on smaller devices.
- Resolved issue where tutorial overlays could reappear in review modes.

---
---
---

### Added
-

### Added
- Reusable `AppBottomSheetContainer` component for consistent bottom sheet chrome across the app; supports optional `hint` slot for in-sheet tutorial banners
- Language selection bottom sheet with 3-column grid, flag tiles, checkmark on active language, and spinner on tile while translating
- Question navigation sheet redesigned as compact 8-column number grid with green tick on answered questions
- `auth_apple_connecting` translation key added to EN and SV locales
- Translation tutorial (2-step): spotlights three-dots menu → language sheet → press-and-hold peek; shows every session in debug builds via `reassemble()` override
- Tutorial hint banner inside language sheet during tutorial flow (`tut_step1_grid_hint` EN + SV)
- Extracted `TestTimerChip`, `QuestionPageItem`, `QuestionNavigationGrid`, `LanguageGrid`, `TutorialCard`, `TutorialCompleteOverlay` as standalone widgets under `features/tests/widgets/`

### Changed
- Test screen header: replaced bordered back button with plain close (X) icon; progress bar pill now stretches to fill available space
- Progress bar inner fill height increased to 10px with fully rounded ends for better visibility
- Timer pill redesigned to match AI action button style (primary tint background, no border)
- Language selector removed from AppBar actions; moved to three-dots menu as "Question Language" entry opening a sheet
- Language sheet uses `CupertinoScaffold.showCupertinoModalBottomSheet` via captured inner context for depth effect
- Question navigation sheet uses same Cupertino depth effect
- Timer text uses tabular figures to prevent width shifts as digits change
- `isSmallScreen` branch removed; language options always shown in three-dots menu
- Tutorial reduced from 4 steps to 2: swipe-left/right navigation steps removed; only translation and peek-original remain
- Tutorial step counters updated to "1 of 2" / "2 of 2" in both EN and SV
- Phase 2 (press-and-hold) now fires after the language sheet is dismissed, not immediately on language selection
- `test_screen.dart` reduced from ~2300 to ~1500 lines via component extraction

### Fixed
- Timer no longer shifts surrounding layout as digits change (tabular figures)
- Language sheet tick correctly moves to newly selected language via `ValueNotifier` (no parent rebuild needed)
- Full-screen loading overlay removed during question translation; tile spinner used instead
- Browser spell-check underlines removed from flag emoji and language names via `SelectionContainer.disabled()`
- Tutorial `FormatException` on missing key target fixed by pointing spotlight at the three-dots `PopupMenuButton` (`_langMenuKey`) instead of the removed standalone language button

---
---

## [1.1.65+263] - 2026-05-31

### Added
- **Smart Learning Feature**: A new structured learning path for BCD tests.
  - Auto-chunking of large question sets into manageable sessions (10-15 questions).
  - Weak Question Pool: Questions answered incorrectly are tracked and re-introduced in subsequent sessions for reinforcement.
  - Mastery Progress: Visual tracking of "Mastered" questions based on passed chunks.
  - Spaced Repetition: Graduating questions from the weak pool after consecutive correct answers.
- **Mock Exam Mode**: Enhanced `Testscreen` with a dedicated "Mock Exam" variant.
  - Conditional Hearts/Lives system (3 hearts) for early mock exam attempts.
  - Game-over state when hearts are depleted, with a specialized summary sheet.
  - Clean UI: Hides standard test controls (translation, feedback, timer toggles) in mock mode to simulate a real exam.
- **New Dashboard Components**:
  - `SmartJourneySection`: A visual progression map for the Smart Learning path.
  - Updated `PerformanceInsightCard` and `WeeklyStreakSection` for better visual consistency.
- **Testing**:
  - Added comprehensive widget tests for the new Mock Exam header and hearts behavior.
  - Unit tests for `SmartProgressService`, `SmartSessionBuilder`, and `SmartUtils`.

### Changed
- Refactored `Testscreen` to support modular headers and "Real-exam" constraints.
- Optimized `ApiService` with support for paginated and ID-specific question fetching.
- Enhanced question navigation grid with "Answered" count summary.
- Improved localized string support for Smart Learning feedback.

### Fixed
- Fixed layout overflows in dashboard carousels on smaller devices.
- Resolved issue where tutorial overlays could reappear in review modes.

---
---

### Added
-

### Added
- Reusable `AppBottomSheetContainer` component for consistent bottom sheet chrome across the app; supports optional `hint` slot for in-sheet tutorial banners
- Language selection bottom sheet with 3-column grid, flag tiles, checkmark on active language, and spinner on tile while translating
- Question navigation sheet redesigned as compact 8-column number grid with green tick on answered questions
- `auth_apple_connecting` translation key added to EN and SV locales
- Translation tutorial (2-step): spotlights three-dots menu → language sheet → press-and-hold peek; shows every session in debug builds via `reassemble()` override
- Tutorial hint banner inside language sheet during tutorial flow (`tut_step1_grid_hint` EN + SV)
- Extracted `TestTimerChip`, `QuestionPageItem`, `QuestionNavigationGrid`, `LanguageGrid`, `TutorialCard`, `TutorialCompleteOverlay` as standalone widgets under `features/tests/widgets/`

### Changed
- Test screen header: replaced bordered back button with plain close (X) icon; progress bar pill now stretches to fill available space
- Progress bar inner fill height increased to 10px with fully rounded ends for better visibility
- Timer pill redesigned to match AI action button style (primary tint background, no border)
- Language selector removed from AppBar actions; moved to three-dots menu as "Question Language" entry opening a sheet
- Language sheet uses `CupertinoScaffold.showCupertinoModalBottomSheet` via captured inner context for depth effect
- Question navigation sheet uses same Cupertino depth effect
- Timer text uses tabular figures to prevent width shifts as digits change
- `isSmallScreen` branch removed; language options always shown in three-dots menu
- Tutorial reduced from 4 steps to 2: swipe-left/right navigation steps removed; only translation and peek-original remain
- Tutorial step counters updated to "1 of 2" / "2 of 2" in both EN and SV
- Phase 2 (press-and-hold) now fires after the language sheet is dismissed, not immediately on language selection
- `test_screen.dart` reduced from ~2300 to ~1500 lines via component extraction

### Fixed
- Timer no longer shifts surrounding layout as digits change (tabular figures)
- Language sheet tick correctly moves to newly selected language via `ValueNotifier` (no parent rebuild needed)
- Full-screen loading overlay removed during question translation; tile spinner used instead
- Browser spell-check underlines removed from flag emoji and language names via `SelectionContainer.disabled()`
- Tutorial `FormatException` on missing key target fixed by pointing spotlight at the three-dots `PopupMenuButton` (`_langMenuKey`) instead of the removed standalone language button

---
---

## [1.1.63+261] - 2026-05-30

### Added
-

### Changed
- Update text styles and improve UI consistency
- Refactor text styles across various components to use `Lexend` font for better readability and consistency
- Adjust font weights for improved visual hierarchy
- Update layout elements to enhance user experience and maintain design standards

### Fixed
-

---
---
---
---
---

## [1.1.62+260] - 2026-05-30

### Added
-

### Changed
- Update text styles and improve UI consistency
- Refactor text styles across various components to use `Lexend` font for better readability and consistency
- Adjust font weights for improved visual hierarchy
- Update layout elements to enhance user experience and maintain design standards

### Fixed
-

---
---
---
---

## [1.1.61+259] - 2026-05-30

### Added
-

### Changed
- Update text styles and improve UI consistency
- Refactor text styles across various components to use `Lexend` font for better readability and consistency
- Adjust font weights for improved visual hierarchy
- Update layout elements to enhance user experience and maintain design standards

### Fixed
-

---
---
---

## [1.1.60+258] - 2026-05-29

### Added
-

### Changed
- Update text styles and improve UI consistency
- Refactor text styles across various components to use `Lexend` font for better readability and consistency
- Adjust font weights for improved visual hierarchy
- Update layout elements to enhance user experience and maintain design standards

### Fixed
-

---
---

## [1.1.59+257] - 2026-05-29

### Added
-

### Changed
- Refreshed app icons for a cleaner, more consistent look across devices
- Improved Android adaptive icon appearance for better visual quality on different launchers and screen types

### Fixed
-

---
---

## [1.1.58+256] - 2026-05-29

### Added
- Theme toggle in Settings for easy light/dark mode switching
- Google Fonts integration for improved typography across the app

### Changed
- Shimmer effect colors adjusted in exam carousel, performance insight, and performance metric cards for better visibility
- Focus categories section refactored with improved layout and user experience
- Question chat sheet optimized for smoother message rendering and scrolling behavior
- Refactored multiple bottom sheets to use shared `AppSheet` base widget for consistency

### Removed
- `recordAiUsage()` removed from `QuestionChatSheet` and `ApiService` — AI usage recording eliminated to avoid unnecessary API calls

---
---

## [1.1.57+255] - 2026-05-29

### Added
- **AI feature gate**: `ai_enabled` setting on `UserSettings` — controls access to AI-powered question chat per user (default `false`; auto-enabled on active subscription, auto-disabled when all subscriptions expire)
- **AI token tracking**: `UserAIUsage` model records every AI exchange with token count, category, licence/exam type, question ID, and question text
- `POST /api/user/ai-usage/` endpoint — records token usage, enforces AI gate server-side
- `/self` API now includes `ai_enabled` and `total_ai_tokens_used` fields
- **Analytics dashboard — AI Feature Usage section**: stat cards (total tokens, enabled users, 7-day active users/tokens, total sessions), daily tokens + sessions chart, exam-type pie chart, top categories bar chart, sessions vs tokens scatter chart, AI user leaderboard with token share bars, most-asked questions table
- `ai_enabled` admin controls: inline on User page, list-editable on User Settings page, bulk enable/disable actions
- `ApiService.recordAiUsage()` — sends token usage with category, licence, question context after every AI response
- AI chat defaults to app's selected language (Swedish/English) while allowing the user to ask in any language

### Changed
- AI chat buttons hidden for users without `ai_enabled` (loaded from `/self` on screen open)
- Token count uses Gemini `usageMetadata` when available, falls back to character-based estimate

---
---
---
---
---
---
---
---
---
---
---

## [1.1.56+254] - 2026-05-29

### Added
- **AI feature gate**: `ai_enabled` setting on `UserSettings` — controls access to AI-powered question chat per user (default `false`; auto-enabled on active subscription, auto-disabled when all subscriptions expire)
- **AI token tracking**: `UserAIUsage` model records every AI exchange with token count, category, licence/exam type, question ID, and question text
- `POST /api/user/ai-usage/` endpoint — records token usage, enforces AI gate server-side
- `/self` API now includes `ai_enabled` and `total_ai_tokens_used` fields
- **Analytics dashboard — AI Feature Usage section**: stat cards (total tokens, enabled users, 7-day active users/tokens, total sessions), daily tokens + sessions chart, exam-type pie chart, top categories bar chart, sessions vs tokens scatter chart, AI user leaderboard with token share bars, most-asked questions table
- `ai_enabled` admin controls: inline on User page, list-editable on User Settings page, bulk enable/disable actions
- `ApiService.recordAiUsage()` — sends token usage with category, licence, question context after every AI response
- AI chat defaults to app's selected language (Swedish/English) while allowing the user to ask in any language

### Changed
- AI chat buttons hidden for users without `ai_enabled` (loaded from `/self` on screen open)
- Token count uses Gemini `usageMetadata` when available, falls back to character-based estimate

---
---
---
---
---
---
---
---
---
---

## [1.1.55+253] - 2026-05-29

### Added
- **AI feature gate**: `ai_enabled` setting on `UserSettings` — controls access to AI-powered question chat per user (default `false`; auto-enabled on active subscription, auto-disabled when all subscriptions expire)
- **AI token tracking**: `UserAIUsage` model records every AI exchange with token count, category, licence/exam type, question ID, and question text
- `POST /api/user/ai-usage/` endpoint — records token usage, enforces AI gate server-side
- `/self` API now includes `ai_enabled` and `total_ai_tokens_used` fields
- **Analytics dashboard — AI Feature Usage section**: stat cards (total tokens, enabled users, 7-day active users/tokens, total sessions), daily tokens + sessions chart, exam-type pie chart, top categories bar chart, sessions vs tokens scatter chart, AI user leaderboard with token share bars, most-asked questions table
- `ai_enabled` admin controls: inline on User page, list-editable on User Settings page, bulk enable/disable actions
- `ApiService.recordAiUsage()` — sends token usage with category, licence, question context after every AI response
- AI chat defaults to app's selected language (Swedish/English) while allowing the user to ask in any language

### Changed
- AI chat buttons hidden for users without `ai_enabled` (loaded from `/self` on screen open)
- Token count uses Gemini `usageMetadata` when available, falls back to character-based estimate

---
---
---
---
---
---
---
---
---

## [1.1.54+252] - 2026-05-29

### Added
- **AI feature gate**: `ai_enabled` setting on `UserSettings` — controls access to AI-powered question chat per user (default `false`; auto-enabled on active subscription, auto-disabled when all subscriptions expire)
- **AI token tracking**: `UserAIUsage` model records every AI exchange with token count, category, licence/exam type, question ID, and question text
- `POST /api/user/ai-usage/` endpoint — records token usage, enforces AI gate server-side
- `/self` API now includes `ai_enabled` and `total_ai_tokens_used` fields
- **Analytics dashboard — AI Feature Usage section**: stat cards (total tokens, enabled users, 7-day active users/tokens, total sessions), daily tokens + sessions chart, exam-type pie chart, top categories bar chart, sessions vs tokens scatter chart, AI user leaderboard with token share bars, most-asked questions table
- `ai_enabled` admin controls: inline on User page, list-editable on User Settings page, bulk enable/disable actions
- `ApiService.recordAiUsage()` — sends token usage with category, licence, question context after every AI response
- AI chat defaults to app's selected language (Swedish/English) while allowing the user to ask in any language

### Changed
- AI chat buttons hidden for users without `ai_enabled` (loaded from `/self` on screen open)
- Token count uses Gemini `usageMetadata` when available, falls back to character-based estimate

---
---
---
---
---
---
---
---

## [1.1.53+251] - 2026-05-29

### Added
- **AI feature gate**: `ai_enabled` setting on `UserSettings` — controls access to AI-powered question chat per user (default `false`; auto-enabled on active subscription, auto-disabled when all subscriptions expire)
- **AI token tracking**: `UserAIUsage` model records every AI exchange with token count, category, licence/exam type, question ID, and question text
- `POST /api/user/ai-usage/` endpoint — records token usage, enforces AI gate server-side
- `/self` API now includes `ai_enabled` and `total_ai_tokens_used` fields
- **Analytics dashboard — AI Feature Usage section**: stat cards (total tokens, enabled users, 7-day active users/tokens, total sessions), daily tokens + sessions chart, exam-type pie chart, top categories bar chart, sessions vs tokens scatter chart, AI user leaderboard with token share bars, most-asked questions table
- `ai_enabled` admin controls: inline on User page, list-editable on User Settings page, bulk enable/disable actions
- `ApiService.recordAiUsage()` — sends token usage with category, licence, question context after every AI response
- AI chat defaults to app's selected language (Swedish/English) while allowing the user to ask in any language

### Changed
- AI chat buttons hidden for users without `ai_enabled` (loaded from `/self` on screen open)
- Token count uses Gemini `usageMetadata` when available, falls back to character-based estimate

---
---
---
---
---
---
---

## [1.1.52+250] - 2026-05-29

### Added
- **AI feature gate**: `ai_enabled` setting on `UserSettings` — controls access to AI-powered question chat per user (default `false`; auto-enabled on active subscription, auto-disabled when all subscriptions expire)
- **AI token tracking**: `UserAIUsage` model records every AI exchange with token count, category, licence/exam type, question ID, and question text
- `POST /api/user/ai-usage/` endpoint — records token usage, enforces AI gate server-side
- `/self` API now includes `ai_enabled` and `total_ai_tokens_used` fields
- **Analytics dashboard — AI Feature Usage section**: stat cards (total tokens, enabled users, 7-day active users/tokens, total sessions), daily tokens + sessions chart, exam-type pie chart, top categories bar chart, sessions vs tokens scatter chart, AI user leaderboard with token share bars, most-asked questions table
- `ai_enabled` admin controls: inline on User page, list-editable on User Settings page, bulk enable/disable actions
- `ApiService.recordAiUsage()` — sends token usage with category, licence, question context after every AI response
- AI chat defaults to app's selected language (Swedish/English) while allowing the user to ask in any language

### Changed
- AI chat buttons hidden for users without `ai_enabled` (loaded from `/self` on screen open)
- Token count uses Gemini `usageMetadata` when available, falls back to character-based estimate

---
---
---
---
---
---

## [1.1.51+249] - 2026-05-29

### Added
- **AI feature gate**: `ai_enabled` setting on `UserSettings` — controls access to AI-powered question chat per user (default `false`; auto-enabled on active subscription, auto-disabled when all subscriptions expire)
- **AI token tracking**: `UserAIUsage` model records every AI exchange with token count, category, licence/exam type, question ID, and question text
- `POST /api/user/ai-usage/` endpoint — records token usage, enforces AI gate server-side
- `/self` API now includes `ai_enabled` and `total_ai_tokens_used` fields
- **Analytics dashboard — AI Feature Usage section**: stat cards (total tokens, enabled users, 7-day active users/tokens, total sessions), daily tokens + sessions chart, exam-type pie chart, top categories bar chart, sessions vs tokens scatter chart, AI user leaderboard with token share bars, most-asked questions table
- `ai_enabled` admin controls: inline on User page, list-editable on User Settings page, bulk enable/disable actions
- `ApiService.recordAiUsage()` — sends token usage with category, licence, question context after every AI response
- AI chat defaults to app's selected language (Swedish/English) while allowing the user to ask in any language

### Changed
- AI chat buttons hidden for users without `ai_enabled` (loaded from `/self` on screen open)
- Token count uses Gemini `usageMetadata` when available, falls back to character-based estimate

---
---
---
---
---

## [1.1.50+248] - 2026-05-29

### Added
- **AI feature gate**: `ai_enabled` setting on `UserSettings` — controls access to AI-powered question chat per user (default `false`; auto-enabled on active subscription, auto-disabled when all subscriptions expire)
- **AI token tracking**: `UserAIUsage` model records every AI exchange with token count, category, licence/exam type, question ID, and question text
- `POST /api/user/ai-usage/` endpoint — records token usage, enforces AI gate server-side
- `/self` API now includes `ai_enabled` and `total_ai_tokens_used` fields
- **Analytics dashboard — AI Feature Usage section**: stat cards (total tokens, enabled users, 7-day active users/tokens, total sessions), daily tokens + sessions chart, exam-type pie chart, top categories bar chart, sessions vs tokens scatter chart, AI user leaderboard with token share bars, most-asked questions table
- `ai_enabled` admin controls: inline on User page, list-editable on User Settings page, bulk enable/disable actions
- `ApiService.recordAiUsage()` — sends token usage with category, licence, question context after every AI response
- AI chat defaults to app's selected language (Swedish/English) while allowing the user to ask in any language

### Changed
- AI chat buttons hidden for users without `ai_enabled` (loaded from `/self` on screen open)
- Token count uses Gemini `usageMetadata` when available, falls back to character-based estimate

---
---
---
---

## [1.1.49+247] - 2026-05-29

### Added
- **AI feature gate**: `ai_enabled` setting on `UserSettings` — controls access to AI-powered question chat per user (default `false`; auto-enabled on active subscription, auto-disabled when all subscriptions expire)
- **AI token tracking**: `UserAIUsage` model records every AI exchange with token count, category, licence/exam type, question ID, and question text
- `POST /api/user/ai-usage/` endpoint — records token usage, enforces AI gate server-side
- `/self` API now includes `ai_enabled` and `total_ai_tokens_used` fields
- **Analytics dashboard — AI Feature Usage section**: stat cards (total tokens, enabled users, 7-day active users/tokens, total sessions), daily tokens + sessions chart, exam-type pie chart, top categories bar chart, sessions vs tokens scatter chart, AI user leaderboard with token share bars, most-asked questions table
- `ai_enabled` admin controls: inline on User page, list-editable on User Settings page, bulk enable/disable actions
- `ApiService.recordAiUsage()` — sends token usage with category, licence, question context after every AI response
- AI chat defaults to app's selected language (Swedish/English) while allowing the user to ask in any language

### Changed
- AI chat buttons hidden for users without `ai_enabled` (loaded from `/self` on screen open)
- Token count uses Gemini `usageMetadata` when available, falls back to character-based estimate

---
---
---

## [1.1.48+246] - 2026-05-29

### Added
- **AI feature gate**: `ai_enabled` setting on `UserSettings` — controls access to AI-powered question chat per user (default `false`; auto-enabled on active subscription, auto-disabled when all subscriptions expire)
- **AI token tracking**: `UserAIUsage` model records every AI exchange with token count, category, licence/exam type, question ID, and question text
- `POST /api/user/ai-usage/` endpoint — records token usage, enforces AI gate server-side
- `/self` API now includes `ai_enabled` and `total_ai_tokens_used` fields
- **Analytics dashboard — AI Feature Usage section**: stat cards (total tokens, enabled users, 7-day active users/tokens, total sessions), daily tokens + sessions chart, exam-type pie chart, top categories bar chart, sessions vs tokens scatter chart, AI user leaderboard with token share bars, most-asked questions table
- `ai_enabled` admin controls: inline on User page, list-editable on User Settings page, bulk enable/disable actions
- `ApiService.recordAiUsage()` — sends token usage with category, licence, question context after every AI response
- AI chat defaults to app's selected language (Swedish/English) while allowing the user to ask in any language

### Changed
- AI chat buttons hidden for users without `ai_enabled` (loaded from `/self` on screen open)
- Token count uses Gemini `usageMetadata` when available, falls back to character-based estimate

---
---

## [1.1.48+246] - 2026-05-29

### Added
- Push notification sent to all users when a new app version is deployed (`make deploy-all` / `make android-deploy` / `fastlane ios production`)
- In-app update dialog on the dashboard shown once per new version after login (platform-appropriate style: Cupertino on iOS, Material on Android)

### Changed
- Updated 20 packages to latest compatible patch/minor versions (firebase, sentry, dio, stripe, google_fonts, and others)

### Fixed
- Lucide icons now render correctly — font was missing from local package override
- `CacheKeyBuilder` lambda updated for `dio_cache_interceptor` 4.0.6 (`Object? body` parameter added to match new typedef)

---
---
---
---
---
---

## [1.1.47+245] - 2026-05-29

### Added
- Push notification sent to all users when a new app version is deployed (`make deploy-all` / `make android-deploy` / `fastlane ios production`)
- In-app update dialog on the dashboard shown once per new version after login (platform-appropriate style: Cupertino on iOS, Material on Android)

### Changed
- Updated 20 packages to latest compatible patch/minor versions (firebase, sentry, dio, stripe, google_fonts, and others)

### Fixed
- Lucide icons now render correctly — font was missing from local package override
- `CacheKeyBuilder` lambda updated for `dio_cache_interceptor` 4.0.6 (`Object? body` parameter added to match new typedef)

---
---
---
---
---

## [1.1.46+244] - 2026-05-29

### Added
- Push notification sent to all users when a new app version is deployed (`make deploy-all` / `make android-deploy` / `fastlane ios production`)
- In-app update dialog on the dashboard shown once per new version after login (platform-appropriate style: Cupertino on iOS, Material on Android)

### Changed
- Updated 20 packages to latest compatible patch/minor versions (firebase, sentry, dio, stripe, google_fonts, and others)

### Fixed
- Lucide icons now render correctly — font was missing from local package override
- `CacheKeyBuilder` lambda updated for `dio_cache_interceptor` 4.0.6 (`Object? body` parameter added to match new typedef)

---
---
---
---

## [1.1.45+243] - 2026-05-29

### Added
- Push notification sent to all users when a new app version is deployed (`make deploy-all` / `make android-deploy` / `fastlane ios production`)
- In-app update dialog on the dashboard shown once per new version after login (platform-appropriate style: Cupertino on iOS, Material on Android)

### Changed
- Updated 20 packages to latest compatible patch/minor versions (firebase, sentry, dio, stripe, google_fonts, and others)

### Fixed
- Lucide icons now render correctly — font was missing from local package override
- `CacheKeyBuilder` lambda updated for `dio_cache_interceptor` 4.0.6 (`Object? body` parameter added to match new typedef)

---
---
---

## [1.1.44+242] - 2026-05-29

### Added
- Push notification sent to all users when a new app version is deployed (`make deploy-all` / `make android-deploy` / `fastlane ios production`)
- In-app update dialog on the dashboard shown once per new version after login (platform-appropriate style: Cupertino on iOS, Material on Android)

### Changed
- Updated 20 packages to latest compatible patch/minor versions (firebase, sentry, dio, stripe, google_fonts, and others)

### Fixed
- Lucide icons now render correctly — font was missing from local package override
- `CacheKeyBuilder` lambda updated for `dio_cache_interceptor` 4.0.6 (`Object? body` parameter added to match new typedef)

---
---

## [1.1.43+241] - 2026-05-26

### Added
- Preload question images (question images, tab images, option images) for the next 2 questions in the background so users see no lag when swiping forward

### Changed
- Question images, tab images, and option thumbnails now use `CachedNetworkImage` instead of `Image.network` for disk-level caching that persists across widget rebuilds

---
---
---
---
---
---
---
---
---

## [1.1.42+240] - 2026-05-26

### Added
- Preload question images (question images, tab images, option images) for the next 2 questions in the background so users see no lag when swiping forward

### Changed
- Question images, tab images, and option thumbnails now use `CachedNetworkImage` instead of `Image.network` for disk-level caching that persists across widget rebuilds

---
---
---
---
---
---
---
---

## [1.1.41+239] - 2026-05-26

### Added
- Preload question images (question images, tab images, option images) for the next 2 questions in the background so users see no lag when swiping forward

### Changed
- Question images, tab images, and option thumbnails now use `CachedNetworkImage` instead of `Image.network` for disk-level caching that persists across widget rebuilds

---
---
---
---
---
---
---

## [1.1.40+238] - 2026-05-26

### Added
- Preload question images (question images, tab images, option images) for the next 2 questions in the background so users see no lag when swiping forward

### Changed
- Question images, tab images, and option thumbnails now use `CachedNetworkImage` instead of `Image.network` for disk-level caching that persists across widget rebuilds

---
---
---
---
---
---

## [1.1.39+237] - 2026-05-26

### Added
- Preload question images (question images, tab images, option images) for the next 2 questions in the background so users see no lag when swiping forward

### Changed
- Question images, tab images, and option thumbnails now use `CachedNetworkImage` instead of `Image.network` for disk-level caching that persists across widget rebuilds

---
---
---
---
---

## [1.1.38+236] - 2026-05-26

### Added
- Preload question images (question images, tab images, option images) for the next 2 questions in the background so users see no lag when swiping forward

### Changed
- Question images, tab images, and option thumbnails now use `CachedNetworkImage` instead of `Image.network` for disk-level caching that persists across widget rebuilds

---
---
---
---

## [1.1.37+235] - 2026-05-26

### Added
- Preload question images (question images, tab images, option images) for the next 2 questions in the background so users see no lag when swiping forward

### Changed
- Question images, tab images, and option thumbnails now use `CachedNetworkImage` instead of `Image.network` for disk-level caching that persists across widget rebuilds

---
---
---

## [1.1.36+234] - 2026-05-26

### Added
- Preload question images (question images, tab images, option images) for the next 2 questions in the background so users see no lag when swiping forward

### Changed
- Question images, tab images, and option thumbnails now use `CachedNetworkImage` instead of `Image.network` for disk-level caching that persists across widget rebuilds

---
---

## [1.1.35+233] - 2026-05-26

### Added
- Preload question images (question images, tab images, option images) for the next 2 questions in the background so users see no lag when swiping forward

### Changed
- Question images, tab images, and option thumbnails now use `CachedNetworkImage` instead of `Image.network` for disk-level caching that persists across widget rebuilds

---

## [1.1.34+232] - 2026-05-26

### Added
- **Question tabs**: BCD test questions now support tabbed reference images (e.g. "Lokalkartan", "Teckenförklaring") — each tab can contain multiple images, viewable in the fullscreen image viewer
- **Tab translations**: fallback tab label translated into English ("Tab") and Swedish ("Flik")

### Changed
- **Question image fix**: deactivated 60 broken BCD question images (Supabase-deleted); questions with tabs no longer show redundant regular images
- Tabs render above answer options so reference material is visible before answering

### Fixed
- Empty tabs (containing only dead motortrafikskola.se images) are now filtered out server-side and never sent to the app

---

## [1.1.33+231] - 2026-05-25

### Added
- **Question tabs**: BCD test questions now support tabbed reference images (e.g. "Lokalkartan", "Teckenförklaring") — each tab can contain multiple images, viewable in the fullscreen image viewer
- **Tab translations**: fallback tab label translated into English ("Tab") and Swedish ("Flik")

### Changed
- **Question image fix**: deactivated 60 broken BCD question images (Supabase-deleted); questions with tabs no longer show redundant regular images
- Tabs render above answer options so reference material is visible before answering

### Fixed
- Empty tabs (containing only dead motortrafikskola.se images) are now filtered out server-side and never sent to the app

---
---

## [1.1.32+230] - 2026-05-25

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.1.31+229] - 2026-05-25

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.1.30+228] - 2026-05-25

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.1.29+227] - 2026-05-25

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.1.28+226] - 2026-05-25

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.1.27+225] - 2026-05-25

### Changed
- **Dashboard exam ordering**: the most recently attempted exam is now always pinned to position 0 in the carousel and auto-selected on load; remaining exams are sorted by total attempt count (descending)

---
---

## [1.1.26+224] - 2026-05-25

### Added
- **Question tabs**: BCD test questions now support tabbed reference images (e.g. "Lokalkartan", "Teckenförklaring") — each tab can contain multiple images, viewable in the fullscreen image viewer
- **Tab translations**: fallback tab label translated into English ("Tab") and Swedish ("Flik")

### Changed
- **Question image fix**: deactivated 60 broken BCD question images (Supabase-deleted); questions with tabs no longer show redundant regular images
- Tabs render above answer options so reference material is visible before answering

### Fixed
- Empty tabs (containing only dead motortrafikskola.se images) are now filtered out server-side and never sent to the app

---
---

## [1.1.25+223] - 2026-05-23

### Added
- **Exam carousel snap-to-left**: tapping an inactive exam card in "My Exams" now animates the carousel so the selected card snaps flush to the left edge of the screen; clamped to scroll bounds so first/last cards behave gracefully
- `lastAttemptDate` getter on `ExamDashboardStats` — derives the most recent batch attempt date across all batches in an exam

### Changed
- **My Exams sorting**: exams in the carousel are now ordered by most-recently-attempted date (most recent first); never-attempted exams remain in their original order at the bottom; re-sorts automatically after every attempt via `DashboardProvider`'s existing Hive watcher
- **Dashboard category sorting**: categories within an exam are now sorted by most-recently-attempted date (most recent first); re-sorts on every provider rebuild
- **Licences screen sorting**: licence type cards and category cards are sorted by last attempt date on load and re-sorted on return from any Practice Test or Custom Test session
- **Getting started tutorial**: removed `kDebugMode` guard so the translation tutorial on the test screen is only shown once (first launch) in both debug and release builds

### Fixed
-

---
---

## [1.1.24+222] - 2026-05-22

### Added
- `AppTextStyles` — centralised text-style class (`lib/core/constants/app_text_styles.dart`) with named static methods (`headingLarge`, `headingMedium`, `headingSmall`, `bodyLarge`, `bodyMedium`, `bodySmall`, `listTitle`, `listSubtitle`, `displayLarge`) backed by Lexend (headings) and Plus Jakarta Sans (body), matching the dashboard typographic system; change font or scale once and it propagates app-wide
- Swedish translations for eight new statistics keys: `stats_no_tests_yet`, `stats_attempt_history`, `stats_avg_time`, `stats_attempt_one`, `stats_attempt_many`, `stats_avg_label`, `stats_best`, `stats_average`, `stats_unknown`

### Changed
- **`ExamCard`** panel overlay colour: replaced primary-derived tint (dark navy in light mode) with neutral white (light) / `#09082F` ink (dark), eliminating the "too dark top-left corner" on pastel exam images; inactive overlay opacity reduced to let the desaturation filter carry more visual weight
- **`ExamCard`** badge pill: mode-aware semi-transparent background (white-tinted in dark, black-tinted in light) with matching text contrast; active/inactive opacity differentiated per badge state
- **`BCDScreen`** (`lib/features/bcd/bcd_screen.dart`) menu tile title and subtitle now use `AppTextStyles.headingMedium` / `AppTextStyles.listSubtitle` replacing bare `const TextStyle`
- **`BCDCategoryHubScreen`** document and checklist tile titles now use `AppTextStyles.listTitle`; checklist body content uses `AppTextStyles.bodyMedium`
- **`ProfileScreen`** username, email, badge label, menu tile titles, and logout sheet title/body all migrated to `AppTextStyles`, removing scattered `GoogleFonts.*` and `const TextStyle` calls
- **`StatsScreen`** all visible text (stat card values/labels, breakdown card headings, mini-stats, attempt history rows, pass/fail badge, empty-state message) migrated to `AppTextStyles`; hardcoded English strings replaced with translation keys (`home_passed`, `home_failed`, `stats_*`)

---
---

## [1.1.23+221] - 2026-05-22

### Added
- `AppBackButton` widget — a styled pill/card back button (`lib/core/widgets/app_back_button.dart`) used uniformly across all screens, matching the notification bell and settings icon style
- Localization keys `profile_statistics`, `home_attempt_details`, and `home_saved_questions_title` in EN and SV, replacing hardcoded English strings in `StatsScreen`, `AttemptDetailScreen`, and `SavedQuestionsPreviewScreen`
- `durationCount` field on `BatchStats` to track the number of attempts with a non-zero duration, enabling accurate cross-batch average calculation

### Changed
- Applied `AppBackButton` as the `leading` widget in app bars across 13 screens: `BCDDocumentViewerScreen`, `BCDLicencesScreen`, `BCDSubscriptionsScreen`, `BCDTestScreen`, `BCDTrafficSignsScreen`, `AttemptDetailScreen`, `NotificationsScreen`, `EditProfileScreen`, `StatsScreen`, `StreakSettingsScreen`, `HelpScreen`, `CustomTestScreen`, `SavedQuestionsPreviewScreen`, `TestScreen`, and `ResultScreen`
- `ExamCard` panel overlay color now derives from the theme's `ColorScheme.primary` (light/dark tinted) instead of per-category hardcoded colors, so all exam cards share a consistent tint
- `ExamCard` gradient changed from a linear left-to-right sweep to a radial top-left gradient for a softer image blend; badge text color is always white regardless of background luminance
- `_ExamCarouselShimmer` refactored to use `ListView.separated` with a constant `_count = 5` instead of hardcoded duplicate children
- `_LazyIndexedStack` introduced in `MainScreen` — defers building a tab screen until its first visit, reducing startup cost from building all 5 screens simultaneously
- Floating nav pill item width/height increased (`56→62` / `44→50`) and icon size increased (`22→26`) for a larger, easier-to-tap target; bottom padding reduced (`12→4`)
- Splash screen animation controllers (`_spinCtrl`, `_pulseCtrl`) now start in `addPostFrameCallback` after the first frame to avoid competing with shader compilation and font loading on startup
- Profile screen settings icon replaced from bare `IconButton` to a styled pill container matching `AppBackButton` aesthetics
- Notifications empty state updated: double-ring icon container (outer 120px / inner 84px), `GoogleFonts.lexend` title, `GoogleFonts.plusJakartaSans` subtitle replacing plain `TextStyle`
- Test screen exit dialog: "Save & Exit" button moved above the "Keep Going" / "Exit" row; "Exit" button now uses `colorScheme.error` foreground color for clearer destructive intent
- TTS language flag font size reduced from 16 to 14 in test screen
- `avgDurationSeconds` on `ExamDashboardStats` now computed as a true weighted average across all batches (`totalDurationSeconds / totalDurationCount`) instead of an average of per-batch averages
- `_examLevelAttemptCount` in `DashboardHelpers` now uses `periodAttempts` (filtered by time period) instead of `allAttempts`, so the attempt counter respects the selected period
- `BatchStats.isCompleted` now uses `allAttempts` (all-time) rather than `periodAttempts` to determine pass status, so a batch stays completed even when filtering to a shorter period

### Removed
- `categoryImagePanelColor()` function from `category_icon_mapper.dart` — superseded by theme-derived panel colors in `ExamCard`
- `_contrastColor()` helper from `_ImageCard` — text color is now determined directly from `isDark` flag

---
---

## [1.1.22+220] - 2026-05-22

### Added
- App download sheet for web users with platform-specific links (iOS/Android)
- Platform detection utility for web environments
- Remote image URLs to `SubscribedExam` model and updated `ExamSyncService` accordingly
- Background color mapping for category images
- Tests for platform detection functionality

### Changed
- Replaced `RefreshIndicator` with `AdaptiveRefreshIndicator` for better pull-to-refresh UX across screens including subscriptions
- Enhanced `ExamCard` to display exam images and improve layout
- Updated Swedish translations for dashboard and app download prompts

### Fixed
- Removed unused chip label in performance overview section

---
---

## [1.1.21+219] - 2026-05-22

### Added
- App download sheet for web users with platform-specific links (iOS/Android)
- Platform detection utility for web environments
- Remote image URLs to `SubscribedExam` model and updated `ExamSyncService` accordingly
- Background color mapping for category images
- Tests for platform detection functionality

### Changed
- Replaced `RefreshIndicator` with `AdaptiveRefreshIndicator` for better pull-to-refresh UX across screens including subscriptions
- Enhanced `ExamCard` to display exam images and improve layout
- Updated Swedish translations for dashboard and app download prompts

### Fixed
- Removed unused chip label in performance overview section

---
---

## [1.1.20+218] - 2026-05-21

### Added
- Loading states with shimmer effect to PerformanceInsightCard, PerformanceMetricCard, and PerformanceOverviewSection for a smoother data-fetching experience
- Custom height support for bars in MiniBarChart to allow more flexible data visualization
- Comprehensive tests for dashboard loading states and OnboardingScreen localization

### Changed
- Removed borders from FreeBcdHubCard and FreeVagmarkesCard to achieve a cleaner, more modern dashboard aesthetic
- Refactored MainScreen to prioritize cached user data, significantly reducing initial load times
- Enhanced NotificationsScreen with a custom back button for better navigation control
- Localized weekday initials in OnboardingScreen to improve the experience for Swedish-speaking users
- Improved PerformanceMetricCard layout for better information density and readability
- Refactored PeriodDropdown state management for more reliable period switching

### Fixed

---

## [1.1.19+217] - 2026-05-20

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.1.18+216] - 2026-05-20

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.1.17+215] - 2026-05-19

### Added
- `IAPSubscriptionOwnedByOtherAccountException` — typed exception thrown when a purchase or restore attempt is rejected because the Apple `original_transaction_id` is already bound to a different app account
- `isIAPOwnedByOtherAccount()` helper for consistent exception matching at call sites
- Localization keys `iap_owned_by_other_title`, `iap_owned_by_other_body`, `iap_owned_by_other_ok` in EN and SV — user-facing text for the account-conflict dialog

### Changed
- `PurchaseParam` now passes `applicationUserName: currentUserId` — embeds the app user ID in every StoreKit transaction so the backend can enforce the account binding
- `verifyAppleIAP` API call now includes `app_user_id` in the POST body for audit logging and binding verification
- `_verifyOnBackend` no longer skips backend verification for `PurchaseStatus.restored` — both `purchased` and `restored` events are now verified; the backend's `original_transaction_id` binding enforces ownership (same account → 200 idempotent, different account → 409)
- `_onPurchaseUpdate`: `IAPSubscriptionOwnedByOtherAccountException` is now propagated via `completer.completeError` instead of being silently deferred — the buy flow surfaces the error to the UI
- `_onPurchaseUpdate`: deferred receipt is no longer saved when the backend returns 409 (it would never succeed for the current user)
- `kDebugMode` path in `_verifyOnBackend` now catches 409 from `confirmBCDIAPPurchase` and converts it to `IAPSubscriptionOwnedByOtherAccountException` — same protection in debug mode as production
- Backend `IAPAppleVerifyView`: extracts `original_transaction_id` separately from `transaction_id` for both StoreKit 2 (JWS) and StoreKit 1 receipt paths
- Backend `IAPAppleVerifyView`: idempotency check now queries both `transaction_id` and `original_transaction_id` to handle renewals correctly
- Backend `IAPAppleVerifyView`: ownership (409) check now uses `original_transaction_id` so the binding covers all renewals of the same subscription, not just the specific `transaction_id`
- Backend `IAPAppleVerifyView`: stores `original_transaction_id` (not the renewal `transaction_id`) so future renewals resolve to the same ownership record
- Backend `ConfirmBCDIAPPurchaseView` (debug path): now checks for an existing Apple IAP subscription for a different user before `update_or_create`, returning 409 if the product is already claimed — mirrors production ownership guard

### Fixed
- Different app account on the same Apple ID could obtain a subscription by triggering a buy flow that iOS resolved as `PurchaseStatus.restored` — backend now rejects with 409 and the UI shows an actionable dialog instead of a misleading success screen
- Account-conflict dialog used hardcoded English strings and no theme colors — replaced with localized keys and `ColorScheme`/`TextTheme` tokens; dialog is now dark-mode safe

---
---

## [1.1.16+214] - 2026-05-19

### Added
- `SubscriptionPlanCard` — new shared widget consolidating plan card UI used across onboarding, paywall sheet, and BCD subscriptions screen; replaces three separate duplicate implementations
- `SubscriptionLegalLinks` — shared Terms of Use / Privacy Policy footer widget, now shown on all purchase flows including the BCD subscriptions screen (fixes Apple Guideline 3.1.2(c) rejection)
- `showIcon` flag on `SubscriptionPlanCard` — category-matched icon displayed inline with plan title on the BCD subscriptions screen only
- Translation keys for subscription duration labels (`onb_duration_year_access`, `onb_duration_months_access`, `onb_duration_one_day`, `onb_duration_days`) in EN and SV, replacing hardcoded English strings
- Translation keys for the full receipt/purchase history screen (`profile_receipt_title`, `profile_receipt_copy_number`, `profile_receipt_number_copied`, `profile_no_purchases`, `profile_receipt_payment_receipt`, `profile_receipt_no`, `profile_receipt_product`, `profile_receipt_duration`, `profile_receipt_amount_paid`, `profile_receipt_payment_via`, `profile_receipt_via_iap`, `profile_receipt_via_card`, `profile_receipt_transaction_id`, `profile_receipt_payment_intent`, `profile_receipt_reference_no`, `profile_receipt_footer`) in EN and SV
- Icon (`Icons.receipt_long_rounded`) added to Purchase History empty state

### Changed
- `formatSubscriptionProductDuration` now accepts `BuildContext` and returns translated duration strings instead of hardcoded English
- BCD subscriptions screen `_ProductCard` refactored to use `SubscriptionPlanCard` — removed ~150 lines of duplicate card UI
- Onboarding `_PlanTierCard` refactored to use `SubscriptionPlanCard` — removed ~280 lines of duplicate card/button/feature-row/legal-links code
- Paywall sheet `_PlanTile` and `_LegalLinks` removed in favour of `SubscriptionPlanCard` and `SubscriptionLegalLinks`
- Paywall sheet title no longer duplicates the product name — falls back to "Subscription Required" so the plan card is the single source of truth for the product name
- BCD subscriptions empty state vertically centred using `LayoutBuilder` instead of a fixed `height: 300` box
- `PaymentCoordinator.pay` renamed to `PaymentCoordinator.show` at all call sites

### Fixed
- Duplicate product name shown in paywall sheet title and inside the plan card simultaneously
- `_formatDuration` / `_formatProductDuration` / `_durationLabel` private helpers deduplicated — all duration formatting now goes through a single shared function
- All static/hardcoded English strings in `receipt_screen.dart` replaced with localised translation keys

---
---

## [1.1.15+213] - 2026-05-19

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.1.14+212] - 2026-05-19

### Added
- Terms of use and privacy policy links on onboarding and paywall screens
- `FIELD_ENCRYPTION_KEY` dart-define wired through all build targets (Makefile, iOS/Android Fastfiles) so the app can decrypt the encrypted `/self` response in production
- `lib/config/local_config.dart.example` — per-developer local dev server URL config; `local_config.dart` is gitignored so IP addresses are never committed

### Changed
- `/self` endpoint now returns AES-256-CBC encrypted payload (`{"d":"..."}`) in production; plain JSON in development — `ApiService._decryptSelfIfNeeded()` handles both transparently so all callers receive an unmodified `Map<String, dynamic>`
- `/self` dashboard response trimmed ~15% (41 KB → 35 KB): removed `is_active`/`is_published` from test objects (always true, not read by app) and replaced recursive full serializer for sub-categories with a lean serializer that drops `subscription_product`, `attempt_count`, and `test_count` (none read by `BcdCache._applyDashboard`)
- Dev server URL in `DioClient` now reads from `local_config.dart` (`kLocalDevBaseUrl`) instead of a hardcoded IP
- Nav bar loading spinner removed — nav tabs are shown immediately without waiting for feature-flag fetch
- Syncing spinner removed from exam dashboard AppBar actions

### Fixed
- Apple IAP deferred receipt cross-account security: receipt now stores the originating `user_id`; `hasDeferredReceipt()` and `verifyDeferredReceipt()` reject and purge receipts that belong to a different user, preventing a second user on the same device from claiming a previous user's subscription
- Backend rejects Apple IAP transactions already claimed by a different account with HTTP 409, preventing subscription transfer between app accounts

---
---

## [1.1.13+211] - 2026-05-18

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.1.12+210] - 2026-05-18

### Added
-

### Changed
-

### Fixed
- Show "Connection timed out" message instead of navigating to home when auth requests time out
- Guest login no longer silently creates a new session after a restore timeout — network errors now surface a proper message and keep the user on the auth page
- Login page no longer shows "Invalid credentials" on connection timeout — a snackbar with the correct timeout message is shown instead
- Auth bottom sheet login suppresses the inline error for timeout and throttle cases already handled by the global snackbar

---
---

## [1.1.11+209] - 2026-05-17

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.1.10+208] - 2026-05-17

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.1.9+207] - 2026-05-17

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.1.8+206] - 2026-05-17

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.1.7+205] - 2026-05-16

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.1.6+204] - 2026-05-16

### Added
- `hasResumableProgressChanges` helper and targeted regression test coverage for resumed test progress detection
- `TestAttemptSaveService` and regression tests covering local-first save order and backend sync failure handling

### Changed
- Moved test/save/resume UI copy in the test screen, result screen, finish/result dialogs, and saved-progress deletion prompts to the existing i18n translation files
- Added new EN/SV translation keys for test flow feedback, result summaries, exit/save prompts, navigation labels, saved-progress prompts, and backend sync failure messaging
- `syncTestAttempt` now returns an explicit backend sync result so the test screen can distinguish local persistence from remote sync success

### Fixed
- "Save & Exit" on resumed tests now treats question-position changes as progress, so leaving from a different question no longer drops the paused state
- Paused and completed test saves now await the backend sync attempt before the screen closes or the flow continues
- Test attempts are now always written to local storage first, and `Save & Exit` keeps the user on the test screen with an error message if backend sync fails instead of silently closing

---
---

## [1.1.5+203] - 2026-05-16

### Added
-

### Changed
- Platform-adaptive pull-to-refresh: Cupertino spinner on iOS/web, Material on Android across all scrollable screens (home, dashboard, licences, BCD licences, BCD traffic signs, stats)
- Subscription screen pull-to-refresh uses `RefreshIndicator.adaptive` to avoid gesture conflicts inside `TabBarView`
- Consistent "Log in" button label across auth and login screens
- Auth screen subtitles constrained to single line (scaled down to fit)
- Onboarding "GET STARTED" title now expands full width; step headline fits on one line

### Fixed
- Apple sign-in button icon color in dark mode now follows theme (matches Google icon treatment)

---
---

## [1.1.4+202] - 2026-05-16

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.1.3+201] - 2026-05-16

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.1.2+200] - 2026-05-16

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.1.1+199] - 2026-05-16

### Added
- `AppFilledButton`, `AppOutlinedButton`, `AppDangerButton`, `AppTextButton` — four new centralised button variants in `lib/core/widgets/app_button.dart`; all button styling now lives in one file
- 11 new translation keys (`btn_save_changes`, `btn_set_password`, `btn_delete_account`, `btn_deleting`, `btn_keep_going`, `btn_exit`, `btn_save_and_exit`, `btn_submit`, `btn_start_saved_test`, `btn_buy_now`, `btn_pay_now`) in EN and SV
- `make web-tunnel` now auto hot-restarts the Flutter web server on every `lib/` file save via `fswatch` + named pipe — changes appear on the tunnel URL without any manual action

### Changed
- Migrated all raw `ElevatedButton`, `FilledButton`, `OutlinedButton`, and `TextButton` usages across 20 screens to the new centralised `App*Button` widgets
- All buttons now use a pill shape (borderRadius: 9999) matching the auth screen style
- Softened button colours: primary gradient reduced to 82 % / 88 % alpha, filled buttons to 78 % alpha, danger buttons use `Colors.red.shade400` instead of full red
- Auth screen: login error banner moved from below the heading to just above the action buttons on both the landing screen and the login sub-screen
- Guest banner card on profile screen replaced harsh outlined card with a soft gradient background (no border) and switched to gradient pill `AppButton`
- "New Test" button in Focus Areas changed from outlined to soft gradient (`AppSecondaryButton`) — no harsh border
- "Start practicing!" onboarding completion button changed to gradient pill `AppButton`
- Exit Test dialog: "Keep Going" and "Exit" text buttons now laid out in a row instead of stacked
- Onboarding top bar title wrapped in `Flexible` + `FittedBox` to prevent overflow on small screens
- `AppLoadingIndicator` replaced `dart:io` `Platform.isIOS` with `kIsWeb` + `defaultTargetPlatform` — fixes crash on Android and Web

### Fixed
- `AppLoadingIndicator` threw "Unsupported operation" on Android and Web due to `dart:io` usage; now uses `flutter/foundation` APIs safe on all platforms
- Progress bar removed from BCD licence cards (Categories screen)

---
---

## [1.1.0+198] - 2026-05-16

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.31+197] - 2026-05-16

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.30+196] - 2026-05-16

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.29+195] - 2026-05-16

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.28+194] - 2026-05-16

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.27+193] - 2026-05-16

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.26+192] - 2026-05-16

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.25+191] - 2026-05-16

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.24+190] - 2026-05-16

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.23+189] - 2026-05-16

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.22+188] - 2026-05-16

### Added
- **Hero animations across splash, auth, and onboarding** — "DRIVE TEST" title flies from the splash screen into the auth landing view; the yellow bolt icon flies from splash into the onboarding top bar; "DRIVE TEST" in the auth app bar is a Hero so it also animates when navigating to login/signup
- **Express login with Google on Android & Web** — landing screen now shows a full-width "Express login via Google" `AppButton` on non-iOS platforms instead of the icon-only social button row
- **"Continue as Guest" always visible** — removed the saved-session guard so the button appears for all users on the landing screen, not only returning guests

### Changed
- **Login and signup are now pushed routes** — `_LoginPage` and `_SignupPage` are independent `StatefulWidget` screens pushed via `Navigator.push`/`pushReplacement`; this enables Hero animations and gives each form its own lifecycle (controllers, loading state, errors all managed locally)
- **Social button icon colours fixed** — Apple icon is now `Colors.black`, Google icon is Google brand blue (`#4285F4`) instead of the theme primary colour
- **Social button border radius** — changed from `BorderRadius.circular(16)` to pill shape (`9999`) to match the primary login button
- **Splash screen "DRIVE TEST" branding** — matches the auth screen style: "DRIVE" in `onSurface`, "TEST" in italic primary blue (was all-italic primary)
- **`AppSocialButton`** — accepts an optional `iconColor` parameter; border radius updated to pill

### Fixed
- **"DRIVE TEST" wrapping on splash** — wrapped in `FittedBox(fit: BoxFit.scaleDown)` so it always stays on one line regardless of screen width

---
---

## [1.0.21+187] - 2026-05-16

### Added
- **Guest session persistence** — guest refresh token is saved to `SharedPreferences` on logout so the same guest account can be restored on the next visit without creating a new one; restoration uses a bare Dio instance (no interceptors) so a stale token never triggers `logoutAndRedirect`
- **"Continue as Guest" button on auth screen** — shown only when a saved guest session exists on the device; restores the session silently with a spinner and navigates to `MainScreen`
- **Pre-purchase account choice sheet** (`_PrePurchaseSheet`) — replaces the mandatory auth gate before purchasing; users can now choose "Sign In / Create Account" or "Continue as Guest" before the payment sheet; purchase is never blocked by registration
- **Per-user Hive box isolation** — every Hive box is now suffixed with the backend user ID extracted from the JWT (e.g. `testAttempts_42`); users on shared devices never see each other's test attempts, subscribed exams, or notifications across sessions
- `AppStorage.kIapDeferredReceipt` and `AppStorage.kGuestRefreshToken` — centralized `SharedPreferences` key constants; no more bare string literals scattered across services
- `ProfileProvider.reset()` — clears all in-memory user fields on logout so the singleton never leaks stale username / email / `isGuest` to the next session
- New localization strings (EN + SV): `onb_pre_purchase_title`, `onb_pre_purchase_subtitle`, `onb_pre_purchase_sign_in`, `onb_pre_purchase_guest`, `auth_continue_as_guest`, `auth_guest_session_error`
- **Purchase History visible to guest users** — "Purchase History" menu item on the Profile screen is now shown for all users including guests; a guest who purchased before creating an account can view their receipt immediately

### Changed
- **Interceptor order in `DioClient`** — auth interceptor now runs first (sets `Authorization` header), then Sentry, then the cache interceptor; previously the cache could build its key before the auth header was set, causing cross-user cache hits on shared devices
- **HTTP cache purged on logout** — `DioClient.logout()` now calls `_cacheStore?.clean()` to evict all in-memory cached responses so the next user cannot receive a previous user's API data from cache
- **`AppStorage` box accessors refactored** — all four typed box accessors (`testAttemptsBox`, `subscribedExamsBox`, `notificationsBox`, `receiptsBox`) now delegate to a single private `_openBox<T>` helper, eliminating six copies of the `isBoxOpen ? box() : openBox()` pattern; `notificationsBox` is now properly async
- **Safety-net clears in `clearUserData` run in parallel** — `_clearTestAttemptsBox` and `_clearSubscribedExamsBox` (invoked only when JWT parsing failed) now run concurrently via `Future.wait`, halving logout latency on the fallback path
- **`markAllRead` saves run in parallel** — `NotificationProvider.markAllRead()` now marks all items in memory first, then flushes all Hive writes concurrently via `Future.wait` instead of awaiting each save in a loop
- **`_PrePurchaseSheet` owns its own translations** — strings are read directly from `Translations.of(context)` inside `build`; the four pre-translated parameters have been removed from the constructor
- **IAP deferred-receipt retry in `_continueAsGuest` is fire-and-forget** — the check no longer blocks navigation to `MainScreen`; the receipt is still retried asynchronously in the background
- **Raw `Hive.openBox` calls replaced with `AppStorage` accessors** — `home_screen.dart` (×3), `stats_screen.dart` (×1), `test_screen.dart` (×3), and `profile_provider.dart` (×1) now all go through `AppStorage.testAttemptsBox()` instead of calling Hive directly
- `ProfileProvider.loadUserFromPrefs()` now always calls `notifyListeners()` and resets all fields to defaults when no stored user JSON is found, preventing stale data from a previous session from persisting in memory
- `AppStorage.clearCurrentUser()` doc comment corrected — removed misleading "legacy" wording

### Fixed
- **In-flight `/self` future cleared on logout** — `_inFlightSelf` is set to `null` during logout so the next session never receives a previous user's profile data from a pending network call that resolves after the session ends
- **Guest flag written to cached user JSON** — `_persistGuestFlag()` merges `is_guest: true` into `AppStorage.kUserJson` immediately after guest login so `_isCurrentUserGuest()` works reliably at logout time even if `ProfileProvider.loadProfile` was never called
- **`kIapDeferredReceipt` cleared on logout** — prevents a subsequent user on the same device from accidentally claiming a previous user's deferred Apple purchase receipt

---
---

## [1.0.20+186] - 2026-05-15

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.19+185] - 2026-05-15

### Added
- Comprehensive localization for authentication, onboarding, and dashboard banners (English & Swedish)
- New authentication screens: `VerifyCodeScreen` and `ResetPasswordScreen` with full localization support
- Step-by-step loading labels for Google Sign-In (connecting, verifying, signing in, creating account)
- `Skill(autoplan)` added to allowed skills in workspace settings

### Changed
- Refactored Profile screen menu with structured action handlers and improved localization for all menu items
- Improved product ID comparison logic in BCD subscriptions and onboarding using string conversion for better reliability
- Replaced various hardcoded UI strings (e.g., "or", "Language", "username or email") with localized translation keys

### Fixed
- Onboarding payment flow now filters out already-owned products from bundles before processing, preventing backend rejection when a bundle contains a pre-owned item
- Fixed profile menu item labels and navigation for "Manage Subscription", "Help", and "Purchase History"

---
---

## [1.0.18+184] - 2026-05-15

### Added
-

### Changed
-

### Fixed
- "Continue as a guest" on the onboarding pricing screen no longer overwrites the session of an already-logged-in user; `guestLogin()` is now skipped when a valid token is already present, so authenticated users proceed directly to the main screen with their own credentials intact

---
---

## [1.0.17+183] - 2026-05-15

### Added
-

### Changed
-

### Fixed
- Logo ("DRIVE TEST") now always renders on a single line; wraps in `FittedBox` so it scales down proportionally on small screens instead of breaking to two lines
- Debug credentials (`abc`/`abc`) are now pre-filled in the "Sign In to Subscribe" bottom sheet in debug mode, matching the behaviour of the main auth screen
- IAP `restored` purchase events (triggered by iOS "You're currently subscribed" dialog) no longer call the backend confirmation endpoint — prevents a different logged-in app user from inheriting a subscription that belongs to the original Apple ID purchaser
- Post-purchase navigation from the onboarding success screen ("Start Tests" / "Back to home") now correctly replaces the onboarding route with `MainScreen`; previously `findAncestorStateOfType` could never locate the onboarding state from its own context, so navigation silently did nothing and the user remained stuck on onboarding

---
---

## [1.0.16+182] - 2026-05-15

### Added
- Guest account flow: users can now continue as a guest from the onboarding pricing screen without registering; guest session is created via `POST /api/user/guest/`
- Guest account conversion: guests can upgrade to a full account in-place via `POST /api/user/guest/convert/` — all progress and session history is preserved
- Guest banner on profile screen prompting guests to create a full account
- `_FreeBCDHubCard` and `_FreeVagmarkesCard` on the dashboard for users without an active subscription, surfacing free content immediately
- Per-button loading indicators on auth sheet: Apple, Google, and form buttons now show individual spinners with a "Signing in…" label instead of a single shared loader
- `required` and `allowDemo` params on `showAuthBottomSheet` — post-purchase sheets cannot be dismissed by tapping outside, and the demo login shortcut is hidden during onboarding

### Changed
- Auth required **before** purchase (not after): login/signup sheet now shown before the StoreKit payment sheet for subscription purchases, satisfying Apple guideline 5.1.1(v) for account-based products
- Removed "Restore Purchases" button and `restore()` flow entirely; auto-renewable subscriptions are restored by StoreKit automatically (Apple guideline 3.1.1)
- `_FreeTrialBanner` removed from the Drive Test (BCD) screen
- `_TestCard` in category hub no longer shows a sequence number; tests are now sorted alphabetically instead
- Category icons on licences and subscriptions screens now use content-specific icons from `category_icon_mapper.dart` instead of generic lock/book icons; unsubscribed categories show a small lock badge overlay
- `_ProductCard` on subscriptions screen redesigned: icon + duration badge row, larger title, `FilledButton` CTAs, category-matched accent colour
- Backend verification failure during purchase no longer surfaces an error to the user — transaction always completes successfully and the receipt is saved for deferred retry
- `debug_credentials.dart` constants used for demo login in both `auth_screen.dart` and `auth_bottom_sheet.dart` (previously hardcoded inline)
- Demo login button hidden behind `kDebugMode` guard in production builds
- Auth screen `_GradientButton` and sheet `_SheetGradientButton` now show spinner + loading label inline (button does not collapse during loading)

### Fixed
- Deferred IAP receipt retried on next login via `IAPService.instance.verifyDeferredReceipt()` called in both `_onSuccess` (auth sheet) and post-login callback (auth screen)
- `_findFreeCategory()` in dashboard replaced empty-map sentinel pattern with `firstWhereOrNull` (collection package)
- Duplicate `category_bcd_ids` → BCD category lookup extracted into `_resolveCategoryForProducts()` in onboarding (was copy-pasted three times)
- Duplicate navigation logic (`pushReplacement` + optional hub push) extracted into `_navigateToMainAndCategory()` in onboarding
- Pass-through `_colorForCategory` / `_iconForCategory` wrapper methods removed from dashboard; `categoryColor()` / `categoryIcon()` called directly
- `.catchError((_) => null)` replaced with `.ignore()` for fire-and-forget deferred receipt calls
- Errors cleared when switching between login/signup/landing views in auth screen

---
---

## [1.0.15+181] - 2026-05-13

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.14+180] - 2026-05-12

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.13+179] - 2026-05-12

### Added
- Payment receipts: Apple IAP purchases now generate and return a `receipt_number` stored on the subscription record
- Exam subscription expiry dates: subscription `end_date` is now derived from the Apple transaction's `expires_date_ms` (or `duration_days` fallback) and persisted correctly so the app displays accurate expiry info
- Deferred IAP receipt verification: Apple JWS token is saved locally when no auth token is present, allowing the user to complete payment before account creation — receipt is sent to backend after login
- Contextual auth sheet titles for post-payment and restore flows so Apple reviewers clearly see the form is for a Drive Test Pro account, not an Apple ID

### Changed
- IAP purchase flow no longer requires login before the StoreKit payment sheet appears (Apple guideline 5.1.1(v))
- Restore Purchases no longer shows the login form before calling StoreKit restore (Apple guideline 3.1.1)

### Fixed
- Missing `onIAPPurchaseConfirmed` callback in onboarding payment flow — backend confirm endpoint is now called for iOS purchases from the onboarding screen (Apple guideline 2.1(b))

---
---

## [1.0.12+178] - 2026-05-12

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.11+177] - 2026-05-12

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.10+176] - 2026-05-12

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.9+175] - 2026-05-12

### Added
- Custom iOS-style stacked notification system: notifications stack behind each other with a peek effect, slide in from the top, and can be dismissed by tap or swipe up
- Auto-dismiss after 4 seconds per notification

### Changed
- Replaced `toastification` package with a custom `OverlayEntry`-based notification stack — removed `ToastificationWrapper` from `main.dart`
- Notification cards now use theme colors throughout (`cardColor`, `colorScheme.onSurface`, `colorScheme.error`, `colorScheme.primary`, `colorScheme.shadow`) with no hardcoded static colors
- Card background is always `theme.cardColor` (white in light mode, dark in dark mode); only the icon changes color per notification type

### Fixed
- Duplicate notifications no longer appear: same message already on screen is silently dropped at the `showAppSnackBar` level
- Multiple simultaneous logout triggers (e.g. several API requests all returning 401 at once) no longer show repeated "logged out" notifications — `logoutAndRedirect` is now guarded by a `_logoutInProgress` flag

---
---

## [1.0.8+174] - 2026-05-08

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.8+174] - 2026-05-08

### Changed
- Receipt number is now **generated server-side** (`RCP-YYYYMMDD-XXXXXX`) in `ConfirmBCDPaymentView` and `ConfirmBCDIAPPurchaseView`; client no longer sends a receipt number — it uses the one returned in the confirm response, falling back to a client-generated value only if the backend does not return one
- `PaymentCoordinator` confirm callback signatures simplified — `receiptNumber` parameter removed since it is no longer passed to the backend
- `confirmBCDPayment` / `confirmBCDIAPPurchase` in `ApiService` cleaned up — `receiptNumber` param removed from request body
- `fetchCurrentUser` accepts `forceRefresh: bool` flag using `CachePolicy.refreshForceCache` so call sites can bypass stale Dio cache entries explicitly

### Fixed
- **Categories screen showing wrong subscription status:** pull-to-refresh was calling `ensureLoaded()` (a no-op on warm cache), returning stale `is_subscribed` values; replaced with `_forceRefresh()` which invalidates BcdCache, clears Dio HTTP cache, and re-fetches `/self` so the list reflects actual subscription state
- **Exam dashboard pull-to-refresh not triggering:** `CustomScrollView` was missing `AlwaysScrollableScrollPhysics`, so the `RefreshIndicator` ignored pull gestures on short lists
- **Stale Hive exams surviving refresh:** `syncNow` now clears the `subscribed_exams` Hive box before re-fetching, so expired or removed subscriptions are not carried over
- **`syncNow` using cached `/self` response:** `fetchCurrentUser` now called with `forceRefresh: true` during `syncNow` to guarantee a network hit

---

## [1.0.7+173] - 2026-05-08

### Added
-

### Changed
-

### Fixed
-

---
---

## [1.0.7+173] - 2026-05-08

### Added
- **Purchase receipt system:** every successful payment generates a receipt (`RCP-YYYYMMDD-XXXXXX`) stored locally in Hive; shown on the post-purchase success overlay and accessible from Profile → Purchase History
- **Receipt backend tracing:** confirm API calls (`confirmBCDPayment`, `confirmBCDIAPPurchase`) now pass a `receipt_number` to the backend so each subscription can be looked up for support; backend-returned receipt number takes precedence over the client-side fallback
- **Purchase History screen:** full list of all past purchases (including expired subscriptions), sorted newest-first, accessible from the profile; receipts survive logout/re-login
- Subscribe CTA card on Exam Dashboard when user has no subscribed exams — fetches available products and opens the paywall directly from the Progress tab
- Paper receipt UI (`ReceiptScreen`): gradient header, zigzag tear line, all transaction fields, "Copy receipt number" button

### Changed
- BCD subcategory screen now injects the parent category's `subscription_product` and `is_subscribed` state into the subcategory map before opening the hub screen, so hub-screen paywall and lock logic work correctly without extra API calls
- `PaymentCoordinator._process` iOS guard moved inside the `try/catch` block so a missing `iap_product_id` now shows the error snackbar instead of silently swallowing the exception
- `PaymentCoordinator` confirm callbacks updated to return `Future<Map<String,dynamic>?>` so the backend response (including `receipt_number`) can be used to build the local receipt
- Subscriptions screen colors fully migrated to `ColorScheme` tokens — replaced hardcoded `#059669` green and `#4F46E5` indigo with `cs.secondary`, `cs.primary`, `cs.onSurfaceVariant`, and `cs.outlineVariant`
- Subscription banner colors on BCD hub and licences screens changed from harsh orange (`tertiaryContainer`) to neutral `surfaceContainerLow` / `primary` tokens
- Receipts are no longer cleared on logout so purchase history persists across sessions

### Fixed
- **IAP/Stripe not initialising from BCD category hub:** embedded `subscription_product` in `bcd_dashboard` omits `iap_product_id`; hub screen now always fetches full product data from `api/v2/subscription-products/` (matched by ID, result cached), so IAP launches correctly on iOS
- **`PaymentCoordinator` silent crash:** iOS "not available for purchase" exception was thrown before the `try` block, escaping the error handler and giving the user no feedback; now caught and shown as a snackbar

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
