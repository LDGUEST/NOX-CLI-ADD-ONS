#!/bin/bash
# Nox Hook: file-size-guard
# Event: PreToolUse (Write)
# Purpose: Blocks writing files over a size threshold — catches accidental base64 dumps, minified bundles, large JSON blobs
# Install: bash install.sh --with-hooks
# Config: NOX_SKIP_FILE_SIZE_GUARD=1 to disable
#         NOX_FILE_SIZE_LIMIT=512000 (bytes, default 500KB)
set -eu

[ "${NOX_SKIP_FILE_SIZE_GUARD:-0}" = "1" ] && exit 0

INPUT=$(cat)
source "$(dirname "$0")/lib-json.sh"

LIMIT="${NOX_FILE_SIZE_LIMIT:-512000}"

# Estimate content size from stdin length (avoid python3 for simple size check)
# wc -c on the full JSON is an upper bound; content is the largest field
SIZE=${#INPUT}
FILE_PATH=$(json_str "$INPUT" file_path)
[ -z "$FILE_PATH" ] && FILE_PATH="unknown"

if [ "$SIZE" -gt "$LIMIT" ] 2>/dev/null; then
    SIZE_KB=$((SIZE / 1024))
    LIMIT_KB=$((LIMIT / 1024))
    echo "BLOCKED: File write exceeds size limit (${SIZE_KB}KB > ${LIMIT_KB}KB)" >&2
    echo "  File: $FILE_PATH" >&2
    echo "  This often means minified code, base64 data, or large JSON is being written to source." >&2
    echo "  If intentional, set NOX_FILE_SIZE_LIMIT=$((SIZE + 1024)) or NOX_SKIP_FILE_SIZE_GUARD=1" >&2
    exit 2
fi

exit 0
