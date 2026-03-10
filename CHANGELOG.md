# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.6.0] - 2026-03-09

### Added
- **YAML frontmatter** on all 34 Claude skills and 23 Codex skills — skills can now auto-invoke from natural language, not just explicit `/nox:name`
- **`/nox:scan`** — new meta-skill that auto-detects project type and dispatches up to 4 parallel agents (reviewer, security, dep-auditor, context-engineer)
- **`/nox:context-engineer` diagnostics** — Phase 2 now runs 11 structural + security checks: circular imports, missing references, large files, deep chains, duplicate imports, exposed secrets
- **Progressive disclosure** — `context-engineer` split into `SKILL.md` + `references/DIAGNOSTICS.md` for Codex/Gemini; Claude version trimmed from 353 → 166 lines
- **Global file protection** — `armor` and `context-engineer` now explicitly prohibit writes to `~/.claude/CLAUDE.md`, `~/.gemini/GEMINI.md`, and other system files
- **`disable-model-invocation: true`** on dangerous skills: `deploy`, `push`, `unloop`, `overwrite` — prevents accidental auto-triggering
- **`compatibility` field** on tools requiring specific deps: `uxtest` (Playwright), `scan` (Agent tool), `security`, `monitorlive`, `cicd`
- **`metadata` field** (`author: nox`, `version: "1.6"`) on all 34 Claude skills
- **GitHub issue templates** — bug report, feature request, skill idea
- **Skill count corrected** — README updated from 33 → 34 skills
- **`CLAUDE.local.md`** added to context-engineer registry (flagged as deprecated)
- **`--codebase` flag** on context-engineer for codebase-level diagnostic checks

### Changed
- **Expanded skills** — architect, landing, questions each rewritten with full phase-based process (from ~20 lines to 100-150 lines each)
- **`skill-create` updated** — now teaches spec-compliant format: frontmatter on all 3 CLIs, `references/` directories, `disable-model-invocation` for dangerous ops
- **Rules sections rewritten** — replaced ALL-CAPS NEVER/ALWAYS mandates with reasoning-based rules per Anthropic skill-creator guidance
- **`update` skill** — Windows path changed from hardcoded to `%USERPROFILE%` pattern

## [1.5.0] - 2026-03-06

### Added
- **MCP server** — any MCP-compatible client (Claude Desktop, Cursor, etc.) can invoke Nox skills via 3 tools: `nox_list`, `nox_skill`, `nox_agent`
- **One-liner curl install** — `curl -fsSL https://raw.githubusercontent.com/LDGUEST/NOX/main/install.sh | bash` clones to `~/.nox` and installs
- MCP server auto-registers in `~/.claude/.mcp.json` during install
- GitHub topics: `claude-code`, `gemini-cli`, `codex-cli`, `ai-skills`, `developer-tools`, `devops`, `security`

### Changed
- `install.sh` — bootstrap preamble for curl pipe detection + MCP server registration section
- `uninstall.sh` — MCP cleanup (removes from `.mcp.json`) + updated hook list to all 19 hooks + `~/.nox` cleanup hint
- Bumped `gemini-extension.json` version to 1.5.0

## [1.4.0] - 2026-03-06

### Added
- `/nox:guardrails` skill — inline safety checks that mirror all 19 Claude Code hooks for Gemini and Codex users
- Guardrails wired into 11 skills across all 3 CLIs (full-phase, quick-phase, iterate, unloop, refactor, tdd, review, audit, security, deploy, push)
- Skill count: 31 → 32

## [1.3.0] - 2026-03-06

