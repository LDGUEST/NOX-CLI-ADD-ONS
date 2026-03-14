#!/usr/bin/env node
// Context Monitor — PostToolUse hook
//
// Two-stage context awareness system:
//
// STAGE 1 — WARNING (remaining <= 35%, ~65% used)
//   Agent: finish current task, stop exploring, no new complex work.
//
// STAGE 2 — HANDOFF (remaining <= 17%, ~83% used)
//   Hook auto-captures mechanical state (git diff, modified files, branch).
//   Agent fills in the INTENT sections (dead ends, decisions, next action).
//   Result: a recovery playbook that survives auto-compact.
//   Agent continues working — no stopping.
//
// Post-compact: agent reads .claude/checkpoints/continuation.md, acts on it,
// then deletes it. The file is always overwritten (single rotating file).
//
// Debounce: 5 tool uses between warnings. Escalation bypasses debounce.

const fs = require('fs');
const os = require('os');
const path = require('path');
const { execSync } = require('child_process');

const WARNING_THRESHOLD = 35;  // remaining_percentage <= 35% (~65% used)
const HANDOFF_THRESHOLD = 17;  // remaining_percentage <= 17% (~83% used)
const STALE_SECONDS = 60;
const DEBOUNCE_CALLS = 5;

let input = '';
const stdinTimeout = setTimeout(() => process.exit(0), 3000);
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  clearTimeout(stdinTimeout);
  try {
    const data = JSON.parse(input);
    const sessionId = data.session_id;
    if (!sessionId) process.exit(0);

    const tmpDir = os.tmpdir();
    const metricsPath = path.join(tmpDir, `claude-ctx-${sessionId}.json`);
    if (!fs.existsSync(metricsPath)) process.exit(0);

    const metrics = JSON.parse(fs.readFileSync(metricsPath, 'utf8'));
    const now = Math.floor(Date.now() / 1000);
    if (metrics.timestamp && (now - metrics.timestamp) > STALE_SECONDS) process.exit(0);

    const remaining = metrics.remaining_percentage;
    const usedPct = metrics.used_pct;
    if (remaining > WARNING_THRESHOLD) process.exit(0);

    // ── Debounce ──
    const warnPath = path.join(tmpDir, `claude-ctx-${sessionId}-warned.json`);
    let warnData = { callsSinceWarn: 0, lastLevel: null };
    let firstWarn = true;
    if (fs.existsSync(warnPath)) {
      try { warnData = JSON.parse(fs.readFileSync(warnPath, 'utf8')); firstWarn = false; } catch (e) {}
    }
    warnData.callsSinceWarn = (warnData.callsSinceWarn || 0) + 1;

    const isHandoff = remaining <= HANDOFF_THRESHOLD;
    const currentLevel = isHandoff ? 'handoff' : 'warning';
    const severityEscalated = currentLevel === 'handoff' && warnData.lastLevel === 'warning';

    if (!firstWarn && warnData.callsSinceWarn < DEBOUNCE_CALLS && !severityEscalated) {
      fs.writeFileSync(warnPath, JSON.stringify(warnData));
      process.exit(0);
    }

    warnData.callsSinceWarn = 0;
    warnData.lastLevel = currentLevel;
    fs.writeFileSync(warnPath, JSON.stringify(warnData));

    const rawCwd = data.cwd || process.cwd();
    // Normalize for cross-platform: forward slashes work everywhere,
    // backslashes break git -C and fs ops under MSYS/Git Bash on Windows
    const cwd = rawCwd.replace(/\\/g, '/');
    const isGsdActive = fs.existsSync(path.join(cwd, '.planning', 'STATE.md'));

    let message;

    if (isHandoff) {
      // ── Auto-capture mechanical state ──
      const checkpointDir = cwd + '/.claude/checkpoints';
      try { fs.mkdirSync(checkpointDir, { recursive: true }); } catch (e) {}
      const continuationPath = checkpointDir + '/continuation.md';
      const gitDir = cwd;

      let scaffold = '# Recovery Playbook\n';
      scaffold += '<!-- Post-compact: read this, act on it, then delete this file -->\n\n';

      // Git state (auto-captured by hook — agent doesn't need to repeat this)
      try {
        const branch = execSync(`git -C "${gitDir}" rev-parse --abbrev-ref HEAD`, {
          timeout: 2000, encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe']
        }).trim();
        scaffold += `**Branch:** ${branch}\n`;

        const diffStat = execSync(`git -C "${gitDir}" diff --stat`, {
          timeout: 2000, encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe']
        }).trim();
        const stagedStat = execSync(`git -C "${gitDir}" diff --cached --stat`, {
          timeout: 2000, encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe']
        }).trim();

        if (diffStat || stagedStat) {
          scaffold += '\n## Files Changed This Session\n```\n';
          if (stagedStat) scaffold += 'Staged:\n' + stagedStat + '\n';
          if (diffStat) scaffold += 'Unstaged:\n' + diffStat + '\n';
          scaffold += '```\n';
        }

        // Last 5 commits (shows what was done recently)
        const log = execSync(`git -C "${gitDir}" log --oneline -5`, {
          timeout: 2000, encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe']
        }).trim();
        if (log) {
          scaffold += '\n## Recent Commits\n```\n' + log + '\n```\n';
        }
      } catch (e) {}

      // GSD state reference
      if (isGsdActive) {
        scaffold += '\n## GSD State\nActive plan tracked in `.planning/STATE.md` — read that for phase/task context.\n';
      }

      // Sections the AGENT must fill (these are the high-value parts)
      scaffold += '\n## User Request\n<!-- AGENT: paste the user\'s original request verbatim -->\n\n';
      scaffold += '## Dead Ends\n<!-- AGENT: what did you try that FAILED? Why? This prevents repeating mistakes -->\n\n';
      scaffold += '## Key Decisions\n<!-- AGENT: choices you made and WHY (e.g., "used X over Y because Z") -->\n\n';
      scaffold += '## Next Action\n<!-- AGENT: the LITERAL next thing to do. Not vague. "Edit line 47 of src/auth.ts to add null check" -->\n\n';
      scaffold += '## Remaining Steps\n<!-- AGENT: numbered list of what\'s left -->\n';

      // Write the scaffold — agent fills in the <!-- AGENT: --> sections
      try { fs.writeFileSync(continuationPath, scaffold); } catch (e) {}

      message = `CONTEXT HANDOFF: Usage at ${usedPct}%. Remaining: ${remaining}%. ` +
        `Auto-compact will fire soon. A recovery playbook scaffold has been written to ${continuationPath}. ` +
        'The mechanical state (git, files, branch) is already captured. ' +
        'You MUST now fill in the sections marked <!-- AGENT: --> with: ' +
        '(1) the user\'s VERBATIM original request, ' +
        '(2) what you tried that FAILED and why (dead ends — this is the most valuable part), ' +
        '(3) key decisions and their reasoning, ' +
        '(4) your LITERAL next action (not vague — exact file, line, change), ' +
        '(5) numbered remaining steps. ' +
        'Keep each section to 1-3 lines. Total file must stay under 40 lines. ' +
        'After filling it in, CONTINUE WORKING — do not stop, do not ask the user. ' +
        'POST-COMPACT INSTRUCTION: If you find .claude/checkpoints/continuation.md at session start, ' +
        'read it, internalize it, then delete it.';
    } else {
      message = `CONTEXT WARNING: Usage at ${usedPct}%. Remaining: ${remaining}%. ` +
        'Context is above 65%. Keep working normally but be efficient — ' +
        'prefer targeted file reads over broad exploration, skip optional research, ' +
        'and take the most direct path to completion. Do NOT stop, slow down, ' +
        'or ask the user about context. Just be surgical.';
    }

    const output = {
      hookSpecificOutput: {
        hookEventName: process.env.GEMINI_API_KEY ? "AfterTool" : "PostToolUse",
        additionalContext: message
      }
    };

    process.stdout.write(JSON.stringify(output));
  } catch (e) {
    process.exit(0);
  }
});
