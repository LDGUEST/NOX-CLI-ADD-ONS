Execute a complete plan-to-ship pipeline with quality gates at every step. This skill orchestrates both GSD and Nox commands into a single automated workflow.

**Requires:** [GSD](https://github.com/get-shit-done-ai/gsd) installed alongside Nox for full functionality. Works without GSD in manual mode.

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

### Step 5: Code Review Gate
Run `/nox:review` on ALL changed files as a final pass. This catches cross-file issues that per-task reviews miss.
- **Critical findings** → block the pipeline, fix before continuing
- **Warnings** → log but proceed
- **Nits** → log for later, don't block

### Step 6: Security Gate (Static)
Run `/nox:security` on all changed files — OWASP Top 10 static analysis.
- **Critical findings** → **block the pipeline** and fix before continuing
- **High/Medium** → logged as warnings

### Step 7: Pentest Gate (Live Exploitation)
Run `/nox:pentest` against the running application. This goes beyond static scanning — it attempts real exploits.
- **Any EXPLOITED finding** → **block the pipeline**. Fix the vulnerability, re-run pentest on that category
- **BLOCKED_BY_SECURITY** → log as hardened, proceed
- **Skip condition:** If the app has no running server (CLI tools, libraries), skip this step

### Step 8: Dependency Gate
Run `/nox:deps` to check for vulnerable, outdated, or unmaintained dependencies.
- **Critical CVEs** → **block the pipeline** and update/replace the package
- **High CVEs** → warn, recommend update before deploy
- **Outdated/unused** → log for cleanup, don't block

### Step 9: Performance Gate
Run `/nox:perf` on changed files and affected endpoints.
- **Critical regressions** (N+1 queries, memory leaks, 10x bundle increase) → **block and fix**
- **Moderate concerns** (missing indexes, large re-renders) → warn, don't block
- **Skip condition:** If changes are docs-only or config-only, skip this step

### Step 10: UX Gate (Visual Verification)
Use Playwright to screenshot every page, route, or component affected by the changes. This is a **mandatory blocking gate** for any UI-facing work.
- **Screenshot all affected views** at desktop (1280px) and mobile (375px) breakpoints
- **Check for**: broken layouts, overlapping elements, missing content, text overflow, z-index issues, invisible interactive elements
- **Compare against expectations** — if the task described a specific UI outcome, verify it visually
- **Broken layout or missing content** → **block the pipeline** and fix before continuing
- **Minor visual polish** (spacing, alignment tweaks) → log but proceed
- **Skip condition:** If changes are backend-only, API-only, or have no UI impact, skip this step

### Step 11: Commit
Run `/nox:commit` to generate Conventional Commits messages for all changes. Stage and commit with proper messages.

### Step 12: Deploy
Run `/nox:deploy` with the full 5-step protocol: preflight → backup → deploy → verify → report.

### Step 13: Verify
Run `/gsd:verify-work` against the original acceptance criteria. Include Playwright screenshots of the deployed application as visual proof. If verification fails, **loop back to Step 4** with the failing criteria as the new task.

### Step 14: Handoff
Run `/nox:handoff` to capture everything learned — bugs found, decisions made, patterns discovered, security findings resolved.

## Pipeline Diagram

```
Plan → Architect → Clarify → Execute → Review → Security → Pentest → Deps → Perf → UX → Commit → Deploy → Verify → Handoff
 GSD      Nox        Nox     GSD+Nox     Nox       Nox        Nox      Nox    Nox   PW     Nox      Nox      GSD       Nox
                                          ▲                                                           │
                                          └──────────────────── loop back on failure ────────────────┘
```

## Decision Points (where the pipeline pauses)

- **After Step 2** — "Approve this architecture?"
- **After Step 3** — Only if ambiguity was found
- **After Step 5** — If Critical review findings exist
- **After Step 6** — If Critical security findings exist
- **After Step 7** — If any vulnerability was successfully exploited
- **After Step 8** — If Critical CVEs found in dependencies
- **After Step 9** — If critical performance regressions detected
- **After Step 10** — If broken layouts or missing content detected via Playwright
- **After Step 13** — If UAT verification fails (loops back to fix)

## Gate Summary

| Gate | Skill | Blocks On | Skip When |
|------|-------|-----------|-----------|
| Code Review | `/nox:review` | Critical findings | Never |
| Security (Static) | `/nox:security` | Critical OWASP findings | Never |
| Pentest (Live) | `/nox:pentest` | Any EXPLOITED vulnerability | No running server |
| Dependencies | `/nox:deps` | Critical CVEs | No package manager |
| Performance | `/nox:perf` | Critical regressions | Docs/config-only changes |
| UX (Visual) | Playwright | Broken layouts, missing content | Backend/API-only changes |

## Without GSD

This skill works without GSD installed. Steps 1, 4, and 13 fall back to manual equivalents:
- Step 1: Creates a task breakdown instead of a GSD plan
- Step 4: Executes tasks sequentially instead of wave-based parallelization
- Step 13: Asks you to manually verify instead of running GSD's UAT

---
Nox
