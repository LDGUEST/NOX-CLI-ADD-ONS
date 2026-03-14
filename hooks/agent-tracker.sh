#!/bin/bash
# Nox Hook: agent-tracker
# Event: SubagentStart
# Purpose: Tracks subagent spawns per session, alerts on runaway agent loops
# Install: bash install.sh --with-hooks
# Config: NOX_SKIP_AGENT_TRACKER=1 to disable
#         NOX_AGENT_LIMIT=10 (max agents before warning, default 10)
set -eu

[ "${NOX_SKIP_AGENT_TRACKER:-0}" = "1" ] && exit 0

INPUT=$(cat)
source "$(dirname "$0")/lib-json.sh"
SESSION_ID=$(json_str "$INPUT" session_id)
[ -z "$SESSION_ID" ] && SESSION_ID="unknown"

LIMIT="${NOX_AGENT_LIMIT:-10}"
TRACKER="/tmp/.claude_agent_tracker_${SESSION_ID}"

# Increment counter
COUNT=1
if [ -f "$TRACKER" ]; then
    PREV=$(cat "$TRACKER" 2>/dev/null || echo "0")
    COUNT=$((PREV + 1))
fi
echo "$COUNT" > "$TRACKER"

if [ "$COUNT" -eq "$LIMIT" ] 2>/dev/null; then
    echo "⚠ AGENT LIMIT: $COUNT subagents spawned this session (limit: $LIMIT)" >&2
    echo "  This may indicate a runaway agent loop. Check /nox:iterate or /nox:unloop progress." >&2
    echo "  Set NOX_AGENT_LIMIT=N to adjust threshold." >&2
elif [ "$COUNT" -gt "$LIMIT" ] 2>/dev/null && [ $((COUNT % 5)) -eq 0 ] 2>/dev/null; then
    echo "⚠ AGENT COUNT: $COUNT subagents (limit was $LIMIT). Still running." >&2
fi

exit 0
