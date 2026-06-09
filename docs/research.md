Research/Discovery:
* Verify data storage: Ensure the app stores data locally only.
* Determine how the app can persist data across app updates.

---

## 1. Is the app local-only today?

Yes, by construction — there is no data layer of any kind yet.

* All "data" is hardcoded as `static const` / `final` lists in `lib/data/sample_data.dart`
  (`todaysWorkouts`, `calendarMarkers`, `workoutCategories`, `recentUpdates`,
  `weeklyVolume`, `history`, `activeExercise()`).
* All mutable UI state lives in `setState` (e.g. `_darkMode`, `_workoutReminders`,
  `_friendActivity` in `lib/screens/settings_screen.dart`) and is therefore reset
  on every relaunch.
* `pubspec.yaml` declares only `flutter`, `cupertino_icons`, `google_fonts`, `intl`.
  No `firebase_*`, `supabase_*`, `dio`, `http`, `cloud_firestore`,
  `shared_preferences`, `sqflite`, `hive`, `isar`, or `drift`. Nothing networked,
  nothing persisted.
* `android/app/src/main/AndroidManifest.xml` declares `INTERNET` and
  `ACCESS_NETWORK_STATE`. These are used solely by `google_fonts` to fetch font
  files on first launch (cached locally afterwards). No app data leaves the device.
* The project rule `.cursor/rules/flutter-best-practices.mdc` already mandates:
  *"Data is local-only. When persisting, use a repository abstraction so storage
  can change without touching screens."*

**Conclusion:** the app is local-only today. Keep it that way by storing all future
persisted state on-device and never adding a remote backend / sync SDK.

## 2. Persisting data across app updates

On both Android and iOS, a normal app update (Play Store, App Store, or sideload)
preserves the app's private sandbox. Data written via the standard Flutter
storage APIs survives updates; it is only wiped on **uninstall** or
**Settings → Clear data** (Android) / device reset.

### Recommended local stores

| Need | Store | Why |
| --- | --- | --- |
| Theme mode, display name, last-selected tab, simple toggles | [`shared_preferences`](https://pub.dev/packages/shared_preferences) | Tiny KV. Backed by `NSUserDefaults` / `SharedPreferences`. Survives updates. |
| Workouts → exercises → sets, sessions, history, calendar entries | [`sqflite`](https://pub.dev/packages/sqflite) (optionally with [`drift`](https://pub.dev/packages/drift) on top) | Relational queries (by date, by category) match the feature list in `updates.md`. Survives updates with `onUpgrade` migrations. |

Both stores live inside the app sandbox (`/data/data/<package>/...` on Android,
the iOS app container). Nothing leaves the device.

### Update-safety rules

* Use `getApplicationDocumentsDirectory()` (or `sqflite`'s default path).
  **Never** persist anything important under `getTemporaryDirectory()` — the OS
  may wipe it without notice.
* Bump the `sqflite` schema `version` on every schema change and handle it in
  `onUpgrade(db, oldVersion, newVersion)` (e.g. `ALTER TABLE ADD COLUMN`).
  Never silently drop/recreate tables.
* For `shared_preferences`, only add new keys. Read with sensible defaults so
  installs upgrading from an older build still work. Never repurpose an old key.
* Wrap both behind repository classes (e.g. `SettingsRepository`,
  `WorkoutRepository`) per the project's MVVM rule so screens never touch
  storage directly. This lets us swap the underlying store later (e.g.
  `sqflite` → `drift`) without touching UI code.
* Initialise stores in `main()` before `runApp()` so screens can read sync data
  on first frame, or expose async loading states from the repositories.

### Backup / restore

* On Android, `allowBackup` is **not** disabled in `AndroidManifest.xml`, so
  user data is included in Google Auto Backup and may roam between the user's
  own devices via their Google Drive. Still device-private, not a backend we
  control — acceptable; revisit if it becomes undesirable (set
  `android:allowBackup="false"` on the `<application>` tag to opt out).
* Optional follow-up: add a Settings → "Export / Import JSON" action so the
  user has a manual backup path independent of the platform.
