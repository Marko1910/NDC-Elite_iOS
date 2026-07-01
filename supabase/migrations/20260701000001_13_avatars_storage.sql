-- ===== Bucket público para fotos de perfil =====
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- Cada usuario guarda su foto en avatars/{user_id}/avatar.jpg
create policy "Avatares públicos para lectura"
  on storage.objects for select
  using (bucket_id = 'avatars');

create policy "Cada usuario sube su propio avatar"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Cada usuario reemplaza su propio avatar"
  on storage.objects for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Cada usuario elimina su propio avatar"
  on storage.objects for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
