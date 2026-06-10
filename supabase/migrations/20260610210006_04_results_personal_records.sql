-- ===== Resultados de WOD por atleta =====
create table public.wod_results (
  id uuid primary key default gen_random_uuid(),
  wod_id uuid not null references public.wods(id) on delete cascade,
  athlete_id uuid not null references public.profiles(id) on delete cascade,
  rx_level public.rx_level not null default 'rx',
  time_seconds int,                          -- metcon por tiempo (08:42 → 522)
  reps int,                                  -- "142 reps"
  rounds int,                                -- "15 rondas"
  weight_used_kg numeric(6,2),
  intensity public.athlete_level,            -- Principiante/Intermedio/Avanzado
  athlete_notes text,                        -- "¿Cómo te sentiste hoy?"
  status public.result_status not null default 'pendiente',
  validated_by uuid references public.profiles(id) on delete set null,
  validated_at timestamptz,
  is_pr boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (wod_id, athlete_id)
);

create index idx_wod_results_athlete on public.wod_results(athlete_id);
create index idx_wod_results_wod on public.wod_results(wod_id);
create index idx_wod_results_status on public.wod_results(status);

-- ===== Récords personales (PRs / Marcas) =====
create table public.personal_records (
  id uuid primary key default gen_random_uuid(),
  athlete_id uuid not null references public.profiles(id) on delete cascade,
  exercise_id uuid not null references public.exercises(id) on delete cascade,
  value numeric(8,2) not null,               -- 145 (kg) o 225 (segundos, Fran 3:45)
  score_type public.score_type not null default 'peso',
  rx_level public.rx_level not null default 'rx',
  record_date date not null default current_date,
  athlete_notes text,                        -- "Me sentí muy fuerte hoy..."
  previous_value numeric(8,2),               -- para mostrar "+5kg" y "103.5% del PR previo"
  status public.result_status not null default 'pendiente',
  validated_by uuid references public.profiles(id) on delete set null,
  validated_at timestamptz,
  created_at timestamptz not null default now()
);

create index idx_prs_athlete on public.personal_records(athlete_id);
create index idx_prs_exercise on public.personal_records(exercise_id);
create index idx_prs_status on public.personal_records(status);
create index idx_prs_record_date on public.personal_records(record_date);

create trigger trg_wod_results_updated_at
  before update on public.wod_results
  for each row execute function public.set_updated_at();

-- ===== RLS =====
alter table public.wod_results enable row level security;
alter table public.personal_records enable row level security;

-- Resultados: el atleta ve los suyos; coach ve todos; validados visibles a la comunidad
create policy "Ver resultados propios, validados o como coach"
  on public.wod_results for select to authenticated
  using (athlete_id = auth.uid() or status = 'validado' or public.is_coach());
create policy "El atleta registra su propio resultado"
  on public.wod_results for insert to authenticated
  with check (athlete_id = auth.uid() or public.is_coach());
create policy "Atleta edita su resultado pendiente; coach edita todo"
  on public.wod_results for update to authenticated
  using ((athlete_id = auth.uid() and status = 'pendiente') or public.is_coach())
  with check (athlete_id = auth.uid() or public.is_coach());
create policy "Solo coaches eliminan resultados"
  on public.wod_results for delete to authenticated
  using (public.is_coach());

-- PRs: misma lógica
create policy "Ver PRs propios, validados o como coach"
  on public.personal_records for select to authenticated
  using (athlete_id = auth.uid() or status = 'validado' or public.is_coach());
create policy "El atleta registra su propio PR"
  on public.personal_records for insert to authenticated
  with check (athlete_id = auth.uid() or public.is_coach());
create policy "Atleta edita su PR pendiente; coach edita todo"
  on public.personal_records for update to authenticated
  using ((athlete_id = auth.uid() and status = 'pendiente') or public.is_coach())
  with check (athlete_id = auth.uid() or public.is_coach());
create policy "Solo coaches eliminan PRs"
  on public.personal_records for delete to authenticated
  using (public.is_coach());
