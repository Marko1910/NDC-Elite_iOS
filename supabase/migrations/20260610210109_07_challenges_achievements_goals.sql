-- ===== Retos (comunidad e individuales) =====
create type public.challenge_type as enum ('comunidad', 'individual');

create table public.challenges (
  id uuid primary key default gen_random_uuid(),
  title text not null,                       -- "1 Millón de Burpees", "Running Sunday - 5 KM"
  description text,
  challenge_type public.challenge_type not null,
  goal_value numeric(12,2) not null,         -- 1000000, 500, 5
  unit text not null,                        -- 'burpees', 'kg', 'km', 'reps'
  current_value numeric(12,2) not null default 0,  -- progreso colectivo (742k)
  starts_on date,
  ends_on date,
  is_active boolean not null default true,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_challenges_active on public.challenges(is_active);

-- ===== Participantes y su progreso personal (0 / 500) =====
create table public.challenge_participants (
  id uuid primary key default gen_random_uuid(),
  challenge_id uuid not null references public.challenges(id) on delete cascade,
  athlete_id uuid not null references public.profiles(id) on delete cascade,
  progress_value numeric(12,2) not null default 0,
  joined_at timestamptz not null default now(),
  completed_at timestamptz,
  unique (challenge_id, athlete_id)
);

create index idx_challenge_participants_challenge on public.challenge_participants(challenge_id);
create index idx_challenge_participants_athlete on public.challenge_participants(athlete_id);

-- ===== Catálogo de logros / badges =====
create table public.achievements (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,                 -- 'early_bird', 'pr_crusher'...
  title text not null,                       -- "Early Bird", "PR Crusher"
  description text,
  icon text,                                 -- nombre de ícono o URL
  created_at timestamptz not null default now()
);

create table public.athlete_achievements (
  id uuid primary key default gen_random_uuid(),
  athlete_id uuid not null references public.profiles(id) on delete cascade,
  achievement_id uuid not null references public.achievements(id) on delete cascade,
  unlocked_at timestamptz not null default now(),
  unique (athlete_id, achievement_id)
);

create index idx_athlete_achievements_athlete on public.athlete_achievements(athlete_id);

-- ===== Objetivos del atleta (Meta Principal, Próximo Objetivo) =====
create table public.athlete_goals (
  id uuid primary key default gen_random_uuid(),
  athlete_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,                       -- "Muscle Ups (Consecutivos)"
  description text,                          -- "Ganar masa muscular y mejorar estabilidad..."
  target_value numeric(10,2),                -- 10
  current_value numeric(10,2) not null default 0,  -- 8
  unit text,                                 -- 'reps', 'kg'
  is_primary boolean not null default false,
  target_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_athlete_goals_athlete on public.athlete_goals(athlete_id);

create trigger trg_challenges_updated_at
  before update on public.challenges
  for each row execute function public.set_updated_at();
create trigger trg_athlete_goals_updated_at
  before update on public.athlete_goals
  for each row execute function public.set_updated_at();

-- ===== RLS =====
alter table public.challenges enable row level security;
alter table public.challenge_participants enable row level security;
alter table public.achievements enable row level security;
alter table public.athlete_achievements enable row level security;
alter table public.athlete_goals enable row level security;

create policy "Retos visibles para autenticados"
  on public.challenges for select to authenticated using (true);
create policy "Solo coaches gestionan retos"
  on public.challenges for all to authenticated
  using (public.is_coach()) with check (public.is_coach());

create policy "Participantes visibles para autenticados"
  on public.challenge_participants for select to authenticated using (true);
create policy "Atleta se une a retos"
  on public.challenge_participants for insert to authenticated
  with check (athlete_id = auth.uid() or public.is_coach());
create policy "Atleta actualiza su progreso; coach cualquiera"
  on public.challenge_participants for update to authenticated
  using (athlete_id = auth.uid() or public.is_coach())
  with check (athlete_id = auth.uid() or public.is_coach());
create policy "Atleta abandona su reto; coach elimina cualquiera"
  on public.challenge_participants for delete to authenticated
  using (athlete_id = auth.uid() or public.is_coach());

create policy "Catálogo de logros visible para autenticados"
  on public.achievements for select to authenticated using (true);
create policy "Solo coaches gestionan catálogo de logros"
  on public.achievements for all to authenticated
  using (public.is_coach()) with check (public.is_coach());

create policy "Logros desbloqueados visibles para autenticados"
  on public.athlete_achievements for select to authenticated using (true);
create policy "Solo coaches otorgan logros"
  on public.athlete_achievements for all to authenticated
  using (public.is_coach()) with check (public.is_coach());

create policy "Atleta ve sus objetivos; coach ve todos"
  on public.athlete_goals for select to authenticated
  using (athlete_id = auth.uid() or public.is_coach());
create policy "Atleta crea sus objetivos; coach a cualquiera"
  on public.athlete_goals for insert to authenticated
  with check (athlete_id = auth.uid() or public.is_coach());
create policy "Atleta actualiza sus objetivos; coach a cualquiera"
  on public.athlete_goals for update to authenticated
  using (athlete_id = auth.uid() or public.is_coach())
  with check (athlete_id = auth.uid() or public.is_coach());
create policy "Atleta elimina sus objetivos; coach a cualquiera"
  on public.athlete_goals for delete to authenticated
  using (athlete_id = auth.uid() or public.is_coach());
