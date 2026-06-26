# agent.md

## Project Name

Personal Planner & Tracker

---

## Purpose

This project is a personal productivity and life-tracking app.

It will eventually include:

- Habit Tracker
- To-do List
- Daily Scheduler
- Projects / Goals
- Time Tracker
- History / Review
- Events / Reminders

The first development module is the **Habit Tracker**, but this is only the first part of the whole project.

---

## Important Product Principle

The most important rule is:

> Preserve historical records.

Do not overwrite or remove historical records unless the user explicitly asks for deletion.

Examples:

- Past habit completion records should remain available.
- Past daily schedules should remain available.
- Completed tasks should remain available.
- Moved tasks should still appear in the original day's history as moved.
- Time logs should remain available for later review.

---

## Current Development Focus

Current focus:

> MVP 1 — Habit Tracker

Do not build the full To-do List, Daily Scheduler, Project system, Time Tracker, History system, or Reminder system yet.

Build the Habit Tracker first in a way that does not block future modules.

---

## Tech Stack

Use:

- Python
- Streamlit
- Supabase PostgreSQL

The project should use Supabase PostgreSQL as the main database from the start.

Do not use CSV, JSON, Markdown, or local text files as the main storage layer.

---

## Secrets and Security

Database credentials must be stored locally in:

```text
.streamlit/secrets.toml
```

Do not commit secrets to GitHub.

The following files should be ignored by Git:

```gitignore
.streamlit/secrets.toml
.env
```

Never hard-code database passwords, API keys, or connection strings in source code.

---

## Expected User Workflow

The eventual workflow of the full app is:

1. Create habits, tasks, projects, or events.
2. Plan the day using a daily scheduler.
3. Mark habits and tasks as done.
4. Record actual time spent.
5. Preserve daily records.
6. Review progress by day, week, and month.

For the first MVP, only implement the habit-related part of this workflow.

---

## MVP 1 — Habit Tracker Requirements

Build a Habit Tracker with these features:

- Create habits.
- Add habit name.
- Add optional description.
- Add optional category.
- Add optional icon.
- Show active habits as cards.
- Mark a habit as done for today.
- Show Undo instead of Done if the habit is already completed today.
- Undo should remove today's completion record so mistaken clicks can be corrected.
- Show a mini monthly calendar for each habit.
- Days with completed records should be displayed in green.
- Show current streak.
- Show monthly completion percentage.
- Store habit history in Supabase PostgreSQL.

---

## Habit Tracker Database Tables

Create only the required Habit Tracker tables for MVP 1 unless the user asks otherwise.

### `habits`

Stores habit definitions.

Suggested schema:

```sql
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
```

### `habit_entries`

Stores daily habit completion records.

Suggested schema:

```sql
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
```

Important:

- There should be only one habit entry per habit per date.
- Use the unique constraint on `(habit_id, entry_date)`.
- Use insert/upsert carefully to avoid duplicate records.

---

## Done / Undo Logic

### Done

When the user clicks Done:

1. Check whether an entry already exists for the habit and today's date.
2. If no entry exists, create one.
3. If an entry already exists, do not create a duplicate.

### Undo

When the user clicks Undo:

1. Remove today's entry for that habit.
2. Refresh the UI state.
3. The calendar should no longer show today as green.

For MVP 1, deletion is acceptable for Undo because it represents correcting a mistaken click.

Do not delete historical entries from previous days unless the user explicitly requests it.

---

## Calendar Display Requirements

Each habit card should show a mini calendar for the selected month.

Calendar behaviour:

- Completed days should be green.
- Today should be visually clear.
- Future days should be neutral or grey.
- Incomplete days should remain uncoloured or light grey.
- The user should be able to see which days have records.

The first version can use simple HTML/CSS inside Streamlit.

---

## Habit Metrics

Calculate and display:

- Current streak
- Monthly completed count
- Monthly completion percentage

Current streak should count consecutive completed days up to today.

