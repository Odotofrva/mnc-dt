-- MENOCLONE Supabase schema
-- Run this in Supabase SQL Editor after creating your project.

create extension if not exists "pgcrypto";

create table if not exists public.closet_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  notes text,
  category text not null check (category in ('Tops','Bottoms','Accessories','Shoes')),
  image_data text not null,
  created_at timestamptz not null default now()
);

alter table public.closet_items enable row level security;

drop policy if exists "Users can read their own closet items" on public.closet_items;
create policy "Users can read their own closet items"
on public.closet_items for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "Users can insert their own closet items" on public.closet_items;
create policy "Users can insert their own closet items"
on public.closet_items for insert
to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update their own closet items" on public.closet_items;
create policy "Users can update their own closet items"
on public.closet_items for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

drop policy if exists "Users can delete their own closet items" on public.closet_items;
create policy "Users can delete their own closet items"
on public.closet_items for delete
to authenticated
using ((select auth.uid()) = user_id);
