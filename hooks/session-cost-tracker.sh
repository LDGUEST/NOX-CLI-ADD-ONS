#!/bin/bash
# Nox Hook: session-cost-tracker
# Event: Stop
# Purpose: Records per-session token/cost metrics for A/B comparison (NOX hooks ON vs OFF).
#          Parses the session transcript (JSONL) for accurate token counts.
#          Writes to SQLite DB for easy querying. Pairs with session-logger.
#
# Install: bash install.sh --with-hooks
# Config:  NOX_SKIP_COST_TRACKER=1 to disable
#          NOX_COST_DB=path to override DB (default: ~/.claude/.nox_metrics.db)
#          NOX_COST_JSONL=path to override JSONL fallback (default: ~/.claude/.nox_metrics.jsonl)
#
# Storage: Prefers sqlite3. When sqlite3 is not available (e.g., Windows Git Bash),
#          falls back to JSON Lines (.nox_metrics.jsonl) with identical fields.
#
# Query examples:
#   sqlite3 ~/.claude/.nox_metrics.db "SELECT hooks_active, COUNT(*), ROUND(AVG(session_cost),4), ROUND(AVG(tokens_used),0) FROM sessions GROUP BY hooks_active"
#   sqlite3 ~/.claude/.nox_metrics.db "SELECT * FROM sessions ORDER BY timestamp DESC LIMIT 20"
set -eu

[ "${NOX_SKIP_COST_TRACKER:-0}" = "1" ] && exit 0

INPUT=$(cat)

# Fast field extraction
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HOOK_DIR/nox-parse.sh" 2>/dev/null || true

# Prevent loops
STOP_ACTIVE=$(nox_field "stop_hook_active" "$INPUT" 2>/dev/null || echo "")
[ "$STOP_ACTIVE" = "true" ] && exit 0

SESSION_ID=$(nox_field "session_id" "$INPUT" 2>/dev/null || echo "")
[ -z "$SESSION_ID" ] && exit 0

CWD=$(nox_field "cwd" "$INPUT" 2>/dev/null || echo "")
TRANSCRIPT=$(nox_field "transcript_path" "$INPUT" 2>/dev/null || echo "")

DB="${NOX_COST_DB:-$HOME/.claude/.nox_metrics.db}"
mkdir -p "$(dirname "$DB")"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
PROJECT=$(basename "$CWD" 2>/dev/null || echo "unknown")

# ── Parse transcript for token counts, cost, and model ──
# transcript_path points to a JSONL file with the full conversation
TOKENS_USED=0
SESSION_COST=0
MODEL="unknown"
INPUT_TOKENS=0
OUTPUT_TOKENS=0
CACHE_READ=0
CACHE_WRITE=0

if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
    # Extract token/cost data + duration from transcript JSONL
    # PERF: tail -5000 limits parsing to last 5000 lines — avoids reading
    # multi-MB transcripts from long sessions. Token/cost data accumulates
    # so the latest entries have the most accurate totals.
    read -r TOKENS_USED SESSION_COST MODEL INPUT_TOKENS OUTPUT_TOKENS CACHE_READ CACHE_WRITE DURATION_MIN <<< "$(tail -5000 "$TRANSCRIPT" | python3 -c "
import sys, json

total_input = 0
total_output = 0
total_cache_read = 0
total_cache_write = 0
total_cost = 0.0
model = 'unknown'
first_ts = last_ts = None

for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try:
        entry = json.loads(line)
    except (json.JSONDecodeError, ValueError):
        continue

    # Timestamps for duration
    ts = entry.get('timestamp')
    if ts:
        if first_ts is None: first_ts = ts
        last_ts = ts

    msg = entry.get('message', {})
    if isinstance(msg, dict):
        if model == 'unknown' and msg.get('model'):
            model = msg['model']
        usage = msg.get('usage', {})
        if usage:
            total_input += usage.get('input_tokens', 0)
            total_output += usage.get('output_tokens', 0)
            total_cache_read += usage.get('cache_read_input_tokens', 0)
            total_cache_write += usage.get('cache_creation_input_tokens', 0)

    usage = entry.get('usage', {})
    if isinstance(usage, dict) and usage:
        total_input += usage.get('input_tokens', 0)
        total_output += usage.get('output_tokens', 0)
        total_cache_read += usage.get('cache_read_input_tokens', 0)
        total_cache_write += usage.get('cache_creation_input_tokens', 0)

    for key in ('costUSD', 'cost_usd', 'cost'):
        c = entry.get(key, 0)
        if c:
            total_cost += float(c)
            break

# Duration
dur = 0
if first_ts and last_ts:
    try:
        dur = max(1, int((float(last_ts) - float(first_ts)) / 60))
    except (ValueError, TypeError):
        try:
            from datetime import datetime
            t1 = datetime.fromisoformat(str(first_ts).replace('Z','+00:00'))
            t2 = datetime.fromisoformat(str(last_ts).replace('Z','+00:00'))
            dur = max(1, int((t2-t1).total_seconds() / 60))
        except: pass

