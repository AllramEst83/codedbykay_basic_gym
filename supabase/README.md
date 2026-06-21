
===================DO NOT IMPLEMENT AT THE MOMENT===========================================

# FlexFlow — Supabase Integration

This document describes how Supabase is used in FlexFlow: authentication, the data sync strategy, Edge Function patterns, and environment setup.

> **Target platforms:** Android (primary), Web. iOS is out of scope for now — omit iOS-specific setup until explicitly added.

> **Research source:** NotebookLM notebook [Supabase Auth and Row Level Security Guide](https://notebooklm.google.com/notebook/3696ed17-acaf-4931-9f6a-a5d69e27cd01) (UUID `3696ed17-acaf-4931-9f6a-a5d69e27cd01`) — consult it for anything not covered here.

---

## Auth Architecture

Supabase Auth passes every request through four layers:

```
Flutter app
  └─► Kong API gateway (shared across all Supabase products)
        └─► Auth service (GoTrue fork — validates, issues, refreshes JWTs)
              └─► Postgres (auth schema — not exposed via the auto-generated API)
```

The `supabase_flutter` client SDK handles the full client layer: token persistence, refresh, removal, and attaching the JWT to every outbound request automatically.

---

## Authentication

FlexFlow uses **Google OAuth exclusively** via Supabase Auth. There is no email/password sign-in — a Google account is required.

The sign-in implementation differs by platform:

| Platform | Method | Package |
|---|---|---|
| Android | `signInWithIdToken` (native modal) | `google_sign_in` |
| Web | `signInWithOAuth` (browser redirect) | built-in Supabase client |

### Android — native Google Sign-In

Use the `google_sign_in` package to get a native OIDC ID token, then exchange it with Supabase. This shows the native account picker without opening a browser.

**Required Google Cloud client IDs:**
- Web Client ID → add to Supabase Dashboard under Authentication → Providers → Google
- Android Client ID → registered in Google Cloud Console for the app's package name + SHA-1

```dart
// ✅ Android native sign-in
final googleUser = await GoogleSignIn(
  serverClientId: '<WEB_CLIENT_ID>',
).signIn();
final googleAuth = await googleUser!.authentication;

await supabase.auth.signInWithIdToken(
  provider: OAuthProvider.google,
  idToken: googleAuth.idToken!,
  accessToken: googleAuth.accessToken,
);
```

### Web — OAuth redirect flow

On Flutter Web, `google_sign_in`'s native flow is not available. Use `signInWithOAuth`, which redirects the user to Google's consent screen and back to the app URL.

```dart
// ✅ Web sign-in
await supabase.auth.signInWithOAuth(
  OAuthProvider.google,
  redirectTo: 'https://yourapp.com/auth/callback', // your deployed web URL
);
```

Add this URL (and `http://localhost` variants for dev) to the **Redirect URLs** allow-list in the Supabase Dashboard.

### Sign out (all platforms)

```dart
await supabase.auth.signOut();
```

### Session restore on cold start

```dart
// In main(), before runApp
final session = supabase.auth.currentSession;
// Route to login screen or home based on session != null
```

---

## Deep Links (Android)

Deep links on Android route the user back into the app after a web-based OAuth flow (e.g. as a fallback or for non-native providers in future).

1. Add `io.supabase.flexflow://login-callback/` to the **Redirect URLs** allow-list in the Supabase Dashboard.
2. Add an intent filter in `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <intent-filter android:autoVerify="true">
     <action android:name="android.intent.action.VIEW" />
     <category android:name="android.intent.category.DEFAULT" />
     <category android:name="android.intent.category.BROWSABLE" />
     <data android:scheme="io.supabase.flexflow" android:host="login-callback" />
   </intent-filter>
   ```
3. Add internet permission (required for production Android builds):
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   ```

The `supabase_flutter` package handles deep-link routing internally via `app_links`.

> **Web** uses real HTTPS redirect URLs, not custom schemes — no deep-link config needed on web.
>
> **iOS** deep-link setup (`Info.plist` `CFBundleURLTypes`) is not required until iOS support is added.

---

## Token Handling

- Access tokens (JWTs) are **short-lived**. Supabase Auth continuously issues new tokens for each session while the user is active.
- The SDK attaches the current JWT to every request automatically — do not manually manage token refresh.
- To forward the token to an Edge Function, read it from the live session (never cache it across async gaps):

```dart
final token = supabase.auth.currentSession?.accessToken;
if (token == null) throw Exception('User not authenticated');
// Attach as: Authorization: Bearer $token
```

### JWT claims reference

| Claim | Type | Description |
|---|---|---|
| `sub` | string | User UUID |
| `role` | string | `authenticated` or `anon` |
| `email` | string | User email |
| `aal` | string | Auth assurance level (`aal1` / `aal2`) |
| `session_id` | string | Unique session identifier |
| `is_anonymous` | bool | Whether the user is anonymous |

---

## Secure Token Storage

Default `supabase_flutter` storage is `SharedPreferences`. Storage behaviour differs by platform:

| Platform | Default storage | Production recommendation |
|---|---|---|
| Android | `SharedPreferences` | `flutter_secure_storage` (Android Keystore) |
| Web | Browser `localStorage` | Default is acceptable; no native keychain available |

For Android production builds, override with a custom `LocalStorage` backed by `flutter_secure_storage`:

```dart
class SecureStorage extends LocalStorage {
  final storage = const FlutterSecureStorage();

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() async =>
      storage.read(key: supabaseAccessTokenKey);

  @override
  Future<bool> hasAccessToken() async =>
      storage.containsKey(key: supabaseAccessTokenKey);

  @override
  Future<void> persistSession(String persistSessionString) async =>
      storage.write(key: supabaseAccessTokenKey, value: persistSessionString);

  @override
  Future<void> removePersistedSession() async =>
      storage.delete(key: supabaseAccessTokenKey);
}

// Pass into Supabase.initialize:
await Supabase.initialize(
  url: ...,
  anonKey: ...,
  localStorage: const SecureStorage(),
);
```

---

## API Keys

Supabase is migrating away from `anon` / `service_role` legacy keys. **Legacy keys are deprecated at end of 2026.**

| Key | Format | Use in |
|---|---|---|
| Publishable key | `sb_publishable_xxx` | Flutter client — safe to bundle; RLS is the security boundary |
| Secret key | `sb_secret_xxx` | Edge Functions / server-side only — never expose to the client |

Find both keys in the Supabase Dashboard under **Settings → API Keys**.

---

## Row Level Security (RLS)

Every user-owned table **must** have RLS enabled. RLS policies act as automatic `WHERE` clauses on every query, enforcing data isolation at the database level.

### Enabling RLS

```sql
-- Tables created via the Supabase Dashboard have RLS enabled by default.
-- Tables created via raw SQL require this explicitly:
ALTER TABLE workout_sessions ENABLE ROW LEVEL SECURITY;
```

### Policy template for user-owned data

```sql
-- SELECT: users can only read their own rows
CREATE POLICY "select_own_rows" ON workout_sessions
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);

