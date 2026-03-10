---
name: tdd
description: Enforce Red-Green-Refactor TDD cycle — write failing test first, then implementation, then refactor. No skipping.
metadata:
  author: nox
  version: "1.6"
---

Enforce the Red-Green-Refactor cycle. No skipping steps. This skill also handles standalone test generation when invoked on existing code without a feature spec.

**Guardrails Active:** [Nox Guardrails](/nox:guardrails) are enforced — secret scanning on all file writes, branch protection on commits, and test regression tracking.

## Mode Selection

- If the user has a **feature or bug to implement** → Run the full TDD cycle (Red-Green-Refactor)
- If the user wants **tests for existing code** → Run Test Generation mode

---

## TDD Mode: Red-Green-Refactor

### Step 1: RED — Write a Failing Test

- Write a test that describes the expected behavior
- Run it and **verify it fails** with the expected error
- If it passes immediately, the test is wrong or the feature already exists — investigate

### Step 2: GREEN — Write Minimal Code to Pass

- Write the absolute minimum code to make the test pass
- No extra features, no premature optimization, no "while I'm here" additions
- Run the test and **verify it passes**

### Step 3: REFACTOR — Clean Up

- Now improve the code: remove duplication, improve naming, extract functions
- Run the test after every change to ensure it still passes
- If any test breaks during refactoring, revert and try again

### TDD Rules

1. **Never write production code without a failing test first**
2. **Never write more test code than needed to create a failure**
3. **Never write more production code than needed to pass the test**
4. **Run tests after every change** — no batching up changes and hoping they work
5. **Commit after each green-refactor cycle** — small, atomic commits

---

## Test Generation Mode

For existing code that needs tests (no new feature being built).

### Step 1: Detect Test Framework

Scan the project for:
- `jest.config.*` or `package.json[jest]` → **Jest**
- `vitest.config.*` → **Vitest**
- `pytest.ini`, `pyproject.toml[tool.pytest]`, `conftest.py` → **Pytest**
- `*_test.go` files → **Go test**
- `Cargo.toml` with `[dev-dependencies]` → **cargo test**
- Existing test files → match their patterns and conventions

### Step 2: Analyze Code Under Test

- Identify all public functions, methods, and exported APIs
- Map input types, return types, and side effects
- Find edge cases: null/undefined, empty collections, boundary values, error states
- Identify external dependencies that need mocking

### Step 3: Write Tests

Cover three categories for each function:

**Happy Path** — Standard inputs produce expected outputs. Common use cases work correctly.

**Edge Cases** — Empty/null/undefined inputs, boundary values (0, -1, MAX_INT, empty string), large inputs, unicode, special characters, concurrent access (if applicable).

**Error Paths** — Invalid inputs throw/return appropriate errors, network failures handled gracefully, missing dependencies fail with clear messages.

### Step 4: Coverage Target

- Aim for 80%+ line coverage on new tests
- 100% coverage on critical paths (auth, payments, data mutations)
- Report uncovered lines and explain why they're not tested (if intentional)

## Shared Rules (both modes)

- Auto-detect the project's test framework from config files
- Match the project's existing test file naming convention
- Use the project's existing assertion library and patterns
- Mock external dependencies, never real network calls in unit tests
- Each test should test ONE thing and have a descriptive name
- Tests must be deterministic — no random data, no time-dependent assertions

---
Nox
