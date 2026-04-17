# Design System Specification: The Nordic Kinetic Editorial

## 1. Overview & Creative North Star: "The Kinetic Scholar"
This design system moves away from the sterile, grid-locked look of traditional EdTech. Instead, it adopts the **"Kinetic Scholar"** North Star—a visual language that feels as fast, bright, and optimistic as a Swedish summer morning.

We reject the "boxed-in" feeling of standard apps. To capture the energy of exam preparation, we use **Intentional Asymmetry** and **Dynamic Layering**. Elements should feel like they are in motion, utilizing overlapping typography and containers that break the traditional container boundaries. We are building a "Digital Magazine" for learning: high-impact, editorial-grade, and deeply motivational.

---

## 2. Colors: Vibrancy Through Tonal Depth
We use the Swedish national palette (Blues and Yellows) but elevate it with a sophisticated Tertiary Orange and a deep "Midnight" Ink for typography.

### Color Tokens

| Token | Hex | Usage |
|-------|-----|-------|
| `surface` | `#f8f5ff` | Base background |
| `surface-container-lowest` | `#ffffff` | Cards on surface |
| `surface-container-low` | `#f2efff` | Secondary sections |
| `surface-container` | `#e8e6ff` | Contained areas |
| `surface-container-high` | `#e1dfff` | High-emphasis containers |
| `surface-container-highest` | `#dbd9ff` | Active workspace |
| `surface-dim` | `#d1d0ff` | Dimmed surfaces |
| `surface-bright` | `#f8f5ff` | Brightened surfaces |
| `primary` | `#0049e6` | Primary actions, CTAs |
| `primary-container` | `#829bff` | Primary tint areas |
| `primary-fixed` | `#829bff` | Fixed primary |
| `primary-fixed-dim` | `#6e8cff` | Dimmed primary fixed |
| `primary-dim` | `#0040cb` | Dimmed primary |
| `inverse-primary` | `#6a89ff` | Inverse primary |
| `on-primary` | `#f2f1ff` | Text on primary |
| `on-primary-container` | `#001a63` | Text on primary container |
| `on-primary-fixed` | `#000000` | Text on primary fixed |
| `on-primary-fixed-variant` | `#002278` | Text on primary fixed variant |
| `secondary` | `#6c5a00` | Secondary actions |
| `secondary-container` | `#ffd709` | Highlights, badges, streaks |
| `secondary-fixed` | `#ffd709` | Fixed secondary |
| `secondary-fixed-dim` | `#efc900` | Dimmed secondary fixed |
| `secondary-dim` | `#5e4e00` | Dimmed secondary |
| `on-secondary` | `#fff2cd` | Text on secondary |
| `on-secondary-container` | `#5b4b00` | Text on secondary container |
| `on-secondary-fixed` | `#453900` | Text on secondary fixed |
| `on-secondary-fixed-variant` | `#665500` | Text on secondary fixed variant |
| `tertiary` | `#9b3f00` | Urgency, countdowns |
| `tertiary-container` | `#ff955e` | In-progress, streaks |
| `tertiary-fixed` | `#ff955e` | Fixed tertiary |
| `tertiary-fixed-dim` | `#ff7f36` | Dimmed tertiary fixed |
| `tertiary-dim` | `#883700` | Dimmed tertiary |
| `on-tertiary` | `#fff0ea` | Text on tertiary |
| `on-tertiary-container` | `#562000` | Text on tertiary container |
| `on-tertiary-fixed` | `#2f0e00` | Text on tertiary fixed |
| `on-tertiary-fixed-variant` | `#642600` | Text on tertiary fixed variant |
| `background` | `#f8f5ff` | App background |
| `on-background` | `#2a2b51` | Text on background |
| `surface-variant` | `#dbd9ff` | Surface variant |
| `on-surface` | `#2a2b51` | Primary text |
| `on-surface-variant` | `#575881` | Secondary text |
| `surface-tint` | `#0049e6` | Surface tint |
| `outline` | `#73739e` | Subtle borders, captions |
| `outline-variant` | `#a9a9d7` | Ghost borders |
| `inverse-surface` | `#09082f` | Focus Shroud overlay |
| `inverse-on-surface` | `#9999c6` | Text on inverse surface |
| `error` | `#b41340` | Error states |
| `error-container` | `#f74b6d` | Error containers |
| `error-dim` | `#a70138` | Dimmed error |
| `on-error` | `#ffefef` | Text on error |
| `on-error-container` | `#510017` | Text on error container |

### The "No-Line" Rule
**Explicit Instruction:** Designers are prohibited from using 1px solid borders to define sections. Boundaries are created through background shifts.
- **The Transition:** A `surface-container-low` section sitting on a `surface` background is the standard for sectioning.
- **The Logic:** If you feel the need to draw a line, instead adjust the background color of the container by one tier in the Material scale.

