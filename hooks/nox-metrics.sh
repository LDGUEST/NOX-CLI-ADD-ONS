#!/bin/bash
# nox-metrics.sh — Query NOX session cost tracker
# Usage: bash nox-metrics.sh [summary|compare|recent|project|expensive|efficient]
set -eu

[ "${NOX_SKIP_ALL:-0}" = "1" ] && exit 0

DB="${NOX_COST_DB:-$HOME/.claude/.nox_metrics.db}"

if ! command -v sqlite3 >/dev/null 2>&1; then
    echo "sqlite3 not found. Install it to use metrics queries."
    exit 1
fi

if [ ! -f "$DB" ]; then
    echo "No metrics DB found at $DB"
    echo "The session-cost-tracker hook creates this after your first session."
    exit 1
fi

CMD="${1:-summary}"

case "$CMD" in
    summary)
        echo "═══ NOX Session Metrics Summary ═══"
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
        echo "═══ NOX Hooks: ON vs OFF ═══"
        echo ""
        echo "── Overview ──"
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
        echo "── Efficiency ──"
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
        echo "── By session size ──"
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
        echo "── By machine ──"
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
        echo "═══ Last 20 Sessions ═══"
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
        echo "═══ Sessions for: $PROJECT ═══"
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
        echo "═══ Most Expensive Sessions ═══"
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
        echo "═══ Cost Efficiency by Model ═══"
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

    *)
        echo "Usage: nox-metrics.sh [summary|compare|recent|project <name>|expensive|efficient]"
        echo ""
        echo "  summary    — Overall stats + per-project breakdown"
        echo "  compare    — A/B: hooks ON vs OFF"
        echo "  recent     — Last 20 sessions"
        echo "  project    — Filter by project name"
        echo "  expensive  — Most expensive sessions"
        echo "  efficient  — Cost efficiency by model"
        ;;
esac
