-- Fijar search_path en set_updated_at (advisor: function_search_path_mutable)
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- handle_new_user solo debe ejecutarlo el trigger de auth, nadie vía API
revoke execute on function public.handle_new_user() from anon, authenticated, public;

-- is_coach: lo necesitan las políticas RLS de usuarios autenticados,
-- pero no debe ser invocable por anónimos
revoke execute on function public.is_coach() from anon, public;
grant execute on function public.is_coach() to authenticated;
