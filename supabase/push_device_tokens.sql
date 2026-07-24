-- FCM device tokens. Run in Supabase → SQL Editor.
create table if not exists device_tokens (
  user_id    uuid not null references users(id) on delete cascade,
  token      text not null,
  updated_at timestamptz default now(),
  primary key (user_id, token)
);

alter table device_tokens enable row level security;
alter table device_tokens force row level security;
revoke all on device_tokens from anon;
grant select, insert, update, delete on device_tokens to authenticated;

-- A user manages only their own tokens. The send-push function reads tokens
-- with the service-role key, which bypasses RLS.
drop policy if exists "device_tokens_own" on device_tokens;
create policy "device_tokens_own" on device_tokens
  for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
