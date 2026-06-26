# Personal Planner & Tracker — plan.md

## 1. Project Overview

**Project name:** Personal Planner & Tracker

This project is a personal productivity and life-tracking application. It will eventually include:

- Habit Tracker
- To-do List
- Daily Scheduler
- Projects / Goals
- Time Tracker
- History / Review
- Events / Reminders

The app should help with daily planning, task organisation, habit tracking, time tracking, and long-term review.

The first development focus is the **Habit Tracker**, but this is only the first module of the wider project.

---

## 2. Product Principle

The most important principle is:

> Preserve historical records.

The app should not simply overwrite old data. Past habit records, completed tasks, daily schedules, tracker entries, time logs, and notes should remain available for daily, weekly, and monthly review.

For example, if a task is planned today but moved to tomorrow, today's record should still show that the task was planned and moved.

---

## 3. Data Storage Decision

The project will use **Supabase PostgreSQL** as the main database from the start.

Reason:

- Supabase is already set up.
- PostgreSQL is suitable for structured relational data.
- The app needs linked records such as habits, tasks, daily schedules, projects, and time logs.
- The app should preserve old data for historical review.
- Supabase allows future cloud access, authentication, and deployment.

The app should not use CSV, JSON, or Markdown files as the main storage format.

Database credentials should be stored locally in:

```text
.streamlit/secrets.toml
```

Secrets must not be committed to GitHub.

---

## 4. Overall Product Scope

The final app should contain the following modules.

| Module | Purpose | Build Order |
|---|---|---:|
| Habit Tracker | Daily repeated habits, green calendar, streaks | 1 |
| To-do List | Specific tasks, due dates, priorities, status | 2 |
| Daily Scheduler | Daily timetable and linked tasks | 3 |
| Projects / Goals | Larger areas such as house purchase, English, driving | 4 |
| Time Tracker | Planned vs actual time spent | 5 |
| History / Review | Daily, weekly, and monthly summaries | 6 |
| Events / Reminders | Scheduled events and alerts | 7 |

---

## 5. MVP Roadmap

### MVP 1 — Habit Tracker

Build the Habit Tracker first.

Requirements:

- Create habits.
- Add habit name, description, category, and optional icon.
- Show habits as cards.
- Mark a habit as done for today.
- Allow undo if the habit was clicked by mistake.
- Show a mini monthly calendar for each habit.
- Display completed days in green.
- Show current streak.
- Show monthly completion percentage.
- Store habit history in Supabase PostgreSQL.
- Do not build the To-do List or Daily Scheduler in this MVP.

Initial database tables:

- `habits`
- `habit_entries`

Status: Not started

---

### MVP 2 — To-do List

After the Habit Tracker is working, build the task system.

Requirements:

- Create tasks.
- Edit tasks.
- Set due dates.
- Set priorities.
- Set task status.
- Mark tasks as done.
- Preserve completed task history.
- Optionally link tasks to projects/goals later.

Database tables:

- `tasks`

Status: Future

---

### MVP 3 — Daily Scheduler

After the To-do List is working, build the Daily Scheduler.

Requirements:

- Create one daily schedule per date.
- Add time blocks.
- Link tasks to time blocks.
- Mark schedule items as done, skipped, moved, or cancelled.
- Preserve past daily schedules.
- Allow unfinished tasks to be moved to another date without deleting the original record.

Database tables:

- `daily_plans`
- `daily_plan_items`

Status: Future

---

### MVP 4 — Projects / Goals

After tasks and daily scheduling are working, add project/goal organisation.

Requirements:

- Create large goals or project areas.
- Link tasks to projects/goals.
- Track project status.
- Review project progress.

Database tables:

- `projects`

Status: Future

---

### MVP 5 — Time Tracking

Add time tracking after the scheduler is stable.

Requirements:

- Add estimated time.
- Add actual time.
- Record time spent by task.
- Record time spent by project.
- Compare planned vs actual time.

