#!/usr/bin/env bash
set -u

# test-install.sh — Integration tests for Nox install/uninstall/validate scripts
# Portable: works on Ubuntu (CI) and Git Bash (Windows/MSYS)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

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

# ── Platform detection ──────────────────────────────────────────
# On Windows/MSYS, ln -s creates copies (no symlink privilege by default)
CAN_SYMLINK=true
SYMLINK_TEST_DIR="$(mktemp -d)"
if ! ln -sf "$0" "$SYMLINK_TEST_DIR/symtest" 2>/dev/null || [ ! -L "$SYMLINK_TEST_DIR/symtest" ]; then
  CAN_SYMLINK=false
fi
rm -rf "$SYMLINK_TEST_DIR"

ORIG_HOME="$HOME"
ORIG_PATH="$PATH"

# ── Setup temp HOME and mock CLI tools ──────────────────────────
setup_env() {
  TEST_HOME="$(mktemp -d)"
  MOCK_BIN="$(mktemp -d)"

  # Create mock commands that just exit 0
  for cmd in claude gemini codex node npm python3 git; do
    cat > "$MOCK_BIN/$cmd" <<'MOCKEOF'
#!/bin/bash
exit 0
MOCKEOF
    chmod +x "$MOCK_BIN/$cmd"
  done

  # Export so install.sh sees our mocks and temp HOME
  export HOME="$TEST_HOME"
  export PATH="$MOCK_BIN:$ORIG_PATH"
}

cleanup_env() {
  export HOME="$ORIG_HOME"
  export PATH="$ORIG_PATH"
  rm -rf "$TEST_HOME" "$MOCK_BIN" 2>/dev/null
}

# ── Count source files for expected values ──────────────────────
EXPECTED_CLAUDE_SKILLS=$(ls -1 "$PROJECT_DIR/claude/nox/"*.md 2>/dev/null | wc -l | tr -d ' ')
EXPECTED_GEMINI_SKILLS=$(ls -1d "$PROJECT_DIR/gemini/skills/"*/ 2>/dev/null | wc -l | tr -d ' ')
EXPECTED_CODEX_SKILLS=$(ls -1d "$PROJECT_DIR/codex/skills/"*/ 2>/dev/null | wc -l | tr -d ' ')
EXPECTED_AGENTS=$(ls -1 "$PROJECT_DIR/agents/"*.md 2>/dev/null | wc -l | tr -d ' ')
EXPECTED_HOOK_SH=$(ls -1 "$PROJECT_DIR/hooks/"*.sh 2>/dev/null | wc -l | tr -d ' ')
EXPECTED_HOOK_JS=$(ls -1 "$PROJECT_DIR/hooks/"*.js 2>/dev/null | wc -l | tr -d ' ')
EXPECTED_HOOKS=$((EXPECTED_HOOK_SH + EXPECTED_HOOK_JS))

echo "=== Nox Install Tests ==="
echo "Source counts: Claude=$EXPECTED_CLAUDE_SKILLS Gemini=$EXPECTED_GEMINI_SKILLS Codex=$EXPECTED_CODEX_SKILLS Agents=$EXPECTED_AGENTS Hooks=$EXPECTED_HOOKS"
echo ""

# ================================================================
# TEST 1: Default install (all platforms)
# ================================================================
echo "--- Test: Default install ---"
setup_env

bash "$PROJECT_DIR/install.sh" > /dev/null 2>&1
RC=$?

if [ "$RC" -eq 0 ]; then
  pass "install.sh exits 0"
else
  fail "install.sh exits $RC (expected 0)"
fi

# Claude skills
if [ -d "$TEST_HOME/.claude/commands/nox" ]; then
  pass "Claude skills directory created"
else
  fail "Claude skills directory not created"
fi

