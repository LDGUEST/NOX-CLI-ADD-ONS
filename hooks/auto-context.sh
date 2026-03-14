#!/bin/bash
# Nox Hook: auto-context
# Event: SessionStart
# Purpose: Injects project state into every new session — git branch, recent commits, TODOs, DEBUGGING.md highlights
# Install: bash install.sh --with-hooks
# Config: NOX_SKIP_AUTO_CONTEXT=1 to disable
set -eu

[ "${NOX_SKIP_AUTO_CONTEXT:-0}" = "1" ] && exit 0

INPUT=$(cat)
source "$(dirname "$0")/lib-json.sh"
CWD=$(json_str "$INPUT" cwd)
[ -z "$CWD" ] && exit 0
cd "$CWD" 2>/dev/null || exit 0

# Only run in git repos
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

echo "--- Nox Auto-Context ---"

# Current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
echo "Branch: $BRANCH"

# Recent commits (last 5)
echo ""
echo "Recent commits:"
git log --oneline -5 2>/dev/null || true

# Uncommitted changes summary
CHANGED=$(git diff --stat --cached 2>/dev/null; git diff --stat 2>/dev/null)
if [ -n "$CHANGED" ]; then
    echo ""
    echo "Uncommitted changes:"
    echo "$CHANGED" | head -10
fi

# TODO/FIXME count
TODO_COUNT=$(grep -rn "TODO\|FIXME\|HACK\|XXX" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" --include="*.py" --include="*.go" --include="*.rs" --include="*.rb" . 2>/dev/null | grep -v node_modules | grep -v .git | wc -l | tr -d ' ')
if [ "$TODO_COUNT" -gt 0 ] 2>/dev/null; then
    echo ""
    echo "Open TODOs/FIXMEs: $TODO_COUNT"
fi

# DEBUGGING.md highlights
if [ -f "DEBUGGING.md" ]; then
    ENTRY_COUNT=$(grep -c "^### " DEBUGGING.md 2>/dev/null || echo "0")
    LATEST=$(grep "^### " DEBUGGING.md 2>/dev/null | tail -1 || true)
    echo ""
    echo "DEBUGGING.md: $ENTRY_COUNT entries"
    [ -n "$LATEST" ] && echo "Latest: $LATEST"
fi

# Recovery playbook from previous session (written by context-monitor at 83% usage)
PLAYBOOK=".claude/checkpoints/continuation.md"
if [ -f "$PLAYBOOK" ]; then
    echo ""
    echo "--- RECOVERY PLAYBOOK (from pre-compact handoff) ---"
    echo "A previous session wrote a recovery playbook before auto-compact."
    echo "Read .claude/checkpoints/continuation.md NOW, act on it, then delete it."
    echo "---"
fi

echo "--- End Auto-Context ---"
exit 0
