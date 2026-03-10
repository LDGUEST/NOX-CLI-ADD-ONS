---
name: refactor
description: Targeted refactoring with a safety net — improves structure while guaranteeing identical behavior.
metadata:
  author: nox
  version: "1.6"
---

Perform a targeted refactoring with a safety net. The goal: improve code structure while guaranteeing identical behavior.

**Guardrails Active:** [Nox Guardrails](/nox:guardrails) are enforced — secret scanning on all file writes, branch protection on commits, and test regression tracking.

## Protocol

### Before: Snapshot Current Behavior

1. Identify all existing tests that cover the code being refactored
2. Run them and record the results (all must pass)
3. If no tests exist, write characterization tests that capture current behavior first
4. Note any side effects, API contracts, or interfaces that must be preserved

### During: Incremental Changes

1. Make ONE structural change at a time
2. Run tests after each change
3. If tests fail, revert the last change and try a different approach
4. Commit after each successful change (small, atomic commits)

### After: Verify

1. Run the full test suite — all tests must pass
2. Verify identical behavior on key code paths
3. Compare before/after: same inputs must produce same outputs
4. Review the diff to ensure no accidental behavior changes

## Refactoring Techniques

- **Extract function** — Pull out a block of code into a named function
- **Inline function** — Replace a single-use function with its body
- **Rename** — Improve naming for clarity
- **Move** — Relocate code to a more appropriate module
- **Simplify conditionals** — Replace nested if/else with guard clauses or early returns
- **Remove duplication** — Consolidate repeated patterns (only when used 3+ times)

## Rules

- Never change behavior and structure in the same commit
- If you're unsure whether a change preserves behavior, don't make it
- Don't refactor code you haven't read and understood
- Don't add features during refactoring — that's a separate task

---
Nox