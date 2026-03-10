---
name: guardrails
description: Enforce NOX guardrails and safety protocols. Use to install cross-CLI hooks and protection rules.
metadata:
  author: nox
  version: "1.6"
---


# Nox Guardrails

These rules are active for the entire session. They replicate the protection that Claude Code users get from hooks. Follow them on EVERY action, not just when explicitly invoked.

## BEFORE Every Bash Command

**Destructive Guard** — Before running any shell command, check if it matches these patterns. If it does, REFUSE and suggest the safer alternative:

| Blocked | Suggest Instead |
|---------|----------------|
| `rm -rf /`, `rm -rf ~`, `rm -rf *` | Target specific files: `rm -rf ./build/` |
| `git reset --hard` | `git stash` to preserve changes |
| `git push --force` to main/master | `git push --force-with-lease` or push to a feature branch |
| `git clean -f` | `git clean -n` (dry run first) |
| `git checkout .` or `git restore .` | Restore specific files by name |
| `DROP TABLE`, `DROP DATABASE`, `TRUNCATE` | Use migrations instead |
| `docker system prune` | `docker image prune` (target specific resources) |

**Branch Protect** — Before running `git commit` or `git push`, check the current branch:
- If on `main`, `master`, or `production` → STOP. Create a feature branch first: `git checkout -b feat/your-change`
- Only skip this if the user explicitly says "commit to main"

**Commit Lint** — Every commit message MUST follow Conventional Commits:
- Format: `type(scope): description` where type is one of: `feat`, `fix`, `chore`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `revert`
- Bad: `"updated stuff"` → Good: `"fix(auth): resolve token expiration on refresh"`

## BEFORE Every File Write

**File Size Guard** — Before writing any file, estimate its size. If >500KB, STOP and warn:
- "This file is unusually large (~XKB). This often means minified code, base64 data, or large JSON. Is this intentional?"
- Common triggers: writing bundled output to source, dumping API responses, embedding binary data

**Secret Scanner** — Before writing any file, scan your output for these patterns. If found, REMOVE THEM immediately:
- API keys: `sk-`, `sk-ant-`, `AKIA`, `ghp_`, `gho_`, `xoxb-`, `xoxp-`
- JWTs: `eyJ...` (long base64 with two dots)
- Generic: any string matching `[A-Za-z0-9]{32,}` assigned to a variable named `key`, `secret`, `token`, `password`, `credential`
- Use environment variables (`process.env.API_KEY`) instead of hardcoded values

## DURING Execution (every 5 file edits)

**Drift Detector** — After every 5 files you modify, mentally tally how many lines you've changed this session:
- At ~100 lines: Suggest a checkpoint commit — "You've made significant changes. Consider committing progress."
- At ~500 lines: Strongly recommend — "500+ lines changed without committing. You should commit now to avoid losing work."

**TODO Tracker** — When you add a `TODO`, `FIXME`, `HACK`, or `XXX` comment, call it out:
- "Added TODO at file.ts:42 — tracking this for follow-up"
- At the end of the session, list all TODOs you added

## AFTER Every Test Run

**Test Regression Guard** — After running tests, note the pass/fail count. If you run tests again later:
- If failures INCREASED: "⚠ Test regression: X new failures. Previous: Y passed, Z failed. Current: A passed, B failed."
- If pass count DROPPED (but no new failures): "⚠ Tests disappeared — were tests deleted?"
- STOP and fix regressions before continuing

## AT Session Start

**Auto Context** — At the start of every session, before doing anything else:
1. Check `git branch` — report current branch
2. Check `git log --oneline -5` — report recent commits
3. Check if `DEBUGGING.md` exists — if so, read it (another model may have already solved the current issue)
4. Check if `MEMORY.md` exists — if so, scan for relevant patterns

## AT Session End

**Memory Reminder** — Before ending a session where you fixed bugs:
- If you fixed a non-obvious bug but didn't update `DEBUGGING.md`, remind: "You fixed [bug]. Consider adding it to DEBUGGING.md so the next model doesn't re-investigate."
- If you made architectural decisions but didn't update `MEMORY.md`, remind: "Consider logging [decision] to MEMORY.md."

## DURING Autonomous Modes (iterate, unloop)

**Agent Limiter** — If you've spawned more than 10 sub-operations in a single session:
- Pause and report: "10+ sub-operations completed. Checking for runaway loops."
- Verify you're still making progress toward the original goal
- If the last 3 operations didn't advance the goal, STOP and report the blocker

**Prompt Self-Check** — If your current task feels too broad ("fix everything", "rewrite all"), STOP and narrow the scope:
- Break it into specific, verifiable sub-tasks
- Execute one at a time with verification between each

---

These guardrails are non-negotiable. They protect the user's codebase whether or not they're watching.

---
Nox