### Added
- 12 new hooks expanding coverage from 2 to 8 hook events (19 total):
  - `auto-context` (SessionStart) — injects project state on every session start
  - `commit-lint` (PreToolUse) — enforces Conventional Commits format
  - `test-regression-guard` (PostToolUse) — tracks test pass/fail, warns on regression
  - `file-size-guard` (PreToolUse) — blocks oversized file writes (>500KB)
  - `todo-tracker` (PostToolUse) — detects and logs new TODO/FIXME comments
  - `compact-saver` (PreCompact) — saves context checkpoint before compaction
  - `session-logger` (Stop) — logs session summaries for work history
  - `agent-tracker` (SubagentStart) — detects runaway agent loops
  - `prompt-guard` (UserPromptSubmit) — warns on vague/destructive prompts
  - `drift-detector` (PostToolUse) — warns on large uncommitted diffs
  - `memory-auto-save` (Stop) — reminds to update DEBUGGING.md after fixes
- README "Why Nox?" panel with 3-column layout (Ship Faster, Catch Everything, Sleep Through It)

## [1.2.0] - 2026-03-06

### Changed
- Merged 5 skills into related skills, reducing total from 36 to 31:
  - `pentest` merged into `security` (security now has scan + pentest modes)
  - `deps` merged into `audit` (audit now includes dependency health)
  - `test` merged into `tdd` (tdd now includes test generation mode)
  - `simplify` merged into `review` (review now includes complexity check)
  - `error` merged into `diagnose` (diagnose now includes error investigation)
- Updated all cross-references in help-forge, full-phase, quick-phase, README, CONTRIBUTING
- Agents (`nox-pentester`, `nox-dep-auditor`, etc.) remain unchanged — they are subagents dispatched by full-phase

## [1.1.0] - 2026-03-06

### Added
- 8 Claude Code agents for parallel quality gate dispatch (`nox-reviewer`, `nox-security-scanner`, `nox-pentester`, `nox-dep-auditor`, `nox-perf-profiler`, `nox-ux-tester`, `nox-monitor`, `nox-prompt-auditor`)
- 7 Claude Code hooks with `--with-hooks` install flag (`destructive-guard`, `sync-guard`, `secret-scanner`, `debug-reminder`, `build-tracker`, `cost-alert`, `notify-complete` + `notify-timer-start`)
- Two-Layer Defense integration (hooks + agents) in `full-phase`, `iterate`, `unloop`
- Parallel quality gate dispatch in `full-phase` — 6 agents fire simultaneously
- `uninstall.sh` — clean removal of all installed skills, agents, and hooks
- `validate.sh` — confirms all 3 CLI formats are in sync
- `CONTRIBUTING.md` — skill authoring standards and contribution guide
- `CHANGELOG.md` — release history
- `LICENSE` — MIT

### Changed
- `full-phase` pipeline reduced from 14 sequential steps to 9 (parallel dispatch)
- `install.sh` now supports agents and hooks installation
- `help-forge` updated to show 36 skills + 8 agents

## [1.0.2] - 2026-03-04

### Added
- `/nox:brainstorm` — structured ideation before architecture or code
- `/nox:uxtest` — Playwright-based interactive UX testing
- `/nox:prompt` — review, optimize, and harden LLM prompts in codebase
- `/nox:skill-create` — scaffold new Nox skills in all 3 CLI formats
- `/nox:monitorlive` — real-time log monitoring during live testing

### Changed
- Pipeline skills now include Playwright UX verification gates

## [1.0.1] - 2026-03-03

### Added
- `/nox:update` — self-update from CLI
- `/nox:context` — review and sync all AI context files
- `/nox:pentest` — autonomous penetration testing
- 5 blocking quality gates in `full-phase`
- Advisory review gate in `quick-phase`

### Fixed
- `install.sh` compatibility with Windows Git Bash

## [1.0.0] - 2026-03-02

### Added
- Initial release: 28 skills across 6 categories
- Claude Code, Gemini CLI, and Codex CLI support
- Auto-installer with `--symlink`, `--claude-only`, `--gemini-only`, `--codex-only`
- GSD combo skills (`full-phase`, `quick-phase`)
- Multi-agent coordination suite (`syncagents`, `handoff`, `unloop`, `iterate`, `overwrite`, `error`)
