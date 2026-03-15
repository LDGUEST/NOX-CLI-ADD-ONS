#!/usr/bin/env bash
set -u

# test-smoke.sh — Quick self-check after install or update
# Verifies skill parity, frontmatter, hooks, lib-json, and validate.sh
# Portable: works on Ubuntu (CI) and Git Bash (Windows/MSYS)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CLAUDE_DIR="$PROJECT_DIR/claude/nox"
GEMINI_DIR="$PROJECT_DIR/gemini/skills"
CODEX_DIR="$PROJECT_DIR/codex/skills"
HOOKS_DIR="$PROJECT_DIR/hooks"

PASS_COUNT=0
FAIL_COUNT=0

pass() {
  echo "PASS: $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo "FAIL: $1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

echo "=== Nox Smoke Tests ==="
echo ""

# ================================================================
# TEST 1: All skill files exist for all 3 CLIs
# ================================================================
echo "--- Skill file existence ---"

CLAUDE_MISSING=0
GEMINI_MISSING=0
CODEX_MISSING=0

# Collect all skill names from Claude (source of truth)
CLAUDE_SKILLS=$(ls -1 "$CLAUDE_DIR"/*.md 2>/dev/null | xargs -I{} basename {} .md | sort)

for skill in $CLAUDE_SKILLS; do
  if [ ! -f "$CLAUDE_DIR/$skill.md" ]; then
    CLAUDE_MISSING=$((CLAUDE_MISSING + 1))
  fi
  if [ ! -f "$GEMINI_DIR/$skill/SKILL.md" ]; then
    echo "  Missing Gemini: $skill"
    GEMINI_MISSING=$((GEMINI_MISSING + 1))
  fi
  if [ ! -f "$CODEX_DIR/$skill/SKILL.md" ]; then
    echo "  Missing Codex: $skill"
    CODEX_MISSING=$((CODEX_MISSING + 1))
  fi
done

if [ "$CLAUDE_MISSING" -eq 0 ]; then
  pass "All Claude skill files exist"
else
  fail "$CLAUDE_MISSING Claude skill files missing"
fi

if [ "$GEMINI_MISSING" -eq 0 ]; then
  pass "All Gemini skill files exist"
else
  fail "$GEMINI_MISSING Gemini skill files missing"
fi

if [ "$CODEX_MISSING" -eq 0 ]; then
  pass "All Codex skill files exist"
else
  fail "$CODEX_MISSING Codex skill files missing"
fi

echo ""

# ================================================================
# TEST 2: Skill count parity across CLIs
# ================================================================
echo "--- Skill count parity ---"

CLAUDE_COUNT=$(ls -1 "$CLAUDE_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
GEMINI_COUNT=$(ls -1d "$GEMINI_DIR"/*/ 2>/dev/null | wc -l | tr -d ' ')
CODEX_COUNT=$(ls -1d "$CODEX_DIR"/*/ 2>/dev/null | wc -l | tr -d ' ')

echo "  Claude=$CLAUDE_COUNT  Gemini=$GEMINI_COUNT  Codex=$CODEX_COUNT"

if [ "$CLAUDE_COUNT" -eq "$GEMINI_COUNT" ] && [ "$CLAUDE_COUNT" -eq "$CODEX_COUNT" ]; then
  pass "Skill counts match across all 3 CLIs ($CLAUDE_COUNT)"
else
  fail "Skill count mismatch: Claude=$CLAUDE_COUNT Gemini=$GEMINI_COUNT Codex=$CODEX_COUNT"
fi

if [ "$CLAUDE_COUNT" -gt 0 ]; then
  pass "At least 1 skill exists ($CLAUDE_COUNT total)"
else
  fail "No skills found"
fi

echo ""

# ================================================================
# TEST 3: Claude skills have valid YAML frontmatter
# ================================================================
echo "--- Claude YAML frontmatter ---"

FM_MISSING=0
FM_NO_NAME=0
FM_NO_DESC=0

for skill_file in "$CLAUDE_DIR"/*.md; do
  [ -f "$skill_file" ] || continue
  skill=$(basename "$skill_file" .md)

  # Check for frontmatter delimiters
  FIRST_LINE=$(head -1 "$skill_file")
  if [ "$FIRST_LINE" != "---" ]; then
    echo "  Missing frontmatter: $skill"
    FM_MISSING=$((FM_MISSING + 1))
    continue
  fi

  # Extract frontmatter block (between first --- and second ---)
  # Check for name: and description: fields
  HAS_NAME=false
  HAS_DESC=false

  # Read lines between the two --- markers
  IN_FM=false
  LINE_NUM=0
  while IFS= read -r line; do
    LINE_NUM=$((LINE_NUM + 1))
    if [ "$LINE_NUM" -eq 1 ]; then
      IN_FM=true
      continue
    fi
    if [ "$IN_FM" = true ] && [ "$line" = "---" ]; then
      break
    fi
    if [ "$IN_FM" = true ]; then
      case "$line" in
        name:*) HAS_NAME=true ;;
        description:*) HAS_DESC=true ;;
      esac
    fi
  done < "$skill_file"

  if [ "$HAS_NAME" = false ]; then
    echo "  Missing 'name:' in frontmatter: $skill"
    FM_NO_NAME=$((FM_NO_NAME + 1))
  fi
  if [ "$HAS_DESC" = false ]; then
    echo "  Missing 'description:' in frontmatter: $skill"
    FM_NO_DESC=$((FM_NO_DESC + 1))
  fi
done

if [ "$FM_MISSING" -eq 0 ]; then
  pass "All Claude skills have YAML frontmatter"
else
  fail "$FM_MISSING Claude skills missing frontmatter"
fi

if [ "$FM_NO_NAME" -eq 0 ]; then
  pass "All Claude skills have 'name' field"
else
  fail "$FM_NO_NAME Claude skills missing 'name' field"
fi

if [ "$FM_NO_DESC" -eq 0 ]; then
  pass "All Claude skills have 'description' field"
else
  fail "$FM_NO_DESC Claude skills missing 'description' field"
fi

echo ""

# ================================================================
# TEST 4: Hook files present and executable
# ================================================================
echo "--- Hook files ---"

# Known hooks that should exist (referenced in standard settings.json configs)
EXPECTED_HOOKS="destructive-guard.sh commit-lint.sh secret-scanner.sh file-size-guard.sh auto-context.sh context-monitor.js session-logger.sh session-cost-tracker.sh prompt-guard.sh"

HOOK_MISSING=0
HOOK_NOT_EXEC=0

for hook in $EXPECTED_HOOKS; do
  if [ ! -f "$HOOKS_DIR/$hook" ]; then
    echo "  Missing hook: $hook"
    HOOK_MISSING=$((HOOK_MISSING + 1))
  elif [ "${hook##*.}" = "sh" ] && [ ! -x "$HOOKS_DIR/$hook" ]; then
    echo "  Not executable: $hook"
    HOOK_NOT_EXEC=$((HOOK_NOT_EXEC + 1))
  fi
done

if [ "$HOOK_MISSING" -eq 0 ]; then
  pass "All expected hook files present ($EXPECTED_HOOKS)"
else
  fail "$HOOK_MISSING expected hook files missing"
fi

if [ "$HOOK_NOT_EXEC" -eq 0 ]; then
  pass "All .sh hooks are executable"
else
  fail "$HOOK_NOT_EXEC .sh hooks are not executable"
fi

# Check all hooks in hooks/ dir have shebangs
SHEBANG_BAD=0
for hook in "$HOOKS_DIR"/*.sh; do
  [ -f "$hook" ] || continue
  FIRST=$(head -1 "$hook")
  case "$FIRST" in
    "#!/bin/bash"|"#!/usr/bin/env bash") ;;
    *) echo "  Bad shebang: $(basename "$hook")"; SHEBANG_BAD=$((SHEBANG_BAD + 1)) ;;
  esac
done

if [ "$SHEBANG_BAD" -eq 0 ]; then
  pass "All .sh hooks have valid bash shebangs"
else
  fail "$SHEBANG_BAD .sh hooks have invalid shebangs"
fi

echo ""

# ================================================================
# TEST 5: lib-json.sh sources correctly
# ================================================================
echo "--- lib-json.sh ---"

if [ -f "$HOOKS_DIR/lib-json.sh" ]; then
  pass "lib-json.sh exists"
else
  fail "lib-json.sh missing"
fi

# Test that sourcing it works and json_str function is available
LIB_TEST=$(bash -c "
  source '$HOOKS_DIR/lib-json.sh' 2>/dev/null
  type json_str >/dev/null 2>&1 && echo 'ok' || echo 'no'
" 2>/dev/null || echo "error")

if [ "$LIB_TEST" = "ok" ]; then
  pass "lib-json.sh sources and exports json_str"
else
  fail "lib-json.sh failed to source or json_str not defined ($LIB_TEST)"
fi

# Test json_str actually extracts a value
EXTRACT_TEST=$(bash -c "
  source '$HOOKS_DIR/lib-json.sh' 2>/dev/null
  result=\$(json_str '{\"tool_name\":\"Bash\",\"session_id\":\"abc123\"}' 'session_id')
  echo \"\$result\"
" 2>/dev/null || echo "error")

if [ "$EXTRACT_TEST" = "abc123" ]; then
  pass "json_str correctly extracts field values"
else
  fail "json_str extraction failed (got '$EXTRACT_TEST', expected 'abc123')"
fi

echo ""

# ================================================================
# TEST 6: validate.sh passes
# ================================================================
echo "--- validate.sh ---"

VALIDATE_OUTPUT=$(bash "$PROJECT_DIR/validate.sh" 2>&1) || true
VALIDATE_RC=$?

if [ "$VALIDATE_RC" -eq 0 ]; then
  pass "validate.sh exits 0"
else
  fail "validate.sh exits $VALIDATE_RC (expected 0)"
fi

# Check that validate.sh reports no errors
if echo "$VALIDATE_OUTPUT" | grep -q "error(s)" 2>/dev/null; then
  ERRORS=$(echo "$VALIDATE_OUTPUT" | grep -oE "[0-9]+ error" | head -1 | grep -oE "[0-9]+")
  if [ "${ERRORS:-0}" = "0" ]; then
    pass "validate.sh reports 0 errors"
  else
    fail "validate.sh reports $ERRORS error(s)"
  fi
else
  pass "validate.sh reports no errors"
fi

echo ""

# ── Summary ─────────────────────────────────────────────────────
echo "==========================="
echo "Results: $PASS_COUNT passed, $FAIL_COUNT failed"
echo "==========================="

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
exit 0
