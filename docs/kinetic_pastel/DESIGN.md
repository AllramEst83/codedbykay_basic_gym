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

## Brand & Style

The design system is engineered for a high-energy fitness environment where motivation meets approachability. It targets active individuals who find traditional "hardcore" fitness aesthetics intimidating. The emotional response is one of optimism, softness, and "snappy" responsiveness. 

The style merges **Minimalism** with **Soft-Tactile** elements. It utilizes heavy whitespace to ensure clarity during intense activity, paired with oversized, pill-shaped interactive elements that feel satisfying to tap. The aesthetic is defined by its use of "Candy-Coated" surfaces—highly rounded, vibrant yet soft colors that make the data-heavy nature of fitness tracking feel effortless and inviting.

## Colors

The palette is a curated selection of functional pastels. Unlike muted tones, these are saturated enough to maintain high contrast against text.

- **Primary (Mint):** Used for "Go" actions, start buttons, and positive progress.
- **Secondary (Lavender):** Used for rest states, recovery metrics, and secondary navigation.
- **Tertiary (Coral):** Used for heart rate zones, high-intensity alerts, and delete actions.
- **Quaternary (Sky Blue):** Used for distance, hydration, and weather-related data.

**Dark Mode Strategy:** Dark mode is not pitch black. It uses a deep charcoal base (`#1A1C1E`) with subtle pastel tints in the overlays to maintain the "soft" brand character. Surface colors in dark mode should use a 5% opacity tint of the primary color to create depth.

## Typography

This design system uses **Plus Jakarta Sans** for headlines and labels to provide a friendly, modern, and slightly geometric appearance that remains highly readable at large sizes. **Be Vietnam Pro** is used for body copy to ensure warmth and contemporary flair in longer descriptions or workout notes.

Key typographic rules:
- **Stat Numbers:** Always use `stat-number` tokens for weights, reps, and times to ensure immediate glanceability.
- **Tight Leading:** Headlines use tight line heights to maintain the "snappy" look.
- **Contrast:** Ensure a minimum 4.5:1 contrast ratio for all body text against pastel backgrounds.

## Layout & Spacing

The layout follows a **Fluid Grid** model with high internal padding to prevent the UI from feeling cramped. 

- **Mobile:** 4-column grid with 20px margins. Elements usually span the full width or 2 columns.
- **Tablet/Desktop:** 12-column centered grid (max-width 1200px).
- **Rhythm:** All spacing must be multiples of the 8px base unit. 
- **Touch Targets:** Minimum touch target size is 48px, but preferred primary actions should be 64px to accommodate sweaty or moving hands during a workout.

## Elevation & Depth

This design system avoids traditional drop shadows in favor of **Tonal Layers** and **Soft Inner Glows**.

- **Surface Tiers:** Use subtle background color shifts to indicate depth. The main background is the base, with cards using the pure white/charcoal surface.
- **Active State:** When a button is pressed, it should physically "shrink" (0.98 scale) rather than gain a shadow, creating a tactile, "squishy" feel.
- **Glassmorphism:** Use only for fixed navigation bars or floating action buttons (FABs) with a high background blur (20px) and a thin 1px white border at 20% opacity.

## Shapes

The shape language is defined by the **Pill** (`rounded-xl`). There are virtually no sharp corners in this design system.

- **Buttons & Chips:** Always use the maximum radius (pill-shaped).
- **Cards:** Use `rounded-xl` (1.5rem / 24px) to create a soft container feel.
- **Input Fields:** Use `rounded-lg` (1rem / 16px) to maintain the friendly aesthetic while providing enough structure for text entry.
- **Progress Bars:** Fully rounded ends to match the pill-shaped buttons.

## Components

- **Buttons:** Primary buttons are oversized, pill-shaped, and use the Primary (Mint) color. Secondary buttons use a thick 2px outline in the same color or a light Sky Blue background.
- **Chips:** Used for muscle groups or workout tags. Small, pill-shaped, using the Secondary (Lavender) background with dark text.
- **Input Fields:** Large, 64px height fields with a soft Lavender border that thickens and turns Mint on focus.
- **Cards:** High-contrast containers with 24px internal padding. In Dark Mode, cards should have a 1px border using a 10% opacity primary color to define the edge.
- **Workout List Items:** High-density rows with large leading icons (pill-shaped backgrounds) and trailing chevron indicators.
- **Progress Circles:** Thick, rounded caps on the stroke, using a Quaternary (Sky Blue) track and Primary (Mint) indicator.