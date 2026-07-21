# Riverpod Global State + Caching — Design

Date: 2026-07-21
Status: Approved (design)

## Goal

Every API/DB fetch loads **once**, is stored in a centralized Riverpod cache, and
all screens reuse it. No duplicate network calls, no spinner on revisit. Data
refreshes only on explicit request (pull-to-refresh), mutation, or realtime change.

Priority domains (user-emphasized): **home feed, profile, streams, messages.**

## Blocker (must land first)

`flutter pub get` fails: `flutter_sound ^9.30.0` needs SDK `^3.7.2`; environment is
Flutter 3.27.4 / Dart 3.6.2. `flutter_sound 9.28.0` needs `^3.3.0` — compatible.

- Pin `flutter_sound: 9.28.0` (exact — `^9.28.0` re-selects 9.30.0).
- Add `flutter_riverpod: ^2.6.1` (supports Dart 3.6).
- Remove `provider` once `ThemeProvider` is migrated (or keep short-term; see below).

## Decisions

- **Rollout:** big-bang, all domains.
- **Style:** manual `flutter_riverpod` providers (hand-written `Notifier` /
  `AsyncNotifier`). No codegen / build_runner.
- **Data shape:** keep `Map<String, dynamic>` rows (no model-class layer) — matches
  the existing codebase and keeps the diff bounded. Providers are typed
  `AsyncNotifier<List<Map<String, dynamic>>>` etc.
- **Theme:** migrate `ThemeProvider` (ChangeNotifier) → Riverpod `NotifierProvider`;
  drop the `provider` package.

## Architecture

App root wrapped in `ProviderScope`. One provider per data domain, each calling
`ref.keepAlive()` so the fetch runs once and the cache survives navigation.

| Provider | Type | Holds | Realtime table | Refresh / invalidation |
|---|---|---|---|---|
| `authStateProvider` | `StreamProvider` | supabase `onAuthStateChange` | — | drives routing + invalidations |
| `currentUserProvider` | `AsyncNotifier<Map?>` | self `users` row | — | profile edit → `invalidate` |
| `friendsProvider` | `AsyncNotifier<List<Map>>` | accepted friends | `friendships` | accept, pull-refresh |
| `friendRequestsProvider` | `AsyncNotifier<List<Map>>` | pending requests | `friendships` | accept/decline |
| `feedProvider` | `AsyncNotifier<List<Map>>` | friends' posts + like/comment counts | `posts`, `likes` | new post, like/unlike (mutate in place), pull-refresh |
| `commentsProvider(postId)` | `family AsyncNotifier<List<Map>>` | comments for a post | `comments` | add comment |
| `conversationsProvider` | `AsyncNotifier<List<Map>>` | chat list (last msg per friend) | `messages` | new message (mutate) |
| `messagesProvider(peerId)` | `family AsyncNotifier<List<Map>>` | one thread | `messages` | send (append), realtime insert |
| `streamsProvider` | `AsyncNotifier<List<Map>>` | live/scheduled streams | `streams` | pull-refresh, status change |
| `notificationsProvider` | `AsyncNotifier<List<Map>>` | notification events | — | `invalidate` |
| `searchProvider(query)` | `family AsyncNotifier<List<Map>>` | user search results | — | query-driven (auto-dispose, not long-cached) |

### Caching behavior

- Screens `watch(provider)` and render `AsyncValue`. First access triggers the one
  fetch; later navigations read cache instantly.
- Spinner only on genuine first load: `value.isLoading && !value.hasValue`.
- Refresh keeps prior data visible (`isRefreshing`) — no full-screen blank flash.
- Realtime handlers live **inside** the provider (subscribe in build, unsubscribe via
  `ref.onDispose`), mutating the cached list so all watchers update together.

### Replaces / moves

- ChangeNotifier controllers removed → providers: `friends_controller`,
  `friend_requests_controller`, `create_post_controller` (becomes a mutation that
  invalidates `feedProvider`), `search_controller`.
- `bottom_nav` global `calls` + message realtime subscriptions move into providers.
- Screens stop calling `Supabase.instance.client` directly for reads; mutations call
  a thin service then invalidate/mutate the relevant provider.

### Out of scope (unchanged)

- Agora RTC engine + `agora-stream-token` edge calls (ephemeral, not cache targets).
- Live voice/video call screens and the incoming-call sheet flow — left as-is; only
  its realtime subscription may move to a provider for cleanliness (optional).

## Phasing (for the plan)

1. **Infra:** pin flutter_sound, add riverpod, `ProviderScope`, migrate `ThemeProvider`. Build green.
2. **Auth + currentUser:** `authStateProvider`, `currentUserProvider`; wire `AuthGate`, profile screens.
3. **Feed:** `feedProvider` + `commentsProvider`; home + comments + create-post.
4. **Friends:** `friendsProvider` + `friendRequestsProvider`; notifications, search.
5. **Messages:** `conversationsProvider` + `messagesProvider`; chat list + thread.
6. **Streams:** `streamsProvider`; stream list + watch.
7. **Cleanup:** remove dead controllers, `provider` dep; update CLAUDE.md.

## Verification (per phase)

`flutter analyze` clean, `flutter build apk --debug` succeeds. Manual: revisit each
migrated screen — data does not refetch (no spinner second time); pull-to-refresh and
realtime still update.

## CLAUDE.md impact

Reverses two current notes: "no repository/model layer" (adding a provider/cache
layer) and "GetX unused — don't introduce" (introducing Riverpod, not GetX). Update
the doc in the cleanup phase.
