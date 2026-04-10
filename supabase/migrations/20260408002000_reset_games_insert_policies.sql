-- Force-reset INSERT policies on public.games to a single known-good policy.
-- This avoids lingering restrictive/legacy policy combinations that can block inserts.

alter table public.games enable row level security;

do $$
declare
  p record;
begin
  for p in
    select policyname
    from pg_policies
    where schemaname = 'public'
      and tablename = 'games'
      and cmd = 'INSERT'
  loop
    execute format('drop policy if exists %I on public.games', p.policyname);
  end loop;
end
$$;

create policy games_insert_authenticated
  on public.games
  for insert
  to authenticated
  with check (auth.uid() is not null);
