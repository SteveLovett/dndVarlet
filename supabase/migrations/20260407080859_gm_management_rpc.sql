-- Returns how many Game Masters currently belong to a game.
create or replace function public.gm_count(p_game_id uuid)
returns integer
language sql
stable
set search_path = public
as $$
  select count(*)::int
  from public.game_members
  where game_id = p_game_id
    and game_role = 'Game Master'::public.game_role;
$$;

-- Promote a member to Game Master.
create or replace function public.promote_to_gm(
  p_game_id uuid,
  p_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caller uuid := auth.uid();
  v_is_caller_gm boolean;
  v_target_exists boolean;
begin
  if v_caller is null then
    raise exception 'Not authenticated';
  end if;

  -- Guard 1: caller must already be a GM in this game
  select exists (
    select 1
    from public.game_members gm
    where gm.game_id = p_game_id
      and gm.user_id = v_caller
      and gm.game_role = 'Game Master'::public.game_role
  )
  into v_is_caller_gm;

  if not v_is_caller_gm then
    raise exception 'Only a Game Master can promote another member';
  end if;

  -- Guard 2: target user must already be a member of this game
  select exists (
    select 1
    from public.game_members gm
    where gm.game_id = p_game_id
      and gm.user_id = p_user_id
  )
  into v_target_exists;

  if not v_target_exists then
    raise exception 'Target user is not a member of this game';
  end if;

  -- Action: set role to Game Master
  update public.game_members
  set game_role = 'Game Master'::public.game_role
  where game_id = p_game_id
    and user_id = p_user_id;
end;
$$;

-- Restrict who can call it
revoke all on function public.promote_to_gm(uuid, uuid) from public;
grant execute on function public.promote_to_gm(uuid, uuid) to authenticated;

-- Demote a Game Master to Player. Fails if that would leave zero GMs.
create or replace function public.demote_from_gm(
  p_game_id uuid,
  p_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caller uuid := auth.uid();
  v_is_caller_gm boolean;
  v_target_is_gm boolean;
  v_gm_count int;
begin
  if v_caller is null then
    raise exception 'Not authenticated';
  end if;

  -- Caller must be a GM in this game
  select exists (
    select 1
    from public.game_members gm
    where gm.game_id = p_game_id
      and gm.user_id = v_caller
      and gm.game_role = 'Game Master'::public.game_role
  )
  into v_is_caller_gm;

  if not v_is_caller_gm then
    raise exception 'Only a Game Master can demote another member';
  end if;

  -- Target must exist and currently be a GM
  select exists (
    select 1
    from public.game_members gm
    where gm.game_id = p_game_id
      and gm.user_id = p_user_id
      and gm.game_role = 'Game Master'::public.game_role
  )
  into v_target_is_gm;

  if not v_target_is_gm then
    raise exception 'Target user is not a Game Master in this game';
  end if;

  -- Guard: must keep at least one GM after demotion
  v_gm_count := public.gm_count(p_game_id);
  if v_gm_count <= 1 then
    raise exception 'Cannot demote the last Game Master';
  end if;

  update public.game_members
  set game_role = 'Player'::public.game_role
  where game_id = p_game_id
    and user_id = p_user_id;
end;
$$;

revoke all on function public.demote_from_gm(uuid, uuid) from public;
grant execute on function public.demote_from_gm(uuid, uuid) to authenticated;

-- Atomically transfer Game Master from one member to another (same game).
-- Typical use: sole GM hands off to another player; still exactly one GM afterward.
create or replace function public.transfer_gm(
  p_game_id uuid,
  p_from_user_id uuid,
  p_to_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caller uuid := auth.uid();
  v_is_caller_gm boolean;
  v_from_is_gm boolean;
  v_to_exists boolean;
begin
  if v_caller is null then
    raise exception 'Not authenticated';
  end if;

  if p_from_user_id = p_to_user_id then
    raise exception 'from_user_id and to_user_id must differ';
  end if;

  -- Caller must be a GM in this game (same rule as promote/demote)
  select exists (
    select 1
    from public.game_members gm
    where gm.game_id = p_game_id
      and gm.user_id = v_caller
      and gm.game_role = 'Game Master'::public.game_role
  )
  into v_is_caller_gm;

  if not v_is_caller_gm then
    raise exception 'Only a Game Master can transfer the Game Master role';
  end if;

  select exists (
    select 1
    from public.game_members gm
    where gm.game_id = p_game_id
      and gm.user_id = p_from_user_id
      and gm.game_role = 'Game Master'::public.game_role
  )
  into v_from_is_gm;

  if not v_from_is_gm then
    raise exception 'from_user_id is not a Game Master in this game';
  end if;

  select exists (
    select 1
    from public.game_members gm
    where gm.game_id = p_game_id
      and gm.user_id = p_to_user_id
  )
  into v_to_exists;

  if not v_to_exists then
    raise exception 'to_user_id is not a member of this game';
  end if;

  -- Promote first, then demote — same transaction; still at least one GM throughout commit.
  update public.game_members
  set game_role = 'Game Master'::public.game_role
  where game_id = p_game_id
    and user_id = p_to_user_id;

  update public.game_members
  set game_role = 'Player'::public.game_role
  where game_id = p_game_id
    and user_id = p_from_user_id;
end;
$$;

revoke all on function public.transfer_gm(uuid, uuid, uuid) from public;
grant execute on function public.transfer_gm(uuid, uuid, uuid) to authenticated;