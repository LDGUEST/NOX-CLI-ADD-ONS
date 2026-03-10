---
name: handoff
description: End-of-session knowledge capture — preserve decisions, blockers, next steps, and context before closing.
metadata:
  author: nox
  version: "1.6"
---

This session is ending. Before we close, execute the full knowledge capture protocol:

## 1. Session Summary

Summarize what was built, fixed, or changed this session. Be specific — include file paths and the nature of each change.

## 2. Knowledge Capture

Log any non-obvious findings using these categories:

- **Bugs**: What broke, root cause, fix applied
- **Decisions**: Why X was chosen over Y, tradeoffs considered
- **Patterns**: Approaches that work well in this codebase
- **Off-limits**: Things that should never be done again (and why)

## 3. Propose Memory Entries

For each finding, propose the exact text and which file it belongs in:

- **Project-specific learnings** → `./MEMORY.md` in project root
- **Cross-project / infrastructure** → global memory file
- **Debugging knowledge** → `./DEBUGGING.md` in project root

## 4. State Changes

If any system state changed (new services, moved files, changed ports, updated configs, new dependencies), flag exactly what changed and what documentation needs updating.

## 5. Next Steps

Note what's incomplete or what the next developer/session should tackle first. Include any blockers or prerequisites.

**Do not write anything until each entry is approved.**

---
Nox