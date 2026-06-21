---
name: Kinetic Pastel
colors:
  surface: '#f4fafd'
  surface-dim: '#d4dbdd'
  surface-bright: '#f4fafd'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eef5f7'
  surface-container: '#e8eff1'
  surface-container-high: '#e2e9ec'
  surface-container-highest: '#dde4e6'
  on-surface: '#161d1f'
  on-surface-variant: '#3e4944'
  inverse-surface: '#2b3234'
  inverse-on-surface: '#ebf2f4'
  outline: '#6e7a74'
  outline-variant: '#bdc9c2'
  surface-tint: '#006c52'
  primary: '#006c52'
  on-primary: '#ffffff'
  primary-container: '#98ffd9'
  on-primary-container: '#00785c'
  inverse-primary: '#73d9b5'
  secondary: '#5c5d6e'
  on-secondary: '#ffffff'
  secondary-container: '#e1e1f5'
  on-secondary-container: '#626374'
  tertiary: '#894e4f'
  on-tertiary: '#ffffff'
  tertiary-container: '#ffe5e4'
  on-tertiary-container: '#965959'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#8ff6d0'
  primary-fixed-dim: '#73d9b5'
  on-primary-fixed: '#002117'
  on-primary-fixed-variant: '#00513d'
  secondary-fixed: '#e1e1f5'
  secondary-fixed-dim: '#c5c5d8'
  on-secondary-fixed: '#191b29'
  on-secondary-fixed-variant: '#444655'
  tertiary-fixed: '#ffdad9'
  tertiary-fixed-dim: '#ffb3b3'
  on-tertiary-fixed: '#370d10'
  on-tertiary-fixed-variant: '#6d3738'
  background: '#f4fafd'
  on-background: '#161d1f'
  surface-variant: '#dde4e6'
  quaternary: '#a1c4fd'
  quaternary-container: '#e3f0ff'
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 48px
    fontWeight: '800'
    lineHeight: 56px
    letterSpacing: -0.02em
  display-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 36px
    fontWeight: '800'
    lineHeight: 44px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  body-lg:
    fontFamily: Be Vietnam Pro
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Be Vietnam Pro
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-bold:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '700'
    lineHeight: 20px
  stat-number:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '800'
    lineHeight: 40px
    letterSpacing: -0.01em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 12px
  md: 24px
  lg: 40px
  xl: 64px
  container-margin: 20px
  gutter: 16px
---

# FlexFlow Design System — Kinetic Pastel

> **Flutter implementation:** `lib/theme/` (tokens) · `lib/widgets/` (shared components)
>
> **Cursor rule:** `.cursor/rules/app-design-design-rule.mdc`

---

## Brand Essence

FlexFlow is a fitness app for people who want energy without intimidation. The visual language is **Kinetic Pastel** — high-energy motivation delivered through soft, candy-coated surfaces rather than hardcore gym aesthetics.

The style merges **minimalism** with **soft-tactile** elements: heavy whitespace for clarity during intense activity, oversized pill-shaped controls that feel satisfying to tap, and functional pastels saturated enough for contrast yet soft enough to feel inviting.

| Attribute | Expression |
|-----------|------------|
| **Tone** | Optimistic, approachable, snappy |
| **Style** | Minimalism + soft-tactile UI |
| **Feel** | Heavy whitespace, oversized pill controls, satisfying tap feedback |
| **Audience** | Active individuals who find traditional fitness apps aggressive or cold |

**Tagline:** *Find your flow.*

**Logo:** Gradient ribbon "F" on a white squircle with soft inner glow. Wordmark uses `display-lg` in `primary`.

---

## Design Principles

