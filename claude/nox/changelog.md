---
name: changelog
description: Generate CHANGELOG.md from git history in Keep a Changelog format.
metadata:
  author: nox
  version: "1.6"
---

Generate a CHANGELOG.md from git history. Follow Keep a Changelog format.

## Process

1. Run `git log --oneline --no-merges` to get commit history since last tag or release
2. If a CHANGELOG.md exists, read it and continue from where it left off
3. If no tags exist, use the full history

## Categorize Each Commit

- **Added** — New features or capabilities
- **Changed** — Changes to existing functionality
- **Deprecated** — Features marked for removal
- **Removed** — Features that were removed
- **Fixed** — Bug fixes
- **Security** — Vulnerability patches

## Format

```markdown
# Changelog

## [Unreleased]

### Added
- Feature description (#issue)

### Fixed
- Bug fix description (#issue)

## [1.0.0] - 2026-03-04

### Added
- Initial release
```

## Rules

- Group by version/tag, newest first
- Write entries from the user's perspective, not the developer's
- Reference issue/PR numbers when available
- Don't list merge commits, version bumps, or trivial changes
- If commits follow Conventional Commits, auto-categorize by type prefix
- Show the proposed changelog and wait for approval before writing

---
Nox