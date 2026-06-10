-- ===== Registro de Lesiones =====
create type public.body_zone as enum (
  'cabeza', 'hombros', 'espalda', 'codos', 'munecas',
  'lumbar', 'cadera', 'rodillas', 'tobillos'
);
create type public.injury_severity as enum ('leve', 'moderada', 'severa');
create type public.injury_status as enum ('activa', 'en_seguimiento', 'resuelta');

create table public.injuries (
  id uuid primary key default gen_random_uuid(),
  athlete_id uuid not null references public.profiles(id) on delete cascade,
  body_zone public.body_zone not null,
  severity public.injury_severity not null,
  description text,                          -- "Pinchazo al hacer sentadilla profunda..."
  incident_date date not null default current_date,
  status public.injury_status not null default 'activa',
  reported_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_injuries_athlete on public.injuries(athlete_id);
create index idx_injuries_status on public.injuries(status);

-- ===== Notas del Coach sobre atletas =====
create type public.note_category as enum ('general', 'performance', 'lesion', 'nutricion');
create type public.note_visibility as enum ('solo_coach', 'compartida');

create table public.coach_notes (
  id uuid primary key default gen_random_uuid(),
  athlete_id uuid not null references public.profiles(id) on delete cascade,
  coach_id uuid not null references public.profiles(id) on delete cascade,
  category public.note_category not null default 'general',
  content text not null,
  visibility public.note_visibility not null default 'solo_coach',
  note_date date not null default current_date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_coach_notes_athlete on public.coach_notes(athlete_id);
create index idx_coach_notes_coach on public.coach_notes(coach_id);

create trigger trg_injuries_updated_at
  before update on public.injuries
  for each row execute function public.set_updated_at();
create trigger trg_coach_notes_updated_at
  before update on public.coach_notes
  for each row execute function public.set_updated_at();

-- ===== RLS =====
alter table public.injuries enable row level security;
alter table public.coach_notes enable row level security;

create policy "Atleta ve sus lesiones; coach ve todas"
  on public.injuries for select to authenticated
  using (athlete_id = auth.uid() or public.is_coach());
create policy "Atleta reporta su lesión; coach registra cualquiera"
  on public.injuries for insert to authenticated
  with check (athlete_id = auth.uid() or public.is_coach());
create policy "Atleta actualiza su lesión; coach actualiza cualquiera"
  on public.injuries for update to authenticated
  using (athlete_id = auth.uid() or public.is_coach())
  with check (athlete_id = auth.uid() or public.is_coach());
create policy "Solo coaches eliminan lesiones"
  on public.injuries for delete to authenticated
  using (public.is_coach());

create policy "Coach ve todas las notas; atleta solo las compartidas suyas"
  on public.coach_notes for select to authenticated
  using (public.is_coach() or (athlete_id = auth.uid() and visibility = 'compartida'));
create policy "Solo coaches crean notas"
  on public.coach_notes for insert to authenticated
  with check (public.is_coach() and coach_id = auth.uid());
create policy "Solo coaches actualizan notas"
  on public.coach_notes for update to authenticated
  using (public.is_coach()) with check (public.is_coach());
create policy "Solo coaches eliminan notas"
  on public.coach_notes for delete to authenticated
  using (public.is_coach());
