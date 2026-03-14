#!/bin/bash
# Nox Hook: drift-detector
# Event: PostToolUse (Write|Edit)
# Purpose: Tracks cumulative lines changed per session, warns at thresholds to encourage checkpoint commits
# Install: bash install.sh --with-hooks
# Config: NOX_SKIP_DRIFT_DETECTOR=1 to disable
#         NOX_DRIFT_WARN=100 (first warning threshold, default 100 lines)
#         NOX_DRIFT_ALERT=500 (escalated warning, default 500 lines)
[ "${NOX_SKIP_DRIFT_DETECTOR:-0}" = "1" ] && exit 0

INPUT=$(cat)

# Fast field extraction without python3
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HOOK_DIR/nox-parse.sh" 2>/dev/null || exit 0

SESSION_ID=$(nox_field "session_id" "$INPUT")
[ -z "$SESSION_ID" ] && SESSION_ID="unknown"
TOOL=$(nox_field "tool_name" "$INPUT")
[ "$TOOL" != "Write" ] && [ "$TOOL" != "Edit" ] && exit 0

WARN="${NOX_DRIFT_WARN:-100}"
ALERT="${NOX_DRIFT_ALERT:-500}"

DRIFT_FILE="/tmp/.claude_drift_${SESSION_ID}"

# Estimate lines changed
LINES_CHANGED=$(echo "$INPUT" | python3 -c "
import sys,json
d=json.load(sys.stdin)
ti=d.get('tool_input',{})
if d.get('tool_name')=='Write':
    content=ti.get('content','') or ti.get('file_text','') or ''
    print(content.count(chr(10))+1)
elif d.get('tool_name')=='Edit':
    old=ti.get('old_string','') or ''
    new=ti.get('new_string','') or ''
    print(abs(new.count(chr(10))-old.count(chr(10)))+max(new.count(chr(10)),old.count(chr(10)))+1)
else:
    print(0)
" 2>/dev/null || echo "0")

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
