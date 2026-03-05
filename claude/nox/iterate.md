Deploy specialized sub-agents for all required steps. Execute, verify against the goal, and recursively self-correct until the objective is 100% complete.

## Execution Protocol

1. **Decompose** — Break the objective into discrete, verifiable steps
2. **Execute** — Complete each step, one at a time
3. **Verify** — After each step, verify it meets the acceptance criteria
4. **Self-correct** — If verification fails, diagnose and fix before proceeding

## Verification Criteria

After each step, confirm:
- The change produces the expected output
- No existing tests are broken
- No regressions in related functionality
- The change is consistent with the project's coding standards
- **Visual verification (UI tasks)**: If the step touches any UI, use Playwright to screenshot the affected page/component. Compare against the expected outcome. If the layout is broken, overlapping, or missing content — this counts as a failed verification and triggers a self-correct cycle. Do not move to the next step with broken UI.

## Safety Guards

- **Max iterations**: Do not attempt more than 10 correction cycles on a single step. If stuck after 10 attempts, halt and report the blocker.
- **Rollback on failure**: If a fix introduces more problems than it solves, revert to the last known good state.
- **Progress logging**: Log each step's status (pass/fail/skip) for the final report.
- **Hook safety net**: If Nox hooks are installed, `destructive-guard` prevents dangerous commands during autonomous execution, `debug-reminder` points to DEBUGGING.md on failures (saving rediagnosis), and `cost-alert` warns if the session gets expensive. These run passively on every tool call — no action needed from the agent.

## Completion

Do not pause, ask for input, or terminate until the final objective is fully validated. When complete, provide a summary of all steps executed and their outcomes.

---
Nox