---
name: full-phase
description: Full plan-to-ship pipeline with quality gates — architecture, implementation, tests, security, deploy.
metadata:
  author: nox
  version: "1.6"
---

Execute a complete plan-to-ship pipeline with quality gates at every step. This skill orchestrates both GSD and Nox commands into a single automated workflow.

**Requires:** [GSD](https://github.com/get-shit-done-ai/gsd) installed alongside Nox for full functionality. Works without GSD in manual mode.

**Guardrails Active:** All [Nox Guardrails](/nox:guardrails) are enforced throughout this pipeline — destructive command blocking, secret scanning, branch protection, commit linting, drift detection, and test regression tracking.

## Pipeline

When invoked with a task description, execute these steps in order:

### Step 1: Plan
Run `/gsd:plan-phase` to create the implementation plan. If GSD is not installed, create a manual task breakdown instead.

### Step 2: Architect
Run `/nox:architect` on the plan output. Produce component diagram, data flow, and tech decisions. **Pause for approval** before proceeding.

### Step 3: Clarify
Run `/nox:questions` to surface any ambiguity in the plan. If questions exist, **pause and wait for answers**. If the plan is unambiguous, skip this step.

### Step 4: Execute with Quality Gates
Run `/gsd:execute-phase` (or manual execution if GSD is not installed). During execution, enforce these gates on every task:
- `/nox:tdd` — Write failing test before production code
- `/nox:review` — Auto-review after each file is modified
- **Playwright screenshot** — After any UI-facing task, use Playwright to screenshot the affected page/component. Visually verify the change looks correct before moving on. If the layout is broken, fix it before proceeding to the next task.
- Flag any issues before moving to the next task

### Step 5: Parallel Quality Gates (The Power Move)

**Dispatch all 6 quality gates simultaneously as independent subagents.** These gates have zero dependencies on each other — running them in parallel cuts gate time by ~80%.

Launch these agents in parallel using the Agent tool (subagent_type for each):

| Agent | Checks | Blocks On |
|-------|--------|-----------|
| `nox-reviewer` | Cross-file code review (all changed files) | Critical findings |
| `nox-security-scanner` | OWASP Top 10 static analysis | Critical OWASP findings |
| `nox-pentester` | Live exploitation against running app | Any EXPLOITED vulnerability |
| `nox-dep-auditor` | CVEs, outdated, unused, license risks | Critical CVEs (CVSS 9.0+) |
| `nox-perf-profiler` | N+1 queries, bundle size, memory leaks | Critical regressions |
| `nox-ux-tester` | Playwright screenshots at 4 breakpoints | Broken layouts, missing content |

**Skip rules** (agents self-determine):
- `nox-pentester` — skips if no running server (CLI tools, libraries)
- `nox-perf-profiler` — skips if changes are docs-only or config-only
- `nox-ux-tester` — skips if changes are backend-only or API-only

**How to dispatch:**
```
Use the Agent tool to launch all 6 agents in a SINGLE message (one tool call per agent).
Each agent receives: the list of changed files, the project root, and the task description.
Each agent returns a structured report with a verdict: PASS | WARN | BLOCK.
```

**After all agents return — evaluate results:**
1. Collect all 6 verdicts
2. If ANY agent returns **BLOCK** → the pipeline stops. Fix the blocking issues, then re-run ONLY the failed agents
3. If agents return **WARN** → log warnings but proceed
4. If all agents return **PASS** → continue to Step 6

**Re-run protocol:** When fixing a BLOCK, only re-dispatch the agents that blocked. Don't re-run all 6.

### Step 6: Commit
Run `/nox:commit` to generate Conventional Commits messages for all changes. Stage and commit with proper messages.

### Step 7: Deploy
Run `/nox:deploy` with the full 5-step protocol: preflight → backup → deploy → verify → report.

### Step 8: Verify
Run `/gsd:verify-work` against the original acceptance criteria. Include Playwright screenshots of the deployed application as visual proof. If verification fails, **loop back to Step 4** with the failing criteria as the new task.

### Step 9: Handoff
Run `/nox:handoff` to capture everything learned — bugs found, decisions made, patterns discovered, security findings resolved.

## Pipeline Diagram

```
Plan → Architect → Clarify → Execute → ┌─ Review ──┐ → Commit → Deploy → Verify → Handoff
 GSD      Nox        Nox     GSD+Nox    │  Security │     Nox      Nox      GSD       Nox
                                        │  Pentest  │
                                        │  Deps     │
                                        │  Perf     │
                                        └─ UX ──────┘
                                         6 PARALLEL      ▲                    │
                                          AGENTS         └── loop on failure ─┘
```

## Decision Points (where the pipeline pauses)

- **After Step 2** — "Approve this architecture?"
- **After Step 3** — Only if ambiguity was found
- **After Step 5** — If ANY agent returns BLOCK (review, security, audit, perf, or UX)
- **After Step 8** — If UAT verification fails (loops back to fix)

## Gate Summary (all run in parallel in Step 5)

| Agent | Gate | Blocks On | Auto-Skips When |
|-------|------|-----------|-----------------|
| `nox-reviewer` | Code Review | Critical findings | Never |
| `nox-security-scanner` | OWASP Top 10 | Critical OWASP findings | Never |
| `nox-pentester` | Live Exploitation | Any EXPLOITED vulnerability | No running server |
| `nox-dep-auditor` | Dependencies | Critical CVEs (CVSS 9.0+) | No package manager |
| `nox-perf-profiler` | Performance | Critical regressions | Docs/config-only changes |
| `nox-ux-tester` | Visual/UX | Broken layouts, missing content | Backend/API-only changes |

## Two-Layer Defense (Hooks + Agents)

This pipeline uses two complementary protection layers:

**Layer 1 — Hooks (continuous, passive):** If Nox hooks are installed (`bash install.sh --with-hooks`), they run automatically on EVERY tool call throughout the entire pipeline:
- `destructive-guard` — blocks `rm -rf`, `git reset --hard`, force push during autonomous execution
- `sync-guard` — warns if another agent modified files between your reads and writes
- `secret-scanner` — catches leaked API keys the moment they're written
- `debug-reminder` — points to DEBUGGING.md when commands fail, saving rediagnosis cycles
- `build-tracker` — alerts if build warnings/errors increase after your changes
- `cost-alert` — warns if session cost exceeds threshold (critical when 6 agents run in parallel)

**Layer 2 — Agents (checkpoint, active):** The 6 parallel agents in Step 5 perform deep analysis at the quality gate checkpoint.

Hooks catch problems **as they happen** during Steps 1-4. Agents catch problems **in aggregate** at Step 5. Together, nothing slips through.

## Without GSD

This skill works without GSD installed. Steps 1, 4, and 8 fall back to manual equivalents:
- Step 1: Creates a task breakdown instead of a GSD plan
- Step 4: Executes tasks sequentially instead of wave-based parallelization
- Step 8: Asks you to manually verify instead of running GSD's UAT

---
Nox
