#!/bin/bash
# notify-timer-start.sh — PreToolUse hook for Bash
# Records start timestamp for commands. Paired with notify-complete.sh
# to detect commands that take >60 seconds and send a notification.
#
# Install: Add to PreToolUse hooks with matcher "Bash"
# Config:  NOX_SKIP_NOTIFY=1 to disable (same var as notify-complete.sh)

[[ "$NOX_SKIP_NOTIFY" == "1" ]] && exit 0

# Drain stdin (required) and record timestamp — no JSON parsing needed
cat > /dev/null
date +%s > /tmp/.claude_cmd_timer

exit 0
