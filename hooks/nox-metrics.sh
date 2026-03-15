#!/bin/bash
# nox-metrics.sh — Query NOX session cost tracker
# Usage: bash nox-metrics.sh [summary|compare|recent|project|expensive|efficient]
#
# Supports two backends:
#   1. sqlite3 + .nox_metrics.db (full query support)
#   2. JSONL fallback + grep/awk (summary + recent when sqlite3 unavailable)
set -eu

[ "${NOX_SKIP_ALL:-0}" = "1" ] && exit 0

DB="${NOX_COST_DB:-$HOME/.claude/.nox_metrics.db}"
JSONL="${NOX_COST_JSONL:-$HOME/.claude/.nox_metrics.jsonl}"

HAS_SQLITE3=false
command -v sqlite3 >/dev/null 2>&1 && HAS_SQLITE3=true

CMD="${1:-summary}"

# ── JSONL fallback functions ──────────────────────────────────
# These provide basic summary/recent output using grep/awk/sort
# when sqlite3 is not available but the JSONL file exists.

jsonl_extract() {
    # Extract a field value from a JSON line
    # $1 = field name, $2 = JSON line
    # Handles both string ("val") and numeric (val) fields
    echo "$2" | grep -oE "\"$1\":(\"[^\"]*\"|[0-9.e+-]+)" | head -1 | sed "s/\"$1\"://;s/\"//g"
}

jsonl_summary() {
    echo "=== NOX Session Metrics Summary (JSONL mode) ==="
    echo ""
    echo "NOTE: Full query capabilities require sqlite3. Showing basic stats."
    echo ""

    awk -F'"' '
    BEGIN { n=0; total_cost=0; total_tokens=0; total_tools=0; total_ctx=0; total_cpk=0 }
    {
        # Extract numeric fields with simple pattern matching
        if (match($0, /"session_cost":([0-9.e+-]+)/, a)) total_cost += a[1]
        if (match($0, /"tokens_used":([0-9]+)/, a)) total_tokens += a[1]
        if (match($0, /"tool_calls":([0-9]+)/, a)) total_tools += a[1]
        if (match($0, /"context_used_pct":([0-9.]+)/, a)) total_ctx += a[1]
        if (match($0, /"cost_per_1k":([0-9.e+-]+)/, a)) total_cpk += a[1]
        n++
    }
    END {
        if (n == 0) { print "  No sessions recorded yet."; exit }
        printf "  sessions:       %d\n", n
        printf "  total_cost:     $%.2f\n", total_cost
        printf "  avg_cost:       $%.4f\n", total_cost / n
        printf "  avg_tokens:     %.0f\n", total_tokens / n
        printf "  avg_cost_per_1k: $%.4f\n", total_cpk / n
        printf "  avg_tool_calls: %.0f\n", total_tools / n
        printf "  avg_context_pct: %.1f%%\n", total_ctx / n
    }
    ' "$JSONL"

    echo ""
    echo "Per project:"

    awk '
    {
        proj = "unknown"
        if (match($0, /"project":"([^"]*)"/, a)) proj = a[1]
        cost = 0; tokens = 0
        if (match($0, /"session_cost":([0-9.e+-]+)/, a)) cost = a[1]
        if (match($0, /"tokens_used":([0-9]+)/, a)) tokens = a[1]
        count[proj]++
        tcost[proj] += cost
        ttokens[proj] += tokens
    }
    END {
        for (p in count) {
            printf "  %-25s  sessions=%d  total_cost=$%.2f  avg_cost=$%.4f  avg_tokens=%.0f\n", \
                p, count[p], tcost[p], tcost[p]/count[p], ttokens[p]/count[p]
        }
    }
    ' "$JSONL" | sort -t'$' -k2 -rn
}