ACTUAL_CLAUDE=$(ls -1 "$TEST_HOME/.claude/commands/nox/"*.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$ACTUAL_CLAUDE" -eq "$EXPECTED_CLAUDE_SKILLS" ]; then
  pass "Claude skill count matches ($ACTUAL_CLAUDE)"
else
  fail "Claude skill count: got $ACTUAL_CLAUDE, expected $EXPECTED_CLAUDE_SKILLS"
fi

# Gemini skills
if [ -d "$TEST_HOME/.gemini/extensions/nox" ]; then
  pass "Gemini extensions directory created"
else
  fail "Gemini extensions directory not created"
fi

if [ -f "$TEST_HOME/.gemini/extensions/nox/gemini-extension.json" ]; then
  pass "Gemini extension.json present"
else
  fail "Gemini extension.json missing"
fi

ACTUAL_GEMINI=$(find "$TEST_HOME/.gemini/extensions/nox/skills" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "$ACTUAL_GEMINI" -eq "$EXPECTED_GEMINI_SKILLS" ]; then
  pass "Gemini skill count matches ($ACTUAL_GEMINI)"
else
  fail "Gemini skill count: got $ACTUAL_GEMINI, expected $EXPECTED_GEMINI_SKILLS"
fi

# Codex skills
if [ -d "$TEST_HOME/.codex/skills" ]; then
  pass "Codex skills directory created"
else
  fail "Codex skills directory not created"
fi

ACTUAL_CODEX=$(find "$TEST_HOME/.codex/skills" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "$ACTUAL_CODEX" -eq "$EXPECTED_CODEX_SKILLS" ]; then
  pass "Codex skill count matches ($ACTUAL_CODEX)"
else
  fail "Codex skill count: got $ACTUAL_CODEX, expected $EXPECTED_CODEX_SKILLS"
fi

# Agents
if [ -d "$TEST_HOME/.claude/agents" ]; then
  pass "Agents directory created"
else
  fail "Agents directory not created"
fi

ACTUAL_AGENTS=$(ls -1 "$TEST_HOME/.claude/agents/"*.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$ACTUAL_AGENTS" -eq "$EXPECTED_AGENTS" ]; then
  pass "Agent count matches ($ACTUAL_AGENTS)"
else
  fail "Agent count: got $ACTUAL_AGENTS, expected $EXPECTED_AGENTS"
fi

# Hooks should NOT be installed by default
if [ -d "$TEST_HOME/.claude/hooks" ] && [ "$(ls -1 "$TEST_HOME/.claude/hooks/"*.sh 2>/dev/null | wc -l | tr -d ' ')" -gt 0 ]; then
  fail "Hooks installed without --with-hooks flag"
else
  pass "Hooks not installed by default"
fi

cleanup_env

echo ""

# ================================================================
# TEST 2: Install with --with-hooks
# ================================================================
echo "--- Test: Install with --with-hooks ---"
setup_env

bash "$PROJECT_DIR/install.sh" --with-hooks > /dev/null 2>&1
RC=$?

if [ "$RC" -eq 0 ]; then
  pass "--with-hooks install exits 0"
else
  fail "--with-hooks install exits $RC (expected 0)"
fi

if [ -d "$TEST_HOME/.claude/hooks" ]; then
  pass "Hooks directory created"
else
  fail "Hooks directory not created"
fi

# Check .sh hooks are executable
SH_EXEC_FAIL=0
for hook in "$TEST_HOME/.claude/hooks/"*.sh; do
  [ -f "$hook" ] || continue
  if [ ! -x "$hook" ]; then
    SH_EXEC_FAIL=$((SH_EXEC_FAIL + 1))
  fi
done
if [ "$SH_EXEC_FAIL" -eq 0 ]; then
  pass "All .sh hooks are executable"
else
  fail "$SH_EXEC_FAIL .sh hooks are not executable"
fi

# Check .js hooks are present
ACTUAL_JS=$(ls -1 "$TEST_HOME/.claude/hooks/"*.js 2>/dev/null | wc -l | tr -d ' ')
if [ "$ACTUAL_JS" -eq "$EXPECTED_HOOK_JS" ]; then
  pass "All .js hooks present ($ACTUAL_JS)"
else
  fail "JS hook count: got $ACTUAL_JS, expected $EXPECTED_HOOK_JS"
fi

# Total hook count
ACTUAL_SH=$(ls -1 "$TEST_HOME/.claude/hooks/"*.sh 2>/dev/null | wc -l | tr -d ' ')
ACTUAL_HOOKS=$((ACTUAL_SH + ACTUAL_JS))
if [ "$ACTUAL_HOOKS" -eq "$EXPECTED_HOOKS" ]; then
  pass "Total hook count matches ($ACTUAL_HOOKS)"
else
  fail "Total hook count: got $ACTUAL_HOOKS, expected $EXPECTED_HOOKS"
fi

cleanup_env

echo ""

# ================================================================
# TEST 3: Install with --symlink
# ================================================================
echo "--- Test: Install with --symlink ---"

if [ "$CAN_SYMLINK" = false ]; then
  echo "SKIP: Platform does not support symlinks (Windows without dev mode)"
  # Count skips as passes so we don't fail the suite
  pass "--symlink install skipped (no symlink support)"
  pass "Symlink check skipped (no symlink support)"
  pass "Gemini symlink check skipped (no symlink support)"
else
  setup_env

  bash "$PROJECT_DIR/install.sh" --symlink > /dev/null 2>&1
  RC=$?

  if [ "$RC" -eq 0 ]; then
    pass "--symlink install exits 0"
  else
    fail "--symlink install exits $RC (expected 0)"
  fi

  # Check that claude skill files are symlinks
  SYMLINK_COUNT=0
  REGULAR_COUNT=0
  for f in "$TEST_HOME/.claude/commands/nox/"*.md; do
    [ -f "$f" ] || continue
    if [ -L "$f" ]; then
      SYMLINK_COUNT=$((SYMLINK_COUNT + 1))
    else
      REGULAR_COUNT=$((REGULAR_COUNT + 1))
    fi
  done

  if [ "$SYMLINK_COUNT" -gt 0 ] && [ "$REGULAR_COUNT" -eq 0 ]; then
    pass "Claude skills are symlinks ($SYMLINK_COUNT files)"
  else
    fail "Symlink check: $SYMLINK_COUNT symlinks, $REGULAR_COUNT regular files"
  fi

  # Check gemini extension.json is a symlink
  if [ -L "$TEST_HOME/.gemini/extensions/nox/gemini-extension.json" ]; then
    pass "Gemini extension.json is a symlink"
  else
    fail "Gemini extension.json is not a symlink"
  fi

  cleanup_env
fi

echo ""

# ================================================================
# TEST 4: Install with --claude-only
# ================================================================
echo "--- Test: Install with --claude-only ---"
setup_env

bash "$PROJECT_DIR/install.sh" --claude-only > /dev/null 2>&1
RC=$?

if [ "$RC" -eq 0 ]; then
  pass "--claude-only install exits 0"
else
  fail "--claude-only install exits $RC (expected 0)"
fi

# Claude should be installed
if [ -d "$TEST_HOME/.claude/commands/nox" ]; then
  pass "Claude skills installed with --claude-only"
else
  fail "Claude skills NOT installed with --claude-only"
fi

# Gemini should NOT be installed
if [ -d "$TEST_HOME/.gemini/extensions/nox" ]; then
  fail "Gemini installed despite --claude-only"
else
  pass "Gemini NOT installed with --claude-only"
fi

# Codex should NOT be installed
if [ -d "$TEST_HOME/.codex/skills" ] && [ "$(find "$TEST_HOME/.codex/skills" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')" -gt 0 ]; then
  fail "Codex installed despite --claude-only"
else
  pass "Codex NOT installed with --claude-only"
fi

cleanup_env

echo ""

# ================================================================
# TEST 5: Uninstall
# ================================================================
echo "--- Test: Uninstall ---"
setup_env

# Install first
bash "$PROJECT_DIR/install.sh" > /dev/null 2>&1

# Then uninstall
bash "$PROJECT_DIR/uninstall.sh" > /dev/null 2>&1
RC=$?

if [ "$RC" -eq 0 ]; then
  pass "uninstall.sh exits 0"
else
  fail "uninstall.sh exits $RC (expected 0)"
fi

# Claude skills should be gone
if [ -d "$TEST_HOME/.claude/commands/nox" ]; then
  fail "Claude skills directory still exists after uninstall"
else
  pass "Claude skills removed by uninstall"
fi

# Gemini should be gone
if [ -d "$TEST_HOME/.gemini/extensions/nox" ]; then
  fail "Gemini directory still exists after uninstall"
else
  pass "Gemini removed by uninstall"
fi

cleanup_env

echo ""

# ================================================================
# TEST 6: validate.sh passes
# ================================================================
echo "--- Test: validate.sh ---"

bash "$PROJECT_DIR/validate.sh" > /dev/null 2>&1
RC=$?

if [ "$RC" -eq 0 ]; then
  pass "validate.sh exits 0"
else
  fail "validate.sh exits $RC (expected 0)"
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
