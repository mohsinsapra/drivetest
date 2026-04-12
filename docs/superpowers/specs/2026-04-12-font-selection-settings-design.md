# Font Selection Settings — Design Spec

**Date:** 2026-04-12  
**Status:** Approved

---

## Overview

Add a font selection setting to the app's Settings screen. Users can tap a chip to switch between available fonts and the change applies immediately, with no Save button required. The selected font persists across app restarts.

---

## Fonts

Two fonts are available:

| Display Name | Family Key | Asset |
|---|---|---|
| NudMoto | `NudMoto` | `assets/fonts/NudMotoya.ttf` |
| Inter | `Inter` | `assets/fonts/Inter.otf` |

`NudMoto` is the default (preserves current behaviour for existing users).

Both must be declared under `flutter.fonts` in `pubspec.yaml`. `Inter` is currently present as an asset but not declared — it will be added.

---

## Architecture

### `FontProvider` (`lib/core/providers/font_provider.dart`)

A new `ChangeNotifier` provider that mirrors the existing `ThemeProvider` pattern exactly.

- **State:** `String _fontFamily` (default: `'NudMoto'`)
- **Persistence key:** `'font_family'` in `SharedPreferences`
- **`fontFamily` getter:** returns current font family string
- **`setFont(String family)`:** saves to `SharedPreferences`, updates state, calls `notifyListeners()`
- **`_load()`:** called in constructor, restores saved value from prefs

### Theme functions (`lib/main.dart`)

`customTheme` and `darkTheme` top-level constants become `buildLightTheme(String font)` and `buildDarkTheme(String font)` functions. All hardcoded `fontFamily: 'NudMoto'` references are replaced with the `font` parameter.

### `MyApp` (`lib/main.dart`)

Reads `FontProvider` via `Provider.of<FontProvider>(context)` and passes `fontProvider.fontFamily` into both theme builder functions.

### Provider registration (`lib/main.dart`)

`FontProvider` is added to `MultiProvider` alongside `ThemeProvider`.

---

## Settings UI (`lib/settings/settings.dart`)

A new `ListTile` is inserted in the "Appearance" section, between the Dark Mode switch and the Language tile.

- **Leading icon:** `Icons.font_download_rounded` in a styled container (matching existing icon style)
- **Title:** `"Font"` (to be added to translation strings later if needed; hardcoded for now)
- **Subtitle:** name of the currently selected font
- **Trailing:** a row of font name chips using the existing `_LangChip` widget

### Chip behaviour

Tapping a chip immediately calls `fontProvider.setFont(family)`. No Save button involvement. The chip highlights to show the active selection. This mirrors the Dark Mode toggle pattern.

---

## Data Flow

```
App start
  └─ FontProvider constructor → _load() → SharedPreferences → _fontFamily set → notifyListeners()
  └─ MyApp builds → buildLightTheme(fontFamily) / buildDarkTheme(fontFamily)

User taps font chip
  └─ fontProvider.setFont('Inter')
       ├─ SharedPreferences.setString('font_family', 'Inter')
       ├─ _fontFamily = 'Inter'
       └─ notifyListeners() → MyApp rebuilds → new font applied immediately
```

---

## Files Changed

| File | Change |
|---|---|
| `pubspec.yaml` | Declare `Inter` font family |
| `lib/core/providers/font_provider.dart` | New file — `FontProvider` |
| `lib/main.dart` | Convert themes to functions, wire `FontProvider`, register in `MultiProvider` |
| `lib/settings/settings.dart` | Add font picker tile in Appearance section |

---

## Out of Scope

- Font size selection
- Per-screen font overrides
- Adding more fonts beyond the two already in `assets/fonts/`
- Translation strings for the font setting label
