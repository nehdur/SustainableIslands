-- Run once in Supabase SQL Editor, using your project's administrator account.
-- Keeps the original player_progress table untouched.
create table if not exists public.island_saves (
 user_id uuid primary key references auth.users(id) on delete cascade,
 save_data jsonb not null,
 updated_at timestamptz not null default now()
);
alter table public.island_saves enable row level security;
drop policy if exists "Read own island" on public.island_saves;
create policy "Read own island" on public.island_saves for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists "Insert own island" on public.island_saves;
create policy "Insert own island" on public.island_saves for insert to authenticated with check ((select auth.uid()) = user_id);
drop policy if exists "Update own island" on public.island_saves;
create policy "Update own island" on public.island_saves for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
grant select, insert, update on public.island_saves to authenticated;