jsonl_recent() {
    echo "=== Last 20 Sessions (JSONL mode) ==="
    echo ""
    echo "NOTE: Full query capabilities require sqlite3. Showing basic view."
    echo ""

    printf "  %-19s  %-4s  %-20s  %-8s  %8s  %8s  %5s  %5s  %s\n" \
        "timestamp" "mach" "project" "model" "cost" "tokens" "tools" "ctx%" "hooks"

    tail -n 20 "$JSONL" | awk '
    {
        ts = "?"; mach = "?"; proj = "?"; model = "?"; cost = 0
        tokens = 0; tools = 0; ctx = 0; hooks = "?"
        if (match($0, /"timestamp":"([^"]*)"/, a)) ts = a[1]
        if (match($0, /"machine":"([^"]*)"/, a)) mach = a[1]
        if (match($0, /"project":"([^"]*)"/, a)) proj = a[1]
        if (match($0, /"model":"([^"]*)"/, a)) model = a[1]
        if (match($0, /"session_cost":([0-9.e+-]+)/, a)) cost = a[1]
        if (match($0, /"tokens_used":([0-9]+)/, a)) tokens = a[1]
        if (match($0, /"tool_calls":([0-9]+)/, a)) tools = a[1]
        if (match($0, /"context_used_pct":([0-9.]+)/, a)) ctx = a[1]
        if (match($0, /"hooks_active":([0-9]+)/, a)) hooks = (a[1] == 1) ? "ON" : "OFF"
        # Truncate model name
        if (length(model) > 8) model = substr(model, 1, 8)
        printf "  %-19s  %-4s  %-20s  %-8s  %8.4f  %8d  %5d  %4.0f%%  %s\n", \
            ts, mach, proj, model, cost, tokens, tools, ctx, hooks
    }
    ' | tac 2>/dev/null || tail -n 20 "$JSONL" | awk '
    {
        ts = "?"; mach = "?"; proj = "?"; model = "?"; cost = 0
        tokens = 0; tools = 0; ctx = 0; hooks = "?"
        if (match($0, /"timestamp":"([^"]*)"/, a)) ts = a[1]
        if (match($0, /"machine":"([^"]*)"/, a)) mach = a[1]
        if (match($0, /"project":"([^"]*)"/, a)) proj = a[1]
        if (match($0, /"model":"([^"]*)"/, a)) model = a[1]
        if (match($0, /"session_cost":([0-9.e+-]+)/, a)) cost = a[1]
        if (match($0, /"tokens_used":([0-9]+)/, a)) tokens = a[1]
        if (match($0, /"tool_calls":([0-9]+)/, a)) tools = a[1]
        if (match($0, /"context_used_pct":([0-9.]+)/, a)) ctx = a[1]
        if (match($0, /"hooks_active":([0-9]+)/, a)) hooks = (a[1] == 1) ? "ON" : "OFF"
        if (length(model) > 8) model = substr(model, 1, 8)
        printf "  %-19s  %-4s  %-20s  %-8s  %8.4f  %8d  %5d  %4.0f%%  %s\n", \
            ts, mach, proj, model, cost, tokens, tools, ctx, hooks
    }'
}

# ── Route: JSONL fallback when no sqlite3 ─────────────────────
if [ "$HAS_SQLITE3" = false ]; then
    if [ ! -f "$JSONL" ]; then
        echo "sqlite3 not found and no JSONL fallback at $JSONL"
        echo "The session-cost-tracker hook creates data after your first session."
        exit 1
    fi

    case "$CMD" in
        summary)
            jsonl_summary
            ;;
        recent)
            jsonl_recent
            ;;
        *)
            echo "sqlite3 not found. JSONL fallback supports: summary, recent"
            echo ""
            echo "Install sqlite3 for full query capabilities:"
            echo "  summary | compare | recent | project <name> | expensive | efficient"
            exit 1
            ;;
    esac
    exit 0
fi

# ── sqlite3 available — full query support ────────────────────

if [ ! -f "$DB" ]; then
    echo "No metrics DB found at $DB"
    echo "The session-cost-tracker hook creates this after your first session."
    exit 1
fi

