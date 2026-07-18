-- ============================================================================
-- Row Level Security policies for the LIVE app
-- Run this in Supabase Dashboard → SQL Editor.
--
-- Why: as of 2026-07-18 the tables users, posts, likes, comments and streams
-- were readable by ANYONE on the internet with just the anon key (emails,
-- phone numbers and DOBs were exposed). These policies restrict every table
-- to authenticated users, and write access to the owning user.
--
-- Safe to re-run: policies are dropped before being recreated.
-- ============================================================================

-- ── USERS ───────────────────────────────────────────────────────────────────
alter table public.users enable row level security;

drop policy if exists "users_select_authenticated" on public.users;
drop policy if exists "users_insert_own" on public.users;
drop policy if exists "users_update_own" on public.users;

-- Any signed-in user can read profiles (needed for search, chat, friend cards).
-- NOTE: email/phone_number are still visible to signed-in users because the
-- app selects * — consider moving them to a private table later.
create policy "users_select_authenticated"
  on public.users for select
  to authenticated
  using (true);

create policy "users_insert_own"
  on public.users for insert
  to authenticated
  with check (auth.uid() = id);

create policy "users_update_own"
  on public.users for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- ── POSTS ───────────────────────────────────────────────────────────────────
alter table public.posts enable row level security;

drop policy if exists "posts_select_authenticated" on public.posts;
drop policy if exists "posts_insert_own" on public.posts;
drop policy if exists "posts_update_own" on public.posts;
drop policy if exists "posts_delete_own" on public.posts;

create policy "posts_select_authenticated"
  on public.posts for select
  to authenticated
  using (true);

create policy "posts_insert_own"
  on public.posts for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "posts_update_own"
  on public.posts for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "posts_delete_own"
  on public.posts for delete
  to authenticated
  using (auth.uid() = user_id);

-- ── LIKES ───────────────────────────────────────────────────────────────────
alter table public.likes enable row level security;

drop policy if exists "likes_select_authenticated" on public.likes;
drop policy if exists "likes_insert_own" on public.likes;
drop policy if exists "likes_delete_own" on public.likes;

create policy "likes_select_authenticated"
  on public.likes for select
  to authenticated
  using (true);

create policy "likes_insert_own"
  on public.likes for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "likes_delete_own"
  on public.likes for delete
  to authenticated
  using (auth.uid() = user_id);

-- ── COMMENTS ────────────────────────────────────────────────────────────────
alter table public.comments enable row level security;

drop policy if exists "comments_select_authenticated" on public.comments;
drop policy if exists "comments_insert_own" on public.comments;
drop policy if exists "comments_update_own" on public.comments;
drop policy if exists "comments_delete_own" on public.comments;

create policy "comments_select_authenticated"
  on public.comments for select
  to authenticated
  using (true);

create policy "comments_insert_own"
  on public.comments for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "comments_update_own"
  on public.comments for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "comments_delete_own"
  on public.comments for delete
  to authenticated
  using (auth.uid() = user_id);

-- ── STREAMS ─────────────────────────────────────────────────────────────────
alter table public.streams enable row level security;

drop policy if exists "streams_select_authenticated" on public.streams;
drop policy if exists "streams_insert_own" on public.streams;
drop policy if exists "streams_update_own" on public.streams;
drop policy if exists "streams_delete_own" on public.streams;

create policy "streams_select_authenticated"
  on public.streams for select
  to authenticated
  using (true);

create policy "streams_insert_own"
  on public.streams for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "streams_update_own"
  on public.streams for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "streams_delete_own"
  on public.streams for delete
  to authenticated
  using (auth.uid() = user_id);

-- ── MESSAGES (participants only) ────────────────────────────────────────────
alter table public.messages enable row level security;

drop policy if exists "messages_select_participants" on public.messages;
drop policy if exists "messages_insert_as_sender" on public.messages;
drop policy if exists "messages_update_participants" on public.messages;
drop policy if exists "messages_delete_as_sender" on public.messages;

create policy "messages_select_participants"
  on public.messages for select
  to authenticated
  using (auth.uid() = sender_id or auth.uid() = receiver_id);

create policy "messages_insert_as_sender"
  on public.messages for insert
  to authenticated
  with check (auth.uid() = sender_id);

-- Sender edits their message; receiver marks it read.
create policy "messages_update_participants"
  on public.messages for update
  to authenticated
  using (auth.uid() = sender_id or auth.uid() = receiver_id)
  with check (auth.uid() = sender_id or auth.uid() = receiver_id);

create policy "messages_delete_as_sender"
  on public.messages for delete
  to authenticated
  using (auth.uid() = sender_id);

-- ── FRIENDSHIPS (involved parties only) ─────────────────────────────────────
alter table public.friendships enable row level security;

drop policy if exists "friendships_select_involved" on public.friendships;
drop policy if exists "friendships_insert_as_requester" on public.friendships;
drop policy if exists "friendships_update_involved" on public.friendships;
drop policy if exists "friendships_delete_involved" on public.friendships;

create policy "friendships_select_involved"
  on public.friendships for select
  to authenticated
  using (auth.uid() = requester_id or auth.uid() = addressee_id);

create policy "friendships_insert_as_requester"
  on public.friendships for insert
  to authenticated
  with check (auth.uid() = requester_id);

-- Addressee accepts/declines; either side may need to update status.
create policy "friendships_update_involved"
  on public.friendships for update
  to authenticated
  using (auth.uid() = requester_id or auth.uid() = addressee_id)
  with check (auth.uid() = requester_id or auth.uid() = addressee_id);

create policy "friendships_delete_involved"
  on public.friendships for delete
  to authenticated
  using (auth.uid() = requester_id or auth.uid() = addressee_id);

-- ── CALLS (participants only) ───────────────────────────────────────────────
alter table public.calls enable row level security;

drop policy if exists "calls_select_participants" on public.calls;
drop policy if exists "calls_insert_as_caller" on public.calls;
drop policy if exists "calls_update_participants" on public.calls;

create policy "calls_select_participants"
  on public.calls for select
  to authenticated
  using (auth.uid() = caller_id or auth.uid() = receiver_id);

create policy "calls_insert_as_caller"
  on public.calls for insert
  to authenticated
  with check (auth.uid() = caller_id);

-- Receiver accepts/declines; caller ends/cancels.
create policy "calls_update_participants"
  on public.calls for update
  to authenticated
  using (auth.uid() = caller_id or auth.uid() = receiver_id)
  with check (auth.uid() = caller_id or auth.uid() = receiver_id);

-- ============================================================================
-- AFTER RUNNING THIS, ALSO CHECK (in the Dashboard):
--
-- 1. Storage → post-images / stream-assets / chat buckets: they are public
--    buckets. Anyone with a URL can fetch media. Acceptable for post images
--    and thumbnails; NOT acceptable for chat attachments/voice notes — move
--    chat files to a private bucket with storage policies + signed URLs.
--
-- 2. Edge Functions → agora-stream-token: make sure "Enforce JWT verification"
--    is ON, otherwise anyone can mint Agora tokens for your app ID.
--
-- 3. Realtime: the incoming-call listener (bottom_nav.dart) uses
--    postgres_changes on `calls` — RLS applies to realtime as well, so the
--    receiver still gets events via calls_select_participants. Verify calls
--    still ring after enabling RLS.
-- ============================================================================