1. **Clarity under exertion** — Large stat numbers, high contrast, generous touch targets (48px min, 64px preferred for primary actions).
2. **Tonal depth over shadows** — Surface color shifts indicate hierarchy; drop shadows are rare and subtle.
3. **Squish, don't shadow** — Press states scale to 0.96–0.98 rather than adding elevation.
4. **Pills everywhere** — Buttons, chips, nav active states, and progress bars use full or near-full border radius.
5. **Functional pastels** — Saturated enough for contrast, soft enough to feel inviting.
6. **Local-first responsiveness** — UI never blocks on network; motion reinforces immediate feedback.

---

## Colors

Material 3 role names are used consistently. See YAML frontmatter above for hex values.

### Semantic roles

- **Primary (Mint):** Go actions, start/finish buttons, positive progress, brand accent.
- **Secondary (Lavender):** Rest states, recovery metrics, secondary navigation.
- **Tertiary (Coral):** Heart-rate zones, rest timers, high-intensity alerts, delete actions.
- **Quaternary (Sky Blue):** Distance, hydration, weather-related data (`#A1C4FD` / container `#E3F0FF`).

### Surfaces

| Role | Usage |
|------|-------|
| `background` / `surface` | App canvas |
| `surface-container-lowest` | Cards, list rows, calendar panel |
| `surface-container-low` | Calendar day cells, hover states |
| `surface-container` | Icon circle backgrounds, dividers |
| `surface-container-highest` | Segmented control track, active set highlight |
| `on-surface` | Primary text, headings |
| `on-surface-variant` | Secondary text, labels, inactive nav |
| `outline-variant` | Input borders (default) |

### Category mapping

| Category | Container | Icon/Text |
|----------|-----------|-----------|
| Gym / Strength | `secondary-container` | `on-secondary-container` / `on-secondary-fixed` |
| Running / Cardio | `primary-container` | `on-primary-container` / `on-primary-fixed` |
| Yoga / Flexibility | `tertiary-container` | `on-tertiary-container` |
| Rest / Recovery | `secondary-container` | `on-secondary-container` |
| History / neutral | `surface-container` | `on-surface` |

### Dark mode

Not pitch black. Base `#1A1C1E`, scaffold `#0E1413`. Surfaces use charcoal with 5% primary tint overlays. Cards get a 1px border at 10% primary opacity. Nav active state switches from `primary-container` pill to solid `primary`. Flutter: `AppTheme.dark()`.

---

## Typography

| Family | Roles |
|--------|-------|
| **Plus Jakarta Sans** | Display, headlines, labels, stat numbers |
| **Be Vietnam Pro** | Body copy, descriptions, workout notes |

| Token | Size | Weight | Line Height | Letter Spacing | Use |
|-------|------|--------|-------------|----------------|-----|
| `display-lg` | 48px | 800 | 56px | −0.02em | Desktop hero titles |
| `display-lg-mobile` | 36px | 800 | 44px | −0.02em | Mobile hero titles, exercise names |
| `headline-md` | 24px | 700 | 32px | — | Section headers, workout titles |
| `body-lg` | 18px | 400 | 28px | — | Subtitles, setting row titles |
| `body-md` | 16px | 400 | 24px | — | Default body, metadata |
| `label-bold` | 14px | 700 | 20px | — | Buttons, chips, nav labels |
| `stat-number` | 32px | 800 | 40px | −0.01em | Weight, reps, duration, calories |

**Rules:** Stat numbers always use `stat-number`. Section eyebrows: `label-bold`, uppercase, wide tracking, `on-surface-variant`. App bar brand: `headline-md` ~22px in `primary`. Nav labels: 10px `label-bold`. Minimum 4.5:1 contrast on pastel backgrounds.

Flutter: `AppTextStyles` in `lib/theme/app_typography.dart`.

---

## Layout & Spacing

Base unit: **8px**. All spacing is a multiple of 8.