total_tokens = total_input + total_output + total_cache_read + total_cache_write
print(f'{total_tokens} {total_cost:.6f} {model.replace(chr(32),chr(95))} {total_input} {total_output} {total_cache_read} {total_cache_write} {dur}')
" 2>/dev/null || echo "0 0 unknown 0 0 0 0 0")"
fi

# ── Detect hooks state ──
HOOKS_ACTIVE=1
[ "${NOX_SKIP_ALL:-0}" = "1" ] && HOOKS_ACTIVE=0
[ -f "$HOME/.claude/.nox_hooks_disabled" ] && HOOKS_ACTIVE=0

# ── Git stats ──
BRANCH="n/a"
FILES_CHANGED=0
COMMITS_THIS_SESSION=0
if [ -n "$CWD" ] && [ -d "$CWD" ]; then
    cd "$CWD" 2>/dev/null || true
    if git rev-parse --git-dir >/dev/null 2>&1; then
        BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "n/a")
        FILES_CHANGED=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
        STAGED=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
        FILES_CHANGED=$((FILES_CHANGED + STAGED))
        # Count commits made in the last 4 hours (rough session window)
        COMMITS_THIS_SESSION=$(git log --oneline --since="4 hours ago" 2>/dev/null | wc -l | tr -d ' ')
    fi
fi

# Duration is now parsed in the single python3 call above

# ── Tool call count from hook counter ──
TOOL_CALLS=0
COUNTER_FILE="$HOME/.claude/.hook_counter"
if [ -f "$COUNTER_FILE" ]; then
    TOOL_CALLS=$(cat "$COUNTER_FILE" 2>/dev/null || echo "0")
fi

# ── Cost per 1k tokens ──
COST_PER_1K=0
if [ "$TOKENS_USED" -gt 0 ] 2>/dev/null && [ "$SESSION_COST" != "0" ] && [ "$SESSION_COST" != "0.000000" ]; then
    COST_PER_1K=$(awk "BEGIN { printf \"%.6f\", ($SESSION_COST / $TOKENS_USED) * 1000 }" 2>/dev/null || echo "0")
fi

# ── Context used percentage from bridge file ──
CONTEXT_USED_PCT=0
BRIDGE="/tmp/claude-ctx-${SESSION_ID}.json"
if [ -f "$BRIDGE" ]; then
    BRIDGE_PCT=$(sed -n 's/.*"used_pct"[[:space:]]*:[[:space:]]*\([0-9.]*\).*/\1/p' "$BRIDGE" 2>/dev/null | head -1)
    [ -n "$BRIDGE_PCT" ] && CONTEXT_USED_PCT="$BRIDGE_PCT"
fi

# ── Skills used (logged by skill invocations) ──
SKILLS_USED=""
if [ -f "$HOME/.claude/.nox_skills_used" ]; then
    SKILLS_USED=$(sort -u "$HOME/.claude/.nox_skills_used" 2>/dev/null | tr '\n' ',' | sed 's/,$//')
    rm -f "$HOME/.claude/.nox_skills_used"
fi

# ── Detect which machine we're on ──
MACHINE="unknown"
case "$(hostname 2>/dev/null)" in
    *Mac-Mini*|*m4*) MACHINE="m4" ;;
    *DESKTOP*|*Admin*|*PC*) MACHINE="pc" ;;
    *m1*|*Mac*) MACHINE="m1" ;;
esac
# Fallback: check by IP / user
if [ "$MACHINE" = "unknown" ]; then
    case "$(whoami 2>/dev/null)" in
        openclaw) MACHINE="m4" ;;
        Admin|admin) MACHINE="pc" ;;
        User|user) MACHINE="m1" ;;
    esac
fi

# ── Build JSON record (used by both SQLite and JSONL backends) ──
JSON_RECORD="{\"session_id\":\"$SESSION_ID\",\"timestamp\":\"$TIMESTAMP\",\"machine\":\"$MACHINE\",\"project\":\"$PROJECT\",\"branch\":\"$BRANCH\",\"model\":\"$MODEL\",\"session_cost\":$SESSION_COST,\"tokens_used\":$TOKENS_USED,\"input_tokens\":$INPUT_TOKENS,\"output_tokens\":$OUTPUT_TOKENS,\"cache_read_tokens\":$CACHE_READ,\"cache_write_tokens\":$CACHE_WRITE,\"cost_per_1k\":$COST_PER_1K,\"tool_calls\":$TOOL_CALLS,\"files_changed\":$FILES_CHANGED,\"commits\":$COMMITS_THIS_SESSION,\"duration_min\":$DURATION_MIN,\"context_used_pct\":$CONTEXT_USED_PCT,\"hooks_active\":$HOOKS_ACTIVE,\"skills_used\":\"$SKILLS_USED\"}"

