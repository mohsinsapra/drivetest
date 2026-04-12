# Font Selection Settings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users pick between NudMoto and Inter fonts in Settings; the change applies immediately and persists across restarts.

**Architecture:** A new `FontProvider` (mirrors `ThemeProvider`) holds the selected font family, persists to `SharedPreferences`, and calls `notifyListeners()` on change. Themes in `main.dart` become builder functions that accept a font string. The Settings screen reads `FontProvider` directly and updates it on chip tap — no Save button involved.

**Tech Stack:** Flutter, Provider, SharedPreferences, flutter_test

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `lib/core/providers/font_provider.dart` | State + persistence for selected font |
| Create | `test/core/providers/font_provider_test.dart` | Unit tests for FontProvider |
| Modify | `pubspec.yaml` | Declare Inter font family |
| Modify | `lib/main.dart` | Theme builder functions, wire FontProvider |
| Modify | `lib/settings/settings.dart` | Font picker tile in Appearance section |

---

## Task 1: Register Inter font in pubspec.yaml

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add Inter to the fonts section**

In `pubspec.yaml`, find the `fonts:` block (line 145) and add the Inter entry directly after the NudMoto entry:

```yaml
  fonts:
    - family: NudMoto
      fonts:
        - asset: assets/fonts/NudMotoya.ttf
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter.otf
```

- [ ] **Step 2: Verify Flutter can resolve the font**

```bash
flutter pub get
```

