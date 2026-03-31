#!/usr/bin/env bash
# PII Safety Check — run before every commit to this PUBLIC repo
# Usage: bash scripts/pii-check.sh
# Returns exit 1 if personal data is found

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "PII Safety Check"
echo "================"

# Patterns that must NEVER appear in this public repo
# "Admin/privileged" in nox-pentester.md is a false positive (generic security term)
HITS=$(grep -rn \
  "openclaw\|100\.116\.\|100\.124\.\|100\.95\.\|Scriber\|GAV-Admin\|GAV-Records\|Happy-Turtle\|Foundry-Wealth\|cookingwithkahnke\|Paint-by-Mentor\|Groove-Music-App\|M4 Mac\|M1 Mac\|Desktop PC\|/Users/openclaw\|Tailscale" \
  --include="*.md" --include="*.sh" --include="*.js" --include="*.json" \
  --exclude="pii-check.sh" \
  --exclude-dir=".claude" \
  --exclude-dir="node_modules" \
  "$SCRIPT_DIR" 2>/dev/null || true)

if [ -n "$HITS" ]; then
  echo ""
  echo "!! PERSONAL DATA DETECTED — DO NOT COMMIT !!"
  echo ""
  echo "$HITS"
  echo ""
  echo "Fix these before committing. This is a PUBLIC repo."
  exit 1
else
  echo "  No personal data found. Safe to commit."
  exit 0
fi
