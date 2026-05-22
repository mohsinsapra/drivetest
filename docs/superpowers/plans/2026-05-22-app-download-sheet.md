# App Download Sheet Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** When a user opens the Flutter web app on an Android or iOS device, show a bottom sheet after the splash screen that prompts them to download the native app from the Play Store or App Store.

**Architecture:** A conditional-import `platform_detector` helper (stub returns `WebPlatform.none`; `dart:html` implementation parses `navigator.userAgent`) feeds a `showAppDownloadSheet` function called from `MainScreen.initState` via `addPostFrameCallback`. The sheet uses the existing `showModalBottomSheet` pattern from `gdpr_consent_sheet.dart`, fully localized via slang keys, with no hardcoded text.

**Tech Stack:** Flutter web, `dart:html` conditional import, `url_launcher`, slang localization (`dart run slang`), `google_fonts` (Lexend + PlusJakartaSans), Material 3 `colorScheme`.

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `lib/core/utils/platform_detector.dart` | Create | Conditional-import entry; exports `WebPlatform` enum and `detectWebPlatform()` |
| `lib/core/utils/platform_detector_stub.dart` | Create | Non-web stub — always returns `WebPlatform.none` |
| `lib/core/utils/platform_detector_html.dart` | Create | Web impl — reads `window.navigator.userAgent` |
| `lib/core/widgets/app_download_sheet.dart` | Create | Bottom sheet UI + `showAppDownloadSheet()` function |
| `lib/main_screen.dart` | Modify | Call `showAppDownloadSheet` in existing `addPostFrameCallback` |
| `lib/core/localization/strings.i18n.json` | Modify | Add EN strings |
| `lib/core/localization/strings_sv.i18n.json` | Modify | Add SV strings |
| `lib/core/localization/strings.g.dart` + `strings_en.g.dart` + `strings_sv.g.dart` | Regenerate | Run `dart run slang` after editing JSON |
| `test/core/utils/platform_detector_test.dart` | Create | Unit test for `WebPlatform` enum and stub behavior |

---

## Task 1: Add localization strings

**Files:**
- Modify: `lib/core/localization/strings.i18n.json`
- Modify: `lib/core/localization/strings_sv.i18n.json`

- [ ] **Step 1: Add EN keys to strings.i18n.json**

Open `lib/core/localization/strings.i18n.json` and add the following keys before the closing `}` (after the last existing entry):

```json
  "app_download_title": "Better on the app",
  "app_download_subtitle_android": "Download the Drive Test app on Google Play for a faster, smoother experience.",
  "app_download_subtitle_ios": "Download the Drive Test app on the App Store for a faster, smoother experience.",
  "app_download_cta_android": "Download on Google Play",
  "app_download_cta_ios": "Download on the App Store",
  "app_download_learn_more": "Learn more at drivetest.se",
  "app_download_dismiss": "Continue in browser"
```

- [ ] **Step 2: Add SV keys to strings_sv.i18n.json**

Open `lib/core/localization/strings_sv.i18n.json` and add before the closing `}`:

```json
  "app_download_title": "Bättre i appen",
  "app_download_subtitle_android": "Ladda ner Drive Test-appen på Google Play för en snabbare och smidigare upplevelse.",
  "app_download_subtitle_ios": "Ladda ner Drive Test-appen från App Store för en snabbare och smidigare upplevelse.",
  "app_download_cta_android": "Ladda ner på Google Play",
  "app_download_cta_ios": "Ladda ner från App Store",
  "app_download_learn_more": "Läs mer på drivetest.se",
  "app_download_dismiss": "Fortsätt i webbläsaren"
```

- [ ] **Step 3: Regenerate slang files**

```bash
cd /Users/muhammadmohsin/Documents/Learning/TAXI/App/taxi_exam_app
dart run slang
```

Expected output: something like `Generated 2 file(s).` with no errors. The files `strings.g.dart`, `strings_en.g.dart`, `strings_sv.g.dart` will be updated.

- [ ] **Step 4: Verify the keys exist in the generated file**

```bash
grep "app_download_title\|app_download_cta_android\|app_download_dismiss" lib/core/localization/strings_en.g.dart
```

