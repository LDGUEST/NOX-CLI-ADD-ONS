#!/bin/bash
# Nox Hook: memory-auto-save
# Event: Stop
# Purpose: On session end, reminds if bugs were fixed but DEBUGGING.md/MEMORY.md weren't updated
# Install: bash install.sh --with-hooks
# Config: NOX_SKIP_MEMORY_SAVE=1 to disable
set -eu

[ "${NOX_SKIP_MEMORY_SAVE:-0}" = "1" ] && exit 0

INPUT=$(cat)
source "$(dirname "$0")/lib-json.sh"

# Check stop_hook_active to prevent loops
ACTIVE=$(json_bool "$INPUT" stop_hook_active)
[ "$ACTIVE" = "true" ] && exit 0

SESSION_ID=$(json_str "$INPUT" session_id)
[ -z "$SESSION_ID" ] && SESSION_ID="unknown"
CWD=$(json_str "$INPUT" cwd)
[ -z "$CWD" ] && exit 0
cd "$CWD" 2>/dev/null || exit 0

# Only remind once per session
REMINDER_FLAG="/tmp/.claude_memory_reminded_${SESSION_ID}"
[ -f "$REMINDER_FLAG" ] && exit 0

# Check if we're in a git repo with recent changes
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

# Look for signs of bug fixes in recent commits (this session)
RECENT=$(git log --oneline --since="4 hours ago" 2>/dev/null || true)
[ -z "$RECENT" ] && exit 0

HAS_FIX=$(echo "$RECENT" | grep -ciE "(fix|bug|patch|resolve|repair|debug|hotfix)" || echo "0")
[ "$HAS_FIX" -eq 0 ] 2>/dev/null && exit 0

# Check if DEBUGGING.md was modified in the same timeframe
DEBUG_MODIFIED=false
if [ -f "DEBUGGING.md" ]; then
    DEBUG_CHANGED=$(git diff --name-only HEAD~${HAS_FIX}..HEAD 2>/dev/null | grep -c "DEBUGGING.md" || echo "0")
    [ "$DEBUG_CHANGED" -gt 0 ] 2>/dev/null && DEBUG_MODIFIED=true
fi

MEMORY_MODIFIED=false
if [ -f "MEMORY.md" ]; then
    MEM_CHANGED=$(git diff --name-only HEAD~${HAS_FIX}..HEAD 2>/dev/null | grep -c "MEMORY.md" || echo "0")
    [ "$MEM_CHANGED" -gt 0 ] 2>/dev/null && MEMORY_MODIFIED=true
fi

if [ "$DEBUG_MODIFIED" = false ] && [ -f "DEBUGGING.md" ]; then
    echo "📝 MEMORY REMINDER: You committed $HAS_FIX fix(es) but didn't update DEBUGGING.md" >&2
    echo "  Consider logging the bug + fix so it's never re-investigated." >&2
    touch "$REMINDER_FLAG"
elif [ "$MEMORY_MODIFIED" = false ] && [ -f "MEMORY.md" ]; then
    echo "📝 MEMORY REMINDER: You committed $HAS_FIX fix(es) but didn't update MEMORY.md" >&2
    echo "  Consider logging patterns or decisions from this session." >&2
    touch "$REMINDER_FLAG"
fi

exit 0
