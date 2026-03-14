---
name: swot
description: Performs a brutally honest SWOT analysis of the codebase — strengths worth protecting, weaknesses to fix, opportunities being missed, threats that could sink the project. Use when deciding what to build next, evaluating project health, or preparing for strategic decisions.
argument-hint: "[focus-area]"
context: fork
agent: general-purpose
metadata:
  author: nox
  version: "1.0"
---

Perform a brutally honest SWOT analysis of this codebase. No sugarcoating, no corporate fluff. The user needs truth, not comfort.

## Step 1: Gather Context

Before analyzing, read and absorb:

1. **Context files** — `CLAUDE.md`, `README.md`, `PROJECT.md`, `MEMORY.md`, `DEBUGGING.md`, `.planning/` directory, any roadmap files
2. **Codebase structure** — file tree, tech stack, dependencies, architecture patterns
3. **Git state** — recent commits, branch activity, frequency of changes, areas of churn
4. **Tests** — coverage presence, test quality, what's tested vs what's not
5. **Dependencies** — `package.json`, `requirements.txt`, `Cargo.toml`, etc.
6. **Config & infra** — CI/CD, deployment setup, env management, Docker/compose files

## Step 2: SWOT Analysis

### STRENGTHS (What's actually working well)

Identify what the project does RIGHT — things worth protecting and doubling down on:

- **Code quality wins** — clean patterns, good abstractions, solid naming
- **Architecture choices** — things that scale well, good separation of concerns
- **Tech stack fit** — where the chosen tools genuinely serve the problem
- **Testing** — areas with good coverage and meaningful tests
- **Developer experience** — fast feedback loops, clear conventions, good docs
- **Domain modeling** — where the code accurately reflects the business domain

Be specific. "Good code quality" is useless. "The event bus architecture cleanly decouples agents and allows adding new ones without touching existing code" is useful.

### WEAKNESSES (What's broken, fragile, or holding you back)

Identify what will cause pain if not addressed. Be ruthless:

- **Technical debt** — shortcuts that compound, hacks that became permanent
- **Missing fundamentals** — no tests, no types, no error handling, no logging
- **Scaling bottlenecks** — things that work at current load but will break at 10x
- **Code smells** — god files, circular dependencies, copy-paste code, magic numbers
- **Knowledge silos** — code only one person understands, undocumented decisions
- **Dependency risks** — unmaintained packages, version conflicts, heavy lock-in
- **DX friction** — slow builds, broken dev setup, confusing folder structure

Rate each weakness: **Urgent** (fix now or pay later), **Important** (fix this quarter), **Minor** (fix when convenient).

### OPPORTUNITIES (What you're leaving on the table)

Identify high-leverage improvements the project is NOT doing but COULD:

- **Quick wins** — low-effort changes with disproportionate impact
- **Architecture unlocks** — refactors that would enable multiple future features
- **Tool upgrades** — better libraries, frameworks, or services available now
- **Automation gaps** — manual processes that could be scripted or CI'd
- **Performance gains** — obvious optimizations being ignored
- **Market/user alignment** — features the codebase is almost ready to support
- **Documentation** — knowledge capture that would accelerate future development

For each opportunity, estimate: **Effort** (hours/days/weeks) and **Impact** (high/medium/low).

### THREATS (What could kill this project)

Identify external and internal risks that could seriously damage the project:

- **Single points of failure** — one service, one person, one API key away from outage
- **Security exposure** — unpatched vulnerabilities, weak auth, exposed secrets
- **Dependency time bombs** — deprecated APIs, EOL runtimes, abandoned packages
- **Scaling cliffs** — hard limits that can't be solved incrementally
- **Bus factor** — critical knowledge in too few heads (or zero documentation)
- **Competitive risk** — where the tech stack or architecture limits future pivots
- **Operational risk** — no monitoring, no alerting, no disaster recovery plan

Rate each threat: **Likelihood** (high/medium/low) and **Impact** (catastrophic/significant/minor).

## Step 3: The Verdict

After the four quadrants, provide:

### Priority Matrix

A ranked list of the **top 5 actions** the user should take, drawn from across all quadrants:

```
PRIORITY  ACTION                                    SOURCE      EFFORT    IMPACT
────────  ──────────────────────────────────────────  ──────────  ────────  ────────
1         [action]                                   [W/O/T]     [time]    [level]
2         [action]                                   [W/O/T]     [time]    [level]
3         [action]                                   [W/O/T]     [time]    [level]
4         [action]                                   [W/O/T]     [time]    [level]
5         [action]                                   [W/O/T]     [time]    [level]
```

### One-Line Reality Check

End with a single honest sentence summarizing the project's strategic position. No hedging.

## Rules

- **Be specific.** Every point must reference actual files, patterns, or evidence from the codebase. No generic observations.
- **Be honest.** If the project is in trouble, say so. If it's in great shape, say that. Don't manufacture problems for balance.
- **Be actionable.** Every weakness, opportunity, and threat should imply a concrete next step.
- **No fluff.** Skip filler phrases like "overall the codebase is solid but could benefit from..." — just state the finding.
- **Proportional depth.** Spend more analysis time on quadrants where there's more to say. An early-stage project might be all opportunities and threats. A mature one might be all strengths and weaknesses.
- **Read the room.** If context files reveal the project's goals and stage, calibrate the analysis accordingly. A prototype doesn't need production-grade security analysis.

---
Nox
