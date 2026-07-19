-- ============================================================================
-- HARDENED RLS — run this if the first script left tables still readable by anon.
--
-- The first script only dropped policies by name. Any PRE-EXISTING permissive
-- policy (e.g. an "Enable read access for all users" policy Supabase adds by
-- default) survived and kept anon reads open. This version:
--   1. dynamically drops EVERY policy on each table (whatever it's named),
--   2. force-enables RLS,
--   3. revokes blanket anon/authenticated table grants,
--   4. recreates the correct owner-scoped policies.
--
-- Run the whole thing in Supabase → SQL Editor. Safe to re-run.
-- ============================================================================

-- 1 + 2: drop all existing policies + enable & force RLS on every app table.
do $$
declare
  t text;
  p record;
  tables text[] := array[
    'users','posts','likes','comments','streams',
    'messages','friendships','calls'
  ];
begin
  foreach t in array tables loop
    -- skip tables that don't exist so the script never half-applies
    if to_regclass('public.' || t) is null then
      raise notice 'skip: public.% does not exist', t;
      continue;
    end if;

    for p in
      select policyname from pg_policies
      where schemaname = 'public' and tablename = t
    loop
      execute format('drop policy %I on public.%I', p.policyname, t);
    end loop;

    execute format('alter table public.%I enable row level security', t);
    execute format('alter table public.%I force row level security', t);

    -- 3: strip blanket grants; RLS policies below are the only way in.
    execute format('revoke all on public.%I from anon', t);
    execute format('revoke all on public.%I from authenticated', t);
    execute format(
      'grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
end $$;

-- 4: recreate correct policies. All reads require a logged-in user (anon gets
--    nothing). Writes are restricted to the owning user / conversation party.

-- ── USERS ────────────────────────────────────────────────────────────────
create policy "users_select_authenticated" on public.users
  for select to authenticated using (true);
create policy "users_insert_own" on public.users
  for insert to authenticated with check (auth.uid() = id);
create policy "users_update_own" on public.users
  for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

-- ── POSTS ────────────────────────────────────────────────────────────────
create policy "posts_select_authenticated" on public.posts
  for select to authenticated using (true);
create policy "posts_insert_own" on public.posts
  for insert to authenticated with check (auth.uid() = user_id);
create policy "posts_update_own" on public.posts
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "posts_delete_own" on public.posts
  for delete to authenticated using (auth.uid() = user_id);

-- ── LIKES ────────────────────────────────────────────────────────────────
create policy "likes_select_authenticated" on public.likes
  for select to authenticated using (true);
create policy "likes_insert_own" on public.likes
  for insert to authenticated with check (auth.uid() = user_id);
create policy "likes_delete_own" on public.likes
  for delete to authenticated using (auth.uid() = user_id);

-- ── COMMENTS ─────────────────────────────────────────────────────────────
create policy "comments_select_authenticated" on public.comments
  for select to authenticated using (true);
create policy "comments_insert_own" on public.comments
  for insert to authenticated with check (auth.uid() = user_id);
create policy "comments_update_own" on public.comments
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "comments_delete_own" on public.comments
  for delete to authenticated using (auth.uid() = user_id);

-- ── STREAMS ──────────────────────────────────────────────────────────────
create policy "streams_select_authenticated" on public.streams
  for select to authenticated using (true);
create policy "streams_insert_own" on public.streams
  for insert to authenticated with check (auth.uid() = user_id);
create policy "streams_update_own" on public.streams
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "streams_delete_own" on public.streams
  for delete to authenticated using (auth.uid() = user_id);

-- ── MESSAGES (participants only) ─────────────────────────────────────────
create policy "messages_select_participants" on public.messages
  for select to authenticated using (auth.uid() = sender_id or auth.uid() = receiver_id);
create policy "messages_insert_as_sender" on public.messages
  for insert to authenticated with check (auth.uid() = sender_id);
create policy "messages_update_participants" on public.messages
  for update to authenticated
  using (auth.uid() = sender_id or auth.uid() = receiver_id)
  with check (auth.uid() = sender_id or auth.uid() = receiver_id);
create policy "messages_delete_as_sender" on public.messages
  for delete to authenticated using (auth.uid() = sender_id);

-- ── FRIENDSHIPS (involved parties only) ──────────────────────────────────
create policy "friendships_select_involved" on public.friendships
  for select to authenticated using (auth.uid() = requester_id or auth.uid() = addressee_id);
create policy "friendships_insert_as_requester" on public.friendships
  for insert to authenticated with check (auth.uid() = requester_id);
create policy "friendships_update_involved" on public.friendships
  for update to authenticated
  using (auth.uid() = requester_id or auth.uid() = addressee_id)
  with check (auth.uid() = requester_id or auth.uid() = addressee_id);
create policy "friendships_delete_involved" on public.friendships
  for delete to authenticated using (auth.uid() = requester_id or auth.uid() = addressee_id);

-- ── CALLS (participants only) ────────────────────────────────────────────
create policy "calls_select_participants" on public.calls
  for select to authenticated using (auth.uid() = caller_id or auth.uid() = receiver_id);
create policy "calls_insert_as_caller" on public.calls
  for insert to authenticated with check (auth.uid() = caller_id);
create policy "calls_update_participants" on public.calls
  for update to authenticated
  using (auth.uid() = caller_id or auth.uid() = receiver_id)
  with check (auth.uid() = caller_id or auth.uid() = receiver_id);
