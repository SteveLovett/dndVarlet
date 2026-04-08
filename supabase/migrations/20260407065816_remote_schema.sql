drop extension if exists "pg_net";

create type "public"."game_role" as enum ('Game Master', 'Player');


  create table "public"."game_members" (
    "game_id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null default auth.uid(),
    "joined_at" timestamp with time zone not null default (now() AT TIME ZONE 'utc'::text),
    "game_role" public.game_role not null default 'Player'::public.game_role
      );


alter table "public"."game_members" enable row level security;


  create table "public"."games" (
    "id" uuid not null default gen_random_uuid(),
    "name" text not null default ''::text,
    "description" text default ''::text,
    "is_public" boolean not null,
    "created_by" uuid not null default auth.uid(),
    "created_at" timestamp with time zone not null default (now() AT TIME ZONE 'utc'::text)
      );


alter table "public"."games" enable row level security;

alter table "public"."profiles" alter column "created_at" set default (now() AT TIME ZONE 'utc'::text);

alter table "public"."profiles" alter column "display_name" set not null;

CREATE UNIQUE INDEX "Games_pkey" ON public.games USING btree (id);

CREATE UNIQUE INDEX game_members_pkey ON public.game_members USING btree (game_id);

CREATE UNIQUE INDEX game_members_user_id_key ON public.game_members USING btree (user_id);

alter table "public"."game_members" add constraint "game_members_pkey" PRIMARY KEY using index "game_members_pkey";

alter table "public"."games" add constraint "Games_pkey" PRIMARY KEY using index "Games_pkey";

alter table "public"."game_members" add constraint "game_members_game_id_fkey" FOREIGN KEY (game_id) REFERENCES public.games(id) not valid;

alter table "public"."game_members" validate constraint "game_members_game_id_fkey";

alter table "public"."game_members" add constraint "game_members_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) not valid;

alter table "public"."game_members" validate constraint "game_members_user_id_fkey";

alter table "public"."game_members" add constraint "game_members_user_id_key" UNIQUE using index "game_members_user_id_key";

alter table "public"."games" add constraint "games_created_by_fkey" FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL not valid;

alter table "public"."games" validate constraint "games_created_by_fkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.rls_auto_enable()
 RETURNS event_trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$function$
;

grant delete on table "public"."game_members" to "anon";

grant insert on table "public"."game_members" to "anon";

grant references on table "public"."game_members" to "anon";

grant select on table "public"."game_members" to "anon";

grant trigger on table "public"."game_members" to "anon";

grant truncate on table "public"."game_members" to "anon";

grant update on table "public"."game_members" to "anon";

grant delete on table "public"."game_members" to "authenticated";

grant insert on table "public"."game_members" to "authenticated";

grant references on table "public"."game_members" to "authenticated";

grant select on table "public"."game_members" to "authenticated";

grant trigger on table "public"."game_members" to "authenticated";

grant truncate on table "public"."game_members" to "authenticated";

grant update on table "public"."game_members" to "authenticated";

grant delete on table "public"."game_members" to "service_role";

grant insert on table "public"."game_members" to "service_role";

grant references on table "public"."game_members" to "service_role";

grant select on table "public"."game_members" to "service_role";

grant trigger on table "public"."game_members" to "service_role";

grant truncate on table "public"."game_members" to "service_role";

grant update on table "public"."game_members" to "service_role";

grant delete on table "public"."games" to "anon";

grant insert on table "public"."games" to "anon";

grant references on table "public"."games" to "anon";

grant select on table "public"."games" to "anon";

grant trigger on table "public"."games" to "anon";

grant truncate on table "public"."games" to "anon";

grant update on table "public"."games" to "anon";

grant delete on table "public"."games" to "authenticated";

grant insert on table "public"."games" to "authenticated";

grant references on table "public"."games" to "authenticated";

grant select on table "public"."games" to "authenticated";

grant trigger on table "public"."games" to "authenticated";

grant truncate on table "public"."games" to "authenticated";

grant update on table "public"."games" to "authenticated";

grant delete on table "public"."games" to "service_role";

grant insert on table "public"."games" to "service_role";

grant references on table "public"."games" to "service_role";

grant select on table "public"."games" to "service_role";

grant trigger on table "public"."games" to "service_role";

grant truncate on table "public"."games" to "service_role";

grant update on table "public"."games" to "service_role";


  create policy "GM can delete game_members"
  on "public"."game_members"
  as permissive
  for delete
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.game_members gm
  WHERE ((gm.game_id = game_members.game_id) AND (gm.user_id = auth.uid()) AND (gm.game_role = 'Game Master'::public.game_role)))));



  create policy "GM can insert game_members"
  on "public"."game_members"
  as permissive
  for insert
  to authenticated
with check (((user_id = auth.uid()) AND (game_role = 'Game Master'::public.game_role) AND (EXISTS ( SELECT 1
   FROM public.games g
  WHERE ((g.id = game_members.game_id) AND (g.created_by = auth.uid()))))));



  create policy "GM can update game_members"
  on "public"."game_members"
  as permissive
  for update
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.game_members gm
  WHERE ((gm.game_id = game_members.game_id) AND (gm.user_id = auth.uid()) AND (gm.game_role = 'Game Master'::public.game_role)))))
with check ((EXISTS ( SELECT 1
   FROM public.game_members gm
  WHERE ((gm.game_id = game_members.game_id) AND (gm.user_id = auth.uid()) AND (gm.game_role = 'Game Master'::public.game_role)))));



  create policy "Players and GM can view game_members"
  on "public"."game_members"
  as permissive
  for select
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.game_members gm
  WHERE ((gm.game_id = game_members.game_id) AND (gm.user_id = auth.uid())))));



  create policy "Only GM can delete games"
  on "public"."games"
  as permissive
  for delete
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.game_members gm
  WHERE ((gm.game_id = games.id) AND (gm.user_id = auth.uid()) AND (gm.game_role = 'Game Master'::public.game_role)))));



  create policy "Only GMs change game fields"
  on "public"."games"
  as permissive
  for update
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.game_members gm
  WHERE ((gm.game_id = games.id) AND (gm.user_id = auth.uid()) AND (gm.game_role = 'Game Master'::public.game_role)))));



  create policy "Only signed-in users create games; creator is recorded correctl"
  on "public"."games"
  as permissive
  for insert
  to authenticated
with check (((created_by = auth.uid()) AND (auth.uid() IS NOT NULL)));



  create policy "User sees games they belong to and public listings"
  on "public"."games"
  as permissive
  for select
  to authenticated
using (((EXISTS ( SELECT 1
   FROM public.game_members gm
  WHERE ((gm.game_id = games.id) AND (gm.user_id = auth.uid())))) OR (is_public = true)));



