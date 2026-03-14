#!/bin/bash
# Nox Hook: session-logger
# Event: Stop
# Purpose: Logs session summary on each response — timestamp, project, branch, files changed. Last entry = final state.
# Install: bash install.sh --with-hooks
# Config: NOX_SKIP_SESSION_LOGGER=1 to disable
#         NOX_SESSION_LOG=path to override log file (default: ~/.claude/.session_log)
set -eu

[ "${NOX_SKIP_SESSION_LOGGER:-0}" = "1" ] && exit 0

INPUT=$(cat)
source "$(dirname "$0")/lib-json.sh"

# Check stop_hook_active to prevent loops
ACTIVE=$(json_bool "$INPUT" stop_hook_active)
[ "$ACTIVE" = "true" ] && exit 0

SESSION_ID=$(json_str "$INPUT" session_id)
[ -z "$SESSION_ID" ] && SESSION_ID="unknown"
CWD=$(json_str "$INPUT" cwd)

LOG_FILE="${NOX_SESSION_LOG:-$HOME/.claude/.session_log}"
mkdir -p "$(dirname "$LOG_FILE")"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
PROJECT=$(basename "$CWD" 2>/dev/null || echo "unknown")
BRANCH="n/a"
FILES_CHANGED=0
COMMITS=0

if [ -n "$CWD" ] && [ -d "$CWD" ]; then
    cd "$CWD" 2>/dev/null || true
    if git rev-parse --git-dir >/dev/null 2>&1; then
        BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "n/a")
        FILES_CHANGED=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
        STAGED=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
        FILES_CHANGED=$((FILES_CHANGED + STAGED))
    fi
fi

# Update session entry (replace previous line for same session, or append)
if grep -q "^${SESSION_ID}|" "$LOG_FILE" 2>/dev/null; then
    # Update existing entry with latest state
    if [ "$(uname)" = "Darwin" ]; then
        sed -i '' "/^${SESSION_ID}|/d" "$LOG_FILE" 2>/dev/null || true
    else
        sed -i "/^${SESSION_ID}|/d" "$LOG_FILE" 2>/dev/null || true
    fi
fi
echo "${SESSION_ID}|${TIMESTAMP}|${PROJECT}|${BRANCH}|${FILES_CHANGED} files changed" >> "$LOG_FILE"

# Keep last 500 entries
LINES=$(wc -l < "$LOG_FILE" 2>/dev/null | tr -d ' ')
if [ "$LINES" -gt 500 ] 2>/dev/null; then
    tail -500 "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
fi

exit 0
