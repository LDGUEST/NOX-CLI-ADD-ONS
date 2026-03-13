#!/usr/bin/env node
// Context Monitor - PostToolUse/AfterTool hook (Gemini uses AfterTool)
// Reads context metrics from the statusline bridge file and injects
// warnings when context usage is high. This makes the AGENT aware of
// context limits (the statusline only shows the user).
//
// How it works:
// 1. The statusline hook writes metrics to /tmp/claude-ctx-{session_id}.json
// 2. This hook reads those metrics after each tool use
// 3. When remaining context drops below thresholds, it injects a warning
//    as additionalContext, which the agent sees in its conversation
//
// Thresholds:
//   WARNING  (remaining <= 35%): Agent should wrap up current task
//   CRITICAL (remaining <= 25%): Agent should save handoff and wrap up
//   HANDOFF  (remaining <= 18%): ~2% before 84% autocompact — IMMEDIATELY save handoff
//
// Debounce: 5 tool uses between warnings to avoid spam
// Severity escalation bypasses debounce (WARNING -> CRITICAL -> HANDOFF fires immediately)

const fs = require('fs');
const os = require('os');
const path = require('path');

const WARNING_THRESHOLD = 35;  // remaining_percentage <= 35%
const CRITICAL_THRESHOLD = 25; // remaining_percentage <= 25%
const HANDOFF_THRESHOLD = 18;  // remaining_percentage <= 18% (~2% before 84% autocompact)
const STALE_SECONDS = 60;      // ignore metrics older than 60s
const DEBOUNCE_CALLS = 5;      // min tool uses between warnings

let input = '';
// Timeout guard: if stdin doesn't close within 3s (e.g. pipe issues on
// Windows/Git Bash), exit silently instead of hanging until Claude Code
// kills the process and reports "hook error". See #775.
const stdinTimeout = setTimeout(() => process.exit(0), 3000);
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  clearTimeout(stdinTimeout);
  try {
    const data = JSON.parse(input);
    const sessionId = data.session_id;

    if (!sessionId) {
      process.exit(0);
    }

    const tmpDir = os.tmpdir();
    const metricsPath = path.join(tmpDir, `claude-ctx-${sessionId}.json`);

    // If no metrics file, this is a subagent or fresh session -- exit silently
    if (!fs.existsSync(metricsPath)) {
      process.exit(0);
    }

    const metrics = JSON.parse(fs.readFileSync(metricsPath, 'utf8'));
    const now = Math.floor(Date.now() / 1000);

    // Ignore stale metrics
    if (metrics.timestamp && (now - metrics.timestamp) > STALE_SECONDS) {
      process.exit(0);
    }

    const remaining = metrics.remaining_percentage;
    const usedPct = metrics.used_pct;

    // No warning needed
    if (remaining > WARNING_THRESHOLD) {
      process.exit(0);
    }

    // Debounce: check if we warned recently
    const warnPath = path.join(tmpDir, `claude-ctx-${sessionId}-warned.json`);
    let warnData = { callsSinceWarn: 0, lastLevel: null };
    let firstWarn = true;

    if (fs.existsSync(warnPath)) {
      try {
        warnData = JSON.parse(fs.readFileSync(warnPath, 'utf8'));
        firstWarn = false;
      } catch (e) {
        // Corrupted file, reset
      }
    }

    warnData.callsSinceWarn = (warnData.callsSinceWarn || 0) + 1;

    const isHandoff = remaining <= HANDOFF_THRESHOLD;
    const isCritical = remaining <= CRITICAL_THRESHOLD;
    const currentLevel = isHandoff ? 'handoff' : (isCritical ? 'critical' : 'warning');

    // Emit immediately on first warning, then debounce subsequent ones
    // Severity escalation (WARNING -> CRITICAL -> HANDOFF) bypasses debounce
    const levels = { warning: 0, critical: 1, handoff: 2 };
    const severityEscalated = (levels[currentLevel] || 0) > (levels[warnData.lastLevel] || -1);
    if (!firstWarn && warnData.callsSinceWarn < DEBOUNCE_CALLS && !severityEscalated) {
      // Update counter and exit without warning
      fs.writeFileSync(warnPath, JSON.stringify(warnData));
      process.exit(0);
    }

    // Reset debounce counter
    warnData.callsSinceWarn = 0;
    warnData.lastLevel = currentLevel;
    fs.writeFileSync(warnPath, JSON.stringify(warnData));

    // Detect if GSD is active (has .planning/STATE.md in working directory)
    const cwd = data.cwd || process.cwd();
    const isGsdActive = fs.existsSync(path.join(cwd, '.planning', 'STATE.md'));

    // Build advisory warning message (never use imperative commands that
    // override user preferences — see #884)
    let message;
    if (isHandoff) {
      // HANDOFF threshold: 2% before autocompact — save state NOW
      message = isGsdActive
        ? `CONTEXT HANDOFF: Usage at ${usedPct}%. Remaining: ${remaining}%. Autocompact imminent. ` +
          'IMMEDIATELY save a handoff memory file to .claude/projects/*/memory/ with: what was done, ' +
          'files changed, what is in progress, what is next. Update MEMORY.md index. ' +
          'GSD state is also tracked in STATE.md. Do this BEFORE any other work.'
        : `CONTEXT HANDOFF: Usage at ${usedPct}%. Remaining: ${remaining}%. Autocompact imminent. ` +
          'IMMEDIATELY save a handoff memory file to .claude/projects/*/memory/ with: what was done, ' +
          'files changed, what is in progress, what is next. Update MEMORY.md index. ' +
          'Do this BEFORE any other work. Then continue working until compaction hits.';
    } else if (isCritical) {
      message = isGsdActive
        ? `CONTEXT CRITICAL: Usage at ${usedPct}%. Remaining: ${remaining}%. ` +
          'Context is nearly exhausted. Do NOT start new complex work or write handoff files — ' +
          'GSD state is already tracked in STATE.md. Inform the user so they can run ' +
          '/gsd:pause-work at the next natural stopping point.'
        : `CONTEXT CRITICAL: Usage at ${usedPct}%. Remaining: ${remaining}%. ` +
          'Context is getting limited. Save a handoff memory file if you have not already, ' +
          'then wrap up current work. Avoid starting new complex tasks.';
    } else {
      message = isGsdActive
        ? `CONTEXT WARNING: Usage at ${usedPct}%. Remaining: ${remaining}%. ` +
          'Context is getting limited. Avoid starting new complex work. If not between ' +
          'defined plan steps, inform the user so they can prepare to pause.'
        : `CONTEXT WARNING: Usage at ${usedPct}%. Remaining: ${remaining}%. ` +
          'Be aware that context is getting limited. Avoid unnecessary exploration or ' +
          'starting new complex work.';
    }

    const output = {
      hookSpecificOutput: {
        hookEventName: process.env.GEMINI_API_KEY ? "AfterTool" : "PostToolUse",
        additionalContext: message
      }
    };

    process.stdout.write(JSON.stringify(output));
  } catch (e) {
    // Silent fail -- never block tool execution
    process.exit(0);
  }
});
