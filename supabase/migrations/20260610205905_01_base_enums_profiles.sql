-- ===== Enums globales =====
create type public.user_role as enum ('atleta', 'coach', 'admin');
create type public.athlete_level as enum ('basico', 'intermedio', 'avanzado');
create type public.rx_level as enum ('rx', 'escalado');
create type public.score_type as enum ('peso', 'tiempo', 'reps', 'rondas', 'distancia', 'calorias');
create type public.result_status as enum ('pendiente', 'validado', 'corregido');

-- ===== Perfiles (atletas y coaches), vinculado a auth.users =====
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  avatar_url text,
  role public.user_role not null default 'atleta',
  level public.athlete_level not null default 'basico',
  weight_kg numeric(5,2),
  member_since date not null default current_date,
  monthly_attendance_goal int not null default 20,
  streak_days int not null default 0,
  points int not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.profiles is 'Perfil de usuario (atleta o coach) de NDC Elite';

-- ===== Helper: ¿el usuario actual es coach/admin? =====
create or replace function public.is_coach()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('coach', 'admin')
  );
$$;

-- ===== Trigger: crear perfil al registrarse =====
create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    new.raw_user_meta_data->>'avatar_url'
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ===== Trigger genérico de updated_at =====
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger trg_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- ===== RLS =====
alter table public.profiles enable row level security;

create policy "Perfiles visibles para usuarios autenticados"
  on public.profiles for select to authenticated using (true);

create policy "Cada usuario actualiza su propio perfil; coach actualiza cualquiera"
  on public.profiles for update to authenticated
  using (id = auth.uid() or public.is_coach())
  with check (id = auth.uid() or public.is_coach());
