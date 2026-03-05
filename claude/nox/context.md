Review and validate all AI context files across the current project and global config. Report what needs updating.

## Files to Check

Scan for these files at ALL levels — project root, `~/.claude/`, and any subdirectories:

| File | Purpose | Location(s) |
|------|---------|-------------|
| `CLAUDE.md` | Project context for Claude Code | Project root, `~/.claude/CLAUDE.md` (global) |
| `MEMORY.md` | Accumulated learnings | Project root, `~/.claude/MEMORY.md`, `~/.claude/projects/*/memory/MEMORY.md` |
| `DEBUGGING.md` | Multi-model debugging knowledge | Project root |
| `GEMINI.md` | Gemini CLI context | Project root |
| `.claude/settings.json` | Project-level Claude settings | Project root `.claude/` |

## Process

1. **Discovery** — Find all context files:
   ```bash
   # Project level
   ls -la CLAUDE.md MEMORY.md DEBUGGING.md GEMINI.md .claude/ 2>/dev/null
   
   # Global level
   ls -la ~/.claude/CLAUDE.md ~/.claude/MEMORY.md 2>/dev/null
   
   # Project memory (Claude Code auto-memory)
   ls ~/.claude/projects/*/memory/MEMORY.md 2>/dev/null
   ```

2. **Read each file** and analyze for:
   - **Stale entries**: dates older than 30 days, references to removed files/features
   - **Contradictions**: conflicting info between files (e.g., CLAUDE.md says one stack, MEMORY.md says another)
   - **Missing context**: important project patterns not captured anywhere
   - **Duplicate entries**: same info repeated across files
   - **Broken references**: links to files/paths that no longer exist

3. **Cross-reference** with the actual codebase:
   - Does `CLAUDE.md` accurately describe the current tech stack?
   - Are env var names in docs matching actual `.env.example` or code?
   - Are file paths mentioned in context files still valid?
   - Does `DEBUGGING.md` reference bugs that have been fixed and removed?

4. **Report** in this format:
   ```
   Context File Review
   ===================
   
   FOUND FILES:
   [check] CLAUDE.md (project) — last modified: YYYY-MM-DD — XX lines
   [check] MEMORY.md (project) — last modified: YYYY-MM-DD — XX lines  
   [missing] DEBUGGING.md — not found (create if bugs have been solved)
   [missing] GEMINI.md — not found (create if using Gemini CLI)
   
   ISSUES:
   [stale] MEMORY.md line 45: references Prisma but project uses Drizzle now
   [conflict] CLAUDE.md says Auth0 but code imports Clerk
   [missing] No env var documentation for STRIPE_WEBHOOK_SECRET
   [duplicate] Same RLS pattern documented in both CLAUDE.md and MEMORY.md
   
   SUGGESTIONS:
   - Update CLAUDE.md tech stack section
   - Remove solved bug from DEBUGGING.md (issue #123)
   - Add MEMORY.md entry for the new caching pattern used in 3 places
   ```

5. **Offer to fix** — For each issue, propose the exact edit and ask for confirmation before writing.

## Rules

- NEVER delete entries without confirmation
- NEVER modify files silently — always show the diff first
- Flag uncertainty: if you're not sure something is stale, mark it as `[maybe stale]`
- Respect attribution labels in DEBUGGING.md (e.g., `[Claude | 2026-03-01]`)
- Check the global CLAUDE.md (`~/.claude/CLAUDE.md`) for shared conventions that should NOT be duplicated in project-level files

---
Nox
