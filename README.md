# FlexFlow

A Flutter fitness tracker for gym strength training and outdoor running. Kinetic Pastel design system — soft pastels, high border-radius, fluid animations.

**Platforms:** Android (primary) · Web (planned)
**Package:** `codedbykay_basic_gym`

---

## Project map

```
lib/
  main.dart                    # Entry point — opens DB, hydrates stores, runs app
  screens/                     # Full-page views
  widgets/                     # Reusable UI components
  theme/                       # Design tokens (colors, spacing, typography, theme)
  models/                      # Domain types (Workout, Exercise, enums)
  data/                        # Stores, repositories, sqflite, services

supabase/
  README.md                    # Supabase integration guide (auth, RLS, sync, Edge Functions)
  ref/                         # Reference implementations for Edge Functions

docs/                          # Project documentation and design references
.cursor/rules/                 # AI coding rules for this project
```

---

## Screens

| Screen | File | Description |
|---|---|---|
| Splash | `screens/splash_screen.dart` | Loading screen shown on cold start |
| Home shell | `screens/home_shell.dart` | Bottom nav host — wraps Calendar, Workouts, Progress, Settings |
| Calendar | `screens/calendar_screen.dart` | Monthly/weekly workout schedule; today's workouts quick-start |
| Workouts | `screens/workouts_screen.dart` | Routine library and management |
| Create workout | `screens/create_workout_screen.dart` | New / edit routine form |
| Routine management | `screens/routine_management_screen.dart` | Reorder and edit exercises within a routine |
| Active session | `screens/active_session_screen.dart` | Real-time gym session tracker (sets, reps, rest timer) |
| Running session | `screens/running_session_screen.dart` | Real-time running session tracker (GPS, distance, pace) |
| Workout history | `screens/workout_history_screen.dart` | Historical log of completed sessions |
| Progress | `screens/progress_screen.dart` | Stats, volume charts, personal records |
| Settings | `screens/settings_screen.dart` | Theme, language, profile, notifications |

---

## Data layer

| File | Role |
|---|---|
| `data/app_state.dart` | Global `themeModeNotifier` and top-level app state |
| `data/workout_store.dart` | In-memory routine store; `ChangeNotifier` |
| `data/calendar_store.dart` | In-memory scheduled-workout store; `ChangeNotifier` |
| `data/session_store.dart` | In-memory completed-session store; `ChangeNotifier` |
| `data/settings_store.dart` | In-memory settings store (theme, language); `ChangeNotifier` |
| `data/session_completion.dart` | Logic for finalising an active session into a `WorkoutSession` |
| `data/progress_stats.dart` | Derived stats computed from the session store |
| `data/permission_service.dart` | Runtime permission requests (location, audio) |
| `data/sample_data.dart` | Seed data used during development |
| `data/repository_provider.dart` | Singleton that wires concrete sqflite repositories to the stores |
| `data/sqflite/app_database.dart` | sqflite singleton; schema v4; migrations |
| `data/repositories/` | Abstract repository interfaces (Routine, Schedule, Session, Settings, InProgressSession) |
| `data/sqflite/` | Concrete sqflite implementations of each repository |

### Models (`models/`)

`workout.dart` — `Workout`, `Exercise`, `WorkoutSession`, `SessionExercise`, `SessionSet`, `WorkoutCategory` enum and display extensions.

---

## Theme (`theme/`)

Never hardcode colors, spacing, radii, or text styles in screens or widgets — always use these tokens.

| File | Exports |
|---|---|
| `app_colors.dart` | `AppColors` — full Kinetic Pastel palette, light and dark surfaces |
| `app_spacing.dart` | `AppSpacing`, `AppRadius` — gutter, padding, corner radius constants |
| `app_typography.dart` | `AppTextStyles` — Plus Jakarta Sans (headlines) + Be Vietnam Pro (body) |
| `app_theme.dart` | `AppTheme.light()` / `AppTheme.dark()` — Material 3 theme builders |

---

## Widgets (`widgets/`)

| File | Widget | Description |
|---|---|---|
| `flex_top_bar.dart` | `FlexTopBar` | Shared top app bar |
| `flex_bottom_nav.dart` | `FlexBottomNav` | Shared bottom navigation bar |
| `primary_pill_button.dart` | `PrimaryPillButton` | Main CTA button in pill shape |
| `category_pill.dart` | `CategoryPill` | Workout category badge (Strength / Cardio / Running) |
| `squish.dart` | `Squish` | Press-scale wrapper for interactive tap feedback |

---

## Supabase

Google OAuth (Android native `signInWithIdToken` · Web `signInWithOAuth`) + PostgREST direct writes protected by Row Level Security.

Full details in **[`supabase/README.md`](supabase/README.md)** — covers auth flows per platform, RLS policy templates, Edge Function skeleton, sync strategy, environment variables, and the sqflite/web compatibility note.

Reference Edge Function utilities in `supabase/ref/`:

| File | Purpose |
|---|---|
| `ref/auth.ts` | Server-side JWT verification (`getAuthenticatedUser`) |
| `ref/supabase.ts` | Supabase client factory (service role + user-scoped) |
| `ref/cors.ts` | CORS preflight and header helpers |
| `ref/errors.ts` | Typed HTTP error classes and `jsonResponse` |
| `ref/crypto.ts` | AES-256-GCM encrypt / decrypt |

---

## Docs (`docs/`)

| File | Contents |
|---|---|
| `docs/project-brief.md` | Original product brief — screens, objectives, design system overview |
| `docs/research.md` | Storage and persistence research notes |
| `docs/gps_research.md` | GPS / location tracking findings |
| `docs/updates.md` | Running changelog of implemented features |
| `docs/error.md` | Known errors and debug notes |
| `docs/kinetic_pastel/DESIGN.md` | Kinetic Pastel design system reference |
| `docs/*/code.html` | Per-screen HTML prototype references (calendar, active session, history, settings, etc.) |

---

## Cursor AI rules (`.cursor/rules/`)

| File | Scope | Contents |
|---|---|---|
| `flutter-best-practices.mdc` | `lib/**/*.dart` | Flutter/Dart conventions — project layout, design system usage, widget patterns, state, navigation, Dart style |
| `supabase-auth-best-practices.mdc` | always | Supabase auth rules — Google Sign-In per platform, RLS templates, token handling, Edge Function patterns, sync rules |

---

## Stack

| Layer | Technology |
|---|---|
| UI framework | Flutter (Material 3, `useMaterial3: true`) |
| Fonts | Plus Jakarta Sans · Be Vietnam Pro (`google_fonts`) |
| Local storage | `sqflite` (Android) — web storage TBD |
| Permissions | `permission_handler`, `geolocator` |
| Backend | Supabase (Auth + PostgREST + Edge Functions) |
| Auth | Google OAuth via `supabase_flutter` + `google_sign_in` |
| Linting | `flutter_lints` |
