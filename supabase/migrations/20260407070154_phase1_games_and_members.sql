-- Helpful index for "my games"
create index if not exists game_members_user_id_idx on public.game_members(user_id);

-- 3) RLS
alter table public.games enable row level security;
alter table public.game_members enable row level security;

-- 4) Policies: games
-- Read games where I'm a member
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

-- Create game as myself
create policy games_insert_owner
  on public.games
  for insert
  to authenticated
  with check (created_by = auth.uid());

-- Update game only if I'm a GM in that game
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
        and gm.game_role = 'Game Master'
    )
  )
  with check (
    exists (
      select 1
      from public.game_members gm
      where gm.game_id = games.id
        and gm.user_id = auth.uid()
        and gm.game_role = 'Game Master'
    )
  );

-- 5) Policies: game_members
-- Read memberships for games I'm in
create policy game_members_select_member
  on public.game_members
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.game_members me
      where me.game_id = game_members.game_id
        and me.user_id = auth.uid()
    )
  );

-- Allow creator to add self as GM for own game (Phase 1 create flow)
create policy game_members_insert_creator_gm
  on public.game_members
  for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and game_role = 'Game Master'
    and exists (
      select 1
      from public.games g
      where g.id = game_id
        and g.created_by = auth.uid()
    )
  );