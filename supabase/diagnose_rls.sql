-- Shows RLS status + every policy on the app tables.
-- Run in Supabase → SQL Editor, paste the two result grids back.

-- (a) is RLS actually enabled on each table?
select relname            as table_name,
       relrowsecurity     as rls_enabled,
       relforcerowsecurity as rls_forced
from pg_class
where relnamespace = 'public'::regnamespace
  and relname in ('users','posts','likes','comments','streams',
                  'messages','friendships','calls')
order by relname;

-- (b) every policy that exists, who it applies to, and its condition.
--     Look for any row where roles contains {public} or {anon} with qual = true
--     — that is the leak.
select tablename, policyname, cmd, roles, qual as using_condition
from pg_policies
where schemaname = 'public'
  and tablename in ('users','posts','likes','comments','streams',
                    'messages','friendships','calls')
order by tablename, cmd;
