#!/bin/bash
# debug-reminder.sh — PostToolUse hook for Bash
# When a command fails, reminds the agent to check DEBUGGING.md before
# re-investigating from scratch. Especially useful for test failures
# in multi-model teams where another model may have already solved it.
#
# Install: Add to PostToolUse hooks with matcher "Bash"
# Config:  Set NOX_SKIP_DEBUG_REMINDER=1 to disable
#          Works with any project that has a DEBUGGING.md in its root

[[ "${NOX_SKIP_DEBUG_REMINDER:-}" == "1" ]] && exit 0

INPUT=$(cat)

# Fast field extraction without python3
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HOOK_DIR/nox-parse.sh" 2>/dev/null || exit 0

TOOL=$(nox_field "tool_name" "$INPUT")
[[ "$TOOL" != "Bash" ]] && exit 0

# Get exit code — fast path with sed, fallback to python3 for nested
EXIT_CODE=$(echo "$INPUT" | sed -n 's/.*"exit_code"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p' | head -1)
[[ -z "$EXIT_CODE" ]] && EXIT_CODE=$(echo "$INPUT" | sed -n 's/.*"exitCode"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p' | head -1)

[[ "$EXIT_CODE" == "0" || -z "$EXIT_CODE" ]] && exit 0

CMD=$(nox_field "command" "$INPUT")

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
