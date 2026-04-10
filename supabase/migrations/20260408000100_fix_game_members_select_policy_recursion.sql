-- Fix RLS recursion on public.game_members.
-- The previous policy queried public.game_members from inside its own USING clause,
-- which can trigger "infinite recursion detected in policy for relation game_members".

drop policy if exists game_members_select_member on public.game_members;

-- Phase 1 dashboard needs each user to read their own memberships.
create policy game_members_select_own
  on public.game_members
  for select
  to authenticated
  using (user_id = auth.uid());
