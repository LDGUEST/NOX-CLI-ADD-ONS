#!/bin/bash
# Nox Hook: auto-context
# Event: SessionStart
# Purpose: Injects project state into every new session — git branch, recent commits, TODOs, DEBUGGING.md highlights
# Install: bash install.sh --with-hooks
# Config: NOX_SKIP_AUTO_CONTEXT=1 to disable
set -eu

[ "${NOX_SKIP_AUTO_CONTEXT:-0}" = "1" ] && exit 0

INPUT=$(cat)

# Fast field extraction without python3
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HOOK_DIR/nox-parse.sh" 2>/dev/null || {
    # Fallback if nox-parse.sh missing
    CWD=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null || echo "")
}
CWD="${CWD:-$(nox_field "cwd" "$INPUT")}"
[ -z "$CWD" ] && exit 0
cd "$CWD" 2>/dev/null || exit 0

# Only run in git repos
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

echo "--- Nox Auto-Context ---"
echo "Branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"

# Recent commits (compact: 5 lines)
echo ""
echo "Recent commits:"
git log --oneline -5 2>/dev/null || true

# Uncommitted changes (only if dirty — skip the echo if clean)
if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
    echo ""
    echo "Uncommitted changes:"
    { git diff --stat --cached 2>/dev/null; git diff --stat 2>/dev/null; } | head -10
fi

# TODO count — use git grep (faster than recursive grep, respects .gitignore)
TODO_COUNT=$(git grep -c -E "TODO|FIXME|HACK|XXX" -- '*.ts' '*.tsx' '*.js' '*.jsx' '*.py' '*.go' '*.rs' '*.rb' 2>/dev/null | awk -F: '{s+=$NF}END{print s+0}')
[ "$TODO_COUNT" -gt 0 ] 2>/dev/null && echo "TODOs: $TODO_COUNT"

# DEBUGGING.md (compact: one line)
if [ -f "DEBUGGING.md" ]; then
    ENTRY_COUNT=$(grep -c "^### " DEBUGGING.md 2>/dev/null || echo "0")
    echo "DEBUGGING.md: $ENTRY_COUNT entries"
fi

# Recovery playbook (critical — this one stays verbose)
PLAYBOOK=".claude/checkpoints/continuation.md"
if [ -f "$PLAYBOOK" ]; then
    echo ""
    echo "--- RECOVERY PLAYBOOK (from pre-compact handoff) ---"
    echo "Read .claude/checkpoints/continuation.md NOW, act on it, then delete it."
    echo "---"
fi

echo "--- End Auto-Context ---"
exit 0
