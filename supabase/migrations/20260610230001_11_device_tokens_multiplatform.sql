-- ===== Preparación multiplataforma (iOS nativo + Web/PWA) =====
-- Tokens de dispositivo para notificaciones push en ambas plataformas:
-- iOS → APNs; Web/PWA → Web Push (endpoint + claves).
-- La misma BD y RLS sirven a ambos clientes; esta tabla es lo único
-- adicional que el backend necesita para diferenciarlos.

create type public.device_platform as enum ('ios', 'web');

create table public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  platform public.device_platform not null,
  -- iOS: token de APNs. Web: JSON del PushSubscription (endpoint + keys).
  token text not null,
  device_name text,                          -- "iPhone de Alex", "Chrome en Windows"
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (user_id, token)
);

create index idx_device_tokens_user on public.device_tokens(user_id);

-- ===== RLS =====
alter table public.device_tokens enable row level security;

create policy "Cada usuario gestiona sus propios dispositivos"
  on public.device_tokens for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
