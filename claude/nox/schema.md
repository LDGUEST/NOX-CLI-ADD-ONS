---
name: schema
description: Designs, reviews, and migrates database schemas — generates ER diagrams, migration plans, and normalization analysis. Use when building or evolving a data model.
argument-hint: "[action]"
context: fork
agent: general-purpose
metadata:
  author: nox
  version: "2.5"
---

Database schema designer and reviewer. Analyze, design, or migrate database schemas with full migration planning and rollback strategies.

## Actions

Select based on user input or infer from context:

| Action | When to use |
|--------|-------------|
| `design` | Build a new schema from requirements |
| `review` | Audit an existing schema for issues |
| `migrate` | Plan schema changes with up/down migrations |
| `normalize` | Analyze normalization level, suggest improvements |
| `visualize` | Generate an ASCII ER diagram of the current schema |

---

## ORM / Database Detection

Scan the project to determine the data layer:

| Signal | Stack |
|--------|-------|
| `schema.prisma` | Prisma (PostgreSQL/MySQL/SQLite) |
| `drizzle.config.ts` or `drizzle/` | Drizzle ORM |
| `models.py` + Django | Django ORM |
| `alembic/` or SQLAlchemy imports | SQLAlchemy |
| `supabase/migrations/` | Supabase (raw SQL) |
| `*.sql` migration files | Raw SQL |
| None found | Ask the user |

---

## Action: Design

1. Gather requirements — entities, relationships, constraints
2. Identify cardinality (1:1, 1:N, M:N) and resolve junction tables
3. Choose appropriate column types (prefer specific types: `uuid` over `text` for IDs, `timestamptz` over `timestamp`)
4. Add standard fields: `id`, `created_at`, `updated_at`
5. Define indexes for foreign keys and common query patterns
6. Generate the schema in the detected ORM format or raw SQL
7. Produce an ASCII ER diagram

## Action: Review

Audit the existing schema for:

- **Normalization issues** — Redundant data, denormalization without justification
- **Missing indexes** — Foreign keys without indexes, common query columns unindexed
- **Type mismatches** — Strings for IDs, integers for booleans, text for enums
- **Naming inconsistencies** — Mixed conventions (camelCase vs snake_case, singular vs plural)
- **Missing constraints** — No NOT NULL where required, no CHECK constraints, no unique constraints
- **Orphan risk** — Foreign keys without CASCADE or SET NULL on delete
- **RLS gaps** — (Supabase) Tables exposed without Row Level Security policies

## Action: Migrate

1. Diff the current schema against the target state
2. Generate migration files in the project's format (Prisma migrate, Drizzle, Alembic, raw SQL)
3. Include both **up** and **down** migrations
4. Flag destructive operations (column drops, type changes, table drops)
5. Suggest a deployment order if migrations have dependencies
6. Provide a rollback plan for each step

### Migration Safety Checklist

- [ ] No data loss without explicit user confirmation
- [ ] Large table migrations use batched operations
- [ ] Index creation uses `CONCURRENTLY` where supported
- [ ] Enum changes are additive (new values only) or use a safe rename strategy
- [ ] Foreign key changes don't break existing data

## Action: Normalize

Analyze the schema's normalization level (1NF through BCNF) and report:

- Current normalization level per table
- Functional dependencies that violate the next normal form
- Concrete suggestions to normalize further (with tradeoff analysis — sometimes denormalization is correct)

## Action: Visualize

Generate an ASCII ER diagram:

```
┌──────────────┐       ┌──────────────────┐
│   users       │       │   posts           │
├──────────────┤       ├──────────────────┤
│ id        PK │───┐   │ id            PK │
│ email     UQ │   │   │ user_id       FK │──┐
│ name         │   └──▶│ title            │  │
│ created_at   │       │ content          │  │
└──────────────┘       │ published_at     │  │
                       └──────────────────┘  │
                       ┌──────────────────┐  │
                       │   comments        │  │
                       ├──────────────────┤  │
                       │ id            PK │  │
                       │ post_id       FK │──┘
                       │ author_id     FK │
                       │ body             │
                       └──────────────────┘
```

Include: primary keys, foreign keys, unique constraints, and cardinality indicators.

## Output Format

Present findings as a structured report. For design and migrate actions, show the full schema/migration code and wait for approval before writing files.

---
Nox
