#!/bin/bash
# cost-alert.sh — PostToolUse hook (all tools)
# Periodically checks session cost and warns if threshold exceeded.
# Only checks every N tool calls to minimize overhead.
#
# PERF: Counter check is the FIRST thing — no stdin read, no python3,
#       no file parsing on 19 out of 20 calls. Total overhead on skip: ~1ms.
#
# Install: Add to PostToolUse hooks (no matcher — runs on all tools)
# Config:  NOX_COST_THRESHOLD  — dollar amount to warn at (default: 15)
#          NOX_COST_CHECK_INTERVAL — check every N tool calls (default: 20)
#          NOX_SKIP_COST_ALERT=1 to disable

[ "${NOX_SKIP_COST_ALERT:-0}" = "1" ] && exit 0

INTERVAL="${NOX_COST_CHECK_INTERVAL:-20}"
COUNTER_FILE="$HOME/.claude/.hook_counter"

# ── Fast path: increment counter, skip if not at interval ──
# This runs BEFORE reading stdin — no python3, no JSON parse on skip
COUNT=0
[ -f "$COUNTER_FILE" ] && COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)
COUNT=$((COUNT + 1))
echo "$COUNT" > "$COUNTER_FILE"
[ $((COUNT % INTERVAL)) -ne 0 ] && exit 0

# ── Slow path: only runs every Nth call ──
# Drain stdin (required for PostToolUse hooks)
cat > /dev/null

THRESHOLD="${NOX_COST_THRESHOLD:-15}"

# Read cost from statusline bridge file (written by statusline-unified.js)
# Try session-specific bridge first, fall back to generic cache
SESSION_COST=""
for f in /tmp/claude-ctx-*.json "$HOME/.claude/.api_cost_cache"; do
    [ -f "$f" ] || continue
    # Fast grep-based extraction — no python3 needed for JSON with known keys
    SESSION_COST=$(grep -oE '"session_cost" *: *[0-9.]+' "$f" 2>/dev/null | head -1 | sed 's/.*: *//')
    [ -n "$SESSION_COST" ] && break
    SESSION_COST=$(grep -oE '"sessionCost" *: *[0-9.]+' "$f" 2>/dev/null | head -1 | sed 's/.*: *//')
    [ -n "$SESSION_COST" ] && break
done

[ -z "$SESSION_COST" ] && exit 0

# Integer comparison in cents — no python3 needed
# Shell can't do float math, so strip decimal and pad to cents
COST_INT=${SESSION_COST%.*}
COST_DEC=${SESSION_COST#*.}
COST_DEC=${COST_DEC:0:2}  # first 2 decimal digits
[ ${#COST_DEC} -eq 1 ] && COST_DEC="${COST_DEC}0"
[ -z "$COST_DEC" ] && COST_DEC="00"
COST_CENTS=$((10#${COST_INT:-0} * 100 + 10#${COST_DEC}))

THRESH_INT=${THRESHOLD%.*}
THRESH_DEC=${THRESHOLD#*.}
THRESH_DEC=${THRESH_DEC:0:2}
[ ${#THRESH_DEC} -eq 1 ] && THRESH_DEC="${THRESH_DEC}0"
[ -z "$THRESH_DEC" ] && THRESH_DEC="00"
THRESHOLD_CENTS=$((10#${THRESH_INT:-0} * 100 + 10#${THRESH_DEC}))

if [ "$COST_CENTS" -gt "$THRESHOLD_CENTS" ] 2>/dev/null; then
    echo "COST ALERT: Session cost is \$${SESSION_COST} (threshold: \$${THRESHOLD}). Consider wrapping up or switching to a cheaper model."
fi

exit 0
