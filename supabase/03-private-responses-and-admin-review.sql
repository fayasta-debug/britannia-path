-- Britannia Path Admin V5
-- Corrige la separación de respuestas por estudiante y habilita su revisión administrativa.
-- Ejecuta este archivo UNA VEZ en Supabase > SQL Editor > New query > Run.

create table if not exists public.activity_responses (
  student_id uuid not null references public.profiles(id) on delete cascade,
  response_key text not null,
  cycle_id text not null default 'general',
  unit_no integer,
  lesson_no integer,
  prompt text not null default '',
  selected_answer text not null default '',
  correct_answer text not null default '',
  is_correct boolean not null default false,
  answered_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (student_id, response_key),
  check (unit_no is null or unit_no between 1 and 4),
  check (lesson_no is null or lesson_no between 1 and 6)
);

create index if not exists activity_responses_student_cycle_idx
  on public.activity_responses(student_id, cycle_id, answered_at desc);

alter table public.activity_responses enable row level security;

drop policy if exists bp_activity_responses_read on public.activity_responses;
drop policy if exists bp_activity_responses_insert on public.activity_responses;
drop policy if exists bp_activity_responses_update on public.activity_responses;
drop policy if exists bp_activity_responses_delete on public.activity_responses;

-- El estudiante solo ve sus propias respuestas. El administrador puede revisarlas todas.
create policy bp_activity_responses_read
on public.activity_responses
for select to authenticated
using (student_id = (select auth.uid()) or public.is_admin());

-- Un estudiante solo puede insertar, actualizar o borrar filas asociadas a su propio id.
create policy bp_activity_responses_insert
on public.activity_responses
for insert to authenticated
with check (student_id = (select auth.uid()));

create policy bp_activity_responses_update
on public.activity_responses
for update to authenticated
using (student_id = (select auth.uid()))
with check (student_id = (select auth.uid()));

create policy bp_activity_responses_delete
on public.activity_responses
for delete to authenticated
using (student_id = (select auth.uid()));

grant select, insert, update, delete on public.activity_responses to authenticated;
revoke all on public.activity_responses from anon;

-- Mantiene updated_at actualizado si la función de V4 ya existe.
do $$ begin
  create trigger activity_responses_touch
  before update on public.activity_responses
  for each row execute function public.touch_updated_at();
exception when duplicate_object then null; end $$;

-- Verificación final.
select
  'activity_responses instalada' as resultado,
  (select relrowsecurity from pg_class where oid='public.activity_responses'::regclass) as rls_activo;

-- Protege las columnas de calificación: el estudiante puede entregar contenido,
-- pero no puede asignarse una nota ni escribir retroalimentación docente.
revoke insert, update on public.assignment_submissions from authenticated;
grant insert(student_id, cycle_id, assignment_type, content, status, submitted_at)
  on public.assignment_submissions to authenticated;
grant update(content, status, submitted_at)
  on public.assignment_submissions to authenticated;
