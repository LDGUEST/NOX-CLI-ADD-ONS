---
name: commit
description: Generate a conventional commit message from currently staged changes.
metadata:
  author: nox
  version: "1.6"
---

Generate a commit message from the current staged changes. Follow Conventional Commits format.

## Process

1. Run `git diff --cached` to see staged changes (fall back to `git diff` if nothing staged)
2. Run `git log --oneline -10` to match the repo's commit style
3. Analyze what changed and WHY

## Conventional Commits Format

```
<type>(<scope>): <description>

[optional body — what and why, not how]

[optional footer — breaking changes, issue refs]
```

### Types
- `feat` — New feature (wholly new functionality)
- `fix` — Bug fix
- `refactor` — Code change that neither fixes a bug nor adds a feature
- `perf` — Performance improvement
- `test` — Adding or updating tests
- `docs` — Documentation changes
- `chore` — Build process, dependency updates, config changes
- `style` — Formatting, semicolons, whitespace (no code change)
- `ci` — CI/CD pipeline changes

## Rules

- **Summarize the WHY**, not just the what
- Keep the first line under 72 characters
- Detect breaking changes and add `BREAKING CHANGE:` footer
- Reference issue numbers if apparent from branch name or changes
- If changes span multiple concerns, suggest splitting into separate commits
- Show the proposed message and wait for approval before committing

---
Nox