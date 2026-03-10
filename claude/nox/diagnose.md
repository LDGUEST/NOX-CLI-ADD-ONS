---
name: diagnose
description: Investigate and diagnose specific errors or broad system health issues across the codebase.
metadata:
  author: nox
  version: "1.6"
---

Investigate and diagnose issues across your system and codebase. This skill handles both specific error investigation and broad system health checks.

## Mode Selection

- If the user reports a **specific error or bug** → Run Error Investigation mode
- If the user wants a **system health check** → Run System Diagnostics mode

---

## Mode: Error Investigation

FIRST: Check if a `DEBUGGING.md` exists in this project. If it does, read it before diagnosing — another model or developer may have already solved this exact issue.

SECOND: Check `CHANGELOG.md` and recent `git log --oneline -20` for related changes that may have introduced this error.

### Analysis Protocol

1. **Identify the root cause** — Don't just fix the symptom. Trace the error to its origin.
2. **Map the failure sequence** — What events led to this crash? What was the trigger?
3. **Provide the specific fix** — Configuration change, code fix, or environment adjustment needed.
4. **Verify the fix** — Explain how to confirm the fix works and doesn't introduce regressions.

### Output Format

```
ROOT CAUSE: [one sentence]
FAILURE CHAIN: [sequence of events]
FIX: [specific change required]
VERIFY: [how to confirm it's fixed]
```

### Post-Fix

If you resolve a non-obvious bug, propose a `DEBUGGING.md` entry so the next developer or model doesn't repeat the investigation:

```markdown
### [Brief title] — [Date]
**Symptom:** What the error looked like
**Root Cause:** What actually went wrong
**Fix:** What resolved it
**Attribution:** [Model/Developer | Date]
```

---

## Mode: System Diagnostics

Run a full system health check across all configured machines and services. Report status without attempting fixes.

### Configuration

Define your infrastructure in environment variables or pass as arguments:

```bash
# Example: export FORGE_MACHINES='["web:192.168.1.10:deploy", "gpu:192.168.1.20:admin"]'
```

### Check Sequence

#### For each machine in `$FORGE_MACHINES`:

1. **Connectivity** — SSH reachable, latency
2. **System Resources** — CPU load, memory usage, disk space on all volumes
3. **Running Services** — Docker containers (`docker ps`), systemd/launchd services
4. **GPU Status** (if applicable) — Utilization, memory, temperature via `nvidia-smi`
5. **Key Ports** — Check if expected ports are listening

#### Service-Specific Checks

If the project has known services, verify each:
- **Web servers**: HTTP 200 on configured endpoints
- **Databases**: Connection test, replication lag
- **Message queues**: Queue depth, consumer status
- **AI/ML services**: Model endpoint health (`/health`, `/api/tags`, `/v1/models`)
- **Containers**: Running state, restart count, resource usage

### Output Format

Present results as a clean status table:

```
┌──────────┬───────────────┬────────┬─────────┐
│ Machine  │ Service       │ Status │ Details │
├──────────┼───────────────┼────────┼─────────┤
│ server-1 │ nginx         │ ✓ UP   │ 200 OK  │
│ server-1 │ postgres      │ ✓ UP   │ 0ms lag │
│ server-2 │ ollama        │ ✗ DOWN │ timeout │
└──────────┴───────────────┴────────┴─────────┘
```

Flag anything that is down, degraded, or unexpected. Do NOT attempt to fix anything — diagnosis only.

---
Nox
