#!/usr/bin/env bash
set -eu
(set -o pipefail 2>/dev/null) && set -o pipefail

# Nox Validator — confirms all 3 CLI formats are in sync
# Usage: bash validate.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$SCRIPT_DIR/claude/nox"
GEMINI_DIR="$SCRIPT_DIR/gemini/skills"
CODEX_DIR="$SCRIPT_DIR/codex/skills"
AGENTS_DIR="$SCRIPT_DIR/agents"
HOOKS_DIR="$SCRIPT_DIR/hooks"

errors=0
warnings=0

echo "Nox Validator"
echo "============="
echo ""

# ── Skill Parity ─────────────────────────────────────────────
echo "Checking skill parity across CLIs..."
echo ""

# Get all skill names from each format
claude_skills=""
if [ -d "$CLAUDE_DIR" ]; then
  claude_skills=$(ls -1 "$CLAUDE_DIR"/*.md 2>/dev/null | xargs -I{} basename {} .md | sort)
fi

gemini_skills=""
if [ -d "$GEMINI_DIR" ]; then
  gemini_skills=$(ls -1d "$GEMINI_DIR"/*/ 2>/dev/null | xargs -I{} basename {} | sort)
fi

codex_skills=""
if [ -d "$CODEX_DIR" ]; then
  codex_skills=$(ls -1d "$CODEX_DIR"/*/ 2>/dev/null | xargs -I{} basename {} | sort)
fi

claude_count=$(echo "$claude_skills" | grep -c . 2>/dev/null || echo 0)
gemini_count=$(echo "$gemini_skills" | grep -c . 2>/dev/null || echo 0)
codex_count=$(echo "$codex_skills" | grep -c . 2>/dev/null || echo 0)

echo "  Claude: $claude_count skills"
echo "  Gemini: $gemini_count skills"
echo "  Codex:  $codex_count skills"
echo ""

# Check for skills missing from any format
all_skills=$(echo -e "$claude_skills\n$gemini_skills\n$codex_skills" | sort -u | grep .)

for skill in $all_skills; do
  missing=""
  [ -f "$CLAUDE_DIR/$skill.md" ] || missing="${missing} Claude"
  [ -f "$GEMINI_DIR/$skill/SKILL.md" ] || missing="${missing} Gemini"
  [ -f "$CODEX_DIR/$skill/SKILL.md" ] || missing="${missing} Codex"

  if [ -n "$missing" ]; then
    echo "  MISSING: '$skill' not found in:$missing"
    errors=$((errors + 1))
  fi
done

if [ "$errors" -eq 0 ]; then
  echo "  All skills present in all 3 formats."
fi

# ── Gemini Frontmatter Check ─────────────────────────────────
echo ""
echo "Checking Gemini YAML frontmatter..."

for skill_dir in "$GEMINI_DIR"/*/; do
  [ -d "$skill_dir" ] || continue
  skill=$(basename "$skill_dir")
  skill_file="$skill_dir/SKILL.md"

  if [ ! -f "$skill_file" ]; then
    echo "  ERROR: $skill — missing SKILL.md"
    errors=$((errors + 1))
    continue
  fi

  # Check for frontmatter
  first_line=$(head -1 "$skill_file")
  if [ "$first_line" != "---" ]; then
    echo "  WARNING: $skill — missing YAML frontmatter (no --- header)"
    warnings=$((warnings + 1))
  fi
done

if [ "$warnings" -eq 0 ] && [ "$errors" -eq 0 ]; then
  echo "  All Gemini skills have YAML frontmatter."
fi

# ── Agents Check ──────────────────────────────────────────────
echo ""
echo "Checking agents..."

if [ -d "$AGENTS_DIR" ]; then
  agent_count=$(ls -1 "$AGENTS_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
  echo "  Found $agent_count agents"

  for agent in "$AGENTS_DIR"/*.md; do
    [ -f "$agent" ] || continue
    name=$(basename "$agent" .md)

    # Check for YAML frontmatter
    first_line=$(head -1 "$agent")
    if [ "$first_line" != "---" ]; then
      echo "  WARNING: $name — missing YAML frontmatter"
      warnings=$((warnings + 1))
    fi
  done
else
  echo "  No agents directory found"
fi

# ── Hooks Check ───────────────────────────────────────────────
echo ""
echo "Checking hooks..."

if [ -d "$HOOKS_DIR" ]; then
  hook_count=$(ls -1 "$HOOKS_DIR"/*.sh 2>/dev/null | wc -l | tr -d ' ')
  echo "  Found $hook_count hooks"

  for hook in "$HOOKS_DIR"/*.sh; do
    [ -f "$hook" ] || continue
    name=$(basename "$hook")

    # Check shebang
    first_line=$(head -1 "$hook")
    if [[ "$first_line" != "#!/bin/bash" && "$first_line" != "#!/usr/bin/env bash" ]]; then
      echo "  WARNING: $name — missing bash shebang"
      warnings=$((warnings + 1))
    fi

    # Check executable bit
    if [ ! -x "$hook" ]; then
      echo "  WARNING: $name — not executable (run: chmod +x hooks/$name)"
      warnings=$((warnings + 1))
    fi
  done
else
  echo "  No hooks directory found"
fi

# ── Content Parity ───────────────────────────────────────────
echo ""
echo "Checking content parity across formats..."
echo ""

# Function: strip YAML frontmatter and leading/trailing whitespace from a skill file
strip_frontmatter() {
  local file="$1"
  awk '
    BEGIN { in_fm=0; past_fm=0 }
    NR==1 && /^---[[:space:]]*$/ { in_fm=1; next }
    in_fm && /^---[[:space:]]*$/ { in_fm=0; past_fm=1; next }
    in_fm { next }
    { print }
  ' "$file" | sed -e '/./,$!d' | tac 2>/dev/null | sed -e '/./,$!d' | tac 2>/dev/null
}

# Fallback for systems without tac
if ! command -v tac &>/dev/null; then
  strip_frontmatter() {
    local file="$1"
    awk '
      BEGIN { in_fm=0; past_fm=0 }
      NR==1 && /^---[[:space:]]*$/ { in_fm=1; next }
      in_fm && /^---[[:space:]]*$/ { in_fm=0; past_fm=1; next }
      in_fm { next }
      { print }
    ' "$file" | sed -e '/./,$!d' | awk '{ lines[NR]=$0 } END { e=NR; while(e>0 && lines[e]~/^[[:space:]]*$/) e--; for(i=1;i<=e;i++) print lines[i] }'
  }
fi

parity_total=0
parity_match=0
parity_diverged=0

for skill in $all_skills; do
  claude_file="$CLAUDE_DIR/$skill.md"
  gemini_file="$GEMINI_DIR/$skill/SKILL.md"
  codex_file="$CODEX_DIR/$skill/SKILL.md"

  # Only check skills present in all 3 formats
  [ -f "$claude_file" ] && [ -f "$gemini_file" ] && [ -f "$codex_file" ] || continue

  parity_total=$((parity_total + 1))

  claude_body=$(strip_frontmatter "$claude_file")
  gemini_body=$(strip_frontmatter "$gemini_file")
  codex_body=$(strip_frontmatter "$codex_file")

  claude_hash=$(echo "$claude_body" | md5sum | awk '{print $1}')
  gemini_hash=$(echo "$gemini_body" | md5sum | awk '{print $1}')
  codex_hash=$(echo "$codex_body" | md5sum | awk '{print $1}')

  claude_lines=$(echo "$claude_body" | wc -l | tr -d ' ')
  gemini_lines=$(echo "$gemini_body" | wc -l | tr -d ' ')
  codex_lines=$(echo "$codex_body" | wc -l | tr -d ' ')

  if [ "$claude_hash" = "$gemini_hash" ] && [ "$claude_hash" = "$codex_hash" ]; then
    parity_match=$((parity_match + 1))
  else
    parity_diverged=$((parity_diverged + 1))
    warnings=$((warnings + 1))

    # Determine match/differ indicators
    if [ "$gemini_hash" = "$claude_hash" ]; then
      gemini_indicator="matches Claude"
    else
      gemini_indicator="differs from Claude"
    fi
    if [ "$codex_hash" = "$claude_hash" ]; then
      codex_indicator="matches Claude"
    else
      codex_indicator="differs from Claude"
    fi

    echo "  WARNING: Content divergence in '$skill':"
    printf "    Claude:  %.8s  (%s lines)\n" "$claude_hash" "$claude_lines"
    if [ "$gemini_indicator" = "matches Claude" ]; then
      printf "    Gemini:  %.8s  (%s lines)  ✓ %s\n" "$gemini_hash" "$gemini_lines" "$gemini_indicator"
    else
      printf "    Gemini:  %.8s  (%s lines)  ✗ %s\n" "$gemini_hash" "$gemini_lines" "$gemini_indicator"
    fi
    if [ "$codex_indicator" = "matches Claude" ]; then
      printf "    Codex:   %.8s  (%s lines)  ✓ %s\n" "$codex_hash" "$codex_lines" "$codex_indicator"
    else
      printf "    Codex:   %.8s  (%s lines)  ✗ %s\n" "$codex_hash" "$codex_lines" "$codex_indicator"
    fi
  fi
done

echo ""
echo "  Content parity: $parity_match/$parity_total skills match across all formats, $parity_diverged diverged"

# ── Summary ───────────────────────────────────────────────────
echo ""
echo "─────────────────────────"
echo "Skills: $claude_count | Agents: ${agent_count:-0} | Hooks: ${hook_count:-0}"

if [ "$errors" -gt 0 ]; then
  echo "RESULT: $errors error(s), $warnings warning(s)"
  exit 1
elif [ "$warnings" -gt 0 ]; then
  echo "RESULT: $warnings warning(s), 0 errors"
  exit 0
else
  echo "RESULT: All checks passed"
  exit 0
fi