-- INSERT: users can only insert rows they own
CREATE POLICY "insert_own_rows" ON workout_sessions
  FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

-- UPDATE: users can only update and cannot reassign ownership
CREATE POLICY "update_own_rows" ON workout_sessions
  FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- DELETE: users can only delete their own rows
CREATE POLICY "delete_own_rows" ON workout_sessions
  FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);
```

### Helper functions

| Function | Returns | Use for |
|---|---|---|
| `auth.uid()` | UUID or null | Identity — user-owned row checks |
| `auth.jwt()` | JSON | Advanced — MFA level, team membership, app metadata |

When checking JWT metadata, use **`raw_app_meta_data`** for security decisions — users cannot modify it. Never use `raw_user_meta_data` for auth rules (users can update it freely).

```sql
-- ✅ Check AAL2 (MFA enforced)
auth.jwt() ->> 'aal' = 'aal2'

-- ✅ Check team membership in app_metadata
auth.jwt() -> 'app_metadata' -> 'teams' ? team_id::text
```

### RLS performance rules

1. **Wrap helper functions in a `SELECT`** — `(select auth.uid())` instead of `auth.uid()` alone. This caches the result once per statement instead of re-evaluating it per row.
2. **Always specify `TO authenticated`** on policies that target signed-in users. Omitting it causes Postgres to evaluate the policy for anonymous requests too.
3. **Index `user_id`** on every user-owned table.
4. **Mirror filters in app code** — don't rely purely on RLS to narrow large result sets. An explicit `.eq('user_id', userId)` lets Postgres build a better query plan.
5. **Views** — create them with `security_invoker = true` (Postgres 15+) so they respect RLS. Default views run as the `postgres` role and bypass RLS entirely.

---

## Data Layer & Sync Strategy

FlexFlow uses **sqflite** (`flexflow.db`) as the local source of truth on Android. Supabase is the remote backing store.

> ⚠️ **Web incompatibility:** `sqflite` has no Flutter Web support. Before launching the web target, the local storage layer must be replaced or abstracted. Options:
> - **Drift** (formerly Moor) with `drift_sqflite` on Android and `drift/web` (SQLite WASM) on web — same SQL, platform-specific backend.
> - **Sembast** — a pure-Dart document store that runs on all platforms.
> - **No local cache on web** — query Supabase directly for all reads; only cache in-memory for the session.
>
> This decision should be made before starting web implementation. The repository abstraction (`RepositoryProvider`) is already in place so the switch is contained to the data layer.

### Recommended approach: direct client writes + RLS

Write to Supabase directly from the Flutter app using the `supabase_flutter` client. RLS policies enforce per-user data isolation — no proxy Edge Function is needed for standard CRUD.

```
Android
  └─► sqflite (local, immediate — never blocks UI)
  └─► Supabase PostgREST (remote, background write via supabase_flutter)

