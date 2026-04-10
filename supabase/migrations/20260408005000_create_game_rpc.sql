-- Create a game and add caller as Game Master in one transaction.
-- SECURITY DEFINER avoids fragile client-side RLS insert combinations while
-- still enforcing auth explicitly inside the function.

create or replace function public.create_game(
  p_name text,
  p_description text,
  p_is_public boolean
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_game_id uuid;
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  insert into public.games (name, description, is_public, created_by)
  values (p_name, p_description, p_is_public, v_uid)
  returning id into v_game_id;

  insert into public.game_members (game_id, user_id, game_role)
  values (v_game_id, v_uid, 'Game Master'::public.game_role);

  return v_game_id;
end;
$$;

revoke all on function public.create_game(text, text, boolean) from public;
grant execute on function public.create_game(text, text, boolean) to authenticated;
