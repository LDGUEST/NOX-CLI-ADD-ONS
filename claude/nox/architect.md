---
name: architect
description: Design-first gate — no code until architecture is reviewed and approved. Use before any feature touching 3+ files.
metadata:
  author: nox
  version: "1.6"
---

Design-first gate. No code, scaffolding, or implementation until the architecture is reviewed and approved. This skill prevents the most expensive rework: building a system whose structure doesn't fit the problem.

## When to Use

- After `/nox:brainstorm` has selected an approach — architect it before building
- Before any feature that touches 3+ files or introduces a new pattern
- When the user asks for something with multiple valid architectures (real-time, event-driven, monolith vs micro)
- Before integrating a new service, database, or third-party dependency

## Process

### Phase 1: Requirements Recap

Before designing anything, confirm you understand the scope:

1. **Re-read the codebase** — check CLAUDE.md, existing architecture, and relevant code
2. **State the goal in one sentence** — if you can't, run `/nox:questions` first
3. **List hard constraints** — tech stack, existing patterns, backward compatibility, deployment target
4. **Identify the quality attributes that matter most** — pick 2-3: performance, security, simplicity, extensibility, reliability, cost

### Phase 2: Architecture Design

Produce these 5 deliverables:

**1. Component Diagram**
- Name every major component/module and its single responsibility
- Show how they communicate (HTTP, events, direct calls, message queue, shared DB)
- Mark the boundaries — what's a new component vs modification of existing
- Use text diagrams (ASCII or markdown tables) — no external tools needed

```
[Client] → [API Route] → [Service Layer] → [Database]
                ↓
          [External API]
```

**2. Data Flow**
- Trace data from origin to destination for each major operation
- Specify the shape at each boundary (request body, DB schema, response format)
- Call out transformations, validations, and side effects
- If there's a database change, include the migration (columns, types, indexes, RLS)

**3. API Contracts**
- Define every new endpoint: method, path, request shape, response shape, status codes
- Specify auth requirements per endpoint (public, authenticated, role-restricted)
- Document error response format (match existing project patterns)
- Include rate limiting or pagination if applicable

**4. Tech Decisions**
For each non-obvious choice, provide:

```
DECISION: Use server-sent events (SSE) for real-time updates
ALTERNATIVES: WebSockets, polling, Supabase Realtime
WHY THIS: SSE is simpler (unidirectional is sufficient), works through
          proxies, no persistent connection management needed
RISK: If bidirectional communication is needed later, must migrate to WS
```

**5. File Structure**
- List every file that will be created or modified
- For new files, describe their responsibility in one line
- For modified files, describe what changes
- Show where new code fits into the existing directory structure

### Phase 3: Validation Checklist

Before presenting, verify the design against these criteria:

| Check | Question |
|-------|----------|
| **Solves the problem** | Does this architecture actually deliver what was asked for? |
| **Fits existing patterns** | Does it follow the conventions already in the codebase? |
| **Minimal surface area** | Are you introducing the fewest new concepts/abstractions necessary? |
| **Failure modes** | What happens when each component fails? Is the failure graceful? |
| **Security** | Does it expose new attack surface? Are inputs validated at boundaries? |
| **Operations** | Can this be deployed without downtime? How will you know if it's broken? |
| **Scale** | Would this design survive 10x the expected load without a rewrite? |
| **Reversibility** | If this approach is wrong, how hard is it to change course? |

If any check fails, revise the design before presenting.

### Phase 4: Present and Gate

Output the full architecture document. Then STOP and explicitly ask:

```
Architecture review complete. Please review and either:
  → APPROVE — I'll proceed to implementation
  → REVISE — Tell me what to change and I'll update the design
  → REJECT — We'll go back to brainstorm or requirements
```

Do NOT proceed to implementation without explicit approval.

## Rules

- **No code in this phase** — not even "example" code. Architecture diagrams, contracts, and decisions only.
- **Read existing code first** — your design must fit the codebase as it IS, not as you imagine it
- **Match existing patterns** — if the project uses service layers, add a service layer. Don't introduce repositories if they use direct DB calls.
- **One new concept at a time** — don't introduce a message queue AND a new auth pattern AND a caching layer in one architecture. Sequence them.
- **Name your files** — "we'll need a new component" is vague. `/src/components/NotificationBell.tsx` is concrete.
- **Call out what you're NOT designing** — explicitly state what's out of scope to prevent scope creep during implementation
- **If the design is trivial, say so** — not everything needs a 5-section architecture doc. "This is a single-file change that adds a column and updates one query" is a valid architecture review.

---
Nox
