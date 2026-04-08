-- Step G: remove a member from a game (GM-only). Cannot remove the last Game Master.
create or replace function public.remove_member(
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
  v_target_is_gm boolean;
  v_gm_count int;
begin
  if v_caller is null then
    raise exception 'Not authenticated';
  end if;

  select exists (
    select 1
    from public.game_members gm
    where gm.game_id = p_game_id
      and gm.user_id = v_caller
      and gm.game_role = 'Game Master'::public.game_role
  )
  into v_is_caller_gm;

  if not v_is_caller_gm then
    raise exception 'Only a Game Master can remove a member';
  end if;

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

  select exists (
    select 1
    from public.game_members gm
    where gm.game_id = p_game_id
      and gm.user_id = p_user_id
      and gm.game_role = 'Game Master'::public.game_role
  )
  into v_target_is_gm;

  if v_target_is_gm then
    v_gm_count := public.gm_count(p_game_id);
    if v_gm_count <= 1 then
      raise exception 'Cannot remove the last Game Master';
    end if;
  end if;

  delete from public.game_members
  where game_id = p_game_id
    and user_id = p_user_id;
end;
$$;

revoke all on function public.remove_member(uuid, uuid) from public;
grant execute on function public.remove_member(uuid, uuid) to authenticated;
