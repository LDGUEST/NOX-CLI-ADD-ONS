---
name: architect
description: Design-first gate — no code until architecture is reviewed and approved
---

Design-first gate. No code, scaffolding, or implementation until the architecture is reviewed and approved. This skill prevents the most expensive rework: building a system whose structure doesn't fit the problem.

## When to Use

- After `/nox:brainstorm` has selected an approach — architect it before building
- Before any feature that touches 3+ files or introduces a new pattern
- When there are multiple valid architectures (real-time, event-driven, monolith vs micro)
- Before integrating a new service, database, or third-party dependency

## Process

### Phase 1: Requirements Recap

1. Re-read the codebase — check context files, existing architecture, and relevant code
2. State the goal in one sentence — if you can't, run `/nox:questions` first
3. List hard constraints — tech stack, existing patterns, backward compatibility, deployment target
4. Identify the 2-3 quality attributes that matter most — performance, security, simplicity, extensibility, reliability

### Phase 2: Architecture Design (5 deliverables)

**1. Component Diagram** — Name every major component, show how they communicate (HTTP, events, direct calls, message queue), mark boundaries between new and existing code. Use text diagrams.

**2. Data Flow** — Trace data from origin to destination for each major operation. Specify shape at each boundary. Call out transformations, validations, and side effects. Include DB migrations if applicable.

**3. API Contracts** — Define every new endpoint: method, path, request/response shape, status codes. Specify auth requirements per endpoint. Document error response format.

**4. Tech Decisions** — For each non-obvious choice:
```
DECISION: [what was chosen]
ALTERNATIVES: [what else was evaluated]
WHY THIS: [why it wins for this context]
RISK: [what could go wrong]
```

**5. File Structure** — List every file created or modified, with one-line responsibility descriptions. Show where new code fits into the existing directory structure.

### Phase 3: Validation

Before presenting, verify:
- Does this actually solve what was asked for?
- Does it follow existing codebase conventions?
- Minimal new abstractions? What happens when each component fails?
- Security — new attack surface? Inputs validated at boundaries?
- Can this be deployed without downtime? Would it survive 10x load?
- How hard is it to change course if this approach is wrong?

### Phase 4: Present and Gate

Output the full architecture document. Then STOP and ask:
```
Architecture review complete. Please:
  -> APPROVE — I'll proceed to implementation
  -> REVISE — Tell me what to change
  -> REJECT — We'll go back to brainstorm or requirements
```

Do NOT proceed without explicit approval.

## Rules

- **No code in this phase** — architecture diagrams, contracts, and decisions only
- **Read existing code first** — your design must fit the codebase as it IS
- **Match existing patterns** — don't introduce repositories if they use direct DB calls
- **One new concept at a time** — don't introduce a message queue AND a new auth pattern AND caching in one design
- **Name your files** — `/src/components/NotificationBell.tsx` not "we'll need a new component"
- **Call out what you're NOT designing** — explicitly state what's out of scope
- **If the design is trivial, say so** — "single-file change that adds a column and updates one query" is a valid review

---
Nox
