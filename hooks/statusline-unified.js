#!/usr/bin/env node
// ─────────────────────────────────────────
// Claude Code Unified Statusline
// Shows: @user | model | task | ▓░ 45% | $0.0015/1k | Session: $0.12 | API: $15.23 | ok
// Works on macOS + Windows (Node.js, no bash/jq deps)
// ─────────────────────────────────────────

const fs = require('fs');
const path = require('path');
const os = require('os');
const { execSync } = require('child_process');
const https = require('https');

const HOME = os.homedir();
const CLAUDE_DIR = path.join(HOME, '.claude');
const TOGGLE_FILE = path.join(CLAUDE_DIR, '.statusline-enabled');
const GH_CACHE = path.join(CLAUDE_DIR, '.gh_user_cache');
const API_COST_CACHE = path.join(CLAUDE_DIR, '.api_cost_cache');

// ── Toggle check ──
if (fs.existsSync(TOGGLE_FILE)) {
  try {
    if (fs.readFileSync(TOGGLE_FILE, 'utf8').trim() === 'off') {
      process.stdout.write('');
      process.exit(0);
    }
  } catch (e) {}
}

// ── Read JSON from stdin ──
let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input);
    const model = data.model?.display_name || 'Claude';
    const dir = data.workspace?.current_dir || process.cwd();
    const session = data.session_id || '';
    const sessionCost = data.cost?.total_cost_usd || 0;
    const remaining = data.context_window?.remaining_percentage;
    const pct = remaining != null ? Math.max(0, Math.min(100, Math.round(100 - remaining))) : 0;

    // ── Token count ──
    const cu = data.context_window?.current_usage || {};
    const usedTokens = (cu.input_tokens || 0) +
      (cu.cache_creation_input_tokens || 0) +
      (cu.cache_read_input_tokens || 0) +
      (cu.output_tokens || 0);

    // ── Cost per 1k tokens ──
    let costPer1k = '0.0000';
    if (usedTokens > 0 && sessionCost > 0) {
      costPer1k = ((sessionCost / usedTokens) * 1000).toFixed(4);
    }

    const sessionCostFmt = sessionCost.toFixed(4);
    const tokenDisplay = usedTokens >= 1000
      ? Math.round(usedTokens / 1000) + 'k'
      : usedTokens.toString();

    // ── GitHub username (cached 60 min) ──
    let ghUser = '';
    let cacheStale = true;
    if (fs.existsSync(GH_CACHE)) {
      try {
        const stat = fs.statSync(GH_CACHE);
        const ageMin = (Date.now() - stat.mtimeMs) / 60000;
        if (ageMin < 60) cacheStale = false;
      } catch (e) {}
    }
    if (cacheStale) {
      try {
        ghUser = execSync('gh api user --jq .login 2>/dev/null', {
          timeout: 3000, encoding: 'utf8'
        }).trim();
        fs.writeFileSync(GH_CACHE, ghUser);
      } catch (e) {
        ghUser = '';
        try { fs.writeFileSync(GH_CACHE, ''); } catch (e2) {}
      }
    } else {
      try { ghUser = fs.readFileSync(GH_CACHE, 'utf8').trim(); } catch (e) {}
    }

    // ── API monthly spend removed ──
    // Was using ANTHROPIC_ADMIN_API_KEY (not set) with session cost fallback (inaccurate)
    // Re-enable when admin key is configured

    // ── Context progress bar (color-coded) ──
    const barWidth = 10;
    const filled = Math.floor(pct * barWidth / 100);
    const rawBar = '\u2593'.repeat(filled) + '\u2591'.repeat(barWidth - filled);
    let barColor;
    if (pct >= 70) barColor = '\x1b[31m';       // red
    else if (pct >= 50) barColor = '\x1b[33m';   // yellow
    else barColor = '\x1b[32m';                   // green
    const bar = `${barColor}${rawBar}\x1b[0m`;

    // ── Context health warning ──
    let warning = '\x1b[32mGood\x1b[0m';
    if (pct >= 85) warning = '\x1b[31mLow\x1b[0m';
    else if (pct >= 70) warning = '\x1b[33mOk\x1b[0m';

    // ── Git branch + dirty indicator (always shown) ──
    let gitBranch = '';
    let gitDirty = ' +0';
    const _nul = os.platform() === 'win32' ? '2>nul' : '2>/dev/null';
    try {
      gitBranch = execSync(`git -C ${JSON.stringify(dir)} rev-parse --abbrev-ref HEAD ${_nul}`, {
        timeout: 2000, encoding: 'utf8'
      }).trim();
      const statusOut = execSync(`git -C ${JSON.stringify(dir)} status --porcelain ${_nul}`, {
        timeout: 2000, encoding: 'utf8'
      }).trim();
      const changeCount = statusOut ? statusOut.split('\n').length : 0;
      gitDirty = ` +${changeCount}`;
    } catch (e) {}

    // ── Write bridge file for context monitor ──
    if (session) {
      try {
        const bridgePath = path.join(os.tmpdir(), `claude-ctx-${session}.json`);
        fs.writeFileSync(bridgePath, JSON.stringify({
          session_id: session,
          remaining_percentage: remaining,
          used_pct: pct,
          timestamp: Math.floor(Date.now() / 1000)
        }));
      } catch (e) {}
    }

    // ── Current GSD task (from todos) ──
    let task = '';
    const todosDir = path.join(CLAUDE_DIR, 'todos');
    if (session && fs.existsSync(todosDir)) {
      try {
        const files = fs.readdirSync(todosDir)
          .filter(f => f.startsWith(session) && f.includes('-agent-') && f.endsWith('.json'))
          .map(f => ({ name: f, mtime: fs.statSync(path.join(todosDir, f)).mtime }))
          .sort((a, b) => b.mtime - a.mtime);
        if (files.length > 0) {
          const todos = JSON.parse(fs.readFileSync(path.join(todosDir, files[0].name), 'utf8'));
          const inProgress = todos.find(t => t.status === 'in_progress');
          if (inProgress) task = inProgress.activeForm || '';
        }
      } catch (e) {}
    }

    // ── GSD update available? ──
    let gsdUpdate = '';
    const gsdCache = path.join(CLAUDE_DIR, 'cache', 'gsd-update-check.json');
    if (fs.existsSync(gsdCache)) {
      try {
        const cache = JSON.parse(fs.readFileSync(gsdCache, 'utf8'));
        if (cache.update_available) gsdUpdate = '\x1b[33m\u2B06 /gsd:update\x1b[0m \u2502 ';
      } catch (e) {}
    }

    // ── Project name from workspace dir ──
    const projectName = path.basename(dir).replace(/^\./, '');

    // ── Build output (two lines) ──
    // Line 1: [project] branch +N • model | health
    const line1Parts = [];
    if (gsdUpdate) line1Parts.push(gsdUpdate);
    let projectInfo = `[${projectName}]`;
    if (gitBranch) projectInfo += ` ${gitBranch}`;
    if (gitDirty) projectInfo += gitDirty;
    line1Parts.push(`${projectInfo} \u2022 ${model}`);
    const line1 = line1Parts.join(' | ');

    // Line 2: health + context bar leading, then costs
    const line2Parts = [];
    line2Parts.push(`${bar} ${pct}% ${barColor}${tokenDisplay}\x1b[0m ${warning}`);
    if (ghUser) line2Parts.push(`@${ghUser}`);
    if (task) line2Parts.push(`\x1b[1m${task}\x1b[0m`);
    line2Parts.push(`Session: \$${sessionCostFmt} (\$${costPer1k}/1k)`);

    process.stdout.write(line1 + '\n' + line2Parts.join(' | '));

  } catch (e) {
    // Silent fail - don't break statusline
  }
});
