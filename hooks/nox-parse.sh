#!/bin/bash
# nox-parse.sh — Lightweight JSON field extractor for NOX hooks
# Replaces python3 JSON parsing with pure bash/sed for common fields.
# Source this file, then call nox_field "field_name" "$INPUT"
#
# Handles flat top-level fields only (session_id, cwd, tool_name, etc.)
# For nested fields, falls back to python3.
#
# Performance: ~0.5ms vs ~80ms for python3 -c "import json..."

nox_field() {
    local key="$1" input="$2"
    # Fast path: extract "key":"value" or "key": "value" with sed
    # Handles string values (most hook fields)
    local val
    val=$(echo "$input" | sed -n "s/.*\"${key}\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -1)
    if [ -n "$val" ]; then
        echo "$val"
        return 0
    fi
    # Try numeric/boolean values
    val=$(echo "$input" | sed -n "s/.*\"${key}\"[[:space:]]*:[[:space:]]*\([0-9.eE+\-]*\).*/\1/p" | head -1)
    if [ -n "$val" ]; then
        echo "$val"
        return 0
    fi
    # Boolean true/false/null
    val=$(echo "$input" | sed -n "s/.*\"${key}\"[[:space:]]*:[[:space:]]*\(true\|false\|null\).*/\1/p" | head -1)
    echo "${val:-}"
}

# Extract nested field: nox_nested "parent.child" "$INPUT"
nox_nested() {
    local path="$1" input="$2"
    python3 -c "
import sys,json
d=json.loads(sys.stdin.read())
keys='${path}'.split('.')
for k in keys:
    if isinstance(d,dict):
        d=d.get(k,'')
    else:
        d=''
        break
print(d)
" <<< "$input" 2>/dev/null
}
