#!/bin/bash
# Nox Hook: commit-lint
# Event: PreToolUse (Bash)
# Purpose: Validates commit messages follow Conventional Commits format
# Install: bash install.sh --with-hooks
# Config: NOX_SKIP_COMMIT_LINT=1 to disable
#         NOX_COMMIT_TYPES="feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert" to customize
set -eu

[ "${NOX_SKIP_COMMIT_LINT:-0}" = "1" ] && exit 0

INPUT=$(cat)

# Use python3 here because command field often contains escaped quotes (git commit -m "...")
CMD=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")
[ -z "$CMD" ] && exit 0

# Only care about git commit with -m flag
echo "$CMD" | grep -qE "git commit.*-m" || exit 0

# Extract the commit message (handles single and double quotes, heredoc)
MSG=$(echo "$CMD" | python3 -c "
import sys, re
cmd = sys.stdin.read()
# Try heredoc pattern first (cat <<'EOF' ... EOF)
m = re.search(r\"<<['\\\"]?EOF['\\\"]?\\n(.+?)\\nEOF\", cmd, re.DOTALL)
if m:
    print(m.group(1).strip())
    sys.exit(0)
# Try -m with quotes
m = re.search(r'-m\s+[\"\\'](.+?)[\"\\']', cmd)
if not m:
    # Try -m with double quotes containing escaped quotes
    m = re.search(r'-m\s+\"(.+?)\"', cmd, re.DOTALL)
if m:
    print(m.group(1).strip())
else:
    print('')
" 2>/dev/null || echo "")

[ -z "$MSG" ] && exit 0

# Validate against Conventional Commits
TYPES="${NOX_COMMIT_TYPES:-feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert}"
PATTERN="^($TYPES)(\(.+\))?!?: .+"

# Get first line of message
FIRST_LINE=$(echo "$MSG" | head -1)

if ! echo "$FIRST_LINE" | grep -qE "$PATTERN"; then
    echo "BLOCKED: Commit message doesn't follow Conventional Commits format." >&2
    echo "" >&2
    echo "  Got: \"$FIRST_LINE\"" >&2
    echo "  Expected: <type>(<scope>): <description>" >&2
    echo "  Types: $TYPES" >&2
    echo "  Examples:" >&2
    echo "    feat: add user authentication" >&2
    echo "    fix(auth): resolve token expiration bug" >&2
    echo "    chore!: drop Node 16 support" >&2
    echo "" >&2
    echo "  (set NOX_SKIP_COMMIT_LINT=1 to override)" >&2
    exit 2
fi

exit 0
