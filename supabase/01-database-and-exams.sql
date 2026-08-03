-- BRITANNIA PATH ADMIN V4
-- Ejecuta este archivo COMPLETO una sola vez en Supabase > SQL Editor.
-- Es idempotente: puedes volver a ejecutarlo si una parte falló.

create extension if not exists pgcrypto;

create table if not exists public.course_cycles (
  id text primary key,
  sequence integer not null unique,
  code text not null unique,
  title text not null,
  mcer text not null,
  total_lessons integer not null default 24,
  passing_score numeric(5,2) not null default 70,
  created_at timestamptz not null default now()
);

insert into public.course_cycles (id, sequence, code, title, mcer, total_lessons, passing_score)
values
('induction',1,'IND-01','Primeros pasos en inglés','Pre-A1',24,70),
('basic-1',2,'BAS-01','¡Hola, inglés!','A1.1',24,70),
('basic-2',3,'BAS-02','Personas y lugares','A1.1',24,70),
('basic-3',4,'BAS-03','Familia y posesiones','A1.1',24,70),
('basic-4',5,'BAS-04','La vida cotidiana','A1.2',24,70),
('basic-5',6,'BAS-05','Preguntas y hábitos','A1.2',24,70),
('basic-6',7,'BAS-06','Habilidades e intereses','A1',24,70),
('basic-7',8,'BAS-07','El hogar y el vecindario','A2.1',24,70),
('basic-8',9,'BAS-08','Comida y compras','A2.1',24,70),
('basic-9',10,'BAS-09','La vida en este momento','A2.1',24,70),
('basic-10',11,'BAS-10','Acontecimientos pasados','A2.2',24,70),
('basic-11',12,'BAS-11','Experiencias y comparaciones','A2.2',24,70),
('basic-12',13,'BAS-12','Planes e inglés práctico','A2',24,70),
('intermediate-1',14,'INT-01','Construcción de fluidez','B1.1',24,70),
('intermediate-2',15,'INT-02','Experiencias de vida','B1.1',24,70),
('intermediate-3',16,'INT-03','Cambio y continuidad','B1.1',24,70),
('intermediate-4',17,'INT-04','Cómo contar historias','B1.1',24,70),
('intermediate-5',18,'INT-05','Posibilidades futuras','B1.2',24,70),
('intermediate-6',19,'INT-06','Reglas, consejos y deducción','B1.2',24,70),
('intermediate-7',20,'INT-07','Condiciones y consecuencias','B1.2',24,70),
('intermediate-8',21,'INT-08','Realidades diferentes','B1.2',24,70),
('intermediate-9',22,'INT-09','Procesos e información','B1+',24,70),
('intermediate-10',23,'INT-10','Comunicación referida','B1+',24,70),
('intermediate-11',24,'INT-11','Conexión de ideas','B1+',24,70),
('intermediate-12',25,'INT-12','Comunicación independiente','B1',24,70),
('advanced-1',26,'ADV-01','Comunicación compleja','B2 transition',24,70),
('advanced-2',27,'ADV-02','Tiempo, posibilidad y deducción','B2 transition',24,70),
('advanced-3',28,'ADV-03','Hipótesis y arrepentimientos','B2',24,70),
('advanced-4',29,'ADV-04','Lenguaje formal e impersonal','B2',24,70),
('advanced-5',30,'ADV-05','Dominio B2','B2',24,70),
('advanced-6',31,'ADV-06','Postura y control académico','B2–C1',24,70),
('advanced-7',32,'ADV-07','Énfasis y sofisticación','C1',24,70),
('advanced-8',33,'ADV-08','Dominio integrado C1','C1',24,70),
('proficiency-1',34,'PRO-01','Precisión léxica','C1+',24,70),
('proficiency-2',35,'PRO-02','Significado implícito y discurso','C2.1',24,70),
('proficiency-3',36,'PRO-03','Dominio académico y profesional','C2.2',24,70),
('proficiency-4',37,'PRO-04','Desempeño integral C2','C2',24,70)
on conflict (id) do update set
  sequence=excluded.sequence, code=excluded.code, title=excluded.title,
  mcer=excluded.mcer, total_lessons=excluded.total_lessons,
  passing_score=excluded.passing_score;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text not null default '',
  role text not null default 'student' check (role in ('admin','student')),
  status text not null default 'active' check (status in ('active','inactive')),
  must_change_password boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_progress (
  user_id uuid primary key references auth.users(id) on delete cascade,
  progress jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.lesson_progress (
  student_id uuid not null references public.profiles(id) on delete cascade,
  lesson_key text not null,
  cycle_id text not null references public.course_cycles(id) on delete cascade,
  unit_no integer not null check (unit_no between 1 and 4),
  lesson_no integer not null check (lesson_no between 1 and 6),
  completed boolean not null default true,
  score numeric(5,2),
  completed_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (student_id, lesson_key)
);

create table if not exists public.cycle_access (
  student_id uuid not null references public.profiles(id) on delete cascade,
  cycle_id text not null references public.course_cycles(id) on delete cascade,
  is_unlocked boolean not null default true,
  unlock_reason text not null default 'automatic',
  unlocked_by uuid references public.profiles(id) on delete set null,
  unlocked_at timestamptz not null default now(),
  primary key (student_id, cycle_id)
);

create table if not exists public.cycle_progress (
  student_id uuid not null references public.profiles(id) on delete cascade,
  cycle_id text not null references public.course_cycles(id) on delete cascade,
  status text not null default 'in_progress' check (status in ('locked','in_progress','ready_for_exam','needs_review','completed')),
  final_exam_score numeric(5,2),
  attempt_count integer not null default 0,
  completed_at timestamptz,
  updated_at timestamptz not null default now(),
  primary key (student_id, cycle_id)
);

create table if not exists public.assignment_submissions (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  cycle_id text not null references public.course_cycles(id) on delete cascade,
  assignment_type text not null check (assignment_type in ('writing','project','oral')),
  content text not null default '',
  status text not null default 'submitted' check (status in ('draft','submitted','reviewed')),
  teacher_score numeric(5,2),
  teacher_feedback text,
  submitted_at timestamptz not null default now(),
  reviewed_at timestamptz,
  unique (student_id, cycle_id, assignment_type)
);

create table if not exists public.exam_questions (
  id uuid primary key default gen_random_uuid(),
  cycle_id text not null references public.course_cycles(id) on delete cascade,
  position integer not null,
  section text not null,
  prompt text not null,
  options jsonb not null,
  correct_index integer not null check (correct_index between 0 and 10),
  explanation text not null default '',
  active boolean not null default true,
  unique (cycle_id, position)
);

create table if not exists public.exam_sessions (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  cycle_id text not null references public.course_cycles(id) on delete cascade,
  question_ids jsonb not null,
  started_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '2 hours'),
  submitted_at timestamptz
);

create table if not exists public.exam_attempts (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  cycle_id text not null references public.course_cycles(id) on delete cascade,
  session_id uuid references public.exam_sessions(id) on delete set null,
  attempt_number integer not null,
  answers jsonb not null default '{}'::jsonb,
  score numeric(5,2) not null,
  passed boolean not null,
  started_at timestamptz,
  submitted_at timestamptz not null default now(),
  unique (student_id, cycle_id, attempt_number)
);

create index if not exists lesson_progress_student_cycle_idx on public.lesson_progress(student_id, cycle_id);
create index if not exists cycle_progress_student_idx on public.cycle_progress(student_id);
create index if not exists exam_attempts_student_cycle_idx on public.exam_attempts(student_id, cycle_id);
create index if not exists assignments_student_cycle_idx on public.assignment_submissions(student_id, cycle_id);

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

do $$ begin
  create trigger profiles_touch before update on public.profiles for each row execute function public.touch_updated_at();
exception when duplicate_object then null; end $$;
do $$ begin
  create trigger lesson_progress_touch before update on public.lesson_progress for each row execute function public.touch_updated_at();
exception when duplicate_object then null; end $$;
do $$ begin
  create trigger cycle_progress_touch before update on public.cycle_progress for each row execute function public.touch_updated_at();
exception when duplicate_object then null; end $$;

create or replace function public.is_admin(check_user uuid default auth.uid())
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists(select 1 from public.profiles p where p.id = check_user and p.role = 'admin' and p.status = 'active');
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer
set search_path = public
as $$
begin
  insert into public.profiles(id,email,full_name,role,status,must_change_password)
  values(
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'display_name', new.raw_user_meta_data->>'full_name', split_part(coalesce(new.email,''),'@',1)),
    'student',
    'active',
    coalesce((new.raw_user_meta_data->>'must_change_password')::boolean,false)
  ) on conflict (id) do nothing;

  insert into public.cycle_access(student_id,cycle_id,is_unlocked,unlock_reason)
  values(new.id,'induction',true,'initial registration')
  on conflict (student_id,cycle_id) do nothing;

  insert into public.cycle_progress(student_id,cycle_id,status)
  values(new.id,'induction','in_progress')
  on conflict (student_id,cycle_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- Migra usuarios que ya existían antes de instalar esta versión.
insert into public.profiles(id,email,full_name,role,status)
select u.id,u.email,coalesce(u.raw_user_meta_data->>'display_name',u.raw_user_meta_data->>'full_name',split_part(coalesce(u.email,''),'@',1)),'student','active'
from auth.users u
on conflict (id) do nothing;
insert into public.cycle_access(student_id,cycle_id,is_unlocked,unlock_reason)
select p.id,'induction',true,'migration' from public.profiles p
on conflict (student_id,cycle_id) do nothing;
insert into public.cycle_progress(student_id,cycle_id,status)
select p.id,'induction','in_progress' from public.profiles p
on conflict (student_id,cycle_id) do nothing;

create or replace function public.mark_password_changed()
returns void
language plpgsql security definer
set search_path = public
as $$ begin
  update public.profiles set must_change_password=false where id=auth.uid();
end; $$;

grant execute on function public.mark_password_changed() to authenticated;
grant execute on function public.is_admin(uuid) to authenticated;

-- RLS
alter table public.course_cycles enable row level security;
alter table public.profiles enable row level security;
alter table public.user_progress enable row level security;
alter table public.lesson_progress enable row level security;
alter table public.cycle_access enable row level security;
alter table public.cycle_progress enable row level security;
alter table public.assignment_submissions enable row level security;
alter table public.exam_questions enable row level security;
alter table public.exam_sessions enable row level security;
alter table public.exam_attempts enable row level security;

-- Borra políticas anteriores con los mismos nombres para permitir reinstalación.
do $$ declare r record; begin
  for r in select schemaname,tablename,policyname from pg_policies where schemaname='public' and policyname like 'bp_%'
  loop execute format('drop policy if exists %I on %I.%I',r.policyname,r.schemaname,r.tablename); end loop;
end $$;

create policy bp_cycles_read on public.course_cycles for select using (true);
create policy bp_profiles_read on public.profiles for select to authenticated using (id=auth.uid() or public.is_admin());
create policy bp_profiles_name_update on public.profiles for update to authenticated using (id=auth.uid()) with check (id=auth.uid());
create policy bp_user_progress_read on public.user_progress for select to authenticated using (user_id=auth.uid() or public.is_admin());
create policy bp_user_progress_insert on public.user_progress for insert to authenticated with check (user_id=auth.uid());
create policy bp_user_progress_update on public.user_progress for update to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());
create policy bp_lessons_read on public.lesson_progress for select to authenticated using (student_id=auth.uid() or public.is_admin());
create policy bp_lessons_insert on public.lesson_progress for insert to authenticated with check (student_id=auth.uid() or public.is_admin());
create policy bp_lessons_update on public.lesson_progress for update to authenticated using (student_id=auth.uid() or public.is_admin()) with check (student_id=auth.uid() or public.is_admin());
create policy bp_access_read on public.cycle_access for select to authenticated using (student_id=auth.uid() or public.is_admin());
create policy bp_access_admin_insert on public.cycle_access for insert to authenticated with check (public.is_admin());
create policy bp_access_admin_update on public.cycle_access for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy bp_access_admin_delete on public.cycle_access for delete to authenticated using (public.is_admin());
create policy bp_cycle_progress_read on public.cycle_progress for select to authenticated using (student_id=auth.uid() or public.is_admin());
create policy bp_cycle_progress_admin_update on public.cycle_progress for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy bp_assignments_read on public.assignment_submissions for select to authenticated using (student_id=auth.uid() or public.is_admin());
create policy bp_assignments_insert on public.assignment_submissions for insert to authenticated with check (student_id=auth.uid() or public.is_admin());
create policy bp_assignments_student_update on public.assignment_submissions for update to authenticated using (student_id=auth.uid() or public.is_admin()) with check (student_id=auth.uid() or public.is_admin());
create policy bp_sessions_read on public.exam_sessions for select to authenticated using (student_id=auth.uid() or public.is_admin());
create policy bp_attempts_read on public.exam_attempts for select to authenticated using (student_id=auth.uid() or public.is_admin());

-- La tabla de respuestas correctas nunca se lee desde el navegador.
revoke all on public.exam_questions from anon, authenticated;
revoke insert, update, delete on public.exam_sessions from anon, authenticated;
revoke insert, update, delete on public.exam_attempts from anon, authenticated;
revoke insert, update, delete on public.cycle_progress from anon;

-- Limita qué columnas de profiles puede editar un estudiante.
revoke update on public.profiles from authenticated;
grant update(full_name) on public.profiles to authenticated;