Expected: three matching lines, e.g.:
```
  String get app_download_title => 'Better on the app';
  String get app_download_cta_android => 'Download on Google Play';
  String get app_download_dismiss => 'Continue in browser';
```

- [ ] **Step 5: Commit**

```bash
git add lib/core/localization/strings.i18n.json lib/core/localization/strings_sv.i18n.json lib/core/localization/strings.g.dart lib/core/localization/strings_en.g.dart lib/core/localization/strings_sv.g.dart
git commit -m "feat: add app_download localization keys (EN + SV)"
```

---

## Task 2: Create the platform detector

**Files:**
- Create: `lib/core/utils/platform_detector.dart`
- Create: `lib/core/utils/platform_detector_stub.dart`
- Create: `lib/core/utils/platform_detector_html.dart`
- Create: `test/core/utils/platform_detector_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/core/utils/platform_detector_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_exam_app/core/utils/platform_detector.dart';

void main() {
  group('WebPlatform', () {
    test('enum has android, ios, and none values', () {
      expect(WebPlatform.values, containsAll([
        WebPlatform.android,
        WebPlatform.ios,
        WebPlatform.none,
      ]));
    });

    test('detectWebPlatform returns none in test environment (stub)', () {
      // The test runner is not a browser, so the stub implementation is used.
      expect(detectWebPlatform(), WebPlatform.none);
    });
  });
}
```

- [ ] **Step 2: Run the test to confirm it fails**

```bash
cd /Users/muhammadmohsin/Documents/Learning/TAXI/App/taxi_exam_app
flutter test test/core/utils/platform_detector_test.dart
```

Expected: FAIL — `Target of URI doesn't exist` or similar, because the file doesn't exist yet.

- [ ] **Step 3: Create the stub**

Create `lib/core/utils/platform_detector_stub.dart`:

```dart
import 'platform_detector.dart';

WebPlatform detectWebPlatformImpl() => WebPlatform.none;
```

- [ ] **Step 4: Create the html implementation**

Create `lib/core/utils/platform_detector_html.dart`:

```dart
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'platform_detector.dart';

WebPlatform detectWebPlatformImpl() {
  final ua = html.window.navigator.userAgent.toLowerCase();
  if (ua.contains('android')) return WebPlatform.android;
  if (ua.contains('iphone') ||
      ua.contains('ipad') ||
      ua.contains('ipod')) return WebPlatform.ios;
  return WebPlatform.none;
}
```

- [ ] **Step 5: Create the conditional-import entry point**

Create `lib/core/utils/platform_detector.dart`:

```dart
import 'platform_detector_stub.dart'
    if (dart.library.html) 'platform_detector_html.dart';

enum WebPlatform { android, ios, none }

WebPlatform detectWebPlatform() => detectWebPlatformImpl();
```

- [ ] **Step 6: Run the test to confirm it passes**

```bash
flutter test test/core/utils/platform_detector_test.dart
```

Expected: PASS — both tests green.

- [ ] **Step 7: Commit**

```bash
git add lib/core/utils/platform_detector.dart lib/core/utils/platform_detector_stub.dart lib/core/utils/platform_detector_html.dart test/core/utils/platform_detector_test.dart
git commit -m "feat: add conditional-import WebPlatform detector for web UA sniffing"
```

---

## Task 3: Create the app download sheet widget

**Files:**
- Create: `lib/core/widgets/app_download_sheet.dart`

- [ ] **Step 1: Create the sheet file**

Create `lib/core/widgets/app_download_sheet.dart`:

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/utils/platform_detector.dart';
import 'package:taxi_exam_app/core/widgets/app_button.dart';

const _kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.mohsinsapra.drivetest';
const _kAppStoreUrl =
    'https://apps.apple.com/app/drive-test-pro/id6765940954';
const _kLandingUrl = 'https://drivetest.se/';

Future<void> showAppDownloadSheet(
  BuildContext context, {
  required WebPlatform platform,
}) async {
  assert(kIsWeb, 'showAppDownloadSheet should only be called on web');
  assert(platform != WebPlatform.none);
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isDismissible: true,
    enableDrag: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AppDownloadSheet(platform: platform),
  );
}

