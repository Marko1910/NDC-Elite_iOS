-- ===== Clases programadas (Clase 07:00 AM, 50 cupos) =====
create type public.attendance_status as enum ('presente', 'ausente', 'tarde');

create table public.class_sessions (
  id uuid primary key default gen_random_uuid(),
  session_date date not null,
  start_time time not null,
  capacity int not null default 50,
  title text,
  coach_id uuid references public.profiles(id) on delete set null,
  wod_id uuid references public.wods(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (session_date, start_time)
);

create index idx_class_sessions_date on public.class_sessions(session_date);

-- ===== Asistencia por atleta y clase =====
create table public.attendance (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.class_sessions(id) on delete cascade,
  athlete_id uuid not null references public.profiles(id) on delete cascade,
  status public.attendance_status not null default 'ausente',
  checked_in_at timestamptz,
  check_in_method text,                      -- 'qr' | 'manual'
  recorded_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (session_id, athlete_id)
);

create index idx_attendance_session on public.attendance(session_id);
create index idx_attendance_athlete on public.attendance(athlete_id);

-- ===== RLS =====
alter table public.class_sessions enable row level security;
alter table public.attendance enable row level security;

create policy "Clases visibles para autenticados"
  on public.class_sessions for select to authenticated using (true);
create policy "Solo coaches gestionan clases"
  on public.class_sessions for all to authenticated
  using (public.is_coach()) with check (public.is_coach());

create policy "Atleta ve su asistencia; coach ve toda"
  on public.attendance for select to authenticated
  using (athlete_id = auth.uid() or public.is_coach());
create policy "Atleta hace check-in propio; coach registra a cualquiera"
  on public.attendance for insert to authenticated
  with check (athlete_id = auth.uid() or public.is_coach());
create policy "Solo coaches corrigen asistencia"
  on public.attendance for update to authenticated
  using (public.is_coach()) with check (public.is_coach());
create policy "Solo coaches eliminan asistencia"
  on public.attendance for delete to authenticated
  using (public.is_coach());
