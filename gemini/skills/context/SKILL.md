Review and validate all AI context files across the current project.

Scan for CLAUDE.md, MEMORY.md, DEBUGGING.md, GEMINI.md at project root and global config (~/.claude/, ~/.gemini/).

For each file found:
1. Report: filename, location, last modified date, line count
2. Check for stale entries (dates >30 days, references to removed features)
3. Check for contradictions between files
4. Check for missing context (important patterns not captured)
5. Cross-reference with actual codebase (tech stack, env vars, file paths)

Report issues as: [stale], [conflict], [missing], [duplicate], [maybe stale]

Offer to fix each issue with exact proposed edits. Never modify files without confirmation.

---
Nox
