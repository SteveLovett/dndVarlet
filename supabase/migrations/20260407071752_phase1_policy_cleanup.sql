-- Remove overlapping legacy policies so one clear Phase 1 policy set remains.

drop policy if exists "User sees games they belong to and public listings" on public.games;
drop policy if exists "Only signed-in users create games; creator is recorded correctly" on public.games;
drop policy if exists "Only GMs change game fields" on public.games;
drop policy if exists "Only GM can delete games" on public.games;

drop policy if exists "Players and GM can view game_members" on public.game_members;
drop policy if exists "GM can insert game_members" on public.game_members;
drop policy if exists "GM can update game_members" on public.game_members;
drop policy if exists "GM can delete game_members" on public.game_members;
