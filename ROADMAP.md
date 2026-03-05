# NOX Roadmap

## v1.0 — Foundation (shipped)

- [x] 28 skills across 6 categories
- [x] Claude Code, Gemini CLI, and Codex CLI support
- [x] Auto-installer with `--symlink`, `--claude-only`, `--gemini-only`, `--codex-only`
- [x] GSD combo skills (`full-phase`, `quick-phase`)
- [x] Multi-agent coordination suite (syncagents, handoff, unloop, iterate, overwrite, error)
- [x] Zero-config install — no API keys, no dependencies

---

## v1.1 — Polish & Community

- [ ] **Uninstall script** — `bash uninstall.sh` to cleanly remove all skills
- [ ] **Update script** — `bash update.sh` or `install.sh --update` to pull latest and reinstall
- [ ] **Version check** — skills report their version, warn if outdated
- [ ] **Skill validation** — `bash validate.sh` confirms all 3 CLI formats are in sync
- [ ] **Contributing guide** — CONTRIBUTING.md with skill authoring standards
- [ ] **Changelog** — CHANGELOG.md tracking releases

---

## v1.2 — New Skills

- [ ] **`/nox:doc`** — Generate documentation from code (JSDoc, docstrings, README sections)
- [ ] **`/nox:api`** — Design and scaffold REST/GraphQL API endpoints from a spec
- [ ] **`/nox:schema`** — Database schema designer — ER diagrams, migration planning, normalization review
- [ ] **`/nox:env`** — Environment variable auditor — find missing vars, detect secrets in code, generate `.env.example`
- [ ] **`/nox:bench`** — Benchmark runner — profile functions, compare before/after, output flame graphs
- [ ] **`/nox:a11y`** — Accessibility audit — WCAG compliance, ARIA roles, keyboard navigation, color contrast

---

## v1.3 — Smarter Agents

- [ ] **Skill chaining** — let skills call other skills (e.g., `commit` auto-runs `review` first)
- [ ] **Context persistence** — skills remember what they did across sessions via shared state files
- [ ] **Agent profiles** — configure skill behavior per agent role (e.g., "strict reviewer" vs "fast shipper")
- [ ] **Skill templates** — `nox create-skill <name>` scaffolds a new skill in all 3 formats

---

## v2.0 — Platform

- [ ] **Nox Hub** — community skill registry (submit, browse, install third-party skills)
- [ ] **Skill marketplace** — curated skill packs by use case (frontend, backend, DevOps, data)
- [ ] **Team configs** — shared `.noxrc` for team-wide skill settings and quality gates
- [ ] **Metrics dashboard** — track which skills your team uses most, time saved, issues caught
- [ ] **Plugin system** — hooks for custom pre/post logic on any skill

---

## Ideas (unscheduled)

- [ ] **Cursor IDE integration** — skills as Cursor rules or extensions
- [ ] **Windsurf / Cline support** — additional AI editor integrations
- [ ] **`/nox:translate`** — i18n extraction and translation management
- [ ] **`/nox:design`** — generate UI mockups from descriptions (ASCII wireframes or component specs)
- [ ] **`/nox:explain`** — explain any codebase to a new contributor (onboarding guide generator)
- [ ] **`/nox:legal`** — license compliance checker across all dependencies
- [ ] **`/nox:estimate`** — effort estimation for tasks based on codebase analysis
- [ ] **`/nox:monitor`** — generate monitoring configs (Prometheus, Grafana, alerting rules)