class _AppDownloadSheet extends StatelessWidget {
  const _AppDownloadSheet({required this.platform});

  final WebPlatform platform;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Translations.of(context);
    final isAndroid = platform == WebPlatform.android;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Icon + title row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isAndroid
                      ? Icons.android_rounded
                      : Icons.phone_iphone_rounded,
                  color: cs.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  t.app_download_title,
                  style: GoogleFonts.lexend(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Subtitle
          Text(
            isAndroid
                ? t.app_download_subtitle_android
                : t.app_download_subtitle_ios,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: cs.onSurfaceVariant,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 28),

          // Primary CTA — opens store
          AppButton(
            label: isAndroid
                ? t.app_download_cta_android
                : t.app_download_cta_ios,
            onPressed: () => launchUrl(
              Uri.parse(isAndroid ? _kPlayStoreUrl : _kAppStoreUrl),
              mode: LaunchMode.externalApplication,
            ),
            height: 56,
          ),
          const SizedBox(height: 12),

          // Learn more link
          Center(
            child: TextButton(
              onPressed: () => launchUrl(
                Uri.parse(_kLandingUrl),
                mode: LaunchMode.externalApplication,
              ),
              child: Text(
                t.app_download_learn_more,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Dismiss
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                t.app_download_dismiss,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/widgets/app_download_sheet.dart
git commit -m "feat: add AppDownloadSheet bottom sheet for web mobile users"
```

---

## Task 4: Wire the sheet into MainScreen

**Files:**
- Modify: `lib/main_screen.dart`

- [ ] **Step 1: Add imports to main_screen.dart**

At the top of `lib/main_screen.dart`, add these two imports alongside the existing ones:

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:taxi_exam_app/core/utils/platform_detector.dart';
import 'package:taxi_exam_app/core/widgets/app_download_sheet.dart';
```

- [ ] **Step 2: Add the trigger method to MainScreenState**

Inside `MainScreenState`, add this private method (e.g. after `_loadTabFlags`):

```dart
void _maybeShowAppDownloadSheet() {
  if (!kIsWeb) return;
  final platform = detectWebPlatform();
  if (platform == WebPlatform.none) return;
  showAppDownloadSheet(context, platform: platform).ignore();
}
```

- [ ] **Step 3: Call the method from the existing addPostFrameCallback**

The current `initState` body is:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    Provider.of<MainScreenProvider>(context, listen: false)
        .setIndex(_kPageDashboard);
    _loadTabFlags();
    NotificationService.init(_apiService).ignore();
  });
}
```

Add `_maybeShowAppDownloadSheet();` as the last line inside the callback:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    Provider.of<MainScreenProvider>(context, listen: false)
        .setIndex(_kPageDashboard);
    _loadTabFlags();
    NotificationService.init(_apiService).ignore();
    _maybeShowAppDownloadSheet();
  });
}
```

- [ ] **Step 4: Run the full test suite to check for regressions**

```bash
flutter test
```

Expected: all tests pass. If `main_screen_provider_test.dart` fails, check that the new imports don't clash with existing ones.

- [ ] **Step 5: Commit**

```bash
git add lib/main_screen.dart
git commit -m "feat: trigger app download sheet on web for Android/iOS users"
```

---

## Task 5: Manual verification

- [ ] **Step 1: Build for web and open in Chrome DevTools mobile emulation**

```bash
flutter run -d chrome
```

- [ ] **Step 2: In Chrome DevTools → toggle device toolbar → select "Pixel 7" (Android UA)**

The sheet should appear after the splash screen with the Play Store CTA and Android icon.

- [ ] **Step 3: Switch to "iPhone 14 Pro" (iOS UA) and reload**

The sheet should appear with the App Store CTA and iPhone icon.

- [ ] **Step 4: Switch to desktop (no mobile UA) and reload**

No sheet should appear.

- [ ] **Step 5: Tap "Download on Google Play" — verify it opens the correct store URL**

- [ ] **Step 6: Tap "Learn more at drivetest.se" — verify it opens `https://drivetest.se/`**

- [ ] **Step 7: Tap "Continue in browser" — verify the sheet dismisses cleanly**
