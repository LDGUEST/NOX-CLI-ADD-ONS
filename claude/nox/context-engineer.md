---
name: context-engineer
description: Audit and govern all AI context files — health scoring, armor enforcement, bloat detection, cross-project drift. Never writes to global system files.
metadata:
  author: nox
  version: "1.6"
---

Discover, audit, and govern all AI context files across your projects. Enforces armor, scores health, detects cross-project drift, and asks the right questions to fill gaps. Built for solo developers juggling dozens of projects.

## When to Use

- Starting a session on a project you haven't touched in weeks
- After a multi-agent session where several AIs modified context files
- Periodic maintenance ("context hygiene day")
- When context files feel bloated, stale, or contradictory
- When starting a new project and need proper context scaffolding

## Arguments

- *(empty)* — audit current project only
- `--all` — sweep all projects in the workspace directory
- `--project <name>` — audit a specific project by name
- `--fix` — auto-propose fixes (still asks confirmation before writing)
- `--score-only` — just show the health dashboard, no remediation
- `--codebase` — include codebase-level diagnostics (large files, import chains, security scan)

## Context File Registry

| File | Purpose | Global Location |
|------|---------|-----------------|
| `CLAUDE.md` | Claude Code project context | `~/.claude/CLAUDE.md` (read-only) |
| `CLAUDE.local.md` | Deprecated local overrides — flag for migration | — |
| `MEMORY.md` | Accumulated learnings | `~/.claude/projects/*/memory/MEMORY.md` |
| `DEBUGGING.md` | Multi-model debugging knowledge | — |
| `GEMINI.md` | Gemini CLI context | `~/.gemini/GEMINI.md` (read-only) |
| `.cursorrules` | Cursor AI rules | — |
| `.clinerules` | Cline rules | — |
| `.windsurfrules` | Windsurf rules | — |
| `.roomodes` | Roo Code mode definitions | — |
| `copilot-instructions.md` | GitHub Copilot instructions | `.github/copilot-instructions.md` |
| `AGENTS.md` | Agent definitions | — |
| `.claude/settings.json` | Claude Code project settings | `~/.claude/settings.json` (read-only) |

## Process

### Phase 1: Discovery

Find all context files at project root, subdirectories (maxdepth 2), and global config locations. For each file record: path, line count, last modified date, whether it has a NOX-ARMOR header, and size category (lean <50, normal 50-150, heavy 150-250, bloated >250).

### Phase 2: Diagnostics

Run these checks. Flag findings — they feed into health scoring as deductions (❌ = -5 Accuracy, ⚠️ = -2 Bloat/Consistency, 🔒 = -10 Accuracy).

**Context file checks:**
- ❌ Circular references — build a reference graph across all context files, detect cycles
- ❌ Missing references — extract every file path mentioned in context files, verify each exists on disk
- ⚠️ Duplicate references — same file/section mentioned 2+ times within or across context files
- ⚠️ Deep reference chains — CLAUDE.md hierarchies deeper than 3 levels (root → sub → sub/sub → ...)
- 🔒 Exposed secrets — scan context files for API keys, tokens, passwords (patterns: sk-, pk_, Bearer, PRIVATE_KEY, -----BEGIN)

**Codebase checks (with `--codebase` or `--all`):**
- ❌ Circular imports — build import graph from import/require statements, detect cycles
- ❌ Missing import files — resolve each import path, flag any that don't exist on disk
- ⚠️ Large files (>1MB) — exclude .git, node_modules, .next, dist, build, .vercel
- ⚠️ Deep import chains — import hierarchies deeper than 5 levels
- ⚠️ Duplicate imports — same module imported multiple times in a single file
- 🔒 Security issues — hardcoded secrets in source files, .env not in .gitignore

Output format:
```
Diagnostics
━━━━━━━━━━━
Context Files:
  ❌ Circular references: 0    ❌ Missing references: 2
  ⚠️ Duplicate refs: 1         ⚠️ Deep chains: 0
  🔒 Exposed secrets: 1        → MEMORY.md:15 "sk-..."

Codebase (--codebase):
  ❌ Circular imports: 1       ❌ Missing imports: 0
  ⚠️ Large files: 2            ⚠️ Deep chains: 1 (depth: 7)
  ⚠️ Duplicate imports: 3      🔒 Security issues: 1
```

