#!/bin/bash
# secret-scanner.sh — PostToolUse hook for Write|Edit
# Scans files after editing for accidentally introduced secrets.
# Catches: OpenAI, Anthropic, AWS, GitHub, Slack, Google API keys,
# JWTs, and generic high-entropy tokens.
#
# PERF: Hash-based dedup — skips re-scanning files whose content hasn't changed.
#       Uses lightweight grep/sed for JSON field extraction instead of python3.
#
# Install: Add to PostToolUse hooks with matcher "Write|Edit"
# Config:  Set NOX_SKIP_SECRET_SCAN=1 to disable
#          Set NOX_SECRET_PATTERNS to a file with custom patterns (one per line)

[[ "${NOX_SKIP_ALL:-0}" == "1" ]] && exit 0
[ "${NOX_SKIP_SECRET_SCAN:-0}" = "1" ] && exit 0

INPUT=$(cat)

# ── Smart routing: bail before sourcing lib-json.sh if tool is irrelevant ──
echo "$INPUT" | grep -qE '"tool_name" *: *"(Write|Edit)"' || exit 0

# ── Lightweight JSON extraction (no python3) ──
source "$(dirname "$0")/lib-json.sh"

FILE=$(json_str "$INPUT" file_path)
[ -z "$FILE" ] && exit 0
[ ! -f "$FILE" ] && exit 0

# Skip binary/asset files
case "$FILE" in
    *.png|*.jpg|*.jpeg|*.gif|*.ico|*.woff|*.woff2|*.ttf|*.eot|*.pdf|*.zip|*.tar|*.gz|*.svg|*.lock)
        exit 0 ;;
esac

# ── Hash-based dedup: skip if content unchanged since last scan ──
HASH_CACHE="$HOME/.claude/.secret_scan_hashes"
if command -v md5sum &>/dev/null; then
    FILE_HASH=$(md5sum "$FILE" 2>/dev/null | cut -d' ' -f1)
elif command -v md5 &>/dev/null; then
    FILE_HASH=$(md5 -q "$FILE" 2>/dev/null)
fi
if [ -n "$FILE_HASH" ] && [ -f "$HASH_CACHE" ]; then
    CACHED=$(grep -F "$FILE=" "$HASH_CACHE" 2>/dev/null | tail -1 | cut -d= -f2-)
    if [ "$CACHED" = "$FILE_HASH" ]; then
        exit 0  # Content unchanged — skip scan
    fi
fi

# Built-in secret patterns
PATTERNS=(
    'sk-[a-zA-Z0-9]{20,}'                           # OpenAI
    'sk-ant-[a-zA-Z0-9_-]{30,}'                      # Anthropic
    'eyJ[a-zA-Z0-9_-]{30,}\.[a-zA-Z0-9_-]{30,}'     # JWT
    'AKIA[0-9A-Z]{16}'                               # AWS Access Key
    'ghp_[a-zA-Z0-9]{36}'                            # GitHub PAT
    'gho_[a-zA-Z0-9]{36}'                            # GitHub OAuth
    'xoxb-[0-9]+-[0-9]+-[a-zA-Z0-9]+'               # Slack Bot Token
    'xoxp-[0-9]+-[0-9]+-[a-zA-Z0-9]+'               # Slack User Token
    'AIza[0-9A-Za-z_-]{35}'                          # Google API Key
    'ya29\.[0-9A-Za-z_-]+'                           # Google OAuth
    'whsec_[a-zA-Z0-9]{32,}'                         # Stripe Webhook Secret
    'sk_live_[a-zA-Z0-9]{24,}'                       # Stripe Secret Key
    'rk_live_[a-zA-Z0-9]{24,}'                       # Stripe Restricted Key
    'sq0atp-[a-zA-Z0-9_-]{22,}'                      # Square Access Token
    'SG\.[a-zA-Z0-9_-]{22,}\.[a-zA-Z0-9_-]{43,}'    # SendGrid API Key
)

# Load custom patterns if configured
if [[ -n "$NOX_SECRET_PATTERNS" && -f "$NOX_SECRET_PATTERNS" ]]; then
    while IFS= read -r line; do
        [[ -n "$line" && "$line" != \#* ]] && PATTERNS+=("$line")
    done < "$NOX_SECRET_PATTERNS"
fi

FOUND=""
for PATTERN in "${PATTERNS[@]}"; do
    MATCH=$(grep -nE "$PATTERN" "$FILE" 2>/dev/null | head -3)
    if [[ -n "$MATCH" ]]; then
        FOUND="${FOUND}\n${MATCH}"
    fi
done

if [ -n "$FOUND" ]; then
    echo "SECRET DETECTED in $FILE:"
    echo -e "$FOUND"
    echo ""
    echo "Remove the secret and use environment variables instead."
    # Don't cache hash — file has a secret, re-scan after edits
    exit 2
fi

# ── Cache hash for clean files (dedup future scans) ──
if [ -n "$FILE_HASH" ]; then
    mkdir -p "$(dirname "$HASH_CACHE")"
    # Remove old entry, append new
    grep -vF "$FILE=" "$HASH_CACHE" 2>/dev/null > "${HASH_CACHE}.tmp" || true
    echo "$FILE=$FILE_HASH" >> "${HASH_CACHE}.tmp"
    # Keep cache bounded (last 200 files)
    tail -n 200 "${HASH_CACHE}.tmp" > "$HASH_CACHE" 2>/dev/null
    rm -f "${HASH_CACHE}.tmp"
fi

exit 0
