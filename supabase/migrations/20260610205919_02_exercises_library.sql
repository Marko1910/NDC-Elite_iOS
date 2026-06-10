-- ===== Biblioteca Técnica de Ejercicios =====
create type public.exercise_category as enum ('fuerza', 'gimnasia', 'endurance', 'movilidad', 'olimpico');

create table public.exercises (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,                -- "Back Squat"
  name_es text,                             -- "Sentadilla por detrás"
  category public.exercise_category not null,
  difficulty public.athlete_level not null default 'basico',
  description text,
  video_url text,
  image_url text,
  default_score_type public.score_type not null default 'peso',
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Pasos numerados de técnica (Setup / Descenso / Profundidad...)
create table public.exercise_technique_steps (
  id uuid primary key default gen_random_uuid(),
  exercise_id uuid not null references public.exercises(id) on delete cascade,
  step_number int not null,
  title text not null,
  description text,
  unique (exercise_id, step_number)
);

create index idx_technique_steps_exercise on public.exercise_technique_steps(exercise_id);

create trigger trg_exercises_updated_at
  before update on public.exercises
  for each row execute function public.set_updated_at();

-- ===== RLS =====
alter table public.exercises enable row level security;
alter table public.exercise_technique_steps enable row level security;

create policy "Ejercicios visibles para autenticados"
  on public.exercises for select to authenticated using (true);
create policy "Solo coaches gestionan ejercicios"
  on public.exercises for all to authenticated
  using (public.is_coach()) with check (public.is_coach());

create policy "Pasos de técnica visibles para autenticados"
  on public.exercise_technique_steps for select to authenticated using (true);
create policy "Solo coaches gestionan pasos de técnica"
  on public.exercise_technique_steps for all to authenticated
  using (public.is_coach()) with check (public.is_coach());
