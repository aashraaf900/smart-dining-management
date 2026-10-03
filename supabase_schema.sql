-- SMART DINING - SUPABASE DATABASE
-- Run this whole file in Supabase Dashboard -> SQL Editor.
-- This schema keeps the same general data model used by the old Firebase panels:
-- student_id, name, phone, hall, meals, credit, RFID, blocked/approved.

create extension if not exists pgcrypto;

create table if not exists public.students (
    id uuid primary key default gen_random_uuid(),
    hall text not null,
    student_id text not null,
    name text not null,
    phone text not null,
    password_hash text not null,
    is_blocked boolean not null default false,
    is_approved boolean not null default true,
    credit_balance numeric not null default 0,
    meals jsonb not null default '{}'::jsonb,
    rfid_uid text,
    card_status text not null default 'Inactive',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (hall, student_id)
);

create table if not exists public.hall_configs (
    hall text primary key,
    closed_dates jsonb not null default '{}'::jsonb,
    meal_times jsonb not null default '{}'::jsonb,
    notice_title text not null default '',
    notice_body text not null default '',
    updated_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists students_updated_at on public.students;
create trigger students_updated_at
before update on public.students
for each row execute function public.set_updated_at();

drop trigger if exists hall_configs_updated_at on public.hall_configs;
create trigger hall_configs_updated_at
before update on public.hall_configs
for each row execute function public.set_updated_at();

insert into public.hall_configs(hall)
values ('STA Hall'), ('KNI Hall'), ('MC Hall')
on conflict (hall) do nothing;

-- =========================================================
-- RLS
-- =========================================================
-- These policies are intentionally simple so the GitHub
-- static panels work immediately with the public anon key.
--
-- IMPORTANT:
-- This is suitable for a prototype/demo. It is NOT a
-- production-security model because browser clients can call
-- the Supabase API directly.
-- Later we can add Supabase Auth + admin policies/RPC/Edge
-- Functions without changing the UI.

alter table public.students enable row level security;
alter table public.hall_configs enable row level security;

drop policy if exists "demo students select" on public.students;
drop policy if exists "demo students insert" on public.students;
drop policy if exists "demo students update" on public.students;
drop policy if exists "demo students delete" on public.students;

create policy "demo students select"
on public.students for select
to anon, authenticated
using (true);

create policy "demo students insert"
on public.students for insert
to anon, authenticated
with check (true);

create policy "demo students update"
on public.students for update
to anon, authenticated
using (true)
with check (true);

create policy "demo students delete"
on public.students for delete
to anon, authenticated
using (true);

drop policy if exists "demo config select" on public.hall_configs;
drop policy if exists "demo config insert" on public.hall_configs;
drop policy if exists "demo config update" on public.hall_configs;
drop policy if exists "demo config delete" on public.hall_configs;

create policy "demo config select"
on public.hall_configs for select
to anon, authenticated
using (true);

create policy "demo config insert"
on public.hall_configs for insert
to anon, authenticated
with check (true);

create policy "demo config update"
on public.hall_configs for update
to anon, authenticated
using (true)
with check (true);

create policy "demo config delete"
on public.hall_configs for delete
to anon, authenticated
using (true);

-- Enable realtime for the students table.
do $$
begin
    alter publication supabase_realtime add table public.students;
exception
    when duplicate_object then null;
end $$;
