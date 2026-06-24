-- ============================================================
-- Habit Tracker — Supabase Setup
-- Run this in the Supabase SQL Editor (Dashboard → SQL Editor)
-- ============================================================

-- 1. HABITS TABLE
create table if not exists habits (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    description text,
    category text,
    icon text,
    is_active boolean not null default true,
    sort_order integer,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- 2. HABIT ENTRIES TABLE
create table if not exists habit_entries (
    id uuid primary key default gen_random_uuid(),
    habit_id uuid not null references habits(id) on delete cascade,
    entry_date date not null,
    is_done boolean not null default true,
    notes text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint unique_habit_entry_per_day unique (habit_id, entry_date)
);

-- 3. INDEX for faster lookups
create index if not exists idx_habit_entries_habit_date
    on habit_entries (habit_id, entry_date);

-- 4. DISABLE RLS (single-user personal app)
--    If you want to add authentication later, enable RLS
--    and create policies for your user.
alter table habits enable row level security;
alter table habit_entries enable row level security;

create policy "Allow all on habits" on habits
    for all using (true) with check (true);

create policy "Allow all on habit_entries" on habit_entries
    for all using (true) with check (true);
