-- Teléfono para el deep link de WhatsApp (recordatorio de inasistencia del coach)
alter table public.profiles
  add column phone text;

comment on column public.profiles.phone is 'Número con código de país (ej. +51987654321) para abrir WhatsApp desde la app del coach';
