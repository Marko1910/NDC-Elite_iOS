-- ===== Alertas y Notificaciones =====
create type public.notification_type as enum (
  'validacion', 'lesion', 'asistencia', 'mensaje', 'logro', 'general'
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,  -- destinatario
  type public.notification_type not null default 'general',
  title text not null,                       -- "Validación Pendiente", "Alerta de Lesión"
  body text,                                 -- "Mateo Rodríguez ha registrado un nuevo PR..."
  related_athlete_id uuid references public.profiles(id) on delete set null,
  metadata jsonb,                            -- refs a PR/lesión/clase según el tipo
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index idx_notifications_user on public.notifications(user_id);
create index idx_notifications_unread on public.notifications(user_id) where not is_read;

-- ===== Tips del Coach ("Mejora tu eficiencia en el Clean") =====
create table public.coach_tips (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  content text,
  video_url text,
  exercise_id uuid references public.exercises(id) on delete set null,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create index idx_coach_tips_exercise on public.coach_tips(exercise_id);

-- ===== Snapshots de ranking (para mostrar subidas/bajadas +3 / -1) =====
create table public.ranking_snapshots (
  id uuid primary key default gen_random_uuid(),
  athlete_id uuid not null references public.profiles(id) on delete cascade,
  points int not null,
  rank int not null,
  snapshot_date date not null default current_date,
  unique (athlete_id, snapshot_date)
);

create index idx_ranking_snapshots_date on public.ranking_snapshots(snapshot_date);

-- ===== RLS =====
alter table public.notifications enable row level security;
alter table public.coach_tips enable row level security;
alter table public.ranking_snapshots enable row level security;

create policy "Cada usuario ve sus notificaciones"
  on public.notifications for select to authenticated
  using (user_id = auth.uid());
create policy "Coaches crean notificaciones"
  on public.notifications for insert to authenticated
  with check (public.is_coach());
create policy "El destinatario marca como leída"
  on public.notifications for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "El destinatario elimina sus notificaciones"
  on public.notifications for delete to authenticated
  using (user_id = auth.uid());

create policy "Tips visibles para autenticados"
  on public.coach_tips for select to authenticated using (true);
create policy "Solo coaches gestionan tips"
  on public.coach_tips for all to authenticated
  using (public.is_coach()) with check (public.is_coach());

create policy "Ranking visible para autenticados"
  on public.ranking_snapshots for select to authenticated using (true);
create policy "Solo coaches gestionan snapshots de ranking"
  on public.ranking_snapshots for all to authenticated
  using (public.is_coach()) with check (public.is_coach());
