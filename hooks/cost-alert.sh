#!/bin/bash
# cost-alert.sh — PostToolUse hook (all tools)
# Periodically checks session cost and warns if threshold exceeded.
# Only checks every N tool calls to minimize overhead.
#
# Install: Add to PostToolUse hooks (no matcher — runs on all tools)
# Config:  NOX_COST_THRESHOLD  — dollar amount to warn at (default: 15)
#          NOX_COST_CHECK_INTERVAL — check every N tool calls (default: 20)
#          NOX_SKIP_COST_ALERT=1 to disable

[[ "$NOX_SKIP_COST_ALERT" == "1" ]] && exit 0

THRESHOLD="${NOX_COST_THRESHOLD:-15}"
INTERVAL="${NOX_COST_CHECK_INTERVAL:-20}"
COUNTER_FILE="$HOME/.claude/.hook_counter"

# Increment counter
COUNT=0
if [[ -f "$COUNTER_FILE" ]]; then
    COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)
fi
COUNT=$((COUNT + 1))
echo "$COUNT" > "$COUNTER_FILE"

# Only check at interval
if [[ $((COUNT % INTERVAL)) -ne 0 ]]; then
    exit 0
fi

# Read cost from statusline cache (written by Claude Code's statusline)
CACHE_FILE="$HOME/.claude/.api_cost_cache"
[[ ! -f "$CACHE_FILE" ]] && exit 0

SESSION_COST=$(python3 -c "
import sys
try:
    with open('$CACHE_FILE') as f:
        data = f.read().strip()
    # Try JSON
    import json
    try:
        d = json.loads(data)
        for key in ['session_cost', 'sessionCost', 'session']:
            if key in d:
                print(str(d[key]).replace('\$',''))
                sys.exit(0)
    except (json.JSONDecodeError, ValueError):
        pass
    # Try key=value pipe-separated
    for pair in data.split('|'):
        k, _, v = pair.partition('=')
        if 'session' in k.lower():
            print(v.strip().replace('\$',''))
            sys.exit(0)
    print('0')
except Exception:
    print('0')
" 2>/dev/null)

[[ -z "$SESSION_COST" || "$SESSION_COST" == "0" ]] && exit 0

# Compare in cents to avoid float issues
COST_CENTS=$(python3 -c "print(int(float('${SESSION_COST}') * 100))" 2>/dev/null || echo 0)
THRESHOLD_CENTS=$(python3 -c "print(int(float('${THRESHOLD}') * 100))" 2>/dev/null || echo 1500)

if [[ "$COST_CENTS" -gt "$THRESHOLD_CENTS" ]]; then
    echo "COST ALERT: Session cost is \$${SESSION_COST} (threshold: \$${THRESHOLD}). Consider wrapping up or switching to a cheaper model."
fi

exit 0
