---
name: syncagents
description: Re-read all relevant files after another agent has modified the repository to avoid stale context conflicts.
metadata:
  author: nox
  version: "1.6"
---

Another agent or process has likely modified this repository since our session started. Avoid worktree messes, detached heads, and overwriting another agent's work with stale context.

Before writing any files or committing, execute this safety check:

## 1. Detect the Environment

Run `git remote -v` to determine if this is a remote-connected repo or local-only.

## 2. If Remote-Connected

Outline the exact sequence to:
- `git stash` current working directory changes
- `git fetch` to get latest remote state
- `git pull --rebase` to incorporate the other agent's pushed work
- `git stash pop` to restore our changes
- Handle any conflicts
- Stage and commit cleanly

## 3. If Local-Only

We are sharing this directory with other agents:
- Run `git log -1 --stat` and `git diff HEAD` to see what the other agent committed
- Verify our pending changes don't overwrite their new code with stale context
- Outline how to stage and commit safely

## 4. Halt for Approval

Show the exact command sequence and your analysis of the current state. **Wait for approval before executing any file writes or git commands.**

---
Nox