-- Fully reset games policies to eliminate legacy conflicts (including cmd = 'ALL').
-- Recreate a clean Phase 1 policy set.

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
  loop
    execute format('drop policy if exists %I on public.games', p.policyname);
  end loop;
end
$$;

-- Read games where the caller is a member.
create policy games_select_member
  on public.games
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.game_members gm
      where gm.game_id = games.id
        and gm.user_id = auth.uid()
    )
  );

-- Allow authenticated users to create games.
-- created_by defaults to auth.uid() in schema; if client provides it, it must match auth.uid().
create policy games_insert_owner
  on public.games
  for insert
  to authenticated
  with check (created_by = auth.uid());

-- Update game fields only when caller is a GM in that game.
create policy games_update_gm
  on public.games
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.game_members gm
      where gm.game_id = games.id
        and gm.user_id = auth.uid()
        and gm.game_role = 'Game Master'::public.game_role
    )
  )
  with check (
    exists (
      select 1
      from public.game_members gm
      where gm.game_id = games.id
        and gm.user_id = auth.uid()
        and gm.game_role = 'Game Master'::public.game_role
    )
  );
