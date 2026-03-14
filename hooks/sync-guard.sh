#!/bin/bash
# sync-guard.sh — PreToolUse hook for Edit|Write
# Warns if unstaged changes exist before editing, which could mean
# another agent or process modified files since your last read.
#
# Install: Add to PreToolUse hooks with matcher "Edit|Write"
# Config:  Set NOX_SKIP_SYNC_GUARD=1 to disable

[[ "${NOX_SKIP_SYNC_GUARD:-}" == "1" ]] && exit 0

# Debounce: only check every 5th Write/Edit to reduce git overhead
SG_COUNTER="/tmp/.claude_sync_guard_counter"
SG_COUNT=0
[[ -f "$SG_COUNTER" ]] && SG_COUNT=$(cat "$SG_COUNTER" 2>/dev/null || echo 0)
SG_COUNT=$((SG_COUNT + 1))
echo "$SG_COUNT" > "$SG_COUNTER"
[[ $((SG_COUNT % 5)) -ne 0 ]] && exit 0

# Only applies inside git repos
if git rev-parse --git-dir >/dev/null 2>&1; then
    if ! git diff --quiet 2>/dev/null; then
        changed=$(git diff --stat --no-color 2>/dev/null | tail -1)
        echo "WARNING: Unstaged changes detected ($changed). Another agent may have edited files. Re-read before editing."
    fi
fi

exit 0