### Phase 3: Health Scoring (0-100)

| Dimension | Weight | Scoring |
|-----------|--------|---------|
| Completeness | 20 | CLAUDE.md (+10), MEMORY.md (+5), DEBUGGING.md (+3), other (+2) |
| Freshness | 20 | All files <30 days (+20), 30-90 days (+10), >90 days (+0). -5 per stale reference. |
| Accuracy | 20 | Stack matches package.json (+10), env vars match code (+5), paths valid (+5). Diagnostic deductions apply. |
| Protection | 15 | CLAUDE.md armored (+8), MEMORY.md armored (+4), other protected (+3) |
| Consistency | 15 | Matches global conventions (+8), no contradictions (+7) |
| Bloat | 10 | All files under limit (+5), no duplicates (+3), no orphans (+2) |

### Phase 4: Report

```
Context Health Dashboard
━━━━━━━━━━━━━━━━━━━━━━━━
Project                  Score   Grade   Issues
─────────────────────────────────────────────────
Scriber                  72/100  C       [no armor] [stale env vars]
GAV-Admin                88/100  B+      [1 stale entry]

Grade scale: A (90-100) B (80-89) C (70-79) D (60-69) F (<60)

DIAGNOSTICS:
  ❌ Circular refs: 0   ❌ Missing refs: 1   🔒 Security: 0

GLOBAL CONTEXT (read-only):
  ~/.claude/CLAUDE.md  — 180 lines — armored: NO — last modified: 2026-03-01
  ~/.claude/MEMORY.md  — 42 lines  — armored: NO — last modified: 2026-03-05
```

### Phase 5: Armor Check

For each context file without a NOX-ARMOR header, ask:

- **CLAUDE.md**: Which sections to lock? Max line count (suggest 150-200)? Any sections that should auto-expire?
- **MEMORY.md**: Max entries before flagging for review (suggest 30-50)? Age threshold (suggest 90 days)? Required categories?
- **DEBUGGING.md**: Archive solved bugs after N days (suggest 60)? Lock attribution format?

Generate the armor header from answers, show the proposed change, confirm before writing.

### Phase 6: Remediation (if --fix or user requests)

For each issue, propose the exact fix, show the diff, and ask before applying:
- **Stale entries** → update with current info
- **Missing files** → generate from codebase analysis (never from a blank template)
- **Bloated files** → show what can move to subdirectory CLAUDE.md files or MEMORY.md
- **Cross-project inconsistencies** → align with global conventions
- **Missing armor** → run the Phase 5 questionnaire

### Phase 7: Cross-Project Sync (--all only)

- Global propagation — patterns in global CLAUDE.md that should exist in all project files
- Convention drift — same concept described differently across projects
- Orphaned memories — global MEMORY.md entries referencing projects that no longer exist
- Missing subsystem CLAUDE.md — subdirectories with >5 source files and no local CLAUDE.md

## Output Summary

```
Context Engineering Report
━━━━━━━━━━━━━━━━━━━━━━━━━━
Projects scanned: 12  |  Files found: 34  |  Avg score: 71/100

Actions taken:
  ✓ 3 files armored   ✓ 5 stale entries flagged
  ✓ 1 CLAUDE.md generated   ⊘ 4 issues deferred

Next audit: 2026-04-08 (30 days)
```

## Rules

- Global system files (`~/.claude/CLAUDE.md`, `~/.claude/settings.json`, `~/.gemini/GEMINI.md`) are read-only — use them for scoring and consistency checks only, never write to them. If the global CLAUDE.md exceeds 200 lines, flag the bloat and suggest what to move to project level; don't add anything to it.
- Show the exact diff and get confirmation before modifying any file.
- Archive or flag context entries rather than deleting them — deleted history can't be recovered.
- Health scores must be based on verifiable facts. If a dimension can't be verified, score it 0 and explain why.
- Generate missing CLAUDE.md files from actual codebase analysis (package.json, imports, structure) — a blank template produces useless context.
- Respect existing armor headers — locked sections stay locked unless the user explicitly unlocks them.
- The Phase 5 questionnaire is required for first-time armor — skipping it produces headers that don't reflect what the user actually wants to protect.
- In `--all` mode, ask permission before scanning projects outside the current workspace.
- Use `[maybe stale]` when uncertain — silent removal is worse than a false positive.

---
Nox
