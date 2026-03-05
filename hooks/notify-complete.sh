#!/bin/bash
# notify-complete.sh — Pre+PostToolUse hook pair for Bash
# Sends a desktop notification when a bash command takes >60 seconds.
# Useful when you've tabbed away during long builds, tests, or deploys.
#
# This is the POST hook. Pair with notify-timer-start.sh as a PRE hook.
#
# Install: Add notify-timer-start.sh to PreToolUse (Bash matcher)
#          Add this file to PostToolUse (Bash matcher)
# Config:  NOX_NOTIFY_THRESHOLD — seconds before notification (default: 60)
#          NOX_SKIP_NOTIFY=1 to disable
# Platform: macOS (osascript), Linux (notify-send), Windows (no-op)

[[ "$NOX_SKIP_NOTIFY" == "1" ]] && exit 0

INPUT=$(cat)
TOOL=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null)
[[ "$TOOL" != "Bash" ]] && exit 0

THRESHOLD="${NOX_NOTIFY_THRESHOLD:-60}"
TIMER_FILE="/tmp/.claude_cmd_timer_$$"
# Also check the generic timer file (from notify-timer-start.sh)
for tf in "/tmp/.claude_cmd_timer" "$TIMER_FILE"; do
    if [[ -f "$tf" ]]; then
        START_TIME=$(cat "$tf" 2>/dev/null)
        NOW=$(date +%s)
        ELAPSED=$((NOW - START_TIME))
        rm -f "$tf"

        if [[ "$ELAPSED" -gt "$THRESHOLD" ]]; then
            CMD=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command','')[:60])" 2>/dev/null)
            EXIT_CODE=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_result',{}).get('exit_code', d.get('tool_result',{}).get('exitCode',0)))" 2>/dev/null)

            STATUS="completed"
            [[ "$EXIT_CODE" != "0" ]] && STATUS="FAILED"

            MSG="${CMD} — ${STATUS} (${ELAPSED}s)"

            # macOS
            if command -v osascript &>/dev/null; then
                osascript -e "display notification \"$MSG\" with title \"Claude Code\" sound name \"Glass\"" 2>/dev/null
            # Linux
            elif command -v notify-send &>/dev/null; then
                notify-send "Claude Code" "$MSG" 2>/dev/null
            fi
        fi
        break
    fi
done

exit 0
