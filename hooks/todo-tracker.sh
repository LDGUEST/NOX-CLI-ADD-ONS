#!/bin/bash
# Nox Hook: todo-tracker
# Event: PostToolUse (Write|Edit)
# Purpose: Detects new TODO/FIXME/HACK/XXX comments added to code, logs them for tracking
# Install: bash install.sh --with-hooks
# Config: NOX_SKIP_TODO_TRACKER=1 to disable
#         NOX_TODO_LOG=path to override log file (default: ~/.claude/.todo_tracker)
[ "${NOX_SKIP_TODO_TRACKER:-0}" = "1" ] && exit 0

INPUT=$(cat)
TOOL=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null || echo "")
[ -z "$TOOL" ] && exit 0
[ "$TOOL" != "Write" ] && [ "$TOOL" != "Edit" ] && exit 0

FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null || echo "")
[ -z "$FILE_PATH" ] && exit 0
[ ! -f "$FILE_PATH" ] && exit 0

# Skip non-code files
echo "$FILE_PATH" | grep -qiE "\.(md|txt|log|json|yaml|yml|toml|lock|svg|png|jpg|gif|ico|woff|ttf|eot)$" && exit 0

LOG_FILE="${NOX_TODO_LOG:-$HOME/.claude/.todo_tracker}"
mkdir -p "$(dirname "$LOG_FILE")"

# Find TODOs in the file
TODOS=$(grep -nE "(TODO|FIXME|HACK|XXX)[: ]" "$FILE_PATH" 2>/dev/null || true)
[ -z "$TODOS" ] && exit 0

# Count new ones (not already in log)
NEW_COUNT=0
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
while IFS= read -r line; do
    LINE_NUM=$(echo "$line" | cut -d: -f1)
    CONTENT=$(echo "$line" | cut -d: -f2- | sed 's/^[[:space:]]*//' | head -c 120)
    KEY="${FILE_PATH}:${LINE_NUM}"
    # Check if already tracked
    if ! grep -qF "$KEY" "$LOG_FILE" 2>/dev/null; then
        echo "${TIMESTAMP} | ${KEY} | ${CONTENT}" >> "$LOG_FILE"
        NEW_COUNT=$((NEW_COUNT + 1))
    fi
done <<< "$TODOS"

if [ "$NEW_COUNT" -gt 0 ]; then
    TOTAL=$(wc -l < "$LOG_FILE" 2>/dev/null | tr -d ' ')
    echo "📝 $NEW_COUNT new TODO(s) tracked in $FILE_PATH ($TOTAL total across project)" >&2

    # State file rotation — prevent unbounded growth.
    # Only check every ~10 appends (when total is divisible by 10) to minimize overhead.
    MAX_LINES="${NOX_LOG_MAX_LINES:-1000}"
    if [ $((TOTAL % 10)) -eq 0 ] && [ "$TOTAL" -gt "$MAX_LINES" ] 2>/dev/null; then
        tail -n "$MAX_LINES" "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
    fi
fi

exit 0
