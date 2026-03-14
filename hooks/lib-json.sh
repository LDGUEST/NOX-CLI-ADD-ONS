#!/bin/bash
# lib-json.sh — Lightweight JSON field extraction for Nox hooks
# Source this file instead of spawning python3 for simple field reads.
#
# Usage:
#   source "$(dirname "$0")/lib-json.sh"
#   INPUT=$(cat)
#   FILE_PATH=$(json_str "$INPUT" file_path)
#   SESSION_ID=$(json_str "$INPUT" session_id)
#   COMMAND=$(json_str "$INPUT" command)
#   TOOL=$(json_str "$INPUT" tool_name)
#
# PERF: grep+sed is ~50x faster than python3 -c for single-field extraction.
#       python3 startup alone is ~30-80ms; grep+sed is <2ms.
#
# Limitations:
# - Only extracts top-level or first-match string values
# - Does not handle escaped quotes within values
# - For complex parsing (multi-field, nested), use python3
#
# Compatibility: Uses grep -oE (POSIX ERE) — works on macOS, Linux, Git Bash/MSYS

json_str() {
    # Extract a string value from JSON by key name
    # $1 = JSON string, $2 = key name
    echo "$1" | grep -oE "\"$2\" *: *\"[^\"]*\"" | head -1 | sed "s/\"$2\" *: *\"//;s/\"$//"
}

json_num() {
    # Extract a numeric value from JSON by key name
    # $1 = JSON string, $2 = key name
    echo "$1" | grep -oE "\"$2\" *: *[0-9.]+" | head -1 | sed "s/\"$2\" *: *//"
}

json_bool() {
    # Extract a boolean value from JSON by key name
    # $1 = JSON string, $2 = key name
    echo "$1" | grep -oE "\"$2\" *: *(true|false)" | head -1 | sed "s/\"$2\" *: *//"
}