| Token | Value | Use |
|-------|-------|-----|
| `xs` | 4px | Tight gaps, dot indicators |
| `base` | 8px | Default inline gap |
| `sm` | 12px | List item padding, chip vertical |
| `gutter` | 16px | Grid gaps, card gutters |
| `container-margin` | 20px | Screen horizontal padding |
| `md` | 24px | Card internal padding, section gaps |
| `lg` | 40px | Major section separation |
| `xl` | 64px | App bar / nav bar height |

**Grid:** Mobile 4-column (20px margins). Tablet/desktop 12-column, max-width 1200px centered.

**Safe areas:** Top bar 64px + status inset. Bottom nav 64px + safe area. Active session bottom bar 100px (replaces nav). FAB sits above nav (~104px from bottom on mobile).

Flutter: `AppSpacing`, `AppRadius` in `lib/theme/app_spacing.dart`.

---

## Shapes

Virtually no sharp corners.

| Token | Value | Use |
|-------|-------|-----|
| `sm` | 8px | Small inner elements |
| `md` / DEFAULT | 16px | Input fields, set rows, thumbnails |
| `card` | 24px | Cards, calendar panel, profile card |
| `lg` | 32px | Bottom nav top corners |
| `xl` | 48px | Settings grouped cards |
| `pill` / `full` | 9999px | Buttons, chips, nav active, calendar days, toggles |

---

## Elevation & Depth

- **Tonal layers** — Default; shift surface container tier instead of shadow.
- **Soft shadow** — Occasional card hover, FAB, finish button glow only.
- **Inner glow / blur orb** — Decorative accents behind workout cards and profile card.
- **Glassmorphism** — Fixed top bar and bottom nav only: 20px blur, 85% surface opacity.
- **Border highlight** — Active set row: `primary/20` border + soft outer glow.
- **Scale on press** — 0.96–0.98 via `Squish` widget.

**Splash gradient mesh:** radial mint top-left, lavender top-right, primary-fixed bottom-right, background bottom-left on white base at ~40% opacity.

---

## Motion & Interaction

| Pattern | Spec | Where |
|---------|------|-------|
| **Squish** | scale 0.96–0.98, 120ms ease-out | All tappable elements |
| **Nav tab press** | scale 0.90 | Bottom nav items |
| **Slide up entrance** | translateY 20px→0, 600ms ease-out | Calendar sections (stagger 100ms) |
| **Soft pulse** | scale 1→1.05→1, 4s infinite | Splash icon float |
| **Pop in** | scale 0→1, 300ms spring | Set completion checkmark |
| **Theme pulse** | primary-container flash, 600ms | Settings theme toggle |

Flutter: `Squish` in `lib/widgets/squish.dart`.

---

## Iconography

Material Icons in Flutter (`Icons.*_outlined` / `_rounded`). Default outline 24px. Filled variant for selected nav tab and category icons. Icon circles: 48px (list), 64px (category bento), 40px (profile header).

---

## Components

### Buttons

| Variant | Style | Height |
|---------|-------|--------|
| **Primary pill** | `primary` bg, `on-primary` text, pill radius | 56–64px |
| **Primary elevated** | Primary + shadow `0 4px 20px primary/30` | 64px |
| **Secondary pill** | `surface-container-highest` or 2px `primary` outline | 48–64px |
| **Card CTA** | `on-*-fixed` bg, `surface-container-lowest` text | auto |
| **FAB** | 64×64 circle, `primary` bg, white icon | 64px |

Flutter: `PrimaryPillButton`.

### Chips

Pill tags for muscle groups / categories. Background: container color. Text: `label-bold`. Padding 12×4px. Flutter: `CategoryPill`.

### Inputs

64px height standalone; inline stat inputs in set rows. Radius `md`. Border 1px `outline-variant` → 2px `primary` on focus. Values centered in `stat-number`.

### Cards

| Type | Background | Radius | Padding |
|------|------------|--------|---------|
| **Workout hero** | `*-container` | `card` | `md` |
| **List row** | `surface-container-lowest` | `md` | `sm`–`md` |
| **Stat tile** | `surface-container-lowest` | `md` | `md` (~140px tall) |
| **Settings group** | `surface-container-lowest` | `xl` | rows + 1px dividers |
| **Profile** | `surface-container-lowest` | `card` | `md` |

