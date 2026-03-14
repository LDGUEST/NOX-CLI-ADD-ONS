#!/bin/bash
# Nox Hook: test-regression-guard
# Event: PostToolUse (Bash)
# Purpose: Tracks test pass/fail counts per project, warns on regression
# Install: bash install.sh --with-hooks
# Config: NOX_SKIP_TEST_GUARD=1 to disable
#         NOX_TEST_STATS=path to override stats file (default: ~/.claude/.test_stats)
set -eu

[ "${NOX_SKIP_TEST_GUARD:-0}" = "1" ] && exit 0

INPUT=$(cat)
source "$(dirname "$0")/lib-json.sh"

CMD=$(json_str "$INPUT" command)
[ -z "$CMD" ] && exit 0

# Only trigger on test commands — fast exit before any heavy processing
echo "$CMD" | grep -qiE "(npm test|npx (jest|vitest|playwright)|yarn test|pnpm test|pytest|python -m (pytest|unittest)|cargo test|go test|ruby -Itest|bundle exec rspec|bun test)" || exit 0

# Get test output — still uses python3 for complex nested extraction
RESULT=$(echo "$INPUT" | python3 -c "
import sys,json
d=json.load(sys.stdin)
r=d.get('tool_result','')
if isinstance(r,dict): r=str(r)
print(r)
" 2>/dev/null || echo "")
[ -z "$RESULT" ] && exit 0

STATS_FILE="${NOX_TEST_STATS:-$HOME/.claude/.test_stats}"
mkdir -p "$(dirname "$STATS_FILE")"

# Count passed/failed from output (covers Jest, Vitest, Pytest, Go, Cargo patterns)
PASSED=$(echo "$RESULT" | grep -oiE "([0-9]+) (passed|pass|ok)" | head -1 | grep -oE "[0-9]+" | head -1 || echo "0")
FAILED=$(echo "$RESULT" | grep -oiE "([0-9]+) (failed|fail|FAIL)" | head -1 | grep -oE "[0-9]+" | head -1 || echo "0")
[ -z "$PASSED" ] && PASSED=0
[ -z "$FAILED" ] && FAILED=0

# Project key
PROJ_KEY=$(pwd | md5sum 2>/dev/null | cut -c1-8 || md5 -q -s "$(pwd)" 2>/dev/null | cut -c1-8 || echo "default")

# Read previous stats
PREV_LINE=$(grep "^${PROJ_KEY}|" "$STATS_FILE" 2>/dev/null || echo "")
PREV_PASSED=0
PREV_FAILED=0
if [ -n "$PREV_LINE" ]; then
    PREV_PASSED=$(echo "$PREV_LINE" | cut -d'|' -f2)
    PREV_FAILED=$(echo "$PREV_LINE" | cut -d'|' -f3)
fi

# Update stats (remove old, append new)
if [ -f "$STATS_FILE" ]; then
    grep -v "^${PROJ_KEY}|" "$STATS_FILE" > "${STATS_FILE}.tmp" 2>/dev/null || true
    mv "${STATS_FILE}.tmp" "$STATS_FILE"
fi
echo "${PROJ_KEY}|${PASSED}|${FAILED}" >> "$STATS_FILE"

# Warn on regression
if [ "$PREV_PASSED" -gt 0 ] 2>/dev/null || [ "$PREV_FAILED" -gt 0 ] 2>/dev/null; then
    if [ "$FAILED" -gt "$PREV_FAILED" ] 2>/dev/null; then
        DELTA=$((FAILED - PREV_FAILED))
        echo "⚠ TEST REGRESSION: $DELTA new test failure(s) detected" >&2
        echo "  Previous: $PREV_PASSED passed, $PREV_FAILED failed" >&2
        echo "  Current:  $PASSED passed, $FAILED failed" >&2
        exit 0
    fi
    if [ "$PASSED" -lt "$PREV_PASSED" ] 2>/dev/null && [ "$FAILED" -eq 0 ] 2>/dev/null; then
        DELTA=$((PREV_PASSED - PASSED))
        echo "⚠ TEST COUNT DROP: $DELTA fewer test(s) passing (were tests deleted?)" >&2
        echo "  Previous: $PREV_PASSED passed | Current: $PASSED passed" >&2
        exit 0
    fi
fi

exit 0