Expected: `Resolving dependencies... Got dependencies.` with no errors.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml
git commit -m "chore: register Inter font family in pubspec"
```

---

## Task 2: Create FontProvider

**Files:**
- Create: `lib/core/providers/font_provider.dart`
- Create: `test/core/providers/font_provider_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/core/providers/font_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/providers/font_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('default font is NudMoto', () async {
    final provider = FontProvider();
    await Future.delayed(Duration.zero);
    expect(provider.fontFamily, 'NudMoto');
  });

  test('setFont updates fontFamily', () async {
    final provider = FontProvider();
    await Future.delayed(Duration.zero);
    await provider.setFont('Inter');
    expect(provider.fontFamily, 'Inter');
  });

  test('setFont calls notifyListeners', () async {
    final provider = FontProvider();
    await Future.delayed(Duration.zero);
    bool notified = false;
    provider.addListener(() => notified = true);
    await provider.setFont('Inter');
    expect(notified, true);
  });

  test('setFont persists to SharedPreferences', () async {
    final provider = FontProvider();
    await Future.delayed(Duration.zero);
    await provider.setFont('Inter');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('font_family'), 'Inter');
  });

  test('loads persisted font on init', () async {
    SharedPreferences.setMockInitialValues({'font_family': 'Inter'});
    final provider = FontProvider();
    await Future.delayed(Duration.zero);
    expect(provider.fontFamily, 'Inter');
  });
}
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
flutter test test/core/providers/font_provider_test.dart
```

Expected: compilation error — `FontProvider` does not exist yet.

- [ ] **Step 3: Create FontProvider**

Create `lib/core/providers/font_provider.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontProvider extends ChangeNotifier {
  static const _key = 'font_family';
  static const _defaultFont = 'NudMoto';

  String _fontFamily = _defaultFont;

  String get fontFamily => _fontFamily;

  FontProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _fontFamily = prefs.getString(_key) ?? _defaultFont;
    notifyListeners();
  }

  Future<void> setFont(String family) async {
    _fontFamily = family;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, family);
    notifyListeners();
  }
}
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
flutter test test/core/providers/font_provider_test.dart
```

Expected:

```
00:00 +5: All tests passed!
```

- [ ] **Step 5: Commit**

```bash
git add lib/core/providers/font_provider.dart test/core/providers/font_provider_test.dart
git commit -m "feat: add FontProvider for font family selection"
```

---

## Task 3: Wire FontProvider into themes and MyApp

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Convert theme constants to builder functions**

In `lib/main.dart`, replace the two top-level `final` theme constants with functions. Find `final darkTheme = ThemeData(` and `final customTheme = ThemeData(` and replace the entire blocks:

```dart
ThemeData buildDarkTheme(String font) => ThemeData(
  fontFamily: font,
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
  appBarTheme: AppBarTheme(
    backgroundColor: const Color(0xFF1C1C1E),
    elevation: 0,
    iconTheme: const IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontFamily: font,
      fontWeight: FontWeight.w600,
    ),
    toolbarTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontFamily: font,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    labelStyle: TextStyle(color: const Color(0xFF9E9E9E), fontFamily: font),
    hintStyle: TextStyle(color: const Color(0xFF757575), fontFamily: font),
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

ThemeData buildLightTheme(String font) => ThemeData(
  fontFamily: font,
  textTheme: TextTheme(
    bodyLarge: TextStyle(fontFamily: font),
    bodyMedium: TextStyle(fontFamily: font),
    titleLarge: TextStyle(fontFamily: font),
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
    fillColor: const Color(0xFF757575),
    labelStyle: TextStyle(color: const Color(0xFF757575), fontFamily: font),
    hintStyle: TextStyle(color: const Color(0xFF9E9E9E), fontFamily: font),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFBDBDBD), width: 0.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFBDBDBD), width: 0.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF2779BC), width: 1),
    ),
  ),
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.white,
    elevation: 0,
    iconTheme: const IconThemeData(color: Colors.black),
    titleTextStyle: TextStyle(
      color: Colors.black,
      fontSize: 20,
      fontFamily: font,
      fontWeight: FontWeight.w600,
    ),
    toolbarTextStyle: TextStyle(
      color: Colors.black,
      fontSize: 18,
      fontFamily: font,
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
```

- [ ] **Step 2: Add FontProvider import and register it in MultiProvider**

At the top of `lib/main.dart`, add the import after the existing provider import:

```dart
import 'package:taxi_exam_app/core/providers/font_provider.dart';
```

In `runApp(...)`, find the `MultiProvider` providers list and add `FontProvider`:

```dart
providers: [
  ChangeNotifierProvider(create: (_) => MainScreenProvider()),
  ChangeNotifierProvider(create: (_) => ThemeProvider()),
  ChangeNotifierProvider(create: (_) => FontProvider()),
],
```

- [ ] **Step 3: Update MyApp.build to use FontProvider and builder functions**

Replace the `MyApp.build` method body so it reads `FontProvider` and passes the font to the theme builders:

```dart
@override
Widget build(BuildContext context) {
  final themeProvider = Provider.of<ThemeProvider>(context);
  final fontProvider = Provider.of<FontProvider>(context);
  final locale = InheritedLocaleData.of<AppLocale, Translations>(context)
      .locale
      .flutterLocale;
  return ToastificationWrapper(
    config: const ToastificationConfig(itemWidth: 320),
    child: MaterialApp(
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
    ),
  );
}
```

- [ ] **Step 4: Verify no compile errors**

```bash
flutter analyze lib/main.dart
```

Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart
git commit -m "feat: make themes font-aware via buildLightTheme/buildDarkTheme"
```

---

## Task 4: Add font picker to Settings screen

**Files:**
- Modify: `lib/settings/settings.dart`

- [ ] **Step 1: Add FontProvider import**

At the top of `lib/settings/settings.dart`, add the import after the existing provider import:

```dart
import 'package:taxi_exam_app/core/providers/font_provider.dart';
```

- [ ] **Step 2: Add font picker tile in the Appearance section**

In the `build` method, add `fontProvider` alongside the existing `themeProvider` line:

```dart
final fontProvider = Provider.of<FontProvider>(context);
```

Then in the ListView children, find the Divider that separates Dark Mode from Language (the line `const Divider(height: 1, indent: 16, endIndent: 16),` before the Language `ListTile`) and insert the font tile + a new divider before it:

```dart
const Divider(height: 1, indent: 16, endIndent: 16),

// Font picker
ListTile(
  leading: Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.purple.shade50,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(Icons.font_download_rounded,
        color: Colors.purple.shade600, size: 20),
  ),
  title: const Text('Font'),
  subtitle: Text(fontProvider.fontFamily),
  trailing: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _LangChip(
        label: 'NudMoto',
        selected: fontProvider.fontFamily == 'NudMoto',
        onTap: () => fontProvider.setFont('NudMoto'),
      ),
      const SizedBox(width: 8),
      _LangChip(
        label: 'Inter',
        selected: fontProvider.fontFamily == 'Inter',
        onTap: () => fontProvider.setFont('Inter'),
      ),
    ],
  ),
),

const Divider(height: 1, indent: 16, endIndent: 16),

// Language tile (already exists below this point)
```

- [ ] **Step 3: Verify no compile errors**

```bash
flutter analyze lib/settings/settings.dart
```

Expected: `No issues found!`

- [ ] **Step 4: Run all tests**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/settings/settings.dart
git commit -m "feat: add font picker to settings appearance section"
```

---

## Task 5: Smoke test on device/simulator

- [ ] **Step 1: Run the app**

```bash
flutter run
```

- [ ] **Step 2: Verify default state**

Open Settings → Appearance. Confirm the Font tile shows `NudMoto` chip highlighted and the app text uses the NudMoto font.

- [ ] **Step 3: Switch to Inter**

Tap the `Inter` chip. Confirm immediately: the Inter chip highlights, the subtitle changes to `Inter`, and the app text switches to Inter globally (check the AppBar title or any screen text).

- [ ] **Step 4: Switch back to NudMoto**

Tap the `NudMoto` chip. Confirm the app text reverts to NudMoto.

- [ ] **Step 5: Verify persistence**

With Inter selected, hot-restart the app (`R` in terminal). Confirm Inter is still selected and applied after restart.
