# NOX Roadmap

## v1.0 — Foundation (shipped 2026-03-02)

- [x] 28 skills across 6 categories
- [x] Claude Code, Gemini CLI, and Codex CLI support
- [x] Auto-installer with `--symlink`, `--claude-only`, `--gemini-only`, `--codex-only`
- [x] GSD combo skills (`full-phase`, `quick-phase`)
- [x] Multi-agent coordination suite (syncagents, handoff, unloop, iterate, overwrite, error)
- [x] Zero-config install — no API keys, no dependencies

---

## v1.1–1.6 — Agents, Hooks, & Skills v2 (shipped through 2026-03-09)

- [x] 8 Claude Code agents for parallel quality gates
- [x] 23 hooks across 8 hook events (up from 2 hooks in v1.0)
- [x] MCP server — any MCP client can invoke Nox skills
- [x] One-liner curl install
- [x] `/nox:guardrails` — inline safety checks for Gemini/Codex
- [x] YAML frontmatter on all skills (Agent Skills Open Standard)
- [x] `/nox:scan` meta-skill dispatching 4 parallel agents
- [x] `/nox:context-engineer` with 11 structural diagnostics
- [x] Progressive disclosure on heavy skills
- [x] Skill count: 28 → 35

---

## v2.0 — Production Hardening (shipped 2026-03-14)

- [x] Skills v2 frontmatter — `disable-model-invocation`, `argument-hint`, `user-invocable`, `context: fork`, `agent`
- [x] Subagent isolation (`context: fork`) on 12 heavy skills
- [x] 35/35 cross-CLI content parity (Claude → Gemini/Codex sync)
- [x] `lib-json.sh` — shared POSIX ERE JSON extraction (~50x faster than python3)
- [x] Session cost tracker with SQLite metrics DB
- [x] `nox-metrics.sh` — query tool for A/B comparison (hooks ON vs OFF)
- [x] CI pipeline (`.github/workflows/ci.yml`)
- [x] Hook + install test suites (45 tests total)
- [x] Content parity validation in `validate.sh`
- [x] Windows Git Bash compatibility fixes across all hooks
- [x] Repo renamed to `NOX-CLI-ADD-ONS`

---

## v2.5 — New Skills & Hook Intelligence (shipped 2026-03-14)

Expanded the skill catalog with 6 high-demand additions, made hooks smarter, and improved Windows compatibility.

### New Skills
- [x] **`/nox:doc`** — Generate documentation from code (JSDoc, docstrings, README sections)
- [x] **`/nox:api`** — Design and scaffold REST/GraphQL API endpoints from a spec
- [x] **`/nox:schema`** — Database schema designer — ER diagrams, migration planning, normalization review
- [x] **`/nox:env`** — Environment variable auditor — find missing vars, detect secrets in code, generate `.env.example`
- [x] **`/nox:explain`** — Onboarding guide generator — explain any codebase to a new contributor
- [x] **`/nox:a11y`** — Accessibility audit — WCAG compliance, ARIA, keyboard nav, color contrast

### Hook Improvements
- [x] **Smart hook routing** — hooks skip irrelevant events faster via early-exit fast paths
- [x] **Hook health dashboard** — `nox-metrics.sh health` validates hook files, checks settings references, reports broken hooks

### Infrastructure
- [x] **SQLite fallback to JSONL** — session cost tracker falls back to `.nox_metrics.jsonl` when sqlite3 is unavailable (Windows)
- [x] **JSONL metrics queries** — `nox-metrics.sh` supports `summary` and `recent` without sqlite3
- [x] **Smoke test suite** — `tests/test-smoke.sh` validates skill parity, frontmatter, hook presence, and lib-json sourcing
- [x] Skill count: 35 → 41

---

## v3.0 — Platform & Community

The jump from "personal tool" to "team/community platform."

### Skill Ecosystem
- [ ] **Nox Hub** — community skill registry: submit, browse, install third-party skills via `nox install <author>/<skill>`
- [ ] **Skill packs** — curated bundles by use case (frontend, backend, DevOps, data, security)
- [ ] **Skill versioning** — skills declare compatibility ranges, `nox update` respects semver
- [ ] **Skill dependencies** — skills can declare they need other skills (e.g., `full-phase` requires `architect`)

### Team Features
- [ ] **Team configs** — shared `.noxrc` for team-wide skill settings, quality gates, and hook policies
- [ ] **Org-level metrics** — aggregate cost/efficiency data across team members
- [ ] **Skill allowlists** — admins control which skills are available to the team
- [ ] **Shared hook policies** — enforce org-wide guardrails (e.g., "no force push", "always lint commits")

### Metrics & Observability
- [ ] **Metrics dashboard** — web UI or TUI for session costs, skill usage, hook performance, model comparison
- [ ] **Cost alerting** — configurable thresholds with Slack/email notifications
- [ ] **Skill analytics** — which skills save the most time, which are never used, adoption trends

### Cross-IDE Support
- [ ] **Cursor integration** — Nox skills as Cursor rules (`.cursor/rules/`)
- [ ] **Windsurf / Cline / Aider support** — skill format adapters for additional AI editors
- [ ] **VS Code extension** — skill browser, hook status, metrics sidebar

### Advanced Automation
- [ ] **Skill chaining** — skills call other skills (e.g., `commit` auto-runs `review` first)
- [ ] **Conditional hooks** — hooks that only fire for specific projects, branches, or file patterns
- [ ] **Agent profiles** — configure skill behavior per role ("strict reviewer" vs "fast shipper" vs "learning mode")
- [ ] **Recovery mode** — on session crash, auto-restore context from cost tracker + handoff notes

---

## Ideas (unscheduled)

- [ ] **`/nox:translate`** — i18n extraction and translation management
- [ ] **`/nox:design`** — generate UI mockups (ASCII wireframes or component specs)
- [ ] **`/nox:legal`** — license compliance checker across all dependencies
- [ ] **`/nox:estimate`** — effort estimation for tasks based on codebase analysis
- [ ] **`/nox:monitor`** — generate monitoring configs (Prometheus, Grafana, alerting rules)
- [ ] **`/nox:bench`** — benchmark runner — profile functions, compare before/after
- [ ] **Nox CLI** — standalone `nox` binary that wraps all commands without needing a host CLI
- [ ] **Plugin system** — hooks for custom pre/post logic on any skill
- [ ] **Skill playground** — web UI to test skills against sample repos before installing
- [ ] **AI model routing** — skills auto-select the best model for the task (Opus for review, Haiku for lint)
