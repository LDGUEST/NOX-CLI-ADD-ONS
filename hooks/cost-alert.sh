#!/bin/bash
# cost-alert.sh — PostToolUse hook (all tools)
# Periodically checks session cost and warns if threshold exceeded.
# Only checks every N tool calls to minimize overhead.
#
# Install: Add to PostToolUse hooks (no matcher — runs on all tools)
# Config:  NOX_COST_THRESHOLD  — dollar amount to warn at (default: 15)
#          NOX_COST_CHECK_INTERVAL — check every N tool calls (default: 20)
#          NOX_SKIP_COST_ALERT=1 to disable

[[ "${NOX_SKIP_COST_ALERT:-}" == "1" ]] && exit 0

THRESHOLD="${NOX_COST_THRESHOLD:-15}"
INTERVAL="${NOX_COST_CHECK_INTERVAL:-20}"
COUNTER_FILE="$HOME/.claude/.hook_counter"

# Increment counter (used by session-cost-tracker too)
COUNT=0
if [[ -f "$COUNTER_FILE" ]]; then
    COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)
fi
COUNT=$((COUNT + 1))
echo "$COUNT" > "$COUNTER_FILE"

# Only check at interval — fast exit for 19 of every 20 calls
if [[ $((COUNT % INTERVAL)) -ne 0 ]]; then
    exit 0
fi

# Read cost from statusline cache
CACHE_FILE="$HOME/.claude/.api_cost_cache"
[[ ! -f "$CACHE_FILE" ]] && exit 0

# Fast extraction: try grep+sed before falling back to python3
CACHE_DATA=$(cat "$CACHE_FILE" 2>/dev/null || echo "")
SESSION_COST=""

# Try JSON format: "session_cost": 1.23 or "sessionCost": 1.23
SESSION_COST=$(echo "$CACHE_DATA" | sed -n 's/.*"session[Cc_]*ost"[[:space:]]*:[[:space:]]*\([0-9.]*\).*/\1/p' | head -1)

# Try pipe-separated: session=1.23
if [[ -z "$SESSION_COST" ]]; then
    SESSION_COST=$(echo "$CACHE_DATA" | tr '|' '\n' | grep -i 'session' | sed 's/.*=[$]*//' | head -1)
fi

[[ -z "$SESSION_COST" || "$SESSION_COST" == "0" ]] && exit 0

# Compare using awk instead of python3 (available everywhere, ~2ms vs ~80ms)
COST_CENTS=$(awk "BEGIN { printf \"%d\", ${SESSION_COST} * 100 }" 2>/dev/null || echo 0)
THRESHOLD_CENTS=$(awk "BEGIN { printf \"%d\", ${THRESHOLD} * 100 }" 2>/dev/null || echo 1500)

if [[ "$COST_CENTS" -gt "$THRESHOLD_CENTS" ]]; then
    echo "COST ALERT: Session cost is \$${SESSION_COST} (threshold: \$${THRESHOLD}). Consider wrapping up or switching to a cheaper model."
fi

exit 0