grant select on public.course_cycles to anon, authenticated;
grant select on public.profiles, public.user_progress, public.lesson_progress, public.cycle_access, public.cycle_progress, public.assignment_submissions, public.exam_sessions, public.exam_attempts to authenticated;
grant insert,update on public.user_progress, public.lesson_progress, public.assignment_submissions to authenticated;
grant insert,update,delete on public.cycle_access to authenticated;
grant update on public.cycle_progress to authenticated;

-- Banco de 444 preguntas (12 por ciclo). Las respuestas quedan solo en el servidor.
insert into public.exam_questions(cycle_id,position,section,prompt,options,correct_index,explanation)
values
('induction',1,'Use of English','Choose the correct subject pronoun: “María is from Lima. ___ is Peruvian.”','["He", "She", "It", "They"]'::jsonb,1,'María is a woman, so the subject pronoun is “she”.'),
('induction',2,'Use of English','Complete the sentence: “I ___ a student.”','["am", "is", "are", "be"]'::jsonb,0,'With “I”, the present form of “be” is “am”.'),
('induction',3,'Use of English','Choose the correct question.','["You are ready?", "Are you ready?", "Do you are ready?", "Is you ready?"]'::jsonb,1,'In a question with “be”, place the verb before the subject.'),
('induction',4,'Use of English','Complete the question: “___ are you from?”','["What", "Where", "When", "Who"]'::jsonb,1,'“Where” asks about a place or origin.'),
('induction',5,'Use of English','Choose the correct article: “She is ___ engineer.”','["a", "an", "the", "—"]'::jsonb,1,'Use “an” before a vowel sound: an engineer.'),
('induction',6,'Use of English','Choose the correct subject pronoun: “María is from Lima. ___ is Peruvian.”','["He", "She", "It", "They"]'::jsonb,1,'María is a woman, so the subject pronoun is “she”.'),
('induction',7,'Vocabulary','Choose the best Spanish meaning of “bedroom”.','["asistir", "entregar", "además", "dormitorio"]'::jsonb,3,'“bedroom” means “dormitorio” in this context.'),
('induction',8,'Vocabulary','Choose the best Spanish meaning of “country”.','["negociar", "coherente con", "país", "responsabilidad"]'::jsonb,2,'“country” means “país” in this context.'),
('induction',9,'Vocabulary','Choose the best Spanish meaning of “teacher”.','["seminario", "preparar la cena", "docente", "tentativo"]'::jsonb,2,'“teacher” means “docente” in this context.'),
('induction',10,'Vocabulary','Choose the best Spanish meaning of “please”.','["por favor", "billete de ida", "experiencia", "en otras palabras"]'::jsonb,0,'“please” means “por favor” in this context.'),
('induction',11,'Communication','Which communicative objective belongs especially to IND-01?','["ask about age, address and occupation", "follow simple classroom instructions", "describe yesterday", "ask about daily activities"]'::jsonb,1,'This cycle explicitly develops the ability to follow simple classroom instructions.'),
('induction',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Complete a basic form and deliver a 30–60 second personal introduction.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('basic-1',1,'Use of English','Choose the correct subject pronoun: “María is from Lima. ___ is Peruvian.”','["He", "She", "It", "They"]'::jsonb,1,'María is a woman, so the subject pronoun is “she”.'),
('basic-1',2,'Use of English','Complete the sentence: “I ___ a student.”','["am", "is", "are", "be"]'::jsonb,0,'With “I”, the present form of “be” is “am”.'),
('basic-1',3,'Use of English','Choose the correct article: “She is ___ engineer.”','["a", "an", "the", "—"]'::jsonb,1,'Use “an” before a vowel sound: an engineer.'),
('basic-1',4,'Use of English','Choose the correct singular noun phrase.','["a books", "an apple", "two chair", "three person"]'::jsonb,1,'“An apple” contains a singular countable noun with the correct article.'),
('basic-1',5,'Use of English','Choose the correct word order.','["Is she a teacher.", "She a teacher is.", "She is a teacher.", "A teacher she is?"]'::jsonb,2,'The basic affirmative order is subject + verb + complement.'),
('basic-1',6,'Use of English','Choose the correct subject pronoun: “María is from Lima. ___ is Peruvian.”','["He", "She", "It", "They"]'::jsonb,1,'María is a woman, so the subject pronoun is “she”.'),
('basic-1',7,'Vocabulary','Choose the best Spanish meaning of “mobile number”.','["predicción", "acción comunitaria", "ya había", "número de móvil"]'::jsonb,3,'“mobile number” means “número de móvil” in this context.'),
('basic-1',8,'Vocabulary','Choose the best Spanish meaning of “student”.','["número de móvil", "matizado", "estudiante", "farmacia"]'::jsonb,2,'“student” means “estudiante” in this context.'),
('basic-1',9,'Vocabulary','Choose the best Spanish meaning of “understand”.','["tono", "entender", "habrá cambiado", "trabajo académico"]'::jsonb,1,'“understand” means “entender” in this context.'),
('basic-1',10,'Vocabulary','Choose the best Spanish meaning of “name”.','["etapa", "escenario", "abuelos", "nombre"]'::jsonb,3,'“name” means “nombre” in this context.'),
('basic-1',11,'Communication','Which communicative objective belongs especially to BAS-01?','["describe current actions", "adapt instantly to register and audience", "greet people", "describe a typical day"]'::jsonb,2,'This cycle explicitly develops the ability to greet people.'),
('basic-1',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Create a personal identity card and give a short introduction.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('basic-2',1,'Use of English','Choose the correct negative sentence.','["She not is British.", "She is not British.", "She does not British.", "She no British."]'::jsonb,1,'The negative of “be” is formed with be + not: “She is not…”.'),
('basic-2',2,'Use of English','Choose the correct question.','["You are ready?", "Are you ready?", "Do you are ready?", "Is you ready?"]'::jsonb,1,'In a question with “be”, place the verb before the subject.'),
('basic-2',3,'Use of English','Complete the question: “___ are you from?”','["What", "Where", "When", "Who"]'::jsonb,1,'“Where” asks about a place or origin.'),
('basic-2',4,'Use of English','Complete: “This is Ana. ___ surname is López.”','["His", "Her", "Its", "Their"]'::jsonb,1,'Use “her” for something belonging to Ana.'),
('basic-2',5,'Use of English','Choose the correct plural.','["childs", "childrens", "children", "childes"]'::jsonb,2,'“Children” is the irregular plural of “child”.'),
('basic-2',6,'Use of English','Choose the correct negative sentence.','["She not is British.", "She is not British.", "She does not British.", "She no British."]'::jsonb,1,'The negative of “be” is formed with be + not: “She is not…”.'),
('basic-2',7,'Vocabulary','Choose the best Spanish meaning of “language”.','["sofá", "idioma", "parafrasear", "armario"]'::jsonb,1,'“language” means “idioma” in this context.'),
('basic-2',8,'Vocabulary','Choose the best Spanish meaning of “repeat”.','["postura", "repetir", "mediar", "finalmente"]'::jsonb,1,'“repeat” means “repetir” in this context.'),
('basic-2',9,'Vocabulary','Choose the best Spanish meaning of “good morning”.','["supervisar", "buenos días", "desde", "contexto"]'::jsonb,1,'“good morning” means “buenos días” in this context.'),
('basic-2',10,'Vocabulary','Choose the best Spanish meaning of “address”.','["implementar", "¿Le gustaría…?", "dirección", "desde aquel día"]'::jsonb,2,'“address” means “dirección” in this context.'),
('basic-2',11,'Communication','Which communicative objective belongs especially to BAS-02?','["express frequency", "exchange personal information", "describe a typical day", "adapt instantly to register and audience"]'::jsonb,1,'This cycle explicitly develops the ability to exchange personal information.'),
('basic-2',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Conduct a personal interview and introduce the interviewee.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('basic-3',1,'Use of English','Complete: “He ___ got two sisters.”','["have", "has", "is", "does"]'::jsonb,1,'With he/she/it, use “has got”.'),
('basic-3',2,'Use of English','Choose the correct possessive form.','["This is Maria bag.", "This is Maria''s bag.", "This is bag of Maria''s.", "This Maria is bag."]'::jsonb,1,'Add ’s to a person’s name to express possession.'),
('basic-3',3,'Use of English','Choose the correct word for several objects near you: “___ books are new.”','["This", "That", "These", "It"]'::jsonb,2,'“These” refers to plural things that are near.'),
('basic-3',4,'Use of English','Complete the question: “___ coat is this?”','["Who", "Whose", "Which is", "Who is"]'::jsonb,1,'“Whose” asks about possession.'),
('basic-3',5,'Use of English','Choose the correct plural.','["childs", "childrens", "children", "childes"]'::jsonb,2,'“Children” is the irregular plural of “child”.'),
('basic-3',6,'Use of English','Complete: “He ___ got two sisters.”','["have", "has", "is", "does"]'::jsonb,1,'With he/she/it, use “has got”.'),
('basic-3',7,'Vocabulary','Choose the best Spanish meaning of “tall”.','["alto/a", "además", "primo/a", "videojuegos"]'::jsonb,0,'“tall” means “alto/a” in this context.'),
('basic-3',8,'Vocabulary','Choose the best Spanish meaning of “hello”.','["hola", "temporalmente", "recomendación", "despertarse"]'::jsonb,0,'“hello” means “hola” in this context.'),
('basic-3',9,'Vocabulary','Choose the best Spanish meaning of “sister”.','["billete de ida", "hermana", "informar", "desafío"]'::jsonb,1,'“sister” means “hermana” in this context.'),
('basic-3',10,'Vocabulary','Choose the best Spanish meaning of “wife”.','["esposa", "amplitud léxica", "pertinente", "reducir"]'::jsonb,0,'“wife” means “esposa” in this context.'),
('basic-3',11,'Communication','Which communicative objective belongs especially to BAS-03?','["spell names and key words", "describe a neighbourhood", "talk about past events", "talk about family"]'::jsonb,3,'This cycle explicitly develops the ability to talk about family.'),
('basic-3',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Create and present a family tree.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('basic-4',1,'Use of English','Complete: “My brother ___ at a bank.”','["work", "works", "working", "is work"]'::jsonb,1,'In the present simple, add -s with he/she/it.'),
('basic-4',2,'Use of English','Choose the correct form: “She ___ English every day.”','["study", "studies", "studying", "studyies"]'::jsonb,1,'A consonant + y changes to -ies: study → studies.'),
('basic-4',3,'Use of English','Choose the correct preposition: “The class starts ___ 6 p.m.”','["in", "on", "at", "by"]'::jsonb,2,'Use “at” with clock times.'),
('basic-4',4,'Use of English','Which word is best to introduce the final step?','["First", "Then", "Finally", "Before"]'::jsonb,2,'“Finally” introduces the last step in a sequence.'),
('basic-4',5,'Use of English','Complete: “My brother ___ at a bank.”','["work", "works", "working", "is work"]'::jsonb,1,'In the present simple, add -s with he/she/it.'),
('basic-4',6,'Use of English','Choose the correct form: “She ___ English every day.”','["study", "studies", "studying", "studyies"]'::jsonb,1,'A consonant + y changes to -ies: study → studies.'),
('basic-4',7,'Vocabulary','Choose the best Spanish meaning of “at the weekend”.','["primo/a", "cuenta", "el fin de semana", "entender"]'::jsonb,2,'“at the weekend” means “el fin de semana” in this context.'),
('basic-4',8,'Vocabulary','Choose the best Spanish meaning of “leave home”.','["podría", "sin embargo", "jersey", "salir de casa"]'::jsonb,3,'“leave home” means “salir de casa” in this context.'),
('basic-4',9,'Vocabulary','Choose the best Spanish meaning of “finish”.','["personaje", "terminar", "Haré…", "intención"]'::jsonb,1,'“finish” means “terminar” in this context.'),
('basic-4',10,'Vocabulary','Choose the best Spanish meaning of “teacher”.','["connotación", "edad", "evidencia", "docente"]'::jsonb,3,'“teacher” means “docente” in this context.'),
('basic-4',11,'Communication','Which communicative objective belongs especially to BAS-04?','["talk about routines", "talk about abilities", "communicate with precision and flexibility", "follow simple classroom instructions"]'::jsonb,0,'This cycle explicitly develops the ability to talk about routines.'),
('basic-4',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Prepare and present “My typical weekday”.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('basic-5',1,'Use of English','Choose the correct negative sentence.','["He doesn''t work on Sundays.", "He don''t works on Sundays.", "He not work on Sundays.", "He isn''t work on Sundays."]'::jsonb,0,'Use does not/doesn’t + base verb with he/she/it.'),
('basic-5',2,'Use of English','Complete: “___ your sister live in London?”','["Do", "Does", "Is", "Has"]'::jsonb,1,'Use “does” with he/she/it, followed by the base verb.'),
('basic-5',3,'Use of English','Complete: “___ your sister live in London?”','["Do", "Does", "Is", "Has"]'::jsonb,1,'Use “does” with he/she/it, followed by the base verb.'),
('basic-5',4,'Use of English','Choose the most natural sentence.','["I go always swimming.", "I always go swimming.", "Always I go swimming.", "I go swimming always every."]'::jsonb,1,'Frequency adverbs normally go before the main verb.'),
('basic-5',5,'Use of English','Choose the most natural sentence.','["I go always swimming.", "I always go swimming.", "Always I go swimming.", "I go swimming always every."]'::jsonb,1,'Frequency adverbs normally go before the main verb.'),
('basic-5',6,'Use of English','Choose the correct negative sentence.','["He doesn''t work on Sundays.", "He don''t works on Sundays.", "He not work on Sundays.", "He isn''t work on Sundays."]'::jsonb,0,'Use does not/doesn’t + base verb with he/she/it.'),
('basic-5',7,'Vocabulary','Choose the best Spanish meaning of “have breakfast”.','["impacto", "el fin de semana", "desayunar", "etapa"]'::jsonb,2,'“have breakfast” means “desayunar” in this context.'),
('basic-5',8,'Vocabulary','Choose the best Spanish meaning of “have lunch”.','["almorzar", "progreso", "hermana", "atenuación"]'::jsonb,0,'“have lunch” means “almorzar” in this context.'),
('basic-5',9,'Vocabulary','Choose the best Spanish meaning of “do homework”.','["por favor", "hacer la tarea", "participar en", "parte interesada"]'::jsonb,1,'“do homework” means “hacer la tarea” in this context.'),
('basic-5',10,'Vocabulary','Choose the best Spanish meaning of “hardly ever”.','["síntesis", "sostenible", "apellido", "casi nunca"]'::jsonb,3,'“hardly ever” means “casi nunca” in this context.'),
('basic-5',11,'Communication','Which communicative objective belongs especially to BAS-05?','["communicate with precision and flexibility", "ask about habits", "greet and introduce yourself", "ask about prices and quantities"]'::jsonb,1,'This cycle explicitly develops the ability to ask about habits.'),
('basic-5',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Design and carry out a survey about habits.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('basic-6',1,'Use of English','Choose the correct sentence.','["She can to swim.", "She cans swim.", "She can swim.", "She can swimming."]'::jsonb,2,'A modal verb is followed by the base form without “to”.'),
('basic-6',2,'Use of English','Complete: “I enjoy ___ British films.”','["watch", "to watching", "watching", "watched"]'::jsonb,2,'After “enjoy”, use the -ing form.'),
('basic-6',3,'Use of English','Complete: “I know Sarah. I work with ___.”','["she", "her", "hers", "herself"]'::jsonb,1,'After a preposition, use the object pronoun “her”.'),
('basic-6',4,'Use of English','Which sentence is an imperative?','["You open the book.", "Open the book, please.", "Do you open the book?", "You are opening the book."]'::jsonb,1,'Imperatives use the base verb without an explicit subject.'),
('basic-6',5,'Use of English','Choose the correct suggestion.','["Let''s to meet at six.", "Let''s meeting at six.", "Let''s meet at six.", "Let''s we meet at six."]'::jsonb,2,'Use “Let’s + base verb”.'),
('basic-6',6,'Use of English','Choose the correct sentence.','["She can to swim.", "She cans swim.", "She can swim.", "She can swimming."]'::jsonb,2,'A modal verb is followed by the base form without “to”.'),
('basic-6',7,'Vocabulary','Choose the best Spanish meaning of “playing the guitar”.','["acción comunitaria", "tocar la guitarra", "desayunar", "evidencia"]'::jsonb,1,'“playing the guitar” means “tocar la guitarra” in this context.'),
('basic-6',8,'Vocabulary','Choose the best Spanish meaning of “practise”.','["residuos", "preparar la cena", "regla de seguridad", "practicar"]'::jsonb,3,'“practise” means “practicar” in this context.'),
('basic-6',9,'Vocabulary','Choose the best Spanish meaning of “invite”.','["verduras", "invitar", "malentendido", "para cuando"]'::jsonb,1,'“invite” means “invitar” in this context.'),
('basic-6',10,'Vocabulary','Choose the best Spanish meaning of “reading”.','["lectura", "como resultado", "alcance", "edad"]'::jsonb,0,'“reading” means “lectura” in this context.'),
('basic-6',11,'Communication','Which communicative objective belongs especially to BAS-06?','["express preferences", "compare places and objects", "recommend destinations or activities", "talk about abilities"]'::jsonb,3,'This cycle explicitly develops the ability to talk about abilities.'),
('basic-6',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Organise a group activity based on shared interests.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('basic-7',1,'Use of English','Complete: “___ two cafés near my house.”','["There is", "There are", "It is", "They are"]'::jsonb,1,'Use “there are” before a plural noun.'),
('basic-7',2,'Use of English','Complete: “Are there ___ shops nearby?”','["some", "any", "much", "a"]'::jsonb,1,'Use “any” in most questions and negatives.'),
('basic-7',3,'Use of English','Complete: “The bank is ___ the chemist’s and the café.”','["between", "under", "through", "during"]'::jsonb,0,'“Between” locates something in the middle of two places.'),
('basic-7',4,'Use of English','Choose the correct article: “She is ___ engineer.”','["a", "an", "the", "—"]'::jsonb,1,'Use “an” before a vowel sound: an engineer.'),
('basic-7',5,'Use of English','Complete: “___ bedrooms are there?”','["How much", "How many", "How often", "How long"]'::jsonb,1,'Use “how many” with plural countable nouns.'),
('basic-7',6,'Use of English','Complete: “___ two cafés near my house.”','["There is", "There are", "It is", "They are"]'::jsonb,1,'Use “there are” before a plural noun.'),
('basic-7',7,'Vocabulary','Choose the best Spanish meaning of “sofa”.','["entregar", "asignar recursos", "chubasco", "sofá"]'::jsonb,3,'“sofa” means “sofá” in this context.'),
('basic-7',8,'Vocabulary','Choose the best Spanish meaning of “nearby”.','["el más impresionante", "de repente", "más fiable", "cerca"]'::jsonb,3,'“nearby” means “cerca” in this context.'),
('basic-7',9,'Vocabulary','Choose the best Spanish meaning of “flat”.','["porción", "departamento", "amable", "titular"]'::jsonb,1,'“flat” means “departamento” in this context.'),
('basic-7',10,'Vocabulary','Choose the best Spanish meaning of “kitchen”.','["cocina", "sugiere firmemente", "responsabilidad", "intención"]'::jsonb,0,'“kitchen” means “cocina” in this context.'),
('basic-7',11,'Communication','Which communicative objective belongs especially to BAS-07?','["describe a home", "contrast routines and current actions", "say where you are from", "spell names and key words"]'::jsonb,0,'This cycle explicitly develops the ability to describe a home.'),
('basic-7',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Design and present an ideal home.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('basic-8',1,'Use of English','Which noun is normally uncountable?','["apple", "bottle", "rice", "sandwich"]'::jsonb,2,'“Rice” is normally treated as an uncountable noun.'),
('basic-8',2,'Use of English','Complete: “Are there ___ shops nearby?”','["some", "any", "much", "a"]'::jsonb,1,'Use “any” in most questions and negatives.'),
('basic-8',3,'Use of English','Which option best describes the focus “a lot of”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops a lot of through form, meaning and communicative use.'),
('basic-8',4,'Use of English','Complete: “How ___ water do you drink?”','["many", "much", "few", "several"]'::jsonb,1,'Use “much” with uncountable nouns such as water.'),
('basic-8',5,'Use of English','Choose the polite restaurant request.','["I want soup.", "Give me soup.", "I would like the soup, please.", "I am liking soup."]'::jsonb,2,'“I would like…” is a polite way to order.'),
('basic-8',6,'Use of English','Which noun is normally uncountable?','["apple", "bottle", "rice", "sandwich"]'::jsonb,2,'“Rice” is normally treated as an uncountable noun.'),
('basic-8',7,'Vocabulary','Choose the best Spanish meaning of “starter”.','["proteger", "entrada", "fruta", "fiable"]'::jsonb,1,'“starter” means “entrada” in this context.'),
('basic-8',8,'Vocabulary','Choose the best Spanish meaning of “Would you like…?”.','["¿Le gustaría…?", "conjunto coherente", "idioma", "agua sin gas"]'::jsonb,0,'“Would you like…?” means “¿Le gustaría…?” in this context.'),
('basic-8',9,'Vocabulary','Choose the best Spanish meaning of “fruit”.','["salir de casa", "fruta", "convincente", "tener que"]'::jsonb,1,'“fruit” means “fruta” in this context.'),
('basic-8',10,'Vocabulary','Choose the best Spanish meaning of “slice”.','["rebanada", "tomar medidas", "explicar", "despertarse"]'::jsonb,0,'“slice” means “rebanada” in this context.'),
('basic-8',11,'Communication','Which communicative objective belongs especially to BAS-08?','["buy products", "talk about family", "order food", "synthesise and mediate across sources"]'::jsonb,2,'This cycle explicitly develops the ability to order food.'),
('basic-8',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Role-play a shopping trip and a restaurant conversation.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('basic-9',1,'Use of English','Complete: “They ___ dinner at the moment.”','["cook", "cooks", "are cooking", "cooked"]'::jsonb,2,'Use am/is/are + -ing for an action happening now.'),
('basic-9',2,'Use of English','Choose the correct sentence for a temporary situation.','["I work from home this week.", "I am working from home this week.", "I working from home this week.", "I have work from home this week."]'::jsonb,1,'The present continuous is common for temporary situations.'),
('basic-9',3,'Use of English','Which sentence is normally correct?','["I am knowing the answer.", "I know the answer.", "I knowing the answer.", "I do knowing the answer."]'::jsonb,1,'“Know” is normally a stative verb and is not used in the continuous form.'),
('basic-9',4,'Use of English','Which option best describes the focus “time expressions”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops time expressions through form, meaning and communicative use.'),
('basic-9',5,'Use of English','Complete: “They ___ dinner at the moment.”','["cook", "cooks", "are cooking", "cooked"]'::jsonb,2,'Use am/is/are + -ing for an action happening now.'),
('basic-9',6,'Use of English','Choose the correct sentence for a temporary situation.','["I work from home this week.", "I am working from home this week.", "I working from home this week.", "I have work from home this week."]'::jsonb,1,'The present continuous is common for temporary situations.'),
('basic-9',7,'Vocabulary','Choose the best Spanish meaning of “right now”.','["natación", "evidencia", "parte interesada", "ahora mismo"]'::jsonb,3,'“right now” means “ahora mismo” in this context.'),
('basic-9',8,'Vocabulary','Choose the best Spanish meaning of “trainers”.','["zapatillas", "tentativo", "presuposición", "despertarse"]'::jsonb,0,'“trainers” means “zapatillas” in this context.'),
('basic-9',9,'Vocabulary','Choose the best Spanish meaning of “fit”.','["andén", "significativo", "quedar bien de talla", "hallazgo"]'::jsonb,2,'“fit” means “quedar bien de talla” in this context.'),
('basic-9',10,'Vocabulary','Choose the best Spanish meaning of “opposite”.','["cita", "en cuanto", "estudiante", "enfrente de"]'::jsonb,3,'“opposite” means “enfrente de” in this context.'),
('basic-9',11,'Communication','Which communicative objective belongs especially to BAS-09?','["greet people", "respond and follow up naturally", "describe current actions", "communicate complex ideas precisely"]'::jsonb,2,'This cycle explicitly develops the ability to describe current actions.'),
('basic-9',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Create a narrated photo report.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('basic-10',1,'Use of English','Complete: “We ___ at home yesterday.”','["was", "were", "are", "be"]'::jsonb,1,'The past of “be” with we/you/they is “were”.'),
('basic-10',2,'Use of English','Which option best describes the focus “regular past simple”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops regular past simple through form, meaning and communicative use.'),
('basic-10',3,'Use of English','Which option best describes the focus “irregular past simple”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops irregular past simple through form, meaning and communicative use.'),
('basic-10',4,'Use of English','Choose the correct question.','["Did you went?", "Did you go?", "Do you went?", "Were you go?"]'::jsonb,1,'After “did”, use the base form of the verb.'),
('basic-10',5,'Use of English','Which option best describes the focus “past time expressions”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops past time expressions through form, meaning and communicative use.'),
('basic-10',6,'Use of English','Complete: “We ___ at home yesterday.”','["was", "were", "are", "be"]'::jsonb,1,'The past of “be” with we/you/they is “were”.'),
('basic-10',7,'Vocabulary','Choose the best Spanish meaning of “trip”.','["viaje corto", "ser bueno en", "fruta", "directo/brusco"]'::jsonb,0,'“trip” means “viaje corto” in this context.'),
('basic-10',8,'Vocabulary','Choose the best Spanish meaning of “arrive”.','["llegar", "empaquetar", "edad", "testigo"]'::jsonb,0,'“arrive” means “llegar” in this context.'),
('basic-10',9,'Vocabulary','Choose the best Spanish meaning of “happen”.','["menú", "ocurrir", "billete de ida", "más fiable"]'::jsonb,1,'“happen” means “ocurrir” in this context.'),
('basic-10',10,'Vocabulary','Choose the best Spanish meaning of “yesterday”.','["fecha límite", "ayer", "asistir", "hijo"]'::jsonb,1,'“yesterday” means “ayer” in this context.'),
('basic-10',11,'Communication','Which communicative objective belongs especially to BAS-10?','["talk about a room", "express preferences", "talk about temporary situations", "talk about past events"]'::jsonb,3,'This cycle explicitly develops the ability to talk about past events.'),
('basic-10',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Narrate a personal event.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('basic-11',1,'Use of English','Complete: “I have never ___ to Scotland.”','["be", "been", "went", "being"]'::jsonb,1,'The past participle of “be” is “been”.'),
('basic-11',2,'Use of English','Which option best describes the focus “ever/never”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops ever/never through form, meaning and communicative use.'),
('basic-11',3,'Use of English','Which option best describes the focus “comparatives”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops comparatives through form, meaning and communicative use.'),
('basic-11',4,'Use of English','Which option best describes the focus “superlatives”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops superlatives through form, meaning and communicative use.'),
('basic-11',5,'Use of English','Which option best describes the focus “too/enough”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops too/enough through form, meaning and communicative use.'),
('basic-11',6,'Use of English','Complete: “I have never ___ to Scotland.”','["be", "been", "went", "being"]'::jsonb,1,'The past participle of “be” is “been”.'),
('basic-11',7,'Vocabulary','Choose the best Spanish meaning of “miss a train”.','["regla de seguridad", "perder un tren", "como resultado", "arroz"]'::jsonb,1,'“miss a train” means “perder un tren” in this context.'),
('basic-11',8,'Vocabulary','Choose the best Spanish meaning of “already”.','["convendría", "lo que importa es", "en este momento", "ya"]'::jsonb,3,'“already” means “ya” in this context.'),
('basic-11',9,'Vocabulary','Choose the best Spanish meaning of “last year”.','["progreso", "mientras que", "solía", "el año pasado"]'::jsonb,3,'“last year” means “el año pasado” in this context.'),
('basic-11',10,'Vocabulary','Choose the best Spanish meaning of “achievement”.','["fruta", "logro", "afirmar", "chubasco"]'::jsonb,1,'“achievement” means “logro” in this context.'),
('basic-11',11,'Communication','Which communicative objective belongs especially to BAS-11?','["talk about weekends", "describe a celebration", "talk about experiences", "talk about family"]'::jsonb,2,'This cycle explicitly develops the ability to talk about experiences.'),
('basic-11',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Prepare a tourist recommendation.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('basic-12',1,'Use of English','Choose the correct sentence for an intention.','["I''m going to study tonight.", "I going study tonight.", "I will to study tonight.", "I am go to study tonight."]'::jsonb,0,'The form is be going to + base verb.'),
('basic-12',2,'Use of English','Choose the sentence that describes a fixed arrangement.','["I meet Sara at six yesterday.", "I''m meeting Sara at six tomorrow.", "I have meet Sara at six.", "I meeting Sara tomorrow."]'::jsonb,1,'The present continuous can express a fixed future arrangement.'),
('basic-12',3,'Use of English','The phone is ringing. Choose the immediate decision.','["I''m going to answer it yesterday.", "I''ll answer it.", "I answer it now every day.", "I answered it."]'::jsonb,1,'“Will” is commonly used for a decision made at the moment of speaking.'),
('basic-12',4,'Use of English','Choose the best advice.','["You should get some rest.", "You should to get some rest.", "You musted rest.", "You are should rest."]'::jsonb,0,'Use should + base verb to give advice.'),
('basic-12',5,'Use of English','Which option best describes the focus “A1–A2 review”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops A1–A2 review through form, meaning and communicative use.'),
('basic-12',6,'Use of English','Choose the correct sentence for an intention.','["I''m going to study tonight.", "I going study tonight.", "I will to study tonight.", "I am go to study tonight."]'::jsonb,0,'The form is be going to + base verb.'),
('basic-12',7,'Vocabulary','Choose the best Spanish meaning of “platform”.','["empezar a trabajar", "andén", "memorable", "energía renovable"]'::jsonb,1,'“platform” means “andén” in this context.'),
('basic-12',8,'Vocabulary','Choose the best Spanish meaning of “be good at”.','["sugerir", "a veces", "visitar", "ser bueno en"]'::jsonb,3,'“be good at” means “ser bueno en” in this context.'),
('basic-12',9,'Vocabulary','Choose the best Spanish meaning of “I’m going to…”.','["Voy a…", "mejorar", "no obstante", "como resultado"]'::jsonb,0,'“I’m going to…” means “Voy a…” in this context.'),
('basic-12',10,'Vocabulary','Choose the best Spanish meaning of “book a room”.','["esposo", "tocar la guitarra", "reservar una habitación", "unirse a un club"]'::jsonb,2,'“book a room” means “reservar una habitación” in this context.'),
('basic-12',11,'Communication','Which communicative objective belongs especially to BAS-12?','["talk about abilities", "interpret and express nuance", "make invitations", "talk about plans"]'::jsonb,3,'This cycle explicitly develops the ability to talk about plans.'),
('basic-12',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Plan a trip and solve a series of practical travel situations.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('intermediate-1',1,'Use of English','Which option best describes the focus “review of core tenses”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops review of core tenses through form, meaning and communicative use.'),
('intermediate-1',2,'Use of English','Which option best describes the focus “natural question forms”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops natural question forms through form, meaning and communicative use.'),
('intermediate-1',3,'Use of English','Which option best describes the focus “interaction strategies”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops interaction strategies through form, meaning and communicative use.'),
('intermediate-1',4,'Use of English','Which option best describes the focus “extended description”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops extended description through form, meaning and communicative use.'),
('intermediate-1',5,'Use of English','Which option best describes the focus “review of core tenses”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops review of core tenses through form, meaning and communicative use.'),
('intermediate-1',6,'Use of English','Which option best describes the focus “natural question forms”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops natural question forms through form, meaning and communicative use.'),
('intermediate-1',7,'Vocabulary','Choose the best Spanish meaning of “student”.','["personaje", "plato principal", "sugerir", "estudiante"]'::jsonb,3,'“student” means “estudiante” in this context.'),
('intermediate-1',8,'Vocabulary','Choose the best Spanish meaning of “more reliable”.','["más fiable", "hola", "viabilidad", "vestirse"]'::jsonb,0,'“more reliable” means “más fiable” in this context.'),
('intermediate-1',9,'Vocabulary','Choose the best Spanish meaning of “name”.','["ser producido", "nombre", "precisión gramatical", "metodología"]'::jsonb,1,'“name” means “nombre” in this context.'),
('intermediate-1',10,'Vocabulary','Choose the best Spanish meaning of “mobile number”.','["darse cuenta", "impacto", "número de móvil", "entrada"]'::jsonb,2,'“mobile number” means “número de móvil” in this context.'),
('intermediate-1',11,'Communication','Which communicative objective belongs especially to INT-01?','["sustain longer interaction", "make invitations", "ask about prices and quantities", "talk about family"]'::jsonb,0,'This cycle explicitly develops the ability to sustain longer interaction.'),
('intermediate-1',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Record a structured personal interview.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('intermediate-2',1,'Use of English','Choose the correct sentence for a finished time.','["I have visited York last year.", "I visited York last year.", "I have visit York last year.", "I was visited York last year."]'::jsonb,1,'Use the past simple with a finished time such as “last year”.'),
('intermediate-2',2,'Use of English','Complete: “Tom is not here; he has ___ to the bank.”','["been", "gone", "went", "go"]'::jsonb,1,'“Gone” means he went and has not returned yet.'),
('intermediate-2',3,'Use of English','Complete: “I have lived here ___ 2022.”','["for", "since", "during", "from"]'::jsonb,1,'Use “since” with a starting point.'),
('intermediate-2',4,'Use of English','Complete: “Have you finished ___?”','["already", "yet", "just", "since"]'::jsonb,1,'“Yet” is common in present-perfect questions and negatives.'),
('intermediate-2',5,'Use of English','Choose the correct sentence for a finished time.','["I have visited York last year.", "I visited York last year.", "I have visit York last year.", "I was visited York last year."]'::jsonb,1,'Use the past simple with a finished time such as “last year”.'),
('intermediate-2',6,'Use of English','Complete: “Tom is not here; he has ___ to the bank.”','["been", "gone", "went", "go"]'::jsonb,1,'“Gone” means he went and has not returned yet.'),
('intermediate-2',7,'Vocabulary','Choose the best Spanish meaning of “demanding”.','["experiencia", "tener que", "admitir", "exigente"]'::jsonb,3,'“demanding” means “exigente” in this context.'),
('intermediate-2',8,'Vocabulary','Choose the best Spanish meaning of “trip”.','["acostarse", "durante", "precisión gramatical", "viaje corto"]'::jsonb,3,'“trip” means “viaje corto” in this context.'),
('intermediate-2',9,'Vocabulary','Choose the best Spanish meaning of “take part in”.','["participar en", "significativo", "cuestionar una afirmación", "tener que"]'::jsonb,0,'“take part in” means “participar en” in this context.'),
('intermediate-2',10,'Vocabulary','Choose the best Spanish meaning of “happen”.','["ser realizado", "enfrente de", "recomendación", "ocurrir"]'::jsonb,3,'“happen” means “ocurrir” in this context.'),
('intermediate-2',11,'Communication','Which communicative objective belongs especially to INT-02?','["introduce yourself", "interpret highly complex meaning", "describe current actions", "sustain longer interaction"]'::jsonb,3,'This cycle explicitly develops the ability to sustain longer interaction.'),
('intermediate-2',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Create a podcast about important experiences.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('intermediate-3',1,'Use of English','Complete: “She has been ___ for two hours.”','["study", "studied", "studying", "studies"]'::jsonb,2,'The form is have/has been + verb-ing.'),
('intermediate-3',2,'Use of English','Which option best describes the focus “duration”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops duration through form, meaning and communicative use.'),
('intermediate-3',3,'Use of English','Which option best describes the focus “recent actions”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops recent actions through form, meaning and communicative use.'),
('intermediate-3',4,'Use of English','Which option best describes the focus “change over time”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops change over time through form, meaning and communicative use.'),
('intermediate-3',5,'Use of English','Complete: “She has been ___ for two hours.”','["study", "studied", "studying", "studies"]'::jsonb,2,'The form is have/has been + verb-ing.'),
('intermediate-3',6,'Use of English','Which option best describes the focus “duration”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops duration through form, meaning and communicative use.'),
('intermediate-3',7,'Vocabulary','Choose the best Spanish meaning of “wake up”.','["despertarse", "etapa", "acción de seguimiento", "enfatizar"]'::jsonb,0,'“wake up” means “despertarse” in this context.'),
('intermediate-3',8,'Vocabulary','Choose the best Spanish meaning of “age”.','["llegar", "advertir", "hijo", "edad"]'::jsonb,3,'“age” means “edad” in this context.'),
('intermediate-3',9,'Vocabulary','Choose the best Spanish meaning of “manager”.','["contraargumento", "gerente", "paquete", "perder un tren"]'::jsonb,1,'“manager” means “gerente” in this context.'),
('intermediate-3',10,'Vocabulary','Choose the best Spanish meaning of “evidence-based”.','["prometer", "basado en evidencia", "afortunadamente", "cerca"]'::jsonb,1,'“evidence-based” means “basado en evidencia” in this context.'),
('intermediate-3',11,'Communication','Which communicative objective belongs especially to INT-03?','["sustain longer interaction", "give basic personal information", "greet and introduce yourself", "talk about cities and countries"]'::jsonb,0,'This cycle explicitly develops the ability to sustain longer interaction.'),
('intermediate-3',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Present how an activity, place or custom has changed.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('intermediate-4',1,'Use of English','Which option best describes the focus “past simple”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops past simple through form, meaning and communicative use.'),
('intermediate-4',2,'Use of English','Complete: “I ___ when you called.”','["slept", "was sleeping", "have slept", "am sleeping"]'::jsonb,1,'The past continuous describes an action in progress in the past.'),
('intermediate-4',3,'Use of English','Complete: “The train had left before we ___.”','["arrive", "arrived", "had arrive", "are arriving"]'::jsonb,1,'The later past action is normally in the past simple.'),
('intermediate-4',4,'Use of English','Choose the correct sentence about a past habit.','["I use to play football.", "I used to play football.", "I was used play football.", "I used playing football."]'::jsonb,1,'Use “used to + base verb” for a past habit or state.'),
('intermediate-4',5,'Use of English','Which option best describes the focus “narrative markers”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops narrative markers through form, meaning and communicative use.'),
('intermediate-4',6,'Use of English','Which option best describes the focus “past simple”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops past simple through form, meaning and communicative use.'),
('intermediate-4',7,'Vocabulary','Choose the best Spanish meaning of “plot”.','["primo/a", "supuesto", "trama", "inequívoco"]'::jsonb,2,'“plot” means “trama” in this context.'),
('intermediate-4',8,'Vocabulary','Choose the best Spanish meaning of “country”.','["bienestar", "afortunadamente", "evidencia", "país"]'::jsonb,3,'“country” means “país” in this context.'),
('intermediate-4',9,'Vocabulary','Choose the best Spanish meaning of “fortunately”.','["propuesta", "afortunadamente", "ciclismo", "ironía"]'::jsonb,1,'“fortunately” means “afortunadamente” in this context.'),
('intermediate-4',10,'Vocabulary','Choose the best Spanish meaning of “from that day on”.','["desde aquel día", "reciclar", "no obstante", "estante"]'::jsonb,0,'“from that day on” means “desde aquel día” in this context.'),
('intermediate-4',11,'Communication','Which communicative objective belongs especially to INT-04?','["sustain longer interaction", "talk about routines", "talk about plans", "talk about cities and countries"]'::jsonb,0,'This cycle explicitly develops the ability to sustain longer interaction.'),
('intermediate-4',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Write and tell an original story.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('intermediate-5',1,'Use of English','The phone is ringing. Choose the immediate decision.','["I''m going to answer it yesterday.", "I''ll answer it.", "I answer it now every day.", "I answered it."]'::jsonb,1,'“Will” is commonly used for a decision made at the moment of speaking.'),
('intermediate-5',2,'Use of English','Choose the correct sentence for an intention.','["I''m going to study tonight.", "I going study tonight.", "I will to study tonight.", "I am go to study tonight."]'::jsonb,0,'The form is be going to + base verb.'),
('intermediate-5',3,'Use of English','Complete: “They ___ dinner at the moment.”','["cook", "cooks", "are cooking", "cooked"]'::jsonb,2,'Use am/is/are + -ing for an action happening now.'),
('intermediate-5',4,'Use of English','Complete: “This time tomorrow, I ___ to London.”','["travel", "will be travelling", "will have travelled", "am travelled"]'::jsonb,1,'The future continuous is will be + verb-ing.'),
('intermediate-5',5,'Use of English','The phone is ringing. Choose the immediate decision.','["I''m going to answer it yesterday.", "I''ll answer it.", "I answer it now every day.", "I answered it."]'::jsonb,1,'“Will” is commonly used for a decision made at the moment of speaking.'),
('intermediate-5',6,'Use of English','Choose the correct sentence for an intention.','["I''m going to study tonight.", "I going study tonight.", "I will to study tonight.", "I am go to study tonight."]'::jsonb,0,'The form is be going to + base verb.'),
('intermediate-5',7,'Vocabulary','Choose the best Spanish meaning of “workload”.','["supuesto", "carga de trabajo", "lectura", "para 2040"]'::jsonb,1,'“workload” means “carga de trabajo” in this context.'),
('intermediate-5',8,'Vocabulary','Choose the best Spanish meaning of “attend”.','["supervisar", "alusión", "asistir", "contingencia"]'::jsonb,2,'“attend” means “asistir” in this context.'),
('intermediate-5',9,'Vocabulary','Choose the best Spanish meaning of “impact”.','["entrada", "impacto", "arroz", "acostarse"]'::jsonb,1,'“impact” means “impacto” in this context.'),
('intermediate-5',10,'Vocabulary','Choose the best Spanish meaning of “renewable energy”.','["de repente", "energía renovable", "explicar", "Haré…"]'::jsonb,1,'“renewable energy” means “energía renovable” in this context.'),
('intermediate-5',11,'Communication','Which communicative objective belongs especially to INT-05?','["sustain longer interaction", "respond and follow up naturally", "understand basic instructions", "greet people"]'::jsonb,0,'This cycle explicitly develops the ability to sustain longer interaction.'),
('intermediate-5',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Present future scenarios about education, work or technology.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('intermediate-6',1,'Use of English','Choose the sentence expressing obligation.','["You might wear a seat belt.", "You must wear a seat belt.", "You would wear a seat belt yesterday.", "You can to wear a seat belt."]'::jsonb,1,'“Must” expresses strong obligation.'),
('intermediate-6',2,'Use of English','Choose the sentence expressing obligation.','["You might wear a seat belt.", "You must wear a seat belt.", "You would wear a seat belt yesterday.", "You can to wear a seat belt."]'::jsonb,1,'“Must” expresses strong obligation.'),
('intermediate-6',3,'Use of English','Choose the best advice.','["You should get some rest.", "You should to get some rest.", "You musted rest.", "You are should rest."]'::jsonb,0,'Use should + base verb to give advice.'),
('intermediate-6',4,'Use of English','Choose the best advice.','["You should get some rest.", "You should to get some rest.", "You musted rest.", "You are should rest."]'::jsonb,0,'Use should + base verb to give advice.'),
('intermediate-6',5,'Use of English','Choose the sentence expressing possibility.','["It might rain later.", "It must to rain later.", "It might rains later.", "It is might rain."]'::jsonb,0,'Use might + base verb for possibility.'),
('intermediate-6',6,'Use of English','The lights are on and music is playing. Choose the best deduction.','["They must be at home.", "They must to be at home.", "They were must at home.", "They can being at home."]'::jsonb,0,'“Must be” expresses a strong present deduction.'),
('intermediate-6',7,'Vocabulary','Choose the best Spanish meaning of “ought to”.','["a menos que", "metáfora", "videojuegos", "convendría"]'::jsonb,3,'“ought to” means “convendría” in this context.'),
('intermediate-6',8,'Vocabulary','Choose the best Spanish meaning of “forbidden”.','["prohibido", "nombre", "el año pasado", "directo/brusco"]'::jsonb,0,'“forbidden” means “prohibido” in this context.'),
('intermediate-6',9,'Vocabulary','Choose the best Spanish meaning of “good morning”.','["buenos días", "mencionar", "el fin de semana", "cuestionar una afirmación"]'::jsonb,0,'“good morning” means “buenos días” in this context.'),
('intermediate-6',10,'Vocabulary','Choose the best Spanish meaning of “appointment”.','["seguir recto", "acción comunitaria", "cita", "implicatura"]'::jsonb,2,'“appointment” means “cita” in this context.'),
('intermediate-6',11,'Communication','Which communicative objective belongs especially to INT-06?','["sustain longer interaction", "recommend destinations or activities", "produce connected spoken and written texts", "give basic personal information"]'::jsonb,0,'This cycle explicitly develops the ability to sustain longer interaction.'),
('intermediate-6',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Create a practical recommendation guide.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('intermediate-7',1,'Use of English','Choose the correct zero conditional.','["If you heat ice, it melts.", "If you will heat ice, it melts.", "If you heated ice, it will melt always.", "If heat ice, melts."]'::jsonb,0,'The zero conditional commonly uses present simple in both clauses.'),
('intermediate-7',2,'Use of English','Choose the correct first conditional.','["If it rains, we will stay inside.", "If it will rain, we stay inside.", "If it rained, we will stayed inside.", "If rain, we would stay."]'::jsonb,0,'Use present simple after if and will + base verb in the result clause.'),
('intermediate-7',3,'Use of English','Choose the sentence with the same meaning as “If you do not hurry, you will miss the bus.”','["Unless you hurry, you will miss the bus.", "Unless you do not hurry, you will miss the bus.", "Unless you hurried, you miss the bus yesterday.", "Unless hurry, you would missed it."]'::jsonb,0,'“Unless” means “if not”.'),
('intermediate-7',4,'Use of English','Which option best describes the focus “as soon as”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops as soon as through form, meaning and communicative use.'),
('intermediate-7',5,'Use of English','Which option best describes the focus “when/until in future clauses”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops when/until in future clauses through form, meaning and communicative use.'),
('intermediate-7',6,'Use of English','Choose the correct zero conditional.','["If you heat ice, it melts.", "If you will heat ice, it melts.", "If you heated ice, it will melt always.", "If heat ice, melts."]'::jsonb,0,'The zero conditional commonly uses present simple in both clauses.'),
('intermediate-7',7,'Vocabulary','Choose the best Spanish meaning of “responsibility”.','["preparar la cena", "lleno de gente", "responsabilidad", "resultado"]'::jsonb,2,'“responsibility” means “responsabilidad” in this context.'),
('intermediate-7',8,'Vocabulary','Choose the best Spanish meaning of “wellbeing”.','["previsión", "bienestar", "billete de ida y vuelta", "rutina de sueño"]'::jsonb,1,'“wellbeing” means “bienestar” in this context.'),
('intermediate-7',9,'Vocabulary','Choose the best Spanish meaning of “age”.','["edad", "inteligencia artificial", "reunirse con amigos", "subyacente"]'::jsonb,0,'“age” means “edad” in this context.'),
('intermediate-7',10,'Vocabulary','Choose the best Spanish meaning of “unless”.','["a menos que", "vacaciones", "llegar", "decir a alguien que"]'::jsonb,0,'“unless” means “a menos que” in this context.'),
('intermediate-7',11,'Communication','Which communicative objective belongs especially to INT-07?','["say where you are from", "describe yesterday", "sustain longer interaction", "express preferences"]'::jsonb,2,'This cycle explicitly develops the ability to sustain longer interaction.'),
('intermediate-7',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Design an awareness campaign.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('intermediate-8',1,'Use of English','Choose the correct hypothetical sentence.','["If I had more time, I would learn Welsh.", "If I have more time, I would learned Welsh.", "If I will have time, I learn Welsh.", "If I had time, I will learn Welsh."]'::jsonb,0,'The second conditional uses past simple + would + base verb.'),
('intermediate-8',2,'Use of English','Choose the sentence expressing a present wish.','["I wish I knew the answer.", "I wish I know the answer yesterday.", "I wish I will know the answer.", "I wish knowing the answer."]'::jsonb,0,'A present unreal wish commonly uses a past form.'),
('intermediate-8',3,'Use of English','Choose the most standard hypothetical advice.','["If I was you, I will apologise.", "If I were you, I would apologise.", "If I am you, I apologised.", "If I be you, I apologise."]'::jsonb,1,'“If I were you, I would…” is the conventional form for hypothetical advice.'),
('intermediate-8',4,'Use of English','Choose the most standard hypothetical advice.','["If I was you, I will apologise.", "If I were you, I would apologise.", "If I am you, I apologised.", "If I be you, I apologise."]'::jsonb,1,'“If I were you, I would…” is the conventional form for hypothetical advice.'),
('intermediate-8',5,'Use of English','Choose the correct hypothetical sentence.','["If I had more time, I would learn Welsh.", "If I have more time, I would learned Welsh.", "If I will have time, I learn Welsh.", "If I had time, I will learn Welsh."]'::jsonb,0,'The second conditional uses past simple + would + base verb.'),
('intermediate-8',6,'Use of English','Choose the sentence expressing a present wish.','["I wish I knew the answer.", "I wish I know the answer yesterday.", "I wish I will know the answer.", "I wish knowing the answer."]'::jsonb,0,'A present unreal wish commonly uses a past form.'),
('intermediate-8',7,'Vocabulary','Choose the best Spanish meaning of “please”.','["coherente con", "viabilidad", "mejorar", "por favor"]'::jsonb,3,'“please” means “por favor” in this context.'),
('intermediate-8',8,'Vocabulary','Choose the best Spanish meaning of “surname”.','["apellido", "voz narrativa", "al final", "acción de seguimiento"]'::jsonb,0,'“surname” means “apellido” in this context.'),
('intermediate-8',9,'Vocabulary','Choose the best Spanish meaning of “consequence”.','["previsión", "lata", "asignar recursos", "consecuencia"]'::jsonb,3,'“consequence” means “consecuencia” in this context.'),
('intermediate-8',10,'Vocabulary','Choose the best Spanish meaning of “teacher”.','["joven", "tomar medidas", "todavía/ya", "docente"]'::jsonb,3,'“teacher” means “docente” in this context.'),
('intermediate-8',11,'Communication','Which communicative objective belongs especially to INT-08?','["describe photographs", "order food", "understand basic instructions", "sustain longer interaction"]'::jsonb,3,'This cycle explicitly develops the ability to sustain longer interaction.'),
('intermediate-8',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Solve a problem through hypothetical proposals.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('intermediate-9',1,'Use of English','Choose the correct passive sentence.','["The product makes in Britain.", "The product is made in Britain.", "The product is make in Britain.", "The product made by Britain every."]'::jsonb,1,'The passive is be + past participle.'),
('intermediate-9',2,'Use of English','Choose the correct passive sentence.','["The product makes in Britain.", "The product is made in Britain.", "The product is make in Britain.", "The product made by Britain every."]'::jsonb,1,'The passive is be + past participle.'),
('intermediate-9',3,'Use of English','Which option best describes the focus “process description”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops process description through form, meaning and communicative use.'),
('intermediate-9',4,'Use of English','Which option best describes the focus “agent omission”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops agent omission through form, meaning and communicative use.'),
('intermediate-9',5,'Use of English','Choose the correct passive sentence.','["The product makes in Britain.", "The product is made in Britain.", "The product is make in Britain.", "The product made by Britain every."]'::jsonb,1,'The passive is be + past participle.'),
('intermediate-9',6,'Use of English','Choose the correct passive sentence.','["The product makes in Britain.", "The product is made in Britain.", "The product is make in Britain.", "The product made by Britain every."]'::jsonb,1,'The passive is be + past participle.'),
('intermediate-9',7,'Vocabulary','Choose the best Spanish meaning of “deliver”.','["impacto", "entregar", "verduras", "empezar a trabajar"]'::jsonb,1,'“deliver” means “entregar” in this context.'),
('intermediate-9',8,'Vocabulary','Choose the best Spanish meaning of “be carried out”.','["plato principal", "ser realizado", "hasta cierto punto", "temporalmente"]'::jsonb,1,'“be carried out” means “ser realizado” in this context.'),
('intermediate-9',9,'Vocabulary','Choose the best Spanish meaning of “report”.','["directo/brusco", "dirección", "aspecto por mejorar", "informar"]'::jsonb,3,'“report” means “informar” in this context.'),
('intermediate-9',10,'Vocabulary','Choose the best Spanish meaning of “I’ll…”.','["Haré…", "síntoma", "tocar la guitarra", "empezar a trabajar"]'::jsonb,0,'“I’ll…” means “Haré…” in this context.'),
('intermediate-9',11,'Communication','Which communicative objective belongs especially to INT-09?','["sustain longer interaction", "contrast routines and current actions", "ask about past experiences", "produce connected spoken and written texts"]'::jsonb,0,'This cycle explicitly develops the ability to sustain longer interaction.'),
('intermediate-9',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Explain a process through a visual presentation.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('intermediate-10',1,'Use of English','Direct speech: “I am tired,” she said. Choose the reported form.','["She said that she was tired.", "She said that I am tired.", "She told that she tired.", "She said she is tire yesterday."]'::jsonb,0,'In past reporting, present “am” commonly backshifts to “was”.'),
('intermediate-10',2,'Use of English','Direct speech: “I am tired,” she said. Choose the reported form.','["She said that she was tired.", "She said that I am tired.", "She told that she tired.", "She said she is tire yesterday."]'::jsonb,0,'In past reporting, present “am” commonly backshifts to “was”.'),
('intermediate-10',3,'Use of English','Direct speech: “I am tired,” she said. Choose the reported form.','["She said that she was tired.", "She said that I am tired.", "She told that she tired.", "She said she is tire yesterday."]'::jsonb,0,'In past reporting, present “am” commonly backshifts to “was”.'),
('intermediate-10',4,'Use of English','Which option best describes the focus “time and reference changes”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops time and reference changes through form, meaning and communicative use.'),
('intermediate-10',5,'Use of English','Choose the correct pattern.','["He suggested to leave early.", "He suggested leaving early.", "He suggested us leave early to.", "He suggest that left."]'::jsonb,1,'“Suggest” can be followed by a gerund: suggest doing.'),
('intermediate-10',6,'Use of English','Direct speech: “I am tired,” she said. Choose the reported form.','["She said that she was tired.", "She said that I am tired.", "She told that she tired.", "She said she is tire yesterday."]'::jsonb,0,'In past reporting, present “am” commonly backshifts to “was”.'),
('intermediate-10',7,'Vocabulary','Choose the best Spanish meaning of “warn”.','["cambio climático", "estaba caminando", "advertir", "joven"]'::jsonb,2,'“warn” means “advertir” in this context.'),
('intermediate-10',8,'Vocabulary','Choose the best Spanish meaning of “tell someone to”.','["precisión gramatical", "decir a alguien que", "entrada", "energía renovable"]'::jsonb,1,'“tell someone to” means “decir a alguien que” in this context.'),
('intermediate-10',9,'Vocabulary','Choose the best Spanish meaning of “misunderstanding”.','["malentendido", "ser aficionado a", "nombre", "empezar a trabajar"]'::jsonb,0,'“misunderstanding” means “malentendido” in this context.'),
('intermediate-10',10,'Vocabulary','Choose the best Spanish meaning of “deadline”.','["fecha límite", "asistir", "preparar la cena", "casa"]'::jsonb,0,'“deadline” means “fecha límite” in this context.'),
('intermediate-10',11,'Communication','Which communicative objective belongs especially to INT-10?','["accept and refuse suggestions", "sustain longer interaction", "describe a celebration", "produce connected spoken and written texts"]'::jsonb,1,'This cycle explicitly develops the ability to sustain longer interaction.'),
('intermediate-10',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Write and present a report based on interviews.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('intermediate-11',1,'Use of English','Choose the correct defining relative clause.','["The woman which works here is a lawyer.", "The woman who works here is a lawyer.", "The woman, who works here is a lawyer.", "The woman who she works here is a lawyer."]'::jsonb,1,'Use “who” for people; do not repeat the subject pronoun.'),
('intermediate-11',2,'Use of English','Choose the correct defining relative clause.','["The woman which works here is a lawyer.", "The woman who works here is a lawyer.", "The woman, who works here is a lawyer.", "The woman who she works here is a lawyer."]'::jsonb,1,'Use “who” for people; do not repeat the subject pronoun.'),
('intermediate-11',3,'Use of English','Choose the correct sentence.','["I decided studying law.", "I decided to study law.", "I decided study law.", "I decided to studying law."]'::jsonb,1,'“Decide” is followed by the to-infinitive.'),
('intermediate-11',4,'Use of English','Choose the closest meaning of “carry out” in “carry out research”.','["cancel", "perform", "discover accidentally", "postpone"]'::jsonb,1,'“Carry out” means perform or conduct.'),
('intermediate-11',5,'Use of English','Choose the connector that introduces a contrast.','["Therefore", "However", "For example", "As a result"]'::jsonb,1,'“However” introduces contrast.'),
('intermediate-11',6,'Use of English','Choose the correct defining relative clause.','["The woman which works here is a lawyer.", "The woman who works here is a lawyer.", "The woman, who works here is a lawyer.", "The woman who she works here is a lawyer."]'::jsonb,1,'Use “who” for people; do not repeat the subject pronoun.'),
('intermediate-11',7,'Vocabulary','Choose the best Spanish meaning of “evidence”.','["alcance", "evidencia", "nunca", "realizar"]'::jsonb,1,'“evidence” means “evidencia” in this context.'),
('intermediate-11',8,'Vocabulary','Choose the best Spanish meaning of “tall”.','["explicar", "convincente", "alto/a", "casi nunca"]'::jsonb,2,'“tall” means “alto/a” in this context.'),
('intermediate-11',9,'Vocabulary','Choose the best Spanish meaning of “although”.','["implicatura", "aunque", "aceptar", "¿Le gustaría…?"]'::jsonb,1,'“although” means “aunque” in this context.'),
('intermediate-11',10,'Vocabulary','Choose the best Spanish meaning of “in addition”.','["concientización", "además", "agua sin gas", "bajo ninguna circunstancia"]'::jsonb,1,'“in addition” means “además” in this context.'),
('intermediate-11',11,'Communication','Which communicative objective belongs especially to INT-11?','["sustain longer interaction", "describe yesterday", "give a basic physical description", "describe a celebration"]'::jsonb,0,'This cycle explicitly develops the ability to sustain longer interaction.'),
('intermediate-11',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Write a well-connected opinion article.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('intermediate-12',1,'Use of English','Which option best describes the focus “B1 tense integration”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops B1 tense integration through form, meaning and communicative use.'),
('intermediate-12',2,'Use of English','Which option best describes the focus “functional review”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops functional review through form, meaning and communicative use.'),
('intermediate-12',3,'Use of English','Choose the connector that introduces a contrast.','["Therefore", "However", "For example", "As a result"]'::jsonb,1,'“However” introduces contrast.'),
('intermediate-12',4,'Use of English','Which action best demonstrates mediation?','["Repeating a technical text word for word.", "Explaining the key points in simpler language for a new audience.", "Ignoring the audience’s needs.", "Translating every word literally without context."]'::jsonb,1,'Mediation involves adapting and relaying meaning for another person or group.'),
('intermediate-12',5,'Use of English','Which option best describes the focus “B1 tense integration”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops B1 tense integration through form, meaning and communicative use.'),
('intermediate-12',6,'Use of English','Which option best describes the focus “functional review”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops functional review through form, meaning and communicative use.'),
('intermediate-12',7,'Vocabulary','Choose the best Spanish meaning of “community action”.','["acción comunitaria", "registro", "premisa", "campaña"]'::jsonb,0,'“community action” means “acción comunitaria” in this context.'),
('intermediate-12',8,'Vocabulary','Choose the best Spanish meaning of “area for improvement”.','["aspecto por mejorar", "comida para llevar", "acostarse", "afirmar"]'::jsonb,0,'“area for improvement” means “aspecto por mejorar” in this context.'),
('intermediate-12',9,'Vocabulary','Choose the best Spanish meaning of “decision”.','["el año pasado", "decisión", "hijo", "inteligencia artificial"]'::jsonb,1,'“decision” means “decisión” in this context.'),
('intermediate-12',10,'Vocabulary','Choose the best Spanish meaning of “suggest”.','["concientización", "sugerir", "punto de giro", "carrera/título"]'::jsonb,1,'“suggest” means “sugerir” in this context.'),
('intermediate-12',11,'Communication','Which communicative objective belongs especially to INT-12?','["say where you are from", "talk about weekends", "spell names and key words", "sustain longer interaction"]'::jsonb,3,'This cycle explicitly develops the ability to sustain longer interaction.'),
('intermediate-12',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Create and defend a proposal to improve a community, institution or service.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('advanced-1',1,'Use of English','Which option best describes the focus “tense contrast”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops tense contrast through form, meaning and communicative use.'),
('advanced-1',2,'Use of English','Which phrase explicitly introduces a reformulation?','["In other words,", "Nevertheless,", "For instance,", "Meanwhile,"]'::jsonb,0,'“In other words” restates an idea in a different way.'),
('advanced-1',3,'Use of English','Which option best describes the focus “discourse markers”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops discourse markers through form, meaning and communicative use.'),
('advanced-1',4,'Use of English','Choose the natural collocation.','["make a decision", "do a decision", "create a decision strongly", "perform a decision"]'::jsonb,0,'English normally uses “make a decision”.'),
('advanced-1',5,'Use of English','Which option best describes the focus “tense contrast”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops tense contrast through form, meaning and communicative use.'),
('advanced-1',6,'Use of English','Which phrase explicitly introduces a reformulation?','["In other words,", "Nevertheless,", "For instance,", "Meanwhile,"]'::jsonb,0,'“In other words” restates an idea in a different way.'),
('advanced-1',7,'Vocabulary','Choose the best Spanish meaning of “understand”.','["mejorar", "viaje corto", "permitido", "entender"]'::jsonb,3,'“understand” means “entender” in this context.'),
('advanced-1',8,'Vocabulary','Choose the best Spanish meaning of “therefore”.','["por lo tanto", "tomar medidas", "materia prima", "deber obligatorio"]'::jsonb,0,'“therefore” means “por lo tanto” in this context.'),
('advanced-1',9,'Vocabulary','Choose the best Spanish meaning of “significant”.','["evidencia", "tentativo", "extraer una conclusión", "significativo"]'::jsonb,3,'“significant” means “significativo” in this context.'),
('advanced-1',10,'Vocabulary','Choose the best Spanish meaning of “relevant”.','["mejorar", "pertinente", "mediar", "arroz"]'::jsonb,1,'“relevant” means “pertinente” in this context.'),
('advanced-1',11,'Communication','Which communicative objective belongs especially to ADV-01?','["greet and introduce yourself", "communicate complex ideas precisely", "argue, reformulate and mediate", "express food preferences"]'::jsonb,1,'This cycle explicitly develops the ability to communicate complex ideas precisely.'),
('advanced-1',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Participate in a panel discussion.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('advanced-2',1,'Use of English','Complete: “This time tomorrow, I ___ to London.”','["travel", "will be travelling", "will have travelled", "am travelled"]'::jsonb,1,'The future continuous is will be + verb-ing.'),
('advanced-2',2,'Use of English','Complete: “By Friday, we ___ the report.”','["finish", "will finish", "will have finished", "are finishing yesterday"]'::jsonb,2,'The future perfect is will have + past participle.'),
('advanced-2',3,'Use of English','The lights are on and music is playing. Choose the best deduction.','["They must be at home.", "They must to be at home.", "They were must at home.", "They can being at home."]'::jsonb,0,'“Must be” expresses a strong present deduction.'),
('advanced-2',4,'Use of English','Choose the best deduction about the past.','["She must have forgotten the meeting.", "She must forgot the meeting.", "She must to have forget.", "She was must forgetting."]'::jsonb,0,'Modal perfect: modal + have + past participle.'),
('advanced-2',5,'Use of English','Complete: “This time tomorrow, I ___ to London.”','["travel", "will be travelling", "will have travelled", "am travelled"]'::jsonb,1,'The future continuous is will be + verb-ing.'),
('advanced-2',6,'Use of English','Complete: “By Friday, we ___ the report.”','["finish", "will finish", "will have finished", "are finishing yesterday"]'::jsonb,2,'The future perfect is will have + past participle.'),
('advanced-2',7,'Vocabulary','Choose the best Spanish meaning of “artificial intelligence”.','["contraargumento", "evidencia", "inteligencia artificial", "fecha límite"]'::jsonb,2,'“artificial intelligence” means “inteligencia artificial” in this context.'),
('advanced-2',8,'Vocabulary','Choose the best Spanish meaning of “methodology”.','["asignar recursos", "empezar a trabajar", "reducir", "metodología"]'::jsonb,3,'“methodology” means “metodología” in this context.'),
('advanced-2',9,'Vocabulary','Choose the best Spanish meaning of “practise”.','["practicar", "inequívoco", "enfatizar", "significativo"]'::jsonb,0,'“practise” means “practicar” in this context.'),
('advanced-2',10,'Vocabulary','Choose the best Spanish meaning of “scenario”.','["escenario", "disponible", "asignar recursos", "explicar"]'::jsonb,0,'“scenario” means “escenario” in this context.'),
('advanced-2',11,'Communication','Which communicative objective belongs especially to ADV-02?','["communicate complex ideas precisely", "talk about temporary situations", "explain ideas with supporting detail", "say where you are from"]'::jsonb,0,'This cycle explicitly develops the ability to communicate complex ideas precisely.'),
('advanced-2',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Produce a reasoned prediction report.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('advanced-3',1,'Use of English','Choose the correct third conditional.','["If I had studied, I would have passed.", "If I studied, I would have passed yesterday.", "If I had study, I will pass.", "If I would study, I had passed."]'::jsonb,0,'The third conditional uses if + past perfect, would have + past participle.'),
('advanced-3',2,'Use of English','Choose the mixed conditional linking a past cause to a present result.','["If I had taken that job, I would live in Edinburgh now.", "If I take that job, I lived in Edinburgh now.", "If I would take the job, I had lived there.", "If I have taken it, I would lived there."]'::jsonb,0,'Past perfect in the if-clause can combine with would + base verb for a present result.'),
('advanced-3',3,'Use of English','Choose the sentence expressing a present wish.','["I wish I knew the answer.", "I wish I know the answer yesterday.", "I wish I will know the answer.", "I wish knowing the answer."]'::jsonb,0,'A present unreal wish commonly uses a past form.'),
('advanced-3',4,'Use of English','Choose the sentence expressing regret about the past.','["I wish I had listened to you.", "I wish I listen to you yesterday.", "I wish I would listened yesterday.", "I wish I have listen."]'::jsonb,0,'Use wish + past perfect for regret about a past event.'),
('advanced-3',5,'Use of English','Choose the correct third conditional.','["If I had studied, I would have passed.", "If I studied, I would have passed yesterday.", "If I had study, I will pass.", "If I would study, I had passed."]'::jsonb,0,'The third conditional uses if + past perfect, would have + past participle.'),
('advanced-3',6,'Use of English','Choose the mixed conditional linking a past cause to a present result.','["If I had taken that job, I would live in Edinburgh now.", "If I take that job, I lived in Edinburgh now.", "If I would take the job, I had lived there.", "If I have taken it, I would lived there."]'::jsonb,0,'Past perfect in the if-clause can combine with would + base verb for a present result.'),
('advanced-3',7,'Vocabulary','Choose the best Spanish meaning of “age”.','["paquete", "abrigo", "edad", "normalmente"]'::jsonb,2,'“age” means “edad” in this context.'),
('advanced-3',8,'Vocabulary','Choose the best Spanish meaning of “unless”.','["a menos que", "disponible", "clase magistral", "hacer la tarea"]'::jsonb,0,'“unless” means “a menos que” in this context.'),
('advanced-3',9,'Vocabulary','Choose the best Spanish meaning of “spell”.','["postular a", "al final", "deletrear", "trabajo remoto"]'::jsonb,2,'“spell” means “deletrear” in this context.'),
('advanced-3',10,'Vocabulary','Choose the best Spanish meaning of “hello”.','["cuenta", "sugiere firmemente", "en curso", "hola"]'::jsonb,3,'“hello” means “hola” in this context.'),
('advanced-3',11,'Communication','Which communicative objective belongs especially to ADV-03?','["talk about weekends", "describe yesterday", "communicate complex ideas precisely", "ask about habits"]'::jsonb,2,'This cycle explicitly develops the ability to communicate complex ideas precisely.'),
('advanced-3',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Analyse decisions and propose alternative outcomes.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('advanced-4',1,'Use of English','Choose the correct advanced passive.','["The decision is expected to be announced tomorrow.", "The decision expects announce tomorrow.", "It expects the decision announce tomorrow.", "The decision is expect announcing."]'::jsonb,0,'The passive reporting pattern is subject + be + past participle + to-infinitive.'),
('advanced-4',2,'Use of English','Choose the sentence meaning that a professional repaired the car for me.','["I repaired my car myself.", "I had my car repaired.", "I had repaired my car before.", "I made my car to repair."]'::jsonb,1,'Have + object + past participle expresses a service arranged for you.'),
('advanced-4',3,'Use of English','Choose the correct pattern.','["He suggested to leave early.", "He suggested leaving early.", "He suggested us leave early to.", "He suggest that left."]'::jsonb,1,'“Suggest” can be followed by a gerund: suggest doing.'),
('advanced-4',4,'Use of English','Choose the correct impersonal reporting structure.','["It is believed that the policy will change.", "It believes that policy change.", "It is believe the policy to change.", "There believes the policy changes."]'::jsonb,0,'Use “It is believed that…” for impersonal reporting.'),
('advanced-4',5,'Use of English','Choose the correct advanced passive.','["The decision is expected to be announced tomorrow.", "The decision expects announce tomorrow.", "It expects the decision announce tomorrow.", "The decision is expect announcing."]'::jsonb,0,'The passive reporting pattern is subject + be + past participle + to-infinitive.'),
('advanced-4',6,'Use of English','Choose the sentence meaning that a professional repaired the car for me.','["I repaired my car myself.", "I had my car repaired.", "I had repaired my car before.", "I made my car to repair."]'::jsonb,1,'Have + object + past participle expresses a service arranged for you.'),
('advanced-4',7,'Vocabulary','Choose the best Spanish meaning of “according to”.','["según", "desafío", "implicatura", "clase magistral"]'::jsonb,0,'“according to” means “según” in this context.'),
('advanced-4',8,'Vocabulary','Choose the best Spanish meaning of “claim”.','["ya", "afirmar", "sugiere firmemente", "propuesta"]'::jsonb,1,'“claim” means “afirmar” in this context.'),
('advanced-4',9,'Vocabulary','Choose the best Spanish meaning of “implication”.','["casi nunca", "implicación", "entregable", "entre"]'::jsonb,1,'“implication” means “implicación” in this context.'),
('advanced-4',10,'Vocabulary','Choose the best Spanish meaning of “raw material”.','["argumento", "materia prima", "hija", "implicatura"]'::jsonb,1,'“raw material” means “materia prima” in this context.'),
('advanced-4',11,'Communication','Which communicative objective belongs especially to ADV-04?','["ask about daily activities", "ask about prices and quantities", "communicate complex ideas precisely", "greet and introduce yourself"]'::jsonb,2,'This cycle explicitly develops the ability to communicate complex ideas precisely.'),
('advanced-4',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Write a formal evidence-based report.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('advanced-5',1,'Use of English','Choose the best reduced clause.','["Having reviewed the evidence, the panel reached a decision.", "Having review the evidence, the panel reached.", "The panel having was reviewed evidence reached.", "Reviewed the evidence, it the panel decided."]'::jsonb,0,'“Having + past participle” can show an earlier completed action.'),
('advanced-5',2,'Use of English','Which option best describes the focus “relative clauses”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops relative clauses through form, meaning and communicative use.'),
('advanced-5',3,'Use of English','Choose the best deduction about the past.','["She must have forgotten the meeting.", "She must forgot the meeting.", "She must to have forget.", "She was must forgetting."]'::jsonb,0,'Modal perfect: modal + have + past participle.'),
('advanced-5',4,'Use of English','Choose the connector that introduces a contrast.','["Therefore", "However", "For example", "As a result"]'::jsonb,1,'“However” introduces contrast.'),
('advanced-5',5,'Use of English','Choose the best reduced clause.','["Having reviewed the evidence, the panel reached a decision.", "Having review the evidence, the panel reached.", "The panel having was reviewed evidence reached.", "Reviewed the evidence, it the panel decided."]'::jsonb,0,'“Having + past participle” can show an earlier completed action.'),
('advanced-5',6,'Use of English','Which option best describes the focus “relative clauses”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops relative clauses through form, meaning and communicative use.'),
('advanced-5',7,'Vocabulary','Choose the best Spanish meaning of “student”.','["predicción", "recomendación", "estudiante", "atenuación"]'::jsonb,2,'“student” means “estudiante” in this context.'),
('advanced-5',8,'Vocabulary','Choose the best Spanish meaning of “understand”.','["entender", "cerca", "etapa", "en conjunto"]'::jsonb,0,'“understand” means “entender” in this context.'),
('advanced-5',9,'Vocabulary','Choose the best Spanish meaning of “deliver”.','["debería", "idiomático", "entregar", "participar en"]'::jsonb,2,'“deliver” means “entregar” in this context.'),
('advanced-5',10,'Vocabulary','Choose the best Spanish meaning of “on balance”.','["enfoque crítico", "puede que", "recurso retórico", "en conjunto"]'::jsonb,3,'“on balance” means “en conjunto” in this context.'),
('advanced-5',11,'Communication','Which communicative objective belongs especially to ADV-05?','["communicate complex ideas precisely", "talk about past events", "express likes and preferences", "express frequency"]'::jsonb,0,'This cycle explicitly develops the ability to communicate complex ideas precisely.'),
('advanced-5',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Research a problem, write an argumentative essay and defend a position.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('advanced-6',1,'Use of English','Which sentence is appropriately cautious?','["This proves the policy is always wrong.", "The findings may suggest that the policy has limitations.", "The policy is obviously useless to everyone.", "There is no possible alternative interpretation."]'::jsonb,1,'“May suggest” appropriately limits the strength of the claim.'),
('advanced-6',2,'Use of English','Which phrase strengthens a claim?','["might possibly indicate", "strongly demonstrates", "perhaps suggests", "could be interpreted as"]'::jsonb,1,'“Strongly demonstrates” is a booster that increases certainty.'),
('advanced-6',3,'Use of English','Which option best describes the focus “stance structures”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops stance structures through form, meaning and communicative use.'),
('advanced-6',4,'Use of English','Choose the most nominalised academic version.','["The committee decided quickly.", "The committee’s rapid decision affected the outcome.", "The committee was deciding and it was quick.", "Quickly, decide the committee."]'::jsonb,1,'“Decision” converts the verb “decide” into a noun, creating a denser academic style.'),
('advanced-6',5,'Use of English','Which sentence is appropriately cautious?','["This proves the policy is always wrong.", "The findings may suggest that the policy has limitations.", "The policy is obviously useless to everyone.", "There is no possible alternative interpretation."]'::jsonb,1,'“May suggest” appropriately limits the strength of the claim.'),
('advanced-6',6,'Use of English','Which phrase strengthens a claim?','["might possibly indicate", "strongly demonstrates", "perhaps suggests", "could be interpreted as"]'::jsonb,1,'“Strongly demonstrates” is a booster that increases certainty.'),
('advanced-6',7,'Vocabulary','Choose the best Spanish meaning of “underlying”.','["apellido", "alacena", "tentativo", "subyacente"]'::jsonb,3,'“underlying” means “subyacente” in this context.'),
('advanced-6',8,'Vocabulary','Choose the best Spanish meaning of “evidence”.','["reunirse con amigos", "evidencia", "afirmación", "por lo tanto"]'::jsonb,1,'“evidence” means “evidencia” in this context.'),
('advanced-6',9,'Vocabulary','Choose the best Spanish meaning of “methodology”.','["metodología", "carrera/título", "integración de fuentes", "permitido"]'::jsonb,0,'“methodology” means “metodología” in this context.'),
('advanced-6',10,'Vocabulary','Choose the best Spanish meaning of “language”.','["ocurrir", "fecha límite", "idioma", "tono"]'::jsonb,2,'“language” means “idioma” in this context.'),
('advanced-6',11,'Communication','Which communicative objective belongs especially to ADV-06?','["explain ideas with supporting detail", "ask about prices and quantities", "communicate complex ideas precisely", "exchange personal information"]'::jsonb,2,'This cycle explicitly develops the ability to communicate complex ideas precisely.'),
('advanced-6',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Write and present an academic analysis.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('advanced-7',1,'Use of English','Choose the correct inversion.','["Never I have seen such a result.", "Never have I seen such a result.", "Never I seen have such result.", "I never have saw such a result."]'::jsonb,1,'After a negative adverbial at the beginning, invert auxiliary and subject.'),
('advanced-7',2,'Use of English','Which sentence is a cleft sentence?','["The evidence matters most.", "What matters most is the evidence.", "The evidence, it matters most.", "Most matters the evidence."]'::jsonb,1,'A wh-cleft uses “What… is…”.'),
('advanced-7',3,'Use of English','Which sentence uses fronting for emphasis?','["I found the conclusion particularly striking.", "Particularly striking was the conclusion.", "The conclusion particularly was striking found.", "Was the conclusion striking particularly?"]'::jsonb,1,'The complement is placed first to create emphasis.'),
('advanced-7',4,'Use of English','Choose the sentence using substitution to avoid repetition.','["I prefer the blue proposal to the red proposal.", "I prefer the blue proposal to the red one.", "I prefer blue to red proposal one it.", "I prefer the blue so red."]'::jsonb,1,'“One” substitutes for a repeated countable noun.'),
('advanced-7',5,'Use of English','Which option best describes the focus “linking”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops linking through form, meaning and communicative use.'),
('advanced-7',6,'Use of English','Choose the correct inversion.','["Never I have seen such a result.", "Never have I seen such a result.", "Never I seen have such result.", "I never have saw such a result."]'::jsonb,1,'After a negative adverbial at the beginning, invert auxiliary and subject.'),
('advanced-7',7,'Vocabulary','Choose the best Spanish meaning of “stance”.','["postura", "decir a alguien que", "aclarar", "previsión"]'::jsonb,0,'“stance” means “postura” in this context.'),
('advanced-7',8,'Vocabulary','Choose the best Spanish meaning of “flawed”.','["fecha límite", "quedar bien de talla", "afirmar", "defectuoso"]'::jsonb,3,'“flawed” means “defectuoso” in this context.'),
('advanced-7',9,'Vocabulary','Choose the best Spanish meaning of “granted that”.','["vecindario", "pronóstico", "admitiendo que", "impacto"]'::jsonb,2,'“granted that” means “admitiendo que” in this context.'),
('advanced-7',10,'Vocabulary','Choose the best Spanish meaning of “rephrase”.','["sala", "reformular", "persuasivo", "esposa"]'::jsonb,1,'“rephrase” means “reformular” in this context.'),
('advanced-7',11,'Communication','Which communicative objective belongs especially to ADV-07?','["talk about routines", "ask about habits", "say dates and telephone numbers", "communicate complex ideas precisely"]'::jsonb,3,'This cycle explicitly develops the ability to communicate complex ideas precisely.'),
('advanced-7',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Transform and deliver a persuasive speech.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('advanced-8',1,'Use of English','Which option best describes the focus “C1 integrated grammar”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops C1 integrated grammar through form, meaning and communicative use.'),
('advanced-8',2,'Use of English','Choose the connector that introduces a contrast.','["Therefore", "However", "For example", "As a result"]'::jsonb,1,'“However” introduces contrast.'),
('advanced-8',3,'Use of English','Which phrase explicitly introduces a reformulation?','["In other words,", "Nevertheless,", "For instance,", "Meanwhile,"]'::jsonb,0,'“In other words” restates an idea in a different way.'),
('advanced-8',4,'Use of English','Choose the most formal version.','["Send me the figures now.", "Could you please provide the figures at your earliest convenience?", "Give us the numbers, OK?", "I want those figures ASAP."]'::jsonb,1,'The second option uses formal, polite professional language.'),
('advanced-8',5,'Use of English','Which option best describes the focus “C1 integrated grammar”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops C1 integrated grammar through form, meaning and communicative use.'),
('advanced-8',6,'Use of English','Choose the connector that introduces a contrast.','["Therefore", "However", "For example", "As a result"]'::jsonb,1,'“However” introduces contrast.'),
('advanced-8',7,'Vocabulary','Choose the best Spanish meaning of “finding”.','["aceptar", "regla de seguridad", "hallazgo", "darse cuenta"]'::jsonb,2,'“finding” means “hallazgo” in this context.'),
('advanced-8',8,'Vocabulary','Choose the best Spanish meaning of “suggest”.','["sugerir", "vecindario", "girar a la izquierda", "reunirse con amigos"]'::jsonb,0,'“suggest” means “sugerir” in this context.'),
('advanced-8',9,'Vocabulary','Choose the best Spanish meaning of “monitor”.','["llovizna", "supervisar", "perder un tren", "entre"]'::jsonb,1,'“monitor” means “supervisar” in this context.'),
('advanced-8',10,'Vocabulary','Choose the best Spanish meaning of “spontaneous interaction”.','["estante", "amplitud léxica", "interacción espontánea", "innovación"]'::jsonb,2,'“spontaneous interaction” means “interacción espontánea” in this context.'),
('advanced-8',11,'Communication','Which communicative objective belongs especially to ADV-08?','["express likes and preferences", "ask for and give directions", "communicate complex ideas precisely", "make invitations"]'::jsonb,2,'This cycle explicitly develops the ability to communicate complex ideas precisely.'),
('advanced-8',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Prepare a C1 portfolio with research, essay, presentation and oral defence.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('proficiency-1',1,'Use of English','Choose the natural collocation.','["make a decision", "do a decision", "create a decision strongly", "perform a decision"]'::jsonb,0,'English normally uses “make a decision”.'),
('proficiency-1',2,'Use of English','Which word is generally more negative in tone?','["slim", "skinny", "slender", "lean"]'::jsonb,1,'“Skinny” often carries a negative connotation.'),
('proficiency-1',3,'Use of English','Choose the most formal version.','["Send me the figures now.", "Could you please provide the figures at your earliest convenience?", "Give us the numbers, OK?", "I want those figures ASAP."]'::jsonb,1,'The second option uses formal, polite professional language.'),
('proficiency-1',4,'Use of English','Choose the idiomatic expression meaning “understand the hidden meaning”.','["read between the lines", "read under the words", "look inside the sentence", "read through the letters"]'::jsonb,0,'“Read between the lines” means infer an implicit meaning.'),
('proficiency-1',5,'Use of English','Choose the natural collocation.','["make a decision", "do a decision", "create a decision strongly", "perform a decision"]'::jsonb,0,'English normally uses “make a decision”.'),
('proficiency-1',6,'Use of English','Which word is generally more negative in tone?','["slim", "skinny", "slender", "lean"]'::jsonb,1,'“Skinny” often carries a negative connotation.'),
('proficiency-1',7,'Vocabulary','Choose the best Spanish meaning of “connotation”.','["durante", "amable", "abrigo", "connotación"]'::jsonb,3,'“connotation” means “connotación” in this context.'),
('proficiency-1',8,'Vocabulary','Choose the best Spanish meaning of “presupposition”.','["presuposición", "resultado", "implicatura", "alusión"]'::jsonb,0,'“presupposition” means “presuposición” in this context.'),
('proficiency-1',9,'Vocabulary','Choose the best Spanish meaning of “grammatical precision”.','["basado en evidencia", "evidencia", "en este momento", "precisión gramatical"]'::jsonb,3,'“grammatical precision” means “precisión gramatical” in this context.'),
('proficiency-1',10,'Vocabulary','Choose the best Spanish meaning of “narrative voice”.','["pantalones", "videojuegos", "ser realizado", "voz narrativa"]'::jsonb,3,'“narrative voice” means “voz narrativa” in this context.'),
('proficiency-1',11,'Communication','Which communicative objective belongs especially to PRO-01?','["describe a home", "make invitations", "ask and answer names", "interpret highly complex meaning"]'::jsonb,3,'This cycle explicitly develops the ability to interpret highly complex meaning.'),
('proficiency-1',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Create an essay and presentation using precise lexical variation.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('proficiency-2',1,'Use of English','In “Even Tom passed the exam”, what is suggested?','["Tom was expected to do very well.", "Tom was considered an unlikely person to pass.", "Nobody else passed.", "The exam did not happen."]'::jsonb,1,'“Even” signals that Tom’s success was relatively unexpected.'),
('proficiency-2',2,'Use of English','In “Even Tom passed the exam”, what is suggested?','["Tom was expected to do very well.", "Tom was considered an unlikely person to pass.", "Nobody else passed.", "The exam did not happen."]'::jsonb,1,'“Even” signals that Tom’s success was relatively unexpected.'),
('proficiency-2',3,'Use of English','A colleague says, “It’s rather warm in here.” In context, this may indirectly mean:','["Please open a window.", "The room is definitely cold.", "I have finished the report.", "Do not speak to me."]'::jsonb,0,'Pragmatic meaning can be indirect and context-dependent.'),
('proficiency-2',4,'Use of English','Choose the connector that introduces a contrast.','["Therefore", "However", "For example", "As a result"]'::jsonb,1,'“However” introduces contrast.'),
('proficiency-2',5,'Use of English','In “Even Tom passed the exam”, what is suggested?','["Tom was expected to do very well.", "Tom was considered an unlikely person to pass.", "Nobody else passed.", "The exam did not happen."]'::jsonb,1,'“Even” signals that Tom’s success was relatively unexpected.'),
('proficiency-2',6,'Use of English','In “Even Tom passed the exam”, what is suggested?','["Tom was expected to do very well.", "Tom was considered an unlikely person to pass.", "Nobody else passed.", "The exam did not happen."]'::jsonb,1,'“Even” signals that Tom’s success was relatively unexpected.'),
('proficiency-2',7,'Vocabulary','Choose the best Spanish meaning of “ambiguity”.','["pronóstico", "padre", "ambigüedad", "alcance"]'::jsonb,2,'“ambiguity” means “ambigüedad” in this context.'),
('proficiency-2',8,'Vocabulary','Choose the best Spanish meaning of “nuanced”.','["matizado", "mencionar", "mientras tanto", "asistir a clase"]'::jsonb,0,'“nuanced” means “matizado” in this context.'),
('proficiency-2',9,'Vocabulary','Choose the best Spanish meaning of “blunt”.','["sugerir", "de repente", "directo/brusco", "decisión"]'::jsonb,2,'“blunt” means “directo/brusco” in this context.'),
('proficiency-2',10,'Vocabulary','Choose the best Spanish meaning of “infer”.','["marco", "durante", "inferir", "aspecto por mejorar"]'::jsonb,2,'“infer” means “inferir” in this context.'),
('proficiency-2',11,'Communication','Which communicative objective belongs especially to PRO-02?','["interpret highly complex meaning", "compare routines", "talk about experiences", "produce connected spoken and written texts"]'::jsonb,0,'This cycle explicitly develops the ability to interpret highly complex meaning.'),
('proficiency-2',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Critically analyse complex speeches, interviews and texts.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('proficiency-3',1,'Use of English','Which sentence best synthesises two sources?','["Source A says X. Source B says Y.", "Taken together, both studies indicate a common trend, although they differ on its cause.", "I copied Source A and then Source B.", "The sources are long and interesting."]'::jsonb,1,'Synthesis identifies a relationship between sources rather than listing them separately.'),
('proficiency-3',2,'Use of English','Which phrase contains a complex nominal group?','["the report", "the recently published independent review of regional policy", "it was reviewed", "reviewing quickly"]'::jsonb,1,'The head noun “review” is expanded by multiple modifiers and a prepositional phrase.'),
('proficiency-3',3,'Use of English','Choose the most formal version.','["Send me the figures now.", "Could you please provide the figures at your earliest convenience?", "Give us the numbers, OK?", "I want those figures ASAP."]'::jsonb,1,'The second option uses formal, polite professional language.'),
('proficiency-3',4,'Use of English','Which action best demonstrates mediation?','["Repeating a technical text word for word.", "Explaining the key points in simpler language for a new audience.", "Ignoring the audience’s needs.", "Translating every word literally without context."]'::jsonb,1,'Mediation involves adapting and relaying meaning for another person or group.'),
('proficiency-3',5,'Use of English','Which sentence best synthesises two sources?','["Source A says X. Source B says Y.", "Taken together, both studies indicate a common trend, although they differ on its cause.", "I copied Source A and then Source B.", "The sources are long and interesting."]'::jsonb,1,'Synthesis identifies a relationship between sources rather than listing them separately.'),
('proficiency-3',6,'Use of English','Which phrase contains a complex nominal group?','["the report", "the recently published independent review of regional policy", "it was reviewed", "reviewing quickly"]'::jsonb,1,'The head noun “review” is expanded by multiple modifiers and a prepositional phrase.'),
('proficiency-3',7,'Vocabulary','Choose the best Spanish meaning of “account for”.','["alguna vez", "tendencia", "explicar", "menú"]'::jsonb,2,'“account for” means “explicar” in this context.'),
('proficiency-3',8,'Vocabulary','Choose the best Spanish meaning of “manufacture”.','["hasta cierto punto", "estudiante", "fabricar", "regla de seguridad"]'::jsonb,2,'“manufacture” means “fabricar” in this context.'),
('proficiency-3',9,'Vocabulary','Choose the best Spanish meaning of “risk assessment”.','["sutil", "normalmente", "evaluación de riesgos", "ahora mismo"]'::jsonb,2,'“risk assessment” means “evaluación de riesgos” in this context.'),
('proficiency-3',10,'Vocabulary','Choose the best Spanish meaning of “ask whether”.','["quien", "preguntar si", "acción de seguimiento", "cuestionar una afirmación"]'::jsonb,1,'“ask whether” means “preguntar si” in this context.'),
('proficiency-3',11,'Communication','Which communicative objective belongs especially to PRO-03?','["interpret highly complex meaning", "argue, reformulate and mediate", "ask about habits", "compare places and objects"]'::jsonb,0,'This cycle explicitly develops the ability to interpret highly complex meaning.'),
('proficiency-3',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Research a topic, synthesise sources and present conclusions to a specialised audience.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.'),
('proficiency-4',1,'Use of English','Which option best describes the focus “full-system grammatical control”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops full-system grammatical control through form, meaning and communicative use.'),
('proficiency-4',2,'Use of English','Which phrase explicitly introduces a reformulation?','["In other words,", "Nevertheless,", "For instance,", "Meanwhile,"]'::jsonb,0,'“In other words” restates an idea in a different way.'),
('proficiency-4',3,'Use of English','Choose the most formal version.','["Send me the figures now.", "Could you please provide the figures at your earliest convenience?", "Give us the numbers, OK?", "I want those figures ASAP."]'::jsonb,1,'The second option uses formal, polite professional language.'),
('proficiency-4',4,'Use of English','A colleague says, “It’s rather warm in here.” In context, this may indirectly mean:','["Please open a window.", "The room is definitely cold.", "I have finished the report.", "Do not speak to me."]'::jsonb,0,'Pragmatic meaning can be indirect and context-dependent.'),
('proficiency-4',5,'Use of English','Which option best describes the focus “full-system grammatical control”?','["Using the form accurately in meaningful context", "Memorising unrelated translations only", "Avoiding complete sentences", "Ignoring register and purpose"]'::jsonb,0,'The cycle develops full-system grammatical control through form, meaning and communicative use.'),
('proficiency-4',6,'Use of English','Which phrase explicitly introduces a reformulation?','["In other words,", "Nevertheless,", "For instance,", "Meanwhile,"]'::jsonb,0,'“In other words” restates an idea in a different way.'),
('proficiency-4',7,'Vocabulary','Choose the best Spanish meaning of “idiomatic”.','["informar", "idiomático", "nunca", "recurso retórico"]'::jsonb,1,'“idiomatic” means “idiomático” in this context.'),
('proficiency-4',8,'Vocabulary','Choose the best Spanish meaning of “valid”.','["válido", "trama", "ya había", "terminar"]'::jsonb,0,'“valid” means “válido” in this context.'),
('proficiency-4',9,'Vocabulary','Choose the best Spanish meaning of “interdisciplinary”.','["tener en cuenta", "en cuanto", "interdisciplinario", "admitiendo que"]'::jsonb,2,'“interdisciplinary” means “interdisciplinario” in this context.'),
('proficiency-4',10,'Vocabulary','Choose the best Spanish meaning of “critical lens”.','["helado", "precisión gramatical", "admitir", "enfoque crítico"]'::jsonb,3,'“critical lens” means “enfoque crítico” in this context.'),
('proficiency-4',11,'Communication','Which communicative objective belongs especially to PRO-04?','["recommend destinations or activities", "introduce another person", "express preferences", "interpret highly complex meaning"]'::jsonb,3,'This cycle explicitly develops the ability to interpret highly complex meaning.'),
('proficiency-4',12,'Integrated task','Which task best represents the final communicative project of this cycle?','["Create and defend a complete C2 portfolio including research, synthesis, academic and professional writing, presentation, debate and mediation.", "Copy an unrelated grammar table without using it.", "Memorise isolated words without producing a text.", "Skip all interaction and assessment."]'::jsonb,0,'The final project integrates the cycle’s language in a meaningful task.')
on conflict (cycle_id,position) do update set
  section=excluded.section,prompt=excluded.prompt,options=excluded.options,
  correct_index=excluded.correct_index,explanation=excluded.explanation,active=true;

-- Comprobación final: debe devolver 37 ciclos y 444 preguntas.
select
  (select count(*) from public.course_cycles) as ciclos,
  (select count(*) from public.exam_questions where active) as preguntas,
  (select count(*) from public.profiles) as usuarios_migrados;
