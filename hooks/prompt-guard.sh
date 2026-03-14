#!/bin/bash
# Nox Hook: prompt-guard
# Event: UserPromptSubmit
# Purpose: Warns on vague or potentially destructive prompts — asks for confirmation before Claude processes them
# Install: bash install.sh --with-hooks
# Config: NOX_SKIP_PROMPT_GUARD=1 to disable
set -eu

[ "${NOX_SKIP_PROMPT_GUARD:-0}" = "1" ] && exit 0

INPUT=$(cat)

# Fast field extraction without python3
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HOOK_DIR/nox-parse.sh" 2>/dev/null || exit 0

PROMPT=$(nox_field "prompt" "$INPUT")
[ -z "$PROMPT" ] && exit 0

# Normalize to lowercase for matching
LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

# Destructive patterns
if echo "$LOWER" | grep -qE "(delete (all|every|the entire)|remove (all|every)|drop (all|every)|wipe|nuke|destroy|start over from scratch|rewrite (everything|the entire|all))"; then
    echo "⚠ PROMPT GUARD: This prompt may trigger destructive changes:" >&2
    echo "  \"$(echo "$PROMPT" | head -c 100)\"" >&2
    echo "  Consider being more specific about what to delete/rewrite." >&2
    echo "  (set NOX_SKIP_PROMPT_GUARD=1 to disable this check)" >&2
    # Don't block — just warn. User already typed it intentionally.
    exit 0
fi

# Overly broad patterns
if echo "$LOWER" | grep -qE "^(fix everything|refactor everything|update everything|change everything|redo everything|rewrite everything)$"; then
    echo "⚠ PROMPT GUARD: Very broad instruction detected:" >&2
    echo "  \"$PROMPT\"" >&2
    echo "  Broad prompts can lead to unintended changes. Consider scoping to specific files or features." >&2
    exit 0
fi

exit 0
