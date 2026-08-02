-- Britannia Path: tabla de progreso por usuario
-- Ejecuta todo este archivo en Supabase > SQL Editor.

create table if not exists public.user_progress (
  user_id uuid primary key references auth.users(id) on delete cascade,
  progress jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.user_progress enable row level security;

-- Evita duplicados si vuelves a ejecutar el archivo.
drop policy if exists "Users can read own progress" on public.user_progress;
drop policy if exists "Users can insert own progress" on public.user_progress;
drop policy if exists "Users can update own progress" on public.user_progress;
drop policy if exists "Users can delete own progress" on public.user_progress;

create policy "Users can read own progress"
on public.user_progress for select
using (auth.uid() = user_id);

create policy "Users can insert own progress"
on public.user_progress for insert
with check (auth.uid() = user_id);

create policy "Users can update own progress"
on public.user_progress for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can delete own progress"
on public.user_progress for delete
using (auth.uid() = user_id);

-- Mantiene updated_at actualizado incluso en cambios directos.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_user_progress_updated_at on public.user_progress;
create trigger set_user_progress_updated_at
before update on public.user_progress
for each row execute function public.set_updated_at();
