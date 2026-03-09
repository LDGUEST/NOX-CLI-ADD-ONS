Auto-detect project type and dispatch relevant NOX agents in parallel. Proactive codebase health check that runs on session start — detects what you're working with and sends the right specialists to audit it without blocking your workflow.

## When to Use

- At the start of any new session on an existing project
- When picking up a project you haven't touched in a while
- When the user says "scan this", "check the project", or "what's the health of this codebase?"
- As a first step before diving into any major feature work

## Arguments

- *(empty)* — standard scan, 3-5 agents based on detection
- `--quick` — fast scan, max 3 agents, skip deep analysis
- `--deep` — comprehensive scan, all applicable agents
- `--focus security|perf|quality` — bias agent selection toward a specific concern

## Process

### Phase 1: Project Detection

Identify the project type from manifest files:

| File | Type |
|------|------|
| `package.json` + `next.config.*` | Next.js |
| `package.json` + `vite.config.*` | Vite + React |
| `go.mod` | Go |
| `Cargo.toml` | Rust |
| `pyproject.toml` / `requirements.txt` | Python |
| `package.json` (plain) | Node.js |
| None of the above | Generic / unknown |

### Phase 2: Capability Detection

Scan for what's present in the project:

- **Tests** — test directories, test config files (jest.config, vitest, pytest, etc.)
- **CI/CD** — .github/workflows, .gitlab-ci.yml, Dockerfile
- **Context files** — CLAUDE.md, MEMORY.md, DEBUGGING.md, .cursorrules, GEMINI.md
- **Auth** — auth libraries, auth routes, middleware
- **Database** — ORMs, migration files, schema files
- **Dependencies** — lock file age, outdated packages
- **Security** — .env files committed, secrets in code, known vulnerable patterns

### Phase 3: Agent Dispatch

Based on detection, select and dispatch 3-5 agents in parallel (max 5):

| Agent | Dispatched When |
|-------|----------------|
| `reviewer` | Always — general code quality pass |
| `security` | Auth present, env files found, or `--focus security` |
| `dep-auditor` | Lock file > 30 days old, or many dependencies |
| `context-engineer` | Missing or stale context files |
| `perf` | Large bundle, slow CI, or `--focus perf` |
| `tdd` | Tests exist but coverage looks low |
| `refactor` | Code duplication or large files detected |

Dispatch agents as background tasks. Do not block the user.

### Phase 4: Dashboard

When agents complete, present a consolidated dashboard:

```
SCAN REPORT — [project name] — [date]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Project: [type] | [framework] | [language]
Agents dispatched: [count]

FINDINGS:
  [agent]  [severity]  [summary]
  [agent]  [severity]  [summary]

TOP ACTIONS:
  1. [most impactful fix]
  2. [second most impactful]
  3. [third]
```

Severity levels: CRITICAL / WARNING / INFO

## Rules

- **Never block** — all agent dispatches run in the background. The user can keep working.
- **Max 5 agents** — even in `--deep` mode. Prioritize by likely impact.
- **Respect existing context files** — if CLAUDE.md, MEMORY.md exist, read them first. Don't duplicate work they already describe.
- **No auto-fix** — scan reports findings only. Fixing requires explicit user action.
- **Quick mode = fast answers** — `--quick` should complete in under 30 seconds. Skip deep analysis.
- **Be honest about unknowns** — if detection is ambiguous, say so. Don't guess project type.

---
Nox
