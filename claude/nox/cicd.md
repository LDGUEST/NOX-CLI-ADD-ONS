---
name: cicd
description: Generate a production-ready CI/CD workflow for this codebase.
metadata:
  author: nox
  version: "1.6"
---

Generate a production-ready CI/CD workflow for this codebase.

## Step 1: Auto-Detect Project

Scan the repo to determine:
- **Language/Runtime**: Node.js, Python, Go, Rust, etc.
- **Framework**: Next.js, Vite, Django, FastAPI, Gin, etc.
- **Package manager**: npm, pnpm, yarn, bun, pip, cargo, go modules
- **Test framework**: Jest, Vitest, Pytest, Go test, cargo test
- **Existing CI**: Check `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`, etc.

## Step 2: Generate Workflow

Create a GitHub Actions workflow (`.github/workflows/ci.yml`) that includes:

1. **Dependency caching** — Use the correct cache strategy for the detected package manager
2. **Linting** — Run the project's configured linter (ESLint, Ruff, golangci-lint, clippy, etc.)
3. **Type checking** — TypeScript `tsc --noEmit`, mypy, etc. if applicable
4. **Testing** — Run the full test suite with coverage reporting
5. **Building** — Verify the project builds successfully
6. **Matrix testing** — Test across relevant versions (Node 18/20/22, Python 3.11/3.12, etc.)

## Step 3: Advanced Options

Include these as commented-out sections the user can enable:
- **Deploy gates** — Require manual approval for production deploys
- **Preview deployments** — Auto-deploy PRs to preview environments
- **Security scanning** — Dependency audit, SAST scanning
- **Artifact uploads** — Build outputs, coverage reports
- **Notifications** — Slack/Discord on failure

## Requirements

- Fail-fast on errors with clear, readable status logs
- Use `concurrency` groups to cancel redundant runs
- Pin action versions to full SHA for security
- Add path filters to only run on relevant file changes

---
Nox