### Surface Hierarchy & Nesting
Treat the UI as a physical stack of fine, semi-translucent paper.
- **Base:** `surface` (#f8f5ff)
- **Sectioning:** `surface-container-low` (#f2efff) for secondary content.
- **Focus:** `surface-container-highest` (#dbd9ff) for active workspace areas.
- **The "Glass & Gradient" Rule:** For floating navigation or "Success" modals, use `surface-container-lowest` (#ffffff) at 80% opacity with a `24px` backdrop blur.

### Signature Textures
To inject "soul" into the flat aesthetic:
- **Primary CTAs:** Use a linear gradient from `primary` (#0049e6) to `primary-container` (#829bff) at a 135° angle.
- **Motivation Strips:** Use `secondary-container` (#ffd709) with a subtle grain texture to highlight key exam tips.

---

## 3. Typography: Editorial Authority
We pair **Lexend** (designed for reading proficiency) with **Plus Jakarta Sans** (a modern, energetic sans-serif).

- **The Display Scale (Lexend):** Use `display-lg` (3.5rem) for motivational milestones (e.g., "90% Ready"). These should be tight-tracked (-2%) to feel impactful.
- **The Headline Scale (Lexend):** `headline-md` (1.75rem) is our workhorse for screen titles. Use it to command attention.
- **The Body Scale (Plus Jakarta Sans):** `body-lg` (1rem) for exam questions. It provides a clean, breathable reading experience.
- **The Label Scale:** `label-md` (0.75rem) in all-caps with +5% letter spacing for category tags (e.g., "MATEMATIK").

### Flutter Font Setup
```dart
// pubspec.yaml dependency: google_fonts: ^6.2.1
import 'package:google_fonts/google_fonts.dart';

// Headline
GoogleFonts.lexend(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)

// Body
GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500)

// Label
GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, letterSpacing: 2.5)
```

---

## 4. Elevation & Depth: Tonal Layering
Traditional drop shadows are too "heavy" for this energetic system. We use **Ambient Softness**.

- **The Layering Principle:** Place a `surface-container-lowest` card on a `surface-container-low` background. This creates a 3D effect purely through color value.
- **Ambient Shadows:** For high-priority floating actions, use a shadow with `Y: 12px, Blur: 32px`. The color must be a tinted version of `on-surface` (#2a2b51) at 6% opacity. Never use pure black shadows.
- **The "Ghost Border" Fallback:** If a border is required for high-contrast accessibility, use `outline-variant` (#a9a9d7) at **15% opacity**. It should be felt, not seen.

---

## 5. Components: Fluidity & Purpose

### Buttons
- **Primary:** Gradient (`primary` to `primary-container`), `full` roundedness. No shadow. On press, gradient shifts 45°.
- **Secondary:** `surface-container-highest` background with `primary` text.
- **Tertiary:** Transparent background, `primary` text, `label-md` typography.

### Progress Visuals (The "Pulse" Chip)
- Instead of a standard bar, use "Energy Rings." Use `secondary` (#6c5a00) for incomplete tasks and `tertiary-container` (#ff955e) for "In-Progress" streaks to keep the energy high.

### Input Fields
- **State:** Background `surface-container-lowest`, `md` (0.75rem) roundedness.
- **Interaction:** On focus, the background stays white but the `outline` token (#73739e) appears at 40% opacity.

### Cards & Lists: The "No-Divider" Mandate
- **Strict Rule:** No horizontal lines between list items.
- **Implementation:** Separate list items using `12px` of vertical white space. Use a `surface-container-low` background for every even-numbered item to create a "zebra" rhythm that guides the eye without clutter.

### New Component: The "Focus Shroud"
For intensive study modes, a full-screen overlay using `inverse-surface` (#09082f) at 95% opacity, with content nested in `surface-container-lowest` to create a "light box" effect that eliminates all peripheral distractions.

---

## 6. Do's and Don'ts

### Do:
- **Do** overlap elements. Let a headline break into the margin of an image or card.
- **Do** use `tertiary` (#9b3f00) for "Urgency" (e.g., exam countdowns) and `secondary` (#6c5a00) for "Reward."
- **Do** utilize the `xl` (1.5rem) roundedness for large containers to maintain a friendly, approachable vibe.

### Don't:
- **Don't** use pure black (#000000) for text. Use `on-surface` (#2a2b51) to keep the palette harmonious.
- **Don't** use 90-degree corners. Everything must have at least a `sm` (0.25rem) radius to avoid looking "corporate."
- **Don't** cramp the layout. If in doubt, double the white space between sections. High-end editorial design requires "luxury" space.
