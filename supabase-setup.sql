-- =====================================================================
-- Invenzo AI Solutions - database setup (run ONCE in Supabase > SQL Editor)
-- Creates: admins list, projects + products tables, security rules,
-- and a public image bucket that only admins can upload to.
-- Safe to re-run.
-- =====================================================================

-- 1) Who is an admin ---------------------------------------------------
create table if not exists public.admins (email text primary key);
insert into public.admins (email) values
  ('mithinkrishnanns@invenzoai.in'),
  ('mukeshpandi@invenzoai.in'),
  ('maheshwaran@invenzoai.in')
on conflict do nothing;

-- Nobody can read the admins table through the API (no policies = no access).
alter table public.admins enable row level security;

create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.admins a
    where lower(a.email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

-- 2) Tables ------------------------------------------------------------
create table if not exists public.projects (
  id          uuid primary key default gen_random_uuid(),
  name        text not null check (char_length(name) between 1 and 120),
  client      text check (char_length(client) <= 120),
  description text check (char_length(description) <= 600),
  url         text,
  image_url   text,
  tags        text[] not null default '{}',
  sort_order  integer not null default 0,
  published   boolean not null default true,
  created_at  timestamptz not null default now()
);

create table if not exists public.products (
  id          uuid primary key default gen_random_uuid(),
  name        text not null check (char_length(name) between 1 and 120),
  tagline     text check (char_length(tagline) <= 140),
  description text check (char_length(description) <= 600),
  url         text,
  image_url   text,
  status      text,
  sort_order  integer not null default 0,
  published   boolean not null default true,
  created_at  timestamptz not null default now()
);

-- 3) Security rules: everyone reads published rows, only admins write ---
alter table public.projects enable row level security;
alter table public.products enable row level security;

drop policy if exists "projects read"   on public.projects;
drop policy if exists "projects insert" on public.projects;
drop policy if exists "projects update" on public.projects;
drop policy if exists "projects delete" on public.projects;
create policy "projects read"   on public.projects for select to anon, authenticated using (published = true or public.is_admin());
create policy "projects insert" on public.projects for insert to authenticated with check (public.is_admin());
create policy "projects update" on public.projects for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "projects delete" on public.projects for delete to authenticated using (public.is_admin());

drop policy if exists "products read"   on public.products;
drop policy if exists "products insert" on public.products;
drop policy if exists "products update" on public.products;
drop policy if exists "products delete" on public.products;
create policy "products read"   on public.products for select to anon, authenticated using (published = true or public.is_admin());
create policy "products insert" on public.products for insert to authenticated with check (public.is_admin());
create policy "products update" on public.products for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "products delete" on public.products for delete to authenticated using (public.is_admin());

-- 4) Image storage -----------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('invenzo-media', 'invenzo-media', true, 5242880,
        array['image/png','image/jpeg','image/webp','image/gif'])
on conflict (id) do update
  set public = true, file_size_limit = 5242880,
      allowed_mime_types = array['image/png','image/jpeg','image/webp','image/gif'];

drop policy if exists "media admin insert" on storage.objects;
drop policy if exists "media admin update" on storage.objects;
drop policy if exists "media admin delete" on storage.objects;
create policy "media admin insert" on storage.objects for insert to authenticated with check (bucket_id = 'invenzo-media' and public.is_admin());
create policy "media admin update" on storage.objects for update to authenticated using (bucket_id = 'invenzo-media' and public.is_admin());
create policy "media admin delete" on storage.objects for delete to authenticated using (bucket_id = 'invenzo-media' and public.is_admin());
-- (Reading images needs no policy: the bucket is public.)
