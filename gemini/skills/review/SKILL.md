---
name: review
description: PR-style code review with complexity and simplification analysis
---

Perform a PR-style code review on the current changes or specified files. Act as a senior reviewer focused on shipping quality code.

**Guardrails Active:** [Nox Guardrails](/nox:guardrails) are enforced — secret scanning on all file writes, branch protection on commits, and test regression tracking.

## Review Scope

If there are staged/unstaged git changes, review those. Otherwise, review the files or components specified by the user.

## Review Categories

For each finding, assign a severity:

- **Critical** — Must fix before merge. Logic errors, security vulnerabilities, data loss risks, breaking changes.
- **Warning** — Should fix. Performance issues, error handling gaps, potential race conditions, maintainability concerns.
- **Nit** — Nice to fix. Style inconsistencies, naming improvements, minor readability tweaks.

## Checklist

- [ ] **Logic** — Does the code do what it claims? Are there off-by-one errors, missing null checks, wrong comparisons?
- [ ] **Security** — Injection vectors, auth bypass, data exposure, XSS, CSRF?
- [ ] **Performance** — N+1 queries, unnecessary re-renders, missing memoization, large bundle imports?
- [ ] **Error handling** — Are failures caught and handled gracefully? Are errors surfaced to the user?
- [ ] **Edge cases** — Empty arrays, null values, concurrent access, network failures?
- [ ] **Style** — Consistent with the project's existing patterns and conventions?
- [ ] **Tests** — Are new code paths covered? Do existing tests still pass?

## Complexity Check

Also review for unnecessary complexity (formerly `/nox:simplify`):

- [ ] **Duplication** — Similar code blocks that should be consolidated
- [ ] **Unnecessary abstractions** — Wrappers, factories, or patterns that add indirection without value
- [ ] **Dead code** — Functions, variables, imports, or exports that are never referenced
- [ ] **Over-engineering** — Feature flags for one-time operations, premature optimization, configurability nobody asked for
- [ ] **Verbose patterns** — Code that can be expressed more simply without losing clarity
- [ ] **Unnecessary dependencies** — Libraries used for something achievable with built-in APIs

**Complexity Rules:**
- Three similar lines of code is better than a premature abstraction
- Don't design for hypothetical future requirements
- The right amount of complexity is the minimum needed for the current task
- If a helper is only used once, inline it
- If a comment explains what the code does (not why), the code should be clearer instead

## Output Format

For each finding:
```
[CRITICAL|WARNING|NIT] file.ts:42 — Brief description
  → Suggested fix or approach
```

For complexity findings:
```
SIMPLIFY: file.ts:42-58
  Current: [what it does now]
  Proposed: [simpler alternative]
  Savings: [lines removed, abstractions eliminated, dependencies dropped]
```

End with an overall verdict: **Approve**, **Request Changes**, or **Comment**.

---
Nox