# ── SQL for creating table + inserting ──
CREATE_SQL="CREATE TABLE IF NOT EXISTS sessions (
    session_id TEXT PRIMARY KEY,
    timestamp TEXT NOT NULL,
    machine TEXT DEFAULT 'unknown',
    project TEXT,
    branch TEXT,
    model TEXT,
    session_cost REAL DEFAULT 0,
    tokens_used INTEGER DEFAULT 0,
    input_tokens INTEGER DEFAULT 0,
    output_tokens INTEGER DEFAULT 0,
    cache_read_tokens INTEGER DEFAULT 0,
    cache_write_tokens INTEGER DEFAULT 0,
    cost_per_1k REAL DEFAULT 0,
    tool_calls INTEGER DEFAULT 0,
    files_changed INTEGER DEFAULT 0,
    commits INTEGER DEFAULT 0,
    duration_min INTEGER DEFAULT 0,
    context_used_pct REAL DEFAULT 0,
    hooks_active INTEGER DEFAULT 1,
    skills_used TEXT DEFAULT '',
    created_at TEXT DEFAULT (datetime('now'))
);"

INSERT_SQL="INSERT OR REPLACE INTO sessions
    (session_id, timestamp, machine, project, branch, model, session_cost, tokens_used,
     input_tokens, output_tokens, cache_read_tokens, cache_write_tokens,
     cost_per_1k, tool_calls, files_changed, commits, duration_min,
     context_used_pct, hooks_active, skills_used)
    VALUES
    ('$SESSION_ID', '$TIMESTAMP', '$MACHINE', '$PROJECT', '$BRANCH', '$MODEL', $SESSION_COST,
     $TOKENS_USED, $INPUT_TOKENS, $OUTPUT_TOKENS, $CACHE_READ, $CACHE_WRITE,
     $COST_PER_1K, $TOOL_CALLS, $FILES_CHANGED, $COMMITS_THIS_SESSION, $DURATION_MIN,
     $CONTEXT_USED_PCT, $HOOKS_ACTIVE, '$SKILLS_USED');"

CLEANUP_SQL="DELETE FROM sessions WHERE session_id NOT IN (SELECT session_id FROM sessions ORDER BY timestamp DESC LIMIT 1000);"

# ── Central DB on M4 Mac ──
# All machines write to M4's DB. If on a remote machine, SSH the insert.
# If M4 is unreachable, write to local fallback DB for later merge via 00.
M4_DB_PATH="/Users/openclaw/.claude/.nox_metrics.db"
M4_SSH="openclaw@100.124.63.67"
LOCAL_FALLBACK="$HOME/.claude/.nox_metrics_local.db"

# Guard: sqlite3 may not be installed (e.g., Windows Git Bash)
HAS_SQLITE3=false
command -v sqlite3 >/dev/null 2>&1 && HAS_SQLITE3=true

# ── JSONL fallback path ──
JSONL_FILE="${NOX_COST_JSONL:-$HOME/.claude/.nox_metrics.jsonl}"

# ── Write session data ──
write_jsonl_fallback() {
    mkdir -p "$(dirname "$JSONL_FILE")"
    echo "$JSON_RECORD" >> "$JSONL_FILE"
    # Keep last 1000 entries
    if [ -f "$JSONL_FILE" ]; then
        LINE_COUNT=$(wc -l < "$JSONL_FILE" | tr -d ' ')
        if [ "$LINE_COUNT" -gt 1000 ]; then
            tail -n 1000 "$JSONL_FILE" > "${JSONL_FILE}.tmp" && mv "${JSONL_FILE}.tmp" "$JSONL_FILE"
        fi
    fi
}

if [ "$MACHINE" = "m4" ]; then
    # We ARE on M4 — write directly
    if [ "$HAS_SQLITE3" = true ]; then
        sqlite3 "$DB" "$CREATE_SQL" 2>/dev/null || true
        sqlite3 "$DB" "$INSERT_SQL" 2>/dev/null || true
        sqlite3 "$DB" "$CLEANUP_SQL" 2>/dev/null || true
    else
        write_jsonl_fallback
    fi
else
    # Remote machine — try SSH insert to M4's central DB (hard 5s timeout)
    if timeout 5 ssh -o ConnectTimeout=2 -o BatchMode=yes -o ServerAliveInterval=2 -o ServerAliveCountMax=1 "$M4_SSH" \
        "sqlite3 '$M4_DB_PATH' \"$CREATE_SQL\" && sqlite3 '$M4_DB_PATH' \"$INSERT_SQL\"" 2>/dev/null; then
        true  # Success — logged to central DB
    elif [ "$HAS_SQLITE3" = true ]; then
        # M4 offline — write locally for later merge
        sqlite3 "$LOCAL_FALLBACK" "$CREATE_SQL" 2>/dev/null || true
        sqlite3 "$LOCAL_FALLBACK" "$INSERT_SQL" 2>/dev/null || true
    else
        # No sqlite3 available — JSONL fallback
        write_jsonl_fallback
    fi
fi

# ── Reset hook counter ──
rm -f "$COUNTER_FILE" 2>/dev/null

exit 0
