-- Voluntarily leave a game (caller removes only themselves).
-- Sole Game Master cannot leave; they must transfer GM or promote another GM first.
create or replace function public.leave_game(p_game_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_is_member boolean;
  v_is_gm boolean;
  v_gm_count int;
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  select exists (
    select 1
    from public.game_members gm
    where gm.game_id = p_game_id
      and gm.user_id = v_uid
  )
  into v_is_member;

  if not v_is_member then
    raise exception 'You are not a member of this game';
  end if;

  select exists (
    select 1
    from public.game_members gm
    where gm.game_id = p_game_id
      and gm.user_id = v_uid
      and gm.game_role = 'Game Master'::public.game_role
  )
  into v_is_gm;

  if v_is_gm then
    v_gm_count := public.gm_count(p_game_id);
    if v_gm_count <= 1 then
      raise exception 'Cannot leave as the last Game Master; transfer the role or promote another Game Master first';
    end if;
  end if;

  delete from public.game_members
  where game_id = p_game_id
    and user_id = v_uid;
end;
$$;

revoke all on function public.leave_game(uuid) from public;
grant execute on function public.leave_game(uuid) to authenticated;
