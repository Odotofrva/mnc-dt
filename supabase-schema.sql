-- Run this in the Supabase SQL editor

create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique,
  display_name text,
  instagram text,
  bio text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.closet_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  category text not null check (category in ('Tops', 'Bottoms', 'Accessories', 'Shoes')),
  brand text,
  color text,
  size text,
  season text,
  notes text,
  image_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.saved_outfits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.outfit_items (
  id uuid primary key default gen_random_uuid(),
  outfit_id uuid not null references public.saved_outfits(id) on delete cascade,
  closet_item_id uuid not null references public.closet_items(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.closet_items enable row level security;
alter table public.saved_outfits enable row level security;
alter table public.outfit_items enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
on public.profiles for select
using (auth.uid() = id);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
on public.profiles for insert
with check (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles for update
using (auth.uid() = id);

drop policy if exists "closet_items_select_own" on public.closet_items;
create policy "closet_items_select_own"
on public.closet_items for select
using (auth.uid() = user_id);

drop policy if exists "closet_items_insert_own" on public.closet_items;
create policy "closet_items_insert_own"
on public.closet_items for insert
with check (auth.uid() = user_id);

drop policy if exists "closet_items_update_own" on public.closet_items;
create policy "closet_items_update_own"
on public.closet_items for update
using (auth.uid() = user_id);

drop policy if exists "closet_items_delete_own" on public.closet_items;
create policy "closet_items_delete_own"
on public.closet_items for delete
using (auth.uid() = user_id);

drop policy if exists "saved_outfits_select_own" on public.saved_outfits;
create policy "saved_outfits_select_own"
on public.saved_outfits for select
using (auth.uid() = user_id);

drop policy if exists "saved_outfits_insert_own" on public.saved_outfits;
create policy "saved_outfits_insert_own"
on public.saved_outfits for insert
with check (auth.uid() = user_id);

drop policy if exists "saved_outfits_update_own" on public.saved_outfits;
create policy "saved_outfits_update_own"
on public.saved_outfits for update
using (auth.uid() = user_id);

drop policy if exists "saved_outfits_delete_own" on public.saved_outfits;
create policy "saved_outfits_delete_own"
on public.saved_outfits for delete
using (auth.uid() = user_id);

drop policy if exists "outfit_items_select_own" on public.outfit_items;
create policy "outfit_items_select_own"
on public.outfit_items for select
using (
  exists (
    select 1 from public.saved_outfits so
    where so.id = outfit_id and so.user_id = auth.uid()
  )
);

drop policy if exists "outfit_items_insert_own" on public.outfit_items;
create policy "outfit_items_insert_own"
on public.outfit_items for insert
with check (
  exists (
    select 1 from public.saved_outfits so
    where so.id = outfit_id and so.user_id = auth.uid()
  )
);

drop policy if exists "outfit_items_delete_own" on public.outfit_items;
create policy "outfit_items_delete_own"
on public.outfit_items for delete
using (
  exists (
    select 1 from public.saved_outfits so
    where so.id = outfit_id and so.user_id = auth.uid()
  )
);
