#!/bin/bash
# build-tracker.sh — PostToolUse hook for Bash
# Tracks build warning/error counts across builds. Alerts when
# warnings or errors increase — catches regressions early.
#
# Install: Add to PostToolUse hooks with matcher "Bash"
# Config:  Set NOX_SKIP_BUILD_TRACKER=1 to disable
#          Stats stored in ~/.claude/.build_stats (auto-created)

[ "${NOX_SKIP_BUILD_TRACKER:-0}" = "1" ] && exit 0

INPUT=$(cat)
source "$(dirname "$0")/lib-json.sh"

CMD=$(json_str "$INPUT" command)

# Only trigger on build commands — fast exit before any heavy processing
echo "$CMD" | grep -qE '(npm\s+run\s+build|next\s+build|npx\s+next\s+build|tsc\b|vite\s+build|cargo\s+build|go\s+build)' || exit 0

# Extract stdout/stderr — still uses python3 because output can be multi-line with escapes
OUTPUT=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
r = d.get('tool_result', {})
out = r.get('stdout', '') + '\n' + r.get('stderr', '')
if not out.strip():
    out = str(r.get('output', ''))
print(out)
" 2>/dev/null)

STATS_FILE="${NOX_BUILD_STATS:-$HOME/.claude/.build_stats}"

# Generate project key from current directory
if command -v md5sum &>/dev/null; then
    PROJECT_KEY=$(echo -n "$(pwd)" | md5sum | cut -d' ' -f1)
elif command -v md5 &>/dev/null; then
    PROJECT_KEY=$(md5 -q -s "$(pwd)")
else
    PROJECT_KEY=$(echo -n "$(pwd)" | cksum | cut -d' ' -f1)
fi

# Count warnings and errors
WARNINGS=$(echo "$OUTPUT" | grep -ciE '(warning|warn\b)' 2>/dev/null || echo 0)
ERRORS=$(echo "$OUTPUT" | grep -ciE '(error\b|ERROR\b)' 2>/dev/null || echo 0)

# Read previous stats
PREV_WARNINGS=0
PREV_ERRORS=0
PREV_LINE=""
if [[ -f "$STATS_FILE" ]]; then
    PREV_LINE=$(grep "^$PROJECT_KEY" "$STATS_FILE" 2>/dev/null)
    if [[ -n "$PREV_LINE" ]]; then
        PREV_WARNINGS=$(echo "$PREV_LINE" | cut -d'|' -f2)
        PREV_ERRORS=$(echo "$PREV_LINE" | cut -d'|' -f3)
    fi
fi

# Save current stats
mkdir -p "$(dirname "$STATS_FILE")"
if [[ -f "$STATS_FILE" ]]; then
    grep -v "^$PROJECT_KEY" "$STATS_FILE" > "${STATS_FILE}.tmp" 2>/dev/null
    mv "${STATS_FILE}.tmp" "$STATS_FILE"
fi
echo "${PROJECT_KEY}|${WARNINGS}|${ERRORS}" >> "$STATS_FILE"

# Alert on increases
if [[ "$WARNINGS" -gt "$PREV_WARNINGS" ]] && [[ -n "$PREV_LINE" ]]; then
    DIFF=$((WARNINGS - PREV_WARNINGS))
    echo "BUILD: Warnings increased by $DIFF ($PREV_WARNINGS -> $WARNINGS)."
fi

if [[ "$ERRORS" -gt "$PREV_ERRORS" ]] && [[ -n "$PREV_LINE" ]]; then
    DIFF=$((ERRORS - PREV_ERRORS))
    echo "BUILD: Errors increased by $DIFF ($PREV_ERRORS -> $ERRORS). Build health declining."
fi

# Baseline on first build
if [[ -z "$PREV_LINE" ]] && [[ "$WARNINGS" -gt 0 || "$ERRORS" -gt 0 ]]; then
    echo "BUILD: Baseline recorded — $ERRORS errors, $WARNINGS warnings."
fi

exit 0
