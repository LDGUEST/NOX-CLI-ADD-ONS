---
name: deploy
description: 5-step deploy protocol — preflight, backup, deploy, verify, report
---

Deploy the current project with full safety checks. Follow this exact 5-step protocol:

## 1. Pre-flight

- Run `git status` and `git diff` to confirm what's being deployed
- Verify the working tree is clean (no uncommitted changes)
- Confirm the current branch and its relationship to the deploy target
- Show a summary of changes since last deploy

## 2. Backup

- If `$DEPLOY_BACKUP_CMD` is set, run it and confirm zero errors
- Otherwise, ensure the current state is committed and pushed to remote
- Tag the current commit as a rollback point: `git tag pre-deploy-$(date +%Y%m%d-%H%M%S)`

## 3. Deploy

- Execute the project's deploy command:
  - If `$DEPLOY_CMD` is set, use it
  - Otherwise auto-detect: `vercel`, `netlify deploy`, `fly deploy`, `railway up`, `git push heroku`, etc.
- Stream deploy logs and watch for errors

## 4. Verify

- Run post-deploy health checks:
  - HTTP 200 on `$DEPLOY_URL` or auto-detected production URL
  - Check for console errors or crash logs
  - Verify critical API endpoints respond
- **Visual verification**: Use Playwright to screenshot the deployed homepage and any critical user-facing pages. Confirm the UI renders correctly post-deploy — no blank pages, no broken layouts, no missing assets.
- If verification fails, prompt for rollback

## 5. Report

- Provide a deployment summary with pass/fail for each step
- Include: commit hash, branch, deploy URL, duration, any warnings

## Safety Rules

- If ANY step fails, halt immediately and report. Do not continue deploying on top of a failed state.
- Never force-push or deploy uncommitted changes.
- Always verify in preview/staging before production when available.

## Environment Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `DEPLOY_CMD` | Custom deploy command | `vercel --prod` |
| `DEPLOY_BACKUP_CMD` | Pre-deploy backup | `./scripts/backup.sh` |
| `DEPLOY_URL` | Production URL to verify | `https://myapp.vercel.app` |
| `DEPLOY_HOST` | Target server (SSH deploys) | `user@server.com` |
| `PROJECT_DIR` | Remote project directory | `/var/www/myapp` |

---
Nox
