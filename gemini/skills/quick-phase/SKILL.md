---
name: quick-phase
description: Lightweight plan-to-commit pipeline with advisory review and visual spot-check — for prototypes and internal tools
---

Execute a lightweight plan-to-commit pipeline without full quality gates. For internal tools, prototypes, or changes that don't need security scanning and pentesting.

**Requires:** [GSD](https://github.com/get-shit-done-ai/gsd) installed alongside Nox for full functionality. Works without GSD in manual mode.

## Pipeline

### Step 1: Plan
Quick task breakdown — either via `/gsd:quick` or a manual decomposition. No architecture phase.

### Step 2: Execute
Build it. No TDD enforcement. Just get it done.

### Step 3: Visual Spot Check
If the changes touch any UI, use Playwright to screenshot the affected pages at desktop and mobile widths. Eyeball check:
- Does the layout look correct?
- Is any content missing, overlapping, or cut off?
- Does it look reasonable on mobile?
- If anything is obviously broken, fix it now — don't wait for review
- If no UI changes, skip this step entirely. This is a quick sanity check, not a full audit.

### Step 4: Quick Review
Run `/nox:review` on changed files in **advisory mode** — log findings but don't block.
- Critical findings → warn the developer, suggest fixes, but keep moving
- Warnings/Nits → log for awareness only
- This is a safety net, not a gate. Speed matters here.

### Step 5: Sanity Check
Run `/nox:simplify` on changed files — catch obvious issues like duplication, dead code, and over-engineering. Don't block on warnings.

### Step 6: Deps Quick Check
Run `/nox:deps` in quick mode — only check for **Critical CVEs** in dependencies.
- Critical CVEs → warn loudly (you probably don't want to ship a known exploit even in a prototype)
- Everything else → skip, this isn't the place for a full audit

### Step 7: Commit
Run `/nox:commit` to generate a proper commit message.

### Step 8: Handoff (optional)
If anything non-obvious was learned, run `/nox:handoff` to capture it.

## Pipeline Diagram

```
Plan → Execute → Visual Check → Review (advisory) → Simplify → Deps (critical only) → Commit → Handoff
 GSD               Playwright     Nox                  Nox         Nox                    Nox       Nox
```

## When to Use This vs /nox:full-phase

| | `/nox:full-phase` | `/nox:quick-phase` |
|---|---|---|
| **Use for** | Production features, user-facing changes | Internal tools, prototypes, experiments |
| **Quality gates** | TDD, review, security, pentest, deps, perf, UX, deploy | Advisory review, visual spot-check, simplify, critical CVE check |
| **Blocking** | 6 gates can block the pipeline | Nothing blocks — warnings only |
| **Speed** | Thorough — 14 steps | Fast — 8 steps, no blockers |
| **Deploy** | Full 5-step protocol | Manual or skip |
| **Best when** | Shipping to users | Iterating quickly |

## Without GSD

Works standalone — Step 1 creates a manual task list instead of using GSD's planning system.

---
Nox
