-- ===== Bootstrap: el primer usuario puede registrarse como coach =====
-- Reemplaza handle_new_user (definido en 01_base_enums_profiles) agregando el
-- caso "requested_role = coach", solo válido si todavía no existe ningún coach.
-- Si ya existe un coach, se ignora la solicitud y el rol queda en 'atleta'
-- (la única vía para volverse coach después es un código de coach, ver abajo).
create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer
set search_path = ''
as $$
declare
  v_role public.user_role := 'atleta';
  v_coach_count int;
begin
  if new.raw_user_meta_data->>'requested_role' = 'coach' then
    select count(*) into v_coach_count from public.profiles where role in ('coach', 'admin');
    if v_coach_count = 0 then
      v_role := 'coach';
    end if;
  end if;

  insert into public.profiles (id, full_name, avatar_url, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    new.raw_user_meta_data->>'avatar_url',
    v_role
  );
  return new;
end;
$$;

-- ¿Ya existe algún coach? (para que RegisterView sepa si mostrar la opción de
-- fundador). Callable sin sesión (anon), por eso no se puede consultar
-- `profiles` directo (RLS exige `authenticated`).
create or replace function public.any_coach_exists()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (select 1 from public.profiles where role in ('coach', 'admin'));
$$;

grant execute on function public.any_coach_exists() to anon, authenticated;

-- ===== Códigos de invitación con rol (atleta o coach) =====
-- El coach principal genera un código de tipo 'coach' y se lo comparte a la
-- persona; al canjearlo, su perfil pasa a coach automáticamente.
alter table public.invitation_codes
  add column if not exists role public.user_role not null default 'atleta';

create or replace function public.redeem_role_code(p_code text)
returns boolean
language plpgsql security definer
set search_path = ''
as $$
declare
  v_id uuid;
  v_role public.user_role;
begin
  select id, role into v_id, v_role
  from public.invitation_codes
  where code = p_code and used_by is null
  for update;

  if v_id is null then
    return false;
  end if;

  update public.invitation_codes set used_by = auth.uid() where id = v_id;

  if v_role = 'coach' then
    update public.profiles set role = 'coach' where id = auth.uid();
  end if;

  return true;
end;
$$;

grant execute on function public.redeem_role_code(text) to authenticated;