### Toggles

Track 56×32px pill. `secondary-container` off / `primary` on. Thumb 24px circle, 300ms transition.

### Segmented control

Track `surface-container-highest`, pill shape. Active segment: `surface` + subtle shadow.

### Progress indicators

Circular (splash): 3px stroke, track `secondary-container`, indicator `primary`. Bar chart: `rounded-t-full` bars. Calendar dots: 6px circles.

### Navigation

- **Top bar (`FlexTopBar`):** Glassmorphic, 64px + status bar, centered "FlexFlow" in `primary`.
- **Bottom nav (`FlexBottomNav`):** 4 tabs — Workouts · Calendar · Progress · Settings. Active: `primary-container` pill.
- **Active session:** Bottom nav replaced by "Add Note" (secondary) + "Finish Workout" (primary elevated) bar.

---

## Screen Patterns

### Splash
Gradient mesh background. Center app icon (192–224px, float animation). Brand in `display-lg-mobile`. Tagline + loading spinner. Auto-transition 3–5s.

### Calendar
Month title, Month/Week/Day segmented control. Calendar grid in white card; selected day = `primary` circle + dot indicators. Today's workout hero cards with category pill, duration, CTA.

### Workout Management
Page title + subtitle. Category bento rows (64px icon circle + chevron). Recent updates list with edit icon. FAB for create.

### Active Session
Contextual header: pause · title + timer · settings. Category pill + exercise counter. Set rows: completed · active (highlighted inputs) · upcoming (dimmed). Rest timer in `tertiary-container`. Bottom action bar replaces nav.

### Progress / History
"This Week" stat tiles (2-column). Volume bar chart with period badge. History list: 80px thumbnail + title + metadata + chevron.

### Settings
Profile card with outlined "Edit Profile" pill. Grouped preference rows with icon circles and toggles. Uppercase section eyebrows.

---

## Flutter Quick Reference

```dart
import 'package:codedbykay_basic_gym/theme/app_colors.dart';
import 'package:codedbykay_basic_gym/theme/app_typography.dart';
import 'package:codedbykay_basic_gym/theme/app_spacing.dart';
import 'package:codedbykay_basic_gym/theme/app_theme.dart';
import 'package:codedbykay_basic_gym/widgets/squish.dart';
import 'package:codedbykay_basic_gym/widgets/primary_pill_button.dart';
import 'package:codedbykay_basic_gym/widgets/category_pill.dart';
import 'package:codedbykay_basic_gym/widgets/flex_top_bar.dart';
import 'package:codedbykay_basic_gym/widgets/flex_bottom_nav.dart';

// ✅ Use tokens
padding: const EdgeInsets.all(AppSpacing.gutter),
style: AppTextStyles.headlineMd,
color: AppColors.primary,
borderRadius: BorderRadius.circular(AppRadius.card),

// ❌ Never hardcode
padding: const EdgeInsets.all(16),
color: Color(0xFF006C52),
```

Wrap interactive targets in `Squish`. Use `FlexTopBar` + `FlexBottomNav` in `HomeShell`. Theme: `AppTheme.light()` / `AppTheme.dark()` with `useMaterial3: true`.

---

## File Index

| Path | Purpose |
|------|---------|
| `design/DESIGN.md` | This document — tokens (YAML) + full system guide |
| `lib/theme/app_colors.dart` | Color constants |
| `lib/theme/app_typography.dart` | Text styles |
| `lib/theme/app_spacing.dart` | Spacing + radius |
| `lib/theme/app_theme.dart` | Material 3 ThemeData |
| `lib/widgets/` | Shared UI components |
| `.cursor/rules/app-design-design-rule.mdc` | Cursor enforcement rule |
