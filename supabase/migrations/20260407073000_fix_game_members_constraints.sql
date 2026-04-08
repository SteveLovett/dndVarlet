-- Fix game_members constraints for many-members-per-game and co-GM support.
-- The generated remote schema used single-column uniqueness, which blocks normal membership.

alter table public.game_members
  drop constraint if exists game_members_pkey;

alter table public.game_members
  drop constraint if exists game_members_user_id_key;

drop index if exists public.game_members_pkey;
drop index if exists public.game_members_user_id_key;

-- One membership per user per game, while allowing:
-- - many users in one game
-- - one user in many games
alter table public.game_members
  add constraint game_members_pkey primary key (game_id, user_id);

create index if not exists game_members_user_id_idx on public.game_members(user_id);
