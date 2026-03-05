#!/bin/bash
# debug-reminder.sh — PostToolUse hook for Bash
# When a command fails, reminds the agent to check DEBUGGING.md before
# re-investigating from scratch. Especially useful for test failures
# in multi-model teams where another model may have already solved it.
#
# Install: Add to PostToolUse hooks with matcher "Bash"
# Config:  Set NOX_SKIP_DEBUG_REMINDER=1 to disable
#          Works with any project that has a DEBUGGING.md in its root

[[ "$NOX_SKIP_DEBUG_REMINDER" == "1" ]] && exit 0

INPUT=$(cat)
TOOL=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null)
[[ "$TOOL" != "Bash" ]] && exit 0

# Get exit code — try multiple field names for compatibility
EXIT_CODE=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
r = d.get('tool_result', {})
for key in ['exit_code', 'exitCode', 'code']:
    v = r.get(key)
    if v is not None:
        print(v)
        sys.exit(0)
# Check if stdout contains error indicators
print(0)
" 2>/dev/null)

[[ "$EXIT_CODE" == "0" || -z "$EXIT_CODE" ]] && exit 0

CMD=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null)

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
