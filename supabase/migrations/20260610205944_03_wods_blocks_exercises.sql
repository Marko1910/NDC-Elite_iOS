-- ===== WODs (incluye sesiones de Running) =====
create type public.wod_type as enum ('amrap', 'emom', 'for_time', 'tabata', 'fuerza', 'running', 'hiit');
create type public.wod_status as enum ('borrador', 'publicado', 'archivado');
create type public.block_type as enum ('calentamiento', 'fuerza', 'metcon', 'skill', 'accesorio');

create table public.wods (
  id uuid primary key default gen_random_uuid(),
  title text not null,                       -- "El Desafío Híbrido", "Fondo Dominical"
  scheduled_date date not null,
  wod_type public.wod_type not null,
  status public.wod_status not null default 'borrador',
  focus text,                                -- "Fuerza & Metcon", "Explosividad..."
  description text,
  time_cap_minutes int,
  -- Campos para sesiones de Running
  distance_km numeric(6,2),
  pace_target text,                          -- "4:30 min/km"
  route_url text,                            -- enlace Strava / Google Maps
  is_outdoor boolean not null default false,
  notes text,                                -- calentamiento, hidratación, intervalos
  created_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_wods_scheduled_date on public.wods(scheduled_date);
create index idx_wods_status on public.wods(status);
create index idx_wods_created_by on public.wods(created_by);

-- ===== Bloques del WOD (Calentamiento / Fuerza / Metcon...) =====
create table public.wod_blocks (
  id uuid primary key default gen_random_uuid(),
  wod_id uuid not null references public.wods(id) on delete cascade,
  block_type public.block_type not null,
  title text,                                -- "Calentamiento", "Fuerza / Técnica"
  duration_minutes int,                      -- "12 Minutos"
  rounds int,                                -- "3 Rondas de:"
  score_type public.score_type,              -- "POR TIEMPO"
  time_cap_minutes int,                      -- "Tiempo Límite 20:00"
  position int not null default 1,
  notes text
);

create index idx_wod_blocks_wod on public.wod_blocks(wod_id);

-- ===== Ejercicios dentro de cada bloque =====
create table public.wod_block_exercises (
  id uuid primary key default gen_random_uuid(),
  block_id uuid not null references public.wod_blocks(id) on delete cascade,
  exercise_id uuid references public.exercises(id) on delete set null,
  position int not null default 1,
  prescription text not null,                -- "5 Sets de 3 Reps al 75% RM. Tempo 3-2-X-1"
  rx_load text,                              -- "135/95 lbs", "60/40kg"
  scaled_load text,                          -- "40/25kg"
  coach_cue text                             -- "Enfócate en la estabilidad del core"
);

create index idx_block_exercises_block on public.wod_block_exercises(block_id);
create index idx_block_exercises_exercise on public.wod_block_exercises(exercise_id);

create trigger trg_wods_updated_at
  before update on public.wods
  for each row execute function public.set_updated_at();

-- ===== RLS =====
alter table public.wods enable row level security;
alter table public.wod_blocks enable row level security;
alter table public.wod_block_exercises enable row level security;

-- Atletas ven solo WODs publicados; coaches ven todo (incl. borradores)
create policy "WODs publicados visibles; coach ve todo"
  on public.wods for select to authenticated
  using (status = 'publicado' or public.is_coach());
create policy "Solo coaches gestionan WODs"
  on public.wods for all to authenticated
  using (public.is_coach()) with check (public.is_coach());

create policy "Bloques visibles si el WOD es visible"
  on public.wod_blocks for select to authenticated
  using (exists (
    select 1 from public.wods w
    where w.id = wod_id and (w.status = 'publicado' or public.is_coach())
  ));
create policy "Solo coaches gestionan bloques"
  on public.wod_blocks for all to authenticated
  using (public.is_coach()) with check (public.is_coach());

create policy "Ejercicios de bloque visibles si el WOD es visible"
  on public.wod_block_exercises for select to authenticated
  using (exists (
    select 1 from public.wod_blocks b
    join public.wods w on w.id = b.wod_id
    where b.id = block_id and (w.status = 'publicado' or public.is_coach())
  ));
create policy "Solo coaches gestionan ejercicios de bloque"
  on public.wod_block_exercises for all to authenticated
  using (public.is_coach()) with check (public.is_coach());
