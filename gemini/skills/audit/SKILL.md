---
name: audit
description: Rigorous technical audit with dependency health analysis
---

Conduct a rigorous technical audit of the current codebase. Do not build new features or write final code yet. Act as a strict Senior Reviewer and identify vulnerabilities, performance bottlenecks, logical flaws, and bad practices.

**Guardrails Active:** [Nox Guardrails](/nox:guardrails) are enforced — secret scanning on all file writes, branch protection on commits, and test regression tracking.

## Audit Categories

1. **Critical Bugs & Blockers** — Logic errors, crashes, data corruption risks
2. **Architecture & Optimization** — Structural issues, performance bottlenecks, scaling concerns
3. **Edge Cases & Security Risks** — Input validation gaps, injection vectors, auth flaws
4. **Dead Code & Unused Exports** — Functions, variables, imports that are never referenced
5. **Accessibility** — Missing ARIA attributes, keyboard navigation gaps, contrast issues (if UI project)

## Dependency Health

Include a full dependency audit as part of the report:

### Vulnerability Scan
- Run `npm audit` / `pip audit` / `cargo audit` / equivalent
- Flag any known CVEs with severity rating
- Provide upgrade path for each vulnerable package

### Outdated Dependencies
- Run `npm outdated` / `pip list --outdated` / equivalent
- Categorize: patch (safe), minor (review), major (breaking changes likely)
- Flag dependencies more than 2 major versions behind

### Unused Dependencies
- Cross-reference `package.json` / `requirements.txt` / `Cargo.toml` against actual imports
- Flag packages listed but never imported
- Flag devDependencies used in production code (or vice versa)

### Duplicate Dependencies
- Check for multiple versions of the same package in the dependency tree
- Identify which top-level packages pull in conflicting versions
- Suggest resolution strategy (dedupe, override, or upgrade)

### License Compliance
- List all dependency licenses
- Flag any copyleft licenses (GPL, AGPL) in an otherwise permissive project
- Flag any packages with no license specified

### Maintenance Health
- Flag packages with no commits in 2+ years
- Flag packages with no maintainer response to issues
- Suggest alternatives for abandoned packages

## Known Tripwires (check these explicitly)

- Env var hygiene: service/secret keys must NEVER appear in client-side code or public env vars
- Console.log / debug statements left in production code
- Functions over 80 lines or files over 300 lines
- Missing input validation at system boundaries (user input, external APIs)
- Hardcoded secrets, API keys, or credentials anywhere in the codebase
- SQL injection vectors (raw string interpolation in queries)
- Missing error handling on async operations

## Output Format

Present your audit as a structured report with severity ratings (Critical / Warning / Info) for each finding. Include file path and line number for every issue.

Include a dependency health summary:
```
DEPENDENCY HEALTH
=================
Vulnerabilities:  X critical, X high, X moderate
Outdated:         X packages (X major, X minor, X patch)
Unused:           X packages
Duplicates:       X version conflicts
License issues:   X packages
Unmaintained:     X packages
```

Ask any clarifying questions before proposing fixes.

---
Nox