case "$CMD" in
    summary)
        echo "=== NOX Session Metrics Summary ==="
        echo ""
        sqlite3 -header -column "$DB" "
            SELECT
                COUNT(*) as sessions,
                ROUND(SUM(session_cost), 2) as total_cost,
                ROUND(AVG(session_cost), 4) as avg_cost,
                ROUND(AVG(tokens_used), 0) as avg_tokens,
                ROUND(AVG(cost_per_1k), 4) as avg_cost_per_1k,
                ROUND(AVG(tool_calls), 0) as avg_tool_calls,
                ROUND(AVG(context_used_pct), 1) as avg_context_pct
            FROM sessions;
        "
        echo ""
        echo "Per project:"
        sqlite3 -header -column "$DB" "
            SELECT
                project,
                COUNT(*) as sessions,
                ROUND(SUM(session_cost), 2) as total_cost,
                ROUND(AVG(session_cost), 4) as avg_cost,
                ROUND(AVG(tokens_used), 0) as avg_tokens
            FROM sessions
            GROUP BY project
            ORDER BY total_cost DESC
            LIMIT 15;
        "
        ;;

    compare)
        echo "=== NOX Hooks: ON vs OFF ==="
        echo ""
        echo "-- Overview --"
        sqlite3 -header -column "$DB" "
            SELECT
                CASE hooks_active WHEN 1 THEN 'HOOKS ON' ELSE 'HOOKS OFF' END as mode,
                COUNT(*) as sessions,
                ROUND(AVG(tokens_used), 0) as avg_tokens,
                ROUND(AVG(output_tokens), 0) as avg_output,
                ROUND(AVG(tool_calls), 0) as avg_tools,
                ROUND(AVG(duration_min), 0) as avg_min,
                ROUND(AVG(commits), 1) as avg_commits,
                ROUND(AVG(context_used_pct), 1) as avg_ctx,
                ROUND(AVG(files_changed), 1) as uncommitted
            FROM sessions
            GROUP BY hooks_active;
        "
        echo ""
        echo "-- Efficiency --"
        sqlite3 -header -column "$DB" "
            SELECT
                CASE hooks_active WHEN 1 THEN 'HOOKS ON' ELSE 'HOOKS OFF' END as mode,
                COUNT(*) as n,
                ROUND(AVG(CASE WHEN tool_calls > 0 THEN 1.0 * tokens_used / tool_calls ELSE 0 END), 0) as tok_per_tool,
                ROUND(AVG(CASE WHEN duration_min > 0 THEN 1.0 * commits / duration_min * 60 ELSE 0 END), 1) as commits_per_hr,
                ROUND(AVG(CASE WHEN duration_min > 0 THEN 1.0 * tokens_used / duration_min ELSE 0 END), 0) as tok_per_min
            FROM sessions
            WHERE tool_calls > 5
            GROUP BY hooks_active;
        "
        echo ""
        echo "-- By session size --"
        sqlite3 -header -column "$DB" "
            SELECT
                CASE hooks_active WHEN 1 THEN 'ON' ELSE 'OFF' END as hooks,
                CASE
                    WHEN tool_calls < 50 THEN 'light(<50)'
                    WHEN tool_calls < 150 THEN 'medium(50-150)'
                    ELSE 'heavy(150+)'
                END as size,
                COUNT(*) as n,
                ROUND(AVG(tokens_used), 0) as avg_tokens,
                ROUND(AVG(context_used_pct), 1) as avg_ctx
            FROM sessions
            GROUP BY hooks_active, size
            ORDER BY hooks, size;
        "
        echo ""
        echo "-- By machine --"
        sqlite3 -header -column "$DB" "
            SELECT
                COALESCE(machine, '?') as mach,
                CASE hooks_active WHEN 1 THEN 'ON' ELSE 'OFF' END as hooks,
                COUNT(*) as n,
                ROUND(AVG(tokens_used), 0) as avg_tokens,
                ROUND(AVG(tool_calls), 0) as avg_tools
            FROM sessions
            GROUP BY machine, hooks_active
            ORDER BY machine, hooks_active;
        "
        echo ""
        HOOKS_ON=$(sqlite3 "$DB" "SELECT COUNT(*) FROM sessions WHERE hooks_active=1;")
        HOOKS_OFF=$(sqlite3 "$DB" "SELECT COUNT(*) FROM sessions WHERE hooks_active=0;")
        echo "Sample sizes: ON=$HOOKS_ON, OFF=$HOOKS_OFF"
        if [ "$HOOKS_OFF" -lt 5 ] 2>/dev/null; then
            echo ""
            echo "Need more hooks-OFF sessions for meaningful comparison."
            echo "Toggle off with: nh > 2 in launcher"
        fi
        ;;

    recent)
        echo "=== Last 20 Sessions ==="
        echo ""
        sqlite3 -header -column "$DB" "
            SELECT
                timestamp,
                COALESCE(machine, '?') as mach,
                project,
                model,
                ROUND(session_cost, 4) as cost,
                tokens_used as tokens,
                tool_calls as tools,
                ROUND(context_used_pct, 0) as ctx_pct,
                CASE hooks_active WHEN 1 THEN 'ON' ELSE 'OFF' END as hooks
            FROM sessions
            ORDER BY timestamp DESC
            LIMIT 20;
        "
        ;;

    project)
        PROJECT="${2:-}"
        if [ -z "$PROJECT" ]; then
            echo "Usage: nox-metrics.sh project <name>"
            echo ""
            echo "Available projects:"
            sqlite3 "$DB" "SELECT DISTINCT project FROM sessions ORDER BY project;"
            exit 1
        fi
        echo "=== Sessions for: $PROJECT ==="
        sqlite3 -header -column "$DB" "
            SELECT
                timestamp,
                model,
                ROUND(session_cost, 4) as cost,
                tokens_used as tokens,
                tool_calls as tools,
                skills_used
            FROM sessions
            WHERE project = '$PROJECT'
            ORDER BY timestamp DESC
            LIMIT 20;
        "
        ;;

    expensive)
        echo "=== Most Expensive Sessions ==="
        echo ""
        sqlite3 -header -column "$DB" "
            SELECT
                timestamp,
                project,
                model,
                ROUND(session_cost, 4) as cost,
                tokens_used as tokens,
                tool_calls as tools,
                skills_used
            FROM sessions
            ORDER BY session_cost DESC
            LIMIT 15;
        "
        ;;

    efficient)
        echo "=== Cost Efficiency by Model ==="
        echo ""
        sqlite3 -header -column "$DB" "
            SELECT
                model,
                COUNT(*) as sessions,
                ROUND(AVG(session_cost), 4) as avg_cost,
                ROUND(AVG(tokens_used), 0) as avg_tokens,
                ROUND(AVG(cost_per_1k), 4) as avg_per_1k,
                ROUND(AVG(tool_calls), 0) as avg_tools
            FROM sessions
            GROUP BY model
            ORDER BY avg_per_1k ASC;
        "
        ;;

    health)
        echo "=== NOX Hook Health Dashboard ==="
        echo ""

        # ── Locate hook directories ──
        HOOKS_DIR="$HOME/.claude/hooks"
        REPO_HOOKS="$(cd "$(dirname "$0")" && pwd)"
        SETTINGS="$HOME/.claude/settings.json"

        # ── 1. Hook file inventory ──
        echo "-- Hook Files --"
        TOTAL_HOOKS=0
        MISSING_HOOKS=0
        NOT_EXEC=0
        if [ -d "$HOOKS_DIR" ]; then
            for f in "$HOOKS_DIR"/*.sh "$HOOKS_DIR"/*.js; do
                [ -f "$f" ] || continue
                TOTAL_HOOKS=$((TOTAL_HOOKS + 1))
                if [ ! -x "$f" ] && [[ "$f" == *.sh ]]; then
                    NOT_EXEC=$((NOT_EXEC + 1))
                    echo "  [!] Not executable: $(basename "$f")"
                fi
            done
        fi
        echo "  Installed: $TOTAL_HOOKS hook files in $HOOKS_DIR"
        [ "$NOT_EXEC" -gt 0 ] && echo "  Warning: $NOT_EXEC shell hook(s) not executable"
        echo ""

        # ── 2. Validate settings.json references ──
        echo "-- Settings.json References --"
        WIRED=0
        BROKEN=0
        if [ -f "$SETTINGS" ]; then
            # Extract hook commands from settings.json
            HOOK_REFS=$(grep -oE '(bash|node) [^"]+\.(sh|js)' "$SETTINGS" 2>/dev/null | sed 's/^bash //;s/^node //' | sed 's/^"//;s/"$//' || true)
            while IFS= read -r ref; do
                [ -z "$ref" ] && continue
                # Normalize path for check
                REF_FILE="$ref"
                # Expand ~ if present
                REF_FILE="${REF_FILE/#\~/$HOME}"
                WIRED=$((WIRED + 1))
                if [ ! -f "$REF_FILE" ]; then
                    BROKEN=$((BROKEN + 1))
                    echo "  [X] BROKEN: $ref"
                fi
            done <<< "$HOOK_REFS"
            echo "  Wired in settings.json: $WIRED hooks"
            [ "$BROKEN" -gt 0 ] && echo "  BROKEN references: $BROKEN" || echo "  All references valid"
        else
            echo "  [!] No settings.json found at $SETTINGS"
        fi
        echo ""

        # ── 3. Hooks per event type ──
        echo "-- Hooks per Event Type --"
        if [ -f "$SETTINGS" ]; then
            for EVENT in SessionStart UserPromptSubmit PreToolUse PostToolUse SubagentStart PreCompact Stop; do
                # Count hook commands under each event section
                # Use a simple approach: find event name, count hook commands until next event
                COUNT=$(python3 -c "
import json, sys
try:
    with open('$SETTINGS') as f:
        s = json.load(f)
    hooks = s.get('hooks', {}).get('$EVENT', [])
    total = 0
    for group in hooks:
        total += len(group.get('hooks', []))
    print(total)
except:
    print(0)
" 2>/dev/null || echo "0")
                [ "$COUNT" -gt 0 ] && printf "  %-20s %s hook(s)\n" "$EVENT" "$COUNT"
            done
        fi
        echo ""

        # ── 4. Session-level hook health from DB ──
        echo "-- Session Hook Activity --"
        sqlite3 -header -column "$DB" "
            SELECT
                CASE hooks_active WHEN 1 THEN 'ON' ELSE 'OFF' END as hooks,
                COUNT(*) as sessions,
                ROUND(AVG(duration_min), 1) as avg_min,
                ROUND(AVG(tool_calls), 0) as avg_tools,
                ROUND(AVG(tokens_used), 0) as avg_tokens
            FROM sessions
            GROUP BY hooks_active;
        " 2>/dev/null
        echo ""

        # ── 5. Average latency proxy (tokens per tool call) ──
        echo "-- Hook Overhead Proxy (tokens/tool by hook state) --"
        sqlite3 -header -column "$DB" "
            SELECT
                CASE hooks_active WHEN 1 THEN 'ON' ELSE 'OFF' END as hooks,
                COUNT(*) as n,
                ROUND(AVG(CASE WHEN tool_calls > 0 THEN 1.0 * tokens_used / tool_calls ELSE 0 END), 0) as tok_per_tool,
                ROUND(AVG(CASE WHEN duration_min > 0 THEN 1.0 * tool_calls / duration_min ELSE 0 END), 1) as tools_per_min
            FROM sessions
            WHERE tool_calls > 5
            GROUP BY hooks_active;
        " 2>/dev/null
        echo ""

        # ── 6. Health score ──
        SCORE=100
        ISSUES=""
        [ "$BROKEN" -gt 0 ] && SCORE=$((SCORE - BROKEN * 15)) && ISSUES="${ISSUES}broken refs, "
        [ "$NOT_EXEC" -gt 0 ] && SCORE=$((SCORE - NOT_EXEC * 10)) && ISSUES="${ISSUES}non-executable hooks, "
        [ ! -f "$SETTINGS" ] && SCORE=$((SCORE - 30)) && ISSUES="${ISSUES}no settings.json, "
        [ "$WIRED" -eq 0 ] && SCORE=$((SCORE - 20)) && ISSUES="${ISSUES}no hooks wired, "
        [ "$SCORE" -lt 0 ] && SCORE=0

        echo "-- Health Score --"
        if [ "$SCORE" -ge 90 ]; then
            echo "  Score: $SCORE/100 - HEALTHY"
        elif [ "$SCORE" -ge 60 ]; then
            echo "  Score: $SCORE/100 - DEGRADED"
        else
            echo "  Score: $SCORE/100 - UNHEALTHY"
        fi
        [ -n "$ISSUES" ] && echo "  Issues: ${ISSUES%, }"
        ;;

    *)
        echo "Usage: nox-metrics.sh [summary|compare|recent|project <name>|expensive|efficient|health]"
        echo ""
        echo "  summary    -- Overall stats + per-project breakdown"
        echo "  compare    -- A/B: hooks ON vs OFF"
        echo "  recent     -- Last 20 sessions"
        echo "  project    -- Filter by project name"
        echo "  expensive  -- Most expensive sessions"
        echo "  efficient  -- Cost efficiency by model"
        echo "  health     -- Hook health dashboard (file checks, broken refs, event counts)"
        ;;
esac
