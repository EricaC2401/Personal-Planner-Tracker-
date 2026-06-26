-- ============================================================
-- Habit Tracker — Supabase Setup
-- Run this in the Supabase SQL Editor (Dashboard → SQL Editor)
-- ============================================================

-- 1. HABITS TABLE
create table if not exists habits (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    description text,
    type text not null default 'habit' check (type in ('habit', 'tracking')),
    target integer,
    category text,
    icon text,
    is_active boolean not null default true,
    sort_order integer,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

alter table habits add column if not exists type text;
alter table habits add column if not exists target integer;

update habits
set type = 'habit'
where type is null;

update habits
set target = 5
where coalesce(type, 'habit') = 'habit'
  and target is null;

update habits
set target = null
where type = 'tracking';

alter table habits alter column type set default 'habit';
alter table habits alter column type set not null;

do $$
begin
    if not exists (
        select 1
        from pg_constraint
        where conname = 'habits_type_check'
    ) then
        alter table habits
            add constraint habits_type_check
            check (type in ('habit', 'tracking'));
    end if;
end $$;

do $$
begin
    if not exists (
        select 1
        from pg_constraint
        where conname = 'habits_target_positive_or_null'
    ) then
        alter table habits
            add constraint habits_target_positive_or_null
            check (target is null or target > 0);
    end if;
end $$;

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

-- 5. CATEGORIES TABLE
create table if not exists categories (
    id uuid primary key default gen_random_uuid(),
    name text not null unique,
    icon text not null default 'ti-check',
    color_key text not null default 'gray',
    sort_order integer,
    created_at timestamptz not null default now()
);

alter table categories enable row level security;

create policy "Allow all on categories" on categories
    for all using (true) with check (true);

-- Seed default categories
insert into categories (name, icon, color_key, sort_order) values
    ('Health & Wellbeing', 'ti-heart', 'green', 1),
    ('Personal Growth', 'ti-star', 'purple', 2),
    ('Learning', 'ti-book', 'blue', 3),
    ('Fitness', 'ti-run', 'green', 4),
    ('Mindfulness', 'ti-brain', 'orange', 5),
    ('Relationships', 'ti-heart', 'pink', 6),
    ('Finance', 'ti-coin', 'olive', 7),
    ('Career', 'ti-briefcase', 'gray', 8),
    ('Other', 'ti-check', 'gray', 9)
on conflict (name) do nothing;

-- ============================================================
-- Daily Planner — Supabase Setup
-- ============================================================

create table if not exists goals (
    id uuid primary key default gen_random_uuid(),
    title text not null,
    area text,
    target_completion_date date,
    is_important boolean not null default false,
    is_urgent boolean not null default false,
    is_done boolean not null default false,
    is_cancelled boolean not null default false,
    is_active boolean not null default true,
    sort_order integer,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists tasks (
    id uuid primary key default gen_random_uuid(),
    title text not null,
    category text,
    area text,
    goal_id uuid references goals(id) on delete set null,
    deadline date,
    is_done boolean not null default false,
    is_cancelled boolean not null default false,
    completed_at date,
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

alter table goals add column if not exists is_cancelled boolean not null default false;
alter table goals add column if not exists target_completion_date date;
alter table goals add column if not exists is_important boolean not null default false;
alter table goals add column if not exists is_urgent boolean not null default false;
alter table tasks add column if not exists is_cancelled boolean not null default false;

create table if not exists events (
    id uuid primary key default gen_random_uuid(),
    title text not null,
    event_date date,
    event_time time,
    venue text,
    category text,
    is_done boolean not null default false,
    is_cancelled boolean not null default false,
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists daily_plans (
    id uuid primary key default gen_random_uuid(),
    plan_date date not null unique,
    notes text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists daily_plan_items (
    id uuid primary key default gen_random_uuid(),
    daily_plan_id uuid not null references daily_plans(id) on delete cascade,
    item_type text not null check (item_type in ('task', 'event', 'schedule_entry')),
    task_id uuid references tasks(id) on delete set null,
    event_id uuid references events(id) on delete set null,
    title_snapshot text not null default '',
    category_snapshot text,
    area_snapshot text,
    status text not null default 'planned' check (status in ('planned', 'done', 'moved', 'cancelled')),
    is_today_focus boolean not null default false,
    is_important boolean not null default false,
    is_urgent boolean not null default false,
    is_highlight boolean not null default false,
    time_text text,
    note_text text,
    sort_order integer,
    source_plan_item_id uuid references daily_plan_items(id) on delete set null,
    moved_to_plan_item_id uuid references daily_plan_items(id) on delete set null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

do $$
begin
    if not exists (
        select 1
        from pg_constraint
        where conname = 'daily_plan_items_reference_check'
    ) then
        alter table daily_plan_items
            add constraint daily_plan_items_reference_check
            check (
                (item_type = 'task' and task_id is not null and event_id is null) or
                (item_type = 'event' and event_id is not null and task_id is null) or
                (item_type = 'schedule_entry' and task_id is null and event_id is null)
            );
    end if;
end $$;

create index if not exists idx_goals_sort_order
    on goals (sort_order, created_at);

create index if not exists idx_tasks_goal_id
    on tasks (goal_id);

create index if not exists idx_tasks_active_done_deadline
    on tasks (is_active, is_done, deadline);

create index if not exists idx_events_active_date
    on events (is_active, event_date);

create index if not exists idx_daily_plans_plan_date
    on daily_plans (plan_date);

create index if not exists idx_daily_plan_items_daily_plan
    on daily_plan_items (daily_plan_id, sort_order);

create index if not exists idx_daily_plan_items_task
    on daily_plan_items (task_id);

create index if not exists idx_daily_plan_items_event
    on daily_plan_items (event_id);

create index if not exists idx_daily_plan_items_status
    on daily_plan_items (status);

create unique index if not exists idx_daily_plan_items_active_task
    on daily_plan_items (daily_plan_id, task_id)
    where item_type = 'task' and status in ('planned', 'done');

alter table goals enable row level security;
alter table tasks enable row level security;
alter table events enable row level security;
alter table daily_plans enable row level security;
alter table daily_plan_items enable row level security;

do $$
begin
    if not exists (
        select 1
        from pg_policies
        where schemaname = 'public'
          and tablename = 'goals'
          and policyname = 'Allow all on goals'
    ) then
        create policy "Allow all on goals" on goals
            for all using (true) with check (true);
    end if;
end $$;

do $$
begin
    if not exists (
        select 1
        from pg_policies
        where schemaname = 'public'
          and tablename = 'tasks'
          and policyname = 'Allow all on tasks'
    ) then
        create policy "Allow all on tasks" on tasks
            for all using (true) with check (true);
    end if;
end $$;

do $$
begin
    if not exists (
        select 1
        from pg_policies
        where schemaname = 'public'
          and tablename = 'events'
          and policyname = 'Allow all on events'
    ) then
        create policy "Allow all on events" on events
            for all using (true) with check (true);
    end if;
end $$;

do $$
begin
    if not exists (
        select 1
        from pg_policies
        where schemaname = 'public'
          and tablename = 'daily_plans'
          and policyname = 'Allow all on daily_plans'
    ) then
        create policy "Allow all on daily_plans" on daily_plans
            for all using (true) with check (true);
    end if;
end $$;

do $$
begin
    if not exists (
        select 1
        from pg_policies
        where schemaname = 'public'
          and tablename = 'daily_plan_items'
          and policyname = 'Allow all on daily_plan_items'
    ) then
        create policy "Allow all on daily_plan_items" on daily_plan_items
            for all using (true) with check (true);
    end if;
end $$;
