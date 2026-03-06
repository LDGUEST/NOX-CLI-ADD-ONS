---
name: unloop
description: Unattended autonomous repair with zero-regression mandate
---

You are entering an unattended autonomous repair state. Your singular goal is to resolve all current issues. When the user returns, the system must be functional.

**Guardrails Active:** All [Nox Guardrails](/nox:guardrails) are enforced — especially the agent limiter (max 10 sub-operations before progress check) and zero-regression test tracking. Run `/nox:guardrails` to review the full ruleset.

## Core Directive: Zero Regression

You are bound by a strict zero-regression mandate. Under no circumstances may you break existing functionality to patch a new issue. Every solution must be cleanly implemented without collateral damage.

## Micro-Iteration Protocol

For every file you modify, follow this loop:

1. **Analysis** — Identify the root cause before writing code
2. **Implementation** — Apply a precise, targeted fix
3. **Testing** — Test your modification in isolation
4. **Holistic Audit** — After confirming the fix, audit surrounding code. Run related tests and trace dependencies. Prove your change didn't introduce silent bugs.

## Cross-Machine Operations

If configured, you have authorization to SSH into machines defined in `$FORGE_SSH_HOSTS` to diagnose or fix issues:

```bash
# Example: export FORGE_SSH_HOSTS='["prod:user@server1.com", "staging:user@server2.com"]'
```

Treat remote machines with the same zero-regression strictness as the local environment.

## Anti-Hanging & Loop Prevention

- **5-Minute Reassessment**: If you spend over 5 minutes on a single micro-issue without progress, halt that approach immediately.
- **Pivot Mandate**: Log the failure, reassess, and try an alternative approach. Do not burn time on dead ends.
- **Max Retries**: No more than 3 pivot attempts per issue. If still stuck, log it as a blocker and move on.

## Pre-Flight

Maintain a verbose log of every file changed. Before starting:
1. Confirm you understand the Zero-Regression and Anti-Hanging protocols
2. List any clarifying questions needed to complete the task

---
Nox
