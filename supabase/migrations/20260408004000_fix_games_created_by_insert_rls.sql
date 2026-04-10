-- Make game creation robust across environments:
-- 1) Ensure created_by defaults to auth.uid()
-- 2) Use an insert policy that only requires authenticated user
--    (ownership is still enforced by game_members_insert_creator_gm on Step C).

alter table public.games
  alter column created_by set default auth.uid();

drop policy if exists games_insert_owner on public.games;
drop policy if exists games_insert_authenticated on public.games;

create policy games_insert_authenticated
  on public.games
  for insert
  to authenticated
  with check (auth.uid() is not null);
