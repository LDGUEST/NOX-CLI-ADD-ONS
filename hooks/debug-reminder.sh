#!/bin/bash
# debug-reminder.sh — PostToolUse hook for Bash
# When a command fails, reminds the agent to check DEBUGGING.md before
# re-investigating from scratch. Especially useful for test failures
# in multi-model teams where another model may have already solved it.
#
# Install: Add to PostToolUse hooks with matcher "Bash"
# Config:  Set NOX_SKIP_DEBUG_REMINDER=1 to disable
#          Works with any project that has a DEBUGGING.md in its root

[[ "${NOX_SKIP_ALL:-0}" == "1" ]] && exit 0
[[ "$NOX_SKIP_DEBUG_REMINDER" == "1" ]] && exit 0

INPUT=$(cat)

# ── Smart routing: bail early if command succeeded (exit_code 0 or absent) ──
# Avoids sourcing lib-json.sh for the majority of Bash calls that succeed
echo "$INPUT" | grep -qE '"(exit_code|exitCode|code)" *: *[1-9]' || exit 0

source "$(dirname "$0")/lib-json.sh"

# Get exit code — check multiple field names
EXIT_CODE=$(json_num "$INPUT" exit_code)
[ -z "$EXIT_CODE" ] && EXIT_CODE=$(json_num "$INPUT" exitCode)
[ -z "$EXIT_CODE" ] && EXIT_CODE=$(json_num "$INPUT" code)
[ "${EXIT_CODE:-0}" = "0" ] && exit 0

CMD=$(json_str "$INPUT" command)

# Detect test commands specifically
IS_TEST=false
if echo "$CMD" | grep -qE '(npm\s+test|npx\s+(jest|vitest|playwright)|pytest|python\s+-m\s+(pytest|unittest)|cargo\s+test|go\s+test|ruby\s+-Itest|bundle\s+exec\s+rspec)'; then
    IS_TEST=true
fi

if [[ -f "./DEBUGGING.md" ]]; then
    if [[ "$IS_TEST" == true ]]; then
        echo "TEST FAILURE — Read DEBUGGING.md before debugging. Another model may have already documented this exact fix."
    else
        echo "Command failed (exit $EXIT_CODE). Check DEBUGGING.md — this error pattern may already be documented."
    fi
elif [[ "$IS_TEST" == true ]]; then
    echo "TEST FAILURE — Consider creating a DEBUGGING.md to document the root cause once fixed. Future agents will thank you."
fi

exit 0
