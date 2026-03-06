---
name: push
description: Push to production with platform auto-detection and retry logic
---

Push the current changes and monitor the deployment. Follow this protocol:

**Guardrails Active:** [Nox Guardrails](/nox:guardrails) are enforced — secret scanning on all file writes, branch protection on commits, and test regression tracking.

## Step 1: Detect Platform

Auto-detect the deployment platform from project config:
- `vercel.json` or `.vercel/` → Vercel
- `netlify.toml` or `_redirects` → Netlify
- `fly.toml` → Fly.io
- `railway.toml` or `railway.json` → Railway
- `Procfile` + `app.json` → Heroku
- `Dockerfile` + CI config → Container-based deploy

## Step 2: Push Safely

1. Push to a feature branch first — never directly to the production branch
2. Wait for the platform to generate a preview/staging deployment
3. Verify the preview deployment is functional
4. If preview passes, merge to the production branch

## Step 3: Monitor

- Watch for build errors in the deployment logs
- Verify the production URL returns HTTP 200 after deploy
- Check for any runtime errors in the first few minutes

## Step 4: Retry Logic

If the push or deployment fails:
- Retry up to 3 times with increasing wait between attempts
- If it continues to fail after 3 attempts, halt and document the blocker
- Do not enter a runaway retry loop

## Step 5: Report

Provide a summary: commit hash, branch, deploy URL, build duration, pass/fail status.

---
Nox