Monthly completion percentage should be based on completed days divided by days elapsed in the selected month, not future days.

---

## Future Modules

The wider project will later include:

### To-do List

Future table:

- `tasks`

Features:

- Create tasks.
- Edit tasks.
- Set due date.
- Set priority.
- Set status.
- Mark as done.
- Preserve completed task history.

### Daily Scheduler

Future tables:

- `daily_plans`
- `daily_plan_items`

Features:

- Daily timetable.
- Time blocks.
- Linked tasks.
- Mark as done, skipped, moved, or cancelled.
- Preserve previous daily schedules.

### Projects / Goals

Future table:

- `projects`

Features:

- Large goals.
- Link tasks to projects.
- Track progress.

### Time Tracker

Future table:

- `time_logs`

Features:

- Estimated time.
- Actual time.
- Time spent by task.
- Time spent by project.

### Events / Reminders

Future tables:

- `events`
- `reminders`

Features:

- Scheduled events.
- Recurring events.
- Reminder settings.
- Calendar view.

Do not implement these future modules during MVP 1 unless the user explicitly asks.

---

## Coding Guidelines

Follow these principles:

- Keep the code simple and readable.
- Prefer small, focused functions.
- Use clear file names and function names.
- Avoid unnecessary abstractions.
- Avoid repeated logic by using helper functions or service functions.
- Separate database logic from UI code where practical.
- Validate user input.
- Handle database errors gracefully.
- Do not add features that were not requested.
- Do not modify unrelated files unnecessarily.

---

## Suggested Folder Structure

```text
personal-planner-tracker/
│
├── README.md
├── plan.md
├── agent.md
├── requirements.txt
├── .gitignore
│
├── .streamlit/
│   └── secrets.toml
│
├── src/
│   ├── app.py
│   ├── config.py
│   ├── database.py
│   │
│   ├── pages/
│   │   ├── habit_tracker.py
│   │   ├── todo_list.py
│   │   ├── daily_scheduler.py
│   │   ├── projects.py
│   │   ├── time_tracker.py
│   │   └── history.py
│   │
│   ├── services/
│   │   ├── habit_service.py
│   │   ├── task_service.py
│   │   ├── schedule_service.py
│   │   └── project_service.py
│   │
│   └── utils/
│       ├── date_utils.py
│       └── validation.py
│
└── tests/
    ├── test_habits.py
    ├── test_tasks.py
    └── test_daily_scheduler.py
```

This structure can be adjusted if the implementation needs a simpler layout.

---

## Testing Guidelines

For MVP 1, test the habit logic where practical.

Important behaviours to test:

- Create a habit.
- Fetch active habits.
- Mark a habit as done for today.
- Prevent duplicate entries for the same habit and date.
- Undo today's completion.
- Fetch completed dates for a month.
- Calculate current streak.
- Calculate monthly completion percentage.

---

## Git Guidelines

Use clear commit messages.

Examples:

```text
Add habit tables
Add habit tracker page
Add done and undo logic
Add habit calendar display
Add streak calculation
Update plan for habit tracker MVP
```

Before committing:

1. Check changed files.
2. Confirm no secrets are included.
3. Run tests if available.
4. Update `plan.md` after meaningful progress.

---

## Documentation Guidelines

Keep these files updated:

- `README.md` for setup and usage.
- `plan.md` for roadmap and progress.
- `agent.md` for AI coding instructions.

Update `plan.md` when a stage is completed or when the project direction changes.

Do not modify `agent.md` unless the user explicitly asks for instruction changes.

---

## Instructions for AI Coding Agents

Before making code changes:

1. Read `agent.md`.
2. Read `plan.md`.
3. Confirm the current development focus.
4. Make only the requested changes.
5. Avoid building future modules too early.
6. Preserve historical data behaviour.
7. Keep secrets out of Git.
8. Update `plan.md` after meaningful progress.

When uncertain, choose the simpler implementation that supports the current MVP.
