#!/bin/bash
# Nox Hook: compact-saver
# Event: PreCompact
# Purpose: Saves a context checkpoint before compaction so post-compaction Claude recovers faster
# Install: bash install.sh --with-hooks
# Config: NOX_SKIP_COMPACT_SAVER=1 to disable
#         NOX_COMPACT_DIR=path to override checkpoint dir (default: .claude/checkpoints/)
set -eu

[ "${NOX_SKIP_COMPACT_SAVER:-0}" = "1" ] && exit 0

INPUT=$(cat)
source "$(dirname "$0")/lib-json.sh"
SESSION_ID=$(json_str "$INPUT" session_id)
[ -z "$SESSION_ID" ] && SESSION_ID="unknown"
CWD=$(json_str "$INPUT" cwd)
[ -z "$CWD" ] && exit 0
cd "$CWD" 2>/dev/null || exit 0

CHECKPOINT_DIR="${NOX_COMPACT_DIR:-.claude/checkpoints}"
mkdir -p "$CHECKPOINT_DIR"

TIMESTAMP=$(date '+%Y-%m-%d_%H%M%S')
CHECKPOINT_FILE="${CHECKPOINT_DIR}/pre-compact_${TIMESTAMP}.md"

{
    echo "# Pre-Compaction Checkpoint"
    echo "**Session:** $SESSION_ID"
    echo "**Saved:** $(date '+%Y-%m-%d %H:%M:%S')"
    echo "**Project:** $CWD"
    echo ""

    # Git state
    if git rev-parse --git-dir >/dev/null 2>&1; then
        echo "## Git State"
        echo "**Branch:** $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"
        echo ""
        echo "### Recent Commits"
        echo '```'
        git log --oneline -10 2>/dev/null || echo "none"
        echo '```'
        echo ""

        DIFF_STAT=$(git diff --stat 2>/dev/null || true)
        STAGED_STAT=$(git diff --cached --stat 2>/dev/null || true)
        if [ -n "$DIFF_STAT" ] || [ -n "$STAGED_STAT" ]; then
            echo "### Uncommitted Changes"
            echo '```'
            [ -n "$STAGED_STAT" ] && echo "Staged:" && echo "$STAGED_STAT"
            [ -n "$DIFF_STAT" ] && echo "Unstaged:" && echo "$DIFF_STAT"
            echo '```'
            echo ""
        fi
    fi

    # Active files (recently modified)
    echo "## Recently Modified Files"
    echo '```'
    find . -maxdepth 3 -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.py" -o -name "*.go" -o -name "*.rs" 2>/dev/null | \
        xargs ls -lt 2>/dev/null | head -10 | awk '{print $NF}' || echo "none"
    echo '```'
} > "$CHECKPOINT_FILE" 2>/dev/null

# Keep only last 3 checkpoints (continuation.md is separate and self-cleaning)
ls -t "${CHECKPOINT_DIR}"/pre-compact_*.md 2>/dev/null | tail -n +4 | xargs rm -f 2>/dev/null || true

echo "💾 Context checkpoint saved: $CHECKPOINT_FILE" >&2
exit 0
