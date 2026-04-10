-- Ensure game creation policy exists and is non-ambiguous.
-- If this policy is missing in an environment, INSERTs into public.games fail with:
-- "new row violates row-level security policy for table games".

alter table public.games enable row level security;

drop policy if exists games_insert_owner on public.games;
drop policy if exists "Only signed-in users create games; creator is recorded correctly" on public.games;

create policy games_insert_owner
  on public.games
  for insert
  to authenticated
  with check (created_by = auth.uid());
