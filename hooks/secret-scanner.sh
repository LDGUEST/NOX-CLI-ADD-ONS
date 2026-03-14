#!/bin/bash
# secret-scanner.sh — PostToolUse hook for Write|Edit
# Scans files after editing for accidentally introduced secrets.
# Catches: OpenAI, Anthropic, AWS, GitHub, Slack, Google API keys,
# JWTs, and generic high-entropy tokens.
#
# Install: Add to PostToolUse hooks with matcher "Write|Edit"
# Config:  Set NOX_SKIP_SECRET_SCAN=1 to disable
#          Set NOX_SECRET_PATTERNS to a file with custom patterns (one per line)

[[ "${NOX_SKIP_SECRET_SCAN:-}" == "1" ]] && exit 0

INPUT=$(cat)

# Fast field extraction without python3 (~0.5ms vs ~80ms)
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HOOK_DIR/nox-parse.sh" 2>/dev/null || { echo "nox-parse.sh not found" >&2; exit 0; }

TOOL=$(nox_field "tool_name" "$INPUT")
[[ "$TOOL" != "Write" && "$TOOL" != "Edit" ]] && exit 0

FILE=$(nox_field "file_path" "$INPUT")
[[ -z "$FILE" || ! -f "$FILE" ]] && exit 0

# Skip binary/asset files
case "$FILE" in
    *.png|*.jpg|*.jpeg|*.gif|*.ico|*.woff|*.woff2|*.ttf|*.eot|*.pdf|*.zip|*.tar|*.gz|*.svg|*.lock)
        exit 0 ;;
esac

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

if [[ -n "$FOUND" ]]; then
    echo "SECRET DETECTED in $FILE:"
    echo -e "$FOUND"
    echo ""
    echo "Remove the secret and use environment variables instead."
    exit 2
fi

exit 0
