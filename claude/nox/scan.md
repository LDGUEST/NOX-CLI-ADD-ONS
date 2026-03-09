Auto-detect your project type and dispatch relevant NOX agents in parallel. Instead of memorizing which skills to run, just scan — NOX figures out what matters and tells you what it found.

## When to Use

- Starting a session on any project — run this first
- When you're not sure which NOX skills are relevant to your codebase
- Before a deploy, merge, or handoff — quick health check
- When the user says "check everything", "what's wrong?", or "audit this"

## Arguments

`$ARGUMENTS` — Scope control:
- *(empty)* — balanced scan, dispatches 3-5 agents based on project type
- `--quick` — fast scan, 2-3 agents max, surface-level only
- `--deep` — full scan, all applicable agents, thorough analysis
- `--focus <area>` — targeted: `security`, `perf`, `quality`, `context`, `deps`

## Process

### Phase 1: Project Detection

Detect the project type and what's present:

```bash
# Framework detection
ls package.json go.mod Cargo.toml pyproject.toml requirements.txt pom.xml 2>/dev/null

# Framework specifics
ls next.config.* vite.config.* astro.config.* svelte.config.* nuxt.config.* 2>/dev/null

# What exists in this project
ls -d .git test* __test* spec* .github src components pages app lib 2>/dev/null

# Context files
ls CLAUDE.md MEMORY.md DEBUGGING.md .cursorrules AGENTS.md 2>/dev/null

# Infrastructure
ls Dockerfile docker-compose* .github/workflows/* .env.example 2>/dev/null
```

Build a detection profile:

```
PROJECT PROFILE
━━━━━━━━━━━━━━
Framework:    Next.js 14 (App Router)
Language:     TypeScript
Package Mgr:  npm (package-lock.json)
Auth:         Auth0 (detected from @auth0/nextjs-auth0)
Database:     Supabase (detected from @supabase/supabase-js)
Tests:        Jest (jest.config.ts found, 23 test files)
CI:           GitHub Actions (2 workflows)
Context:      CLAUDE.md (142 lines), MEMORY.md (38 lines)
Deploy:       Vercel (vercel.json found)
```

### Phase 2: Agent Selection

Based on the profile, select which agents to dispatch. Use this priority matrix:

| Agent | Dispatch When | Priority |
|-------|---------------|----------|
| `nox-reviewer` | Always (any project with source code) | HIGH |
| `nox-security-scanner` | Auth, API routes, env vars, user input detected | HIGH |
| `nox-dep-auditor` | package.json/go.mod/Cargo.toml exists | MEDIUM |
| `context-engineer` | Context files exist OR are missing but should exist | MEDIUM |
| `nox-perf-profiler` | Frontend detected, or DB queries, or >50 source files | LOW |
| `nox-ux-tester` | Frontend with pages/routes detected | LOW |
| `nox-prompt-auditor` | LLM/AI API imports detected (anthropic, openai, etc.) | LOW |

**Agent limits by mode:**
- `--quick`: max 2 agents (highest priority only)
- *(default)*: max 4 agents
- `--deep`: all applicable agents (no limit)
- `--focus`: only agents relevant to the focus area

**Focus area mapping:**
- `--focus security` → security-scanner + dep-auditor
- `--focus perf` → perf-profiler + reviewer (perf dimension only)
- `--focus quality` → reviewer + context-engineer
- `--focus context` → context-engineer only (with --all flag)
- `--focus deps` → dep-auditor only (thorough mode)

### Phase 3: Parallel Dispatch

Launch selected agents in parallel using the Agent tool. Each agent runs independently and returns findings.

```
Scanning: MyProject (Next.js 14 + Supabase + Auth0)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Dispatching 4 agents:
  ▸ nox-reviewer — scanning code quality...
  ▸ nox-security-scanner — checking OWASP top 10...
  ▸ nox-dep-auditor — auditing 142 dependencies...
  ▸ context-engineer — checking context health...

Working... (results appear as agents complete)
```

### Phase 4: Results Dashboard

As agents complete, compile findings into a single dashboard:

```
NOX Scan Results
━━━━━━━━━━━━━━━━
Project: MyProject | Framework: Next.js 14 | Scanned: 2026-03-08

CODE QUALITY                                         ⚠ 3 findings
  ⚠ [warning] Unused import in src/lib/utils.ts:14
  ⚠ [warning] Function exceeds 80 lines: src/app/api/webhook/route.ts:processEvent()
  ⚠ [nit] Inconsistent error handling in 2 API routes

SECURITY                                             ✗ 1 critical
  ✗ [critical] No CSRF protection on /api/settings POST endpoint
  ⚠ [warning] Rate limiting not configured for auth endpoints

DEPENDENCIES                                         ⚠ 2 findings
  ⚠ [warning] 4 packages outdated (minor versions)
  ℹ [info] All licenses compatible (MIT, Apache-2.0)

CONTEXT HEALTH                                       Score: 78/100
  ⚠ [no armor] CLAUDE.md has no NOX-ARMOR header
  ✓ MEMORY.md up to date (last modified 2 days ago)

SUMMARY
  Critical: 1 | Warnings: 5 | Info: 1
  Action needed: Fix CSRF protection before deploy
```

### Phase 5: Recommendations

Based on findings, suggest specific NOX skills to run:

```
Recommended next steps:
  1. /nox:security — fix the CSRF critical finding
  2. /nox:armor — protect CLAUDE.md and stabilized modules
  3. /nox:refactor — clean up the 80+ line function
```

## Rules

- **Never block the user** — scan runs in the background, user can keep working
- **Max 5 agents** in default mode — more than that is noisy, not helpful
- **Don't fabricate findings** — if an agent returns nothing, report "all clear" for that category
- **Respect existing context** — read CLAUDE.md first to understand project conventions before judging
- **Deduplicate** — if two agents find the same issue, report it once
- **Actionable output only** — every finding must suggest a specific next step or skill to run
- **No auto-fix** — scan reports, it doesn't change code. The user decides what to act on.
- **Cache detection** — if the project profile hasn't changed since last scan, note it ("Same profile as last scan — showing delta only")
- **Be honest about coverage** — if you couldn't scan something (no tests to analyze, no frontend to check), say so instead of implying coverage

---
Nox
