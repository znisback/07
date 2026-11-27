-- ZnisBack Studio — configuração inicial do Supabase
-- 1) Crie os dois usuários em Authentication > Users (Add user).
--    E-mails internos: znisback@znisback.app e lnisback@znisback.app
--    Use as senhas definidas pelos donos. Desative cadastro público e confirmação
--    de e-mail para esses usuários internos (Authentication > Providers > Email).
-- 2) Execute este SQL depois de criar as duas contas.
-- 3) O bucket PRIVADO studio-files é criado (ou forçado a privado) por este próprio SQL.
-- Pode rodar de novo a qualquer momento: ele é seguro para repetir.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null check (username in ('znisback','lnisback')),
  created_at timestamptz not null default now()
);
insert into public.profiles(id, username)
select id, case email
  when 'znisback@znisback.app' then 'znisback'
  when 'lnisback@znisback.app' then 'lnisback'
end
from auth.users
where email in ('znisback@znisback.app','lnisback@znisback.app')
on conflict (id) do update set username=excluded.username;

create table if not exists public.shared_files (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  owner_name text not null check (owner_name in ('znisback','lnisback')),
  shared_with uuid references public.profiles(id) on delete set null,
  file_name text not null,
  file_size bigint not null default 0,
  storage_path text not null unique,
  mime_type text,
  created_at timestamptz not null default now()
);
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete cascade,
  sender_name text not null check (sender_name in ('znisback','lnisback')),
  body text not null check (char_length(body) between 1 and 2000),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.shared_files enable row level security;
alter table public.messages enable row level security;

drop policy if exists "profiles two users read" on public.profiles;
create policy "profiles two users read" on public.profiles for select to authenticated
using (true);

drop policy if exists "files visible to owner or recipient" on public.shared_files;
create policy "files visible to owner or recipient" on public.shared_files for select to authenticated
using (owner_id=(select auth.uid()) or shared_with=(select auth.uid()));
drop policy if exists "users insert own files" on public.shared_files;
create policy "users insert own files" on public.shared_files for insert to authenticated
with check (owner_id=(select auth.uid()) and owner_name=(select username from public.profiles where id=(select auth.uid())) and split_part(storage_path,'/',1)=(select auth.uid())::text);
drop policy if exists "owners update own files" on public.shared_files;
create policy "owners update own files" on public.shared_files for update to authenticated
using (owner_id=(select auth.uid())) with check (owner_id=(select auth.uid()) and split_part(storage_path,'/',1)=(select auth.uid())::text);
drop policy if exists "owners delete own files" on public.shared_files;
create policy "owners delete own files" on public.shared_files for delete to authenticated
using (owner_id=(select auth.uid()));

drop policy if exists "two users read chat" on public.messages;
create policy "two users read chat" on public.messages for select to authenticated
using (exists(select 1 from public.profiles where id=(select auth.uid())));
drop policy if exists "two users send chat" on public.messages;
create policy "two users send chat" on public.messages for insert to authenticated
with check (sender_id=(select auth.uid()) and sender_name=(select username from public.profiles where id=(select auth.uid())));

-- Storage: uploads só podem ser criados dentro da pasta do próprio usuário.
drop policy if exists "upload own studio files" on storage.objects;
create policy "upload own studio files" on storage.objects for insert to authenticated
with check (bucket_id='studio-files' and (storage.foldername(name))[1]=(select auth.uid())::text
  and exists(select 1 from public.profiles where id=(select auth.uid())));
drop policy if exists "read permitted studio files" on storage.objects;
create policy "read permitted studio files" on storage.objects for select to authenticated
using (bucket_id='studio-files' and exists (
  select 1 from public.shared_files f
  where f.storage_path=storage.objects.name
    and (f.owner_id=(select auth.uid()) or f.shared_with=(select auth.uid()))
));
drop policy if exists "delete own studio files" on storage.objects;
create policy "delete own studio files" on storage.objects for delete to authenticated
using (bucket_id='studio-files' and (storage.foldername(name))[1]=(select auth.uid())::text);

-- Realtime: liga chat e arquivos (ignora se já estiver ligado).
do $$
begin
  begin alter publication supabase_realtime add table public.messages; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.shared_files; exception when duplicate_object then null; end;
end $$;

-- Permissões SQL para as contas autenticadas.
grant usage on schema public to authenticated;
grant select on public.profiles to authenticated;
grant select, insert, update, delete on public.shared_files to authenticated;
grant select, insert on public.messages to authenticated;

-- Bucket privado (cria ou força privado).
insert into storage.buckets (id, name, public) values ('studio-files','studio-files',false)
on conflict (id) do update set public=false;

-- Índices (desempenho das políticas e do chat).
create index if not exists shared_files_owner_idx on public.shared_files(owner_id);
create index if not exists shared_files_shared_with_idx on public.shared_files(shared_with);
create index if not exists messages_created_idx on public.messages(created_at desc);
create index if not exists messages_sender_idx on public.messages(sender_id);

-- Contas anônimas não precisam de acesso às tabelas.
revoke all on public.profiles, public.shared_files, public.messages from anon;

-- Foto de perfil: JPEG pequeno guardado como texto base64 em profiles.avatar.
alter table public.profiles add column if not exists avatar text;
alter table public.profiles drop constraint if exists profiles_avatar_check;
alter table public.profiles add constraint profiles_avatar_check
  check (avatar is null or (avatar like 'data:image/jpeg;base64,%' and char_length(avatar) < 150000));
drop policy if exists "users update own profile" on public.profiles;
create policy "users update own profile" on public.profiles for update to authenticated
using (id=(select auth.uid())) with check (id=(select auth.uid()));
revoke insert, update, delete on public.profiles from authenticated;
grant update (avatar) on public.profiles to authenticated;
do $$
begin
  begin alter publication supabase_realtime add table public.profiles; exception when duplicate_object then null; end;
end $$;