Database tables:

- `time_logs`

Status: Future

---

### MVP 6 — History / Review

Add review pages after enough historical data exists.

Requirements:

- Daily history.
- Weekly review.
- Monthly review.
- Habit completion summary.
- Task completion summary.
- Time spent summary.

Status: Future

---

### MVP 7 — Events / Reminders

Add scheduled events and reminders later.

Requirements:

- Create scheduled events.
- Add reminder settings.
- Support recurring events.
- Show events in the Daily Scheduler.
- Add calendar-style view.

Database tables:

- `events`
- `reminders`

Status: Future

---

## 6. Habit Tracker MVP Detail

The first version should look and behave similarly to a Notion-style habit tracker.

Each habit card should show:

- Habit name
- Optional icon
- Description
- Category
- Done button if today has not been completed
- Undo button if today has already been completed
- Mini calendar for the selected month
- Green completed days
- Current streak
- Monthly completion percentage

### Done / Undo Behaviour

When the user clicks **Done**:

- If no record exists for today, insert a new `habit_entries` record.
- If a record already exists, do not create a duplicate.

When the user clicks **Undo**:

- Remove today's `habit_entries` record for that habit.
- This allows mistaken clicks to be corrected.

For the MVP, undo can delete today's entry. Later, the app may use soft delete or audit history if needed.

---

## 7. Suggested Database Schema

### 7.1 `habits`

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

### 7.2 `habit_entries`

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

### 7.3 Future Tables

Future modules may use:

- `projects`
- `tasks`
- `daily_plans`
- `daily_plan_items`
- `time_logs`
- `events`
- `reminders`
- `trackers`
- `tracker_entries`

These should not be built until needed unless the user explicitly requests them.

---

## 8. Suggested App Structure

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
│   └── secrets.toml          # local only, do not commit
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

---

## 9. Development Stages

### Stage 1 — Project Setup

- Create repository.
- Add `README.md`.
- Add `plan.md`.
- Add `agent.md`.
- Add `.gitignore`.
- Set up Streamlit project.
- Set up Python virtual environment.
- Add Supabase database connection configuration.

Status: Not started

---

### Stage 2 — Habit Tracker Database

- Create `habits` table.
- Create `habit_entries` table.
- Add unique constraint for one habit entry per habit per date.
- Add sample habits for testing.

Status: Not started

---

### Stage 3 — Habit Tracker UI

- Create Habit Tracker page.
- Display active habits as cards.
- Add new habit form.
- Add Done button.
- Add Undo button.
- Show current month mini calendar.
- Display completed days in green.

Status: Not started

Update:

- The current front-end now supports a shared typed item model for `habit` and `tracking` items.
- Tracking logs use the same date-level entry records as habits, but are excluded from habit dashboard metrics.
- Calendar rendering should keep showing both item types together so recorded dates can be reviewed alongside habit activity.
- Habit items keep weekly-target and streak-oriented wording, while tracking items use neutral record wording.

---

### Stage 4 — Habit Metrics

- Calculate current streak.
- Calculate monthly completion count.
- Calculate monthly completion percentage.
- Display metrics on each habit card.

Status: Not started

---

### Stage 5 — Habit Management

- Edit habit name.
- Edit description.
- Edit category.
- Archive inactive habits.
- Avoid hard deletion unless explicitly requested.

Status: Future

---

## 10. Current Priority

Current focus:

> Build MVP 1: Habit Tracker.

Do not start the To-do List, Daily Scheduler, Project system, Time Tracker, or Reminder system until the Habit Tracker MVP is working.

---

## 11. Notes for Future Review

The app should eventually support daily, weekly, and monthly review.

Possible future review questions:

- Which habits were completed most consistently?
- Which tasks were completed this week?
- What was planned but not completed?
- How much time was spent on each project?
- What patterns appear across the month?

These review features should be built after enough data exists.
