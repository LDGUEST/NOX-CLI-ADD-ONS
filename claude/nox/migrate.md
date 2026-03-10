---
name: migrate
description: Generate a database migration for a schema change. Auto-detects ORM and migration framework.
metadata:
  author: nox
  version: "1.6"
---

Generate a database migration for the requested schema change. Auto-detect the ORM and migration framework.

## Step 1: Detect Stack

Scan the project for:
- `prisma/schema.prisma` → **Prisma** (`npx prisma migrate dev`)
- `drizzle.config.*` → **Drizzle** (`npx drizzle-kit generate`)
- `knexfile.*` → **Knex** (`npx knex migrate:make`)
- `alembic.ini` or `migrations/` with Python → **Alembic** (`alembic revision`)
- `supabase/migrations/` → **Supabase** (`supabase migration new`)
- `django` in requirements → **Django** (`python manage.py makemigrations`)
- `ecto` in mix.exs → **Ecto** (`mix ecto.gen.migration`)
- Raw SQL files → Generate timestamped `.sql` migration

## Step 2: Generate Migration

1. Write the UP migration (apply the change)
2. Write the DOWN migration (reverse the change)
3. Handle data migrations if existing data needs transforming
4. Add appropriate indexes for new columns used in queries or joins

## Step 3: Validate

- Verify the migration is reversible
- Check for destructive operations (dropping columns/tables) and warn
- Ensure foreign key constraints are handled in the correct order
- Flag if the migration might lock large tables in production

## Safety Rules

- **Never drop a column/table without explicit confirmation**
- Always generate both UP and DOWN migrations
- For large tables, suggest batched migrations to avoid locks
- Test the migration against a local/staging database before production
- Include a rollback plan for every migration

---
Nox