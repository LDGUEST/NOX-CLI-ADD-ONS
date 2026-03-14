#!/bin/bash
# Nox Hook: drift-detector
# Event: PostToolUse (Write|Edit)
# Purpose: Tracks cumulative lines changed per session, warns at thresholds to encourage checkpoint commits
#
# PERF: Uses grep/sed for JSON extraction instead of python3.
#       Estimates line count from newlines in content/new_string fields.
#
# Install: bash install.sh --with-hooks
# Config: NOX_SKIP_DRIFT_DETECTOR=1 to disable
#         NOX_DRIFT_WARN=100 (first warning threshold, default 100 lines)
#         NOX_DRIFT_ALERT=500 (escalated warning, default 500 lines)
[ "${NOX_SKIP_DRIFT_DETECTOR:-0}" = "1" ] && exit 0

INPUT=$(cat)

# ── Lightweight JSON extraction (no python3) ──
source "$(dirname "$0")/lib-json.sh"
SESSION_ID=$(json_str "$INPUT" session_id)
[ -z "$SESSION_ID" ] && SESSION_ID="unknown"

WARN="${NOX_DRIFT_WARN:-100}"
ALERT="${NOX_DRIFT_ALERT:-500}"

DRIFT_FILE="/tmp/.claude_drift_${SESSION_ID}"

# Estimate lines changed using grep -c to count newlines in the content
# For Write: count newlines in "content" field
# For Edit: count newlines in "new_string" field
# This is approximate but avoids spawning python3
LINES_CHANGED=$(echo "$INPUT" | grep -oE '"(content|new_string|file_text)" *: *"[^"]*"' | head -1 | tr -cd '\n\\' | wc -c | tr -d ' ')
[ -z "$LINES_CHANGED" ] && LINES_CHANGED=1
[ "$LINES_CHANGED" -lt 1 ] 2>/dev/null && LINES_CHANGED=1

# Accumulate
PREV=0
if [ -f "$DRIFT_FILE" ]; then
    PREV=$(cat "$DRIFT_FILE" 2>/dev/null || echo "0")
fi
TOTAL=$((PREV + LINES_CHANGED))
echo "$TOTAL" > "$DRIFT_FILE"

# Check thresholds (only warn once per threshold)
PREV_WARNED="${DRIFT_FILE}.warned"
WARNED_AT=$(cat "$PREV_WARNED" 2>/dev/null || echo "0")

if [ "$TOTAL" -ge "$ALERT" ] 2>/dev/null && [ "$WARNED_AT" -lt "$ALERT" ] 2>/dev/null; then
    echo "🔴 DRIFT ALERT: ~$TOTAL lines changed this session without committing" >&2
    echo "  You have significant uncommitted work. Consider: git add -A && git commit" >&2
    echo "$ALERT" > "$PREV_WARNED"
elif [ "$TOTAL" -ge "$WARN" ] 2>/dev/null && [ "$WARNED_AT" -lt "$WARN" ] 2>/dev/null; then
    echo "🟡 DRIFT WARNING: ~$TOTAL lines changed this session without committing" >&2
    echo "  Consider a checkpoint commit to save progress." >&2
    echo "$WARN" > "$PREV_WARNED"
fi

exit 0