Web (current)
  └─► Supabase PostgREST (direct reads/writes — no local cache until storage layer is resolved)
```

Use Edge Functions only for operations that require server-side privilege (service role) or server-side logic (aggregations, scheduled jobs, third-party webhooks).

### Sync pattern (Android)

1. **Write locally first** (sqflite) so the UI is never blocked on network.
2. **Mirror to Supabase** in the background via the repository layer. Use `updated_at` (Unix ms) for last-write-wins conflict resolution.
3. **On app start / reconnect**, fetch rows where `updated_at > last_sync_timestamp` from Supabase and upsert into sqflite.
4. Honour soft-deletes (`deleted_at` column) — never hard-delete remotely once a row has been synced.

### Supabase table requirements

Mirror the local `flexflow.db` schema (v4) and add these columns to every user-owned table:

```sql
user_id   UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
```

---

## Edge Functions

Reference implementations live in `supabase/ref/`. Copy into your Edge Function bundle as needed.

| File | Purpose |
|---|---|
| `ref/supabase.ts` | Singleton Supabase client (service role). Use `getSupabaseClient()` for admin ops; `createSupabaseClientWithAuth(token)` to act as the calling user and respect RLS. |
| `ref/auth.ts` | `getAuthenticatedUser(req)` — extracts and verifies the Bearer token server-side using `supabase.auth.getUser(token)`. Throws `AuthenticationError` on failure. Call this at the top of every protected handler. |
| `ref/cors.ts` | `getCorsHeaders(req)` and `handleCorsPreflightRequest(req)` — handle preflight and apply CORS headers. Always respond to `OPTIONS` first. |
| `ref/errors.ts` | Typed HTTP error classes (`BadRequestError`, `AuthenticationError`, `ForbiddenError`, `NotFoundError`) and `jsonResponse()` helper. |
| `ref/crypto.ts` | AES-256-GCM encrypt/decrypt using PBKDF2 key derivation — for encrypting sensitive values stored in the database. |

### Canonical Edge Function skeleton

```typescript
import { getAuthenticatedUser } from '../ref/auth.ts';
import { getCorsHeaders, handleCorsPreflightRequest } from '../ref/cors.ts';
import { jsonResponse, HttpError, AuthenticationError } from '../ref/errors.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return handleCorsPreflightRequest(req);
  }

  try {
    const user = await getAuthenticatedUser(req);
    // ... handler logic using user.userId ...
    return jsonResponse({ ok: true }, { status: 200, headers: getCorsHeaders(req) });
  } catch (err) {
    if (err instanceof HttpError) {
      return jsonResponse({ error: err.message }, { status: err.status, headers: getCorsHeaders(req) });
    }
    console.error('Unhandled:', err);
    return jsonResponse({ error: 'Internal server error' }, { status: 500, headers: getCorsHeaders(req) });
  }
});
```

---

## Environment Variables

| Variable | Where used | Notes |
|---|---|---|
| `SUPABASE_URL` | Edge Functions | Injected automatically by the Supabase runtime |
| `SUPABASE_SERVICE_ROLE_KEY` | Edge Functions | **Never** expose to the Flutter client |
| `sb_publishable_xxx` | Flutter client | Safe to bundle; RLS is the security boundary |
| `ALLOWED_ORIGINS` | Edge Functions (`cors.ts`) | Comma-separated origins; use `*` for dev only |
| `ENCRYPTION_KEY` | Edge Functions (`crypto.ts`) | 32-byte hex string |
| `ENCRYPTION_SALT` | Edge Functions (`crypto.ts`) | 32-byte hex string |

Store secrets in Supabase's **Vault** or as Edge Function secrets — never commit them to source control.

---

## References

- Supabase Auth docs: https://supabase.com/docs/guides/auth
- Supabase RLS docs: https://supabase.com/docs/guides/database/postgres/row-level-security
- `supabase_flutter` package: https://pub.dev/packages/supabase_flutter
- Login with Google (Flutter): https://supabase.com/docs/guides/auth/social-login/auth-google?queryGroups=platform&platform=flutter
- NotebookLM notebook (project research): UUID `3696ed17-acaf-4931-9f6a-a5d69e27cd01`
- Reference implementations: `supabase/ref/`
