#!/usr/bin/env bash
set -eu
# pipefail not supported in all bash versions (e.g., Windows Git Bash)
(set -o pipefail 2>/dev/null) && set -o pipefail

# Nox Installer — Claude Code + Gemini CLI + Codex CLI
# Usage: bash install.sh [--claude-only | --gemini-only | --codex-only | --symlink]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_SRC="$SCRIPT_DIR/claude"
GEMINI_SRC="$SCRIPT_DIR/gemini"
CODEX_SRC="$SCRIPT_DIR/codex"
AGENTS_SRC="$SCRIPT_DIR/agents"

CLAUDE_DEST="$HOME/.claude/commands"
GEMINI_DEST="$HOME/.gemini/extensions/nox"
CODEX_DEST="$HOME/.agents/skills"
AGENTS_DEST="$HOME/.claude/agents"

INSTALL_CLAUDE=true
INSTALL_GEMINI=true
INSTALL_CODEX=true
USE_SYMLINK=false

for arg in "$@"; do
  case "$arg" in
    --claude-only) INSTALL_GEMINI=false; INSTALL_CODEX=false ;;
    --gemini-only) INSTALL_CLAUDE=false; INSTALL_CODEX=false ;;
    --codex-only)  INSTALL_CLAUDE=false; INSTALL_GEMINI=false ;;
    --symlink)     USE_SYMLINK=true ;;
    --help|-h)
      echo "Nox Installer"
      echo ""
      echo "Usage: bash install.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --claude-only   Only install Claude Code skills"
      echo "  --gemini-only   Only install Gemini CLI skills"
      echo "  --codex-only    Only install Codex CLI skills"
      echo "  --symlink       Symlink instead of copy (auto-updates on git pull)"
      echo "  --help          Show this help"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg (try --help)"
      exit 1
      ;;
  esac
done

install_file() {
  local src="$1" dest="$2"
  if [ "$USE_SYMLINK" = true ]; then
    ln -sf "$src" "$dest"
  else
    cp "$src" "$dest"
  fi
}

# ── Claude Code ──────────────────────────────────────────────
if [ "$INSTALL_CLAUDE" = true ]; then
  if command -v claude &>/dev/null; then
    echo "Installing Nox skills for Claude Code..."
    mkdir -p "$CLAUDE_DEST/nox"

    count=0
    for skill in "$CLAUDE_SRC/nox"/*.md; do
      name="$(basename "$skill")"
      install_file "$skill" "$CLAUDE_DEST/nox/$name"
      count=$((count + 1))
    done

    echo "  -> $count skills installed to $CLAUDE_DEST/nox/ (use /nox:<name>)"
  else
    echo "Claude Code not found — skipping (install: https://docs.anthropic.com/en/docs/claude-code)"
  fi
fi

# ── Gemini CLI ───────────────────────────────────────────────
if [ "$INSTALL_GEMINI" = true ]; then
  if command -v gemini &>/dev/null; then
    echo "Installing Nox skills for Gemini CLI..."
    mkdir -p "$GEMINI_DEST"

    install_file "$GEMINI_SRC/gemini-extension.json" "$GEMINI_DEST/gemini-extension.json"

    count=0
    for skill_dir in "$GEMINI_SRC/skills"/*/; do
      name="$(basename "$skill_dir")"
      mkdir -p "$GEMINI_DEST/skills/$name"
      install_file "$skill_dir/SKILL.md" "$GEMINI_DEST/skills/$name/SKILL.md"
      count=$((count + 1))
    done

    echo "  -> $count skills installed to $GEMINI_DEST"
  else
    echo "Gemini CLI not found — skipping (install: https://github.com/google-gemini/gemini-cli)"
  fi
fi

# ── Codex CLI ────────────────────────────────────────────────
if [ "$INSTALL_CODEX" = true ]; then
  if command -v codex &>/dev/null; then
    echo "Installing Nox skills for Codex CLI..."

    count=0
    for skill_dir in "$CODEX_SRC/skills"/*/; do
      name="$(basename "$skill_dir")"
      mkdir -p "$CODEX_DEST/$name"
      install_file "$skill_dir/SKILL.md" "$CODEX_DEST/$name/SKILL.md"
      count=$((count + 1))
    done

    echo "  -> $count skills installed to $CODEX_DEST"
  else
    echo "Codex CLI not found — skipping (install: https://developers.openai.com/codex/cli/)"
  fi
fi

# ── Agents (Claude Code only) ────────────────────────────────
if [ "$INSTALL_CLAUDE" = true ] && [ -d "$AGENTS_SRC" ]; then
  if command -v claude &>/dev/null; then
    echo "Installing Nox agents for Claude Code..."
    mkdir -p "$AGENTS_DEST"

    agent_count=0
    for agent in "$AGENTS_SRC"/*.md; do
      [ -f "$agent" ] || continue
      name="$(basename "$agent")"
      install_file "$agent" "$AGENTS_DEST/$name"
      agent_count=$((agent_count + 1))
    done

    echo "  -> $agent_count agents installed to $AGENTS_DEST/"
  fi
fi

echo ""
echo "Nox installed. Type /nox in Claude Code to see all skills."