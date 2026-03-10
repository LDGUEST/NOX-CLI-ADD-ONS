---
name: monitorlive
description: Launch a background agent to watch live application logs in real-time during active testing.
metadata:
  author: nox
  version: "1.6"
---

Launch a background monitoring agent that watches live application logs in real-time. Use this during live testing to observe actual user behavior, catch errors as they happen, and surface issues without manually tailing logs.

## Setup

1. **Detect the log source** — Inspect the project to determine where logs live:
   - **Vercel**: `vercel logs --follow` or `vercel logs <deployment-url> --follow`
   - **Next.js / Node**: `tail -f` on `.next/server/` logs, or `npm run dev` console output
   - **Docker**: `docker logs -f <container>`
   - **PM2**: `pm2 logs`
   - **Systemd**: `journalctl -fu <service>`
   - **Railway**: `railway logs --follow`
   - **Fly.io**: `fly logs`
   - **Supabase Edge Functions**: `supabase functions serve` output or Supabase dashboard logs
   - **Django / Flask / FastAPI**: Detect framework, tail the appropriate log file or process output
   - **Custom log file**: Look for `LOG_FILE`, `LOG_PATH` env vars, or common paths (`/var/log/`, `./logs/`, `./tmp/`)
   - If unsure, ask which service or process to monitor

2. **Start the log stream** — Run the appropriate tail/follow command in the background

3. **Watch and report** — Continuously monitor the stream for:
   - **Errors** (5xx, unhandled exceptions, stack traces, panic, FATAL)
   - **Warnings** (4xx spikes, deprecation notices, slow queries > 1s)
   - **Auth events** (login failures, token expiry, permission denied)
   - **Performance signals** (response times > 2s, memory warnings, connection pool exhaustion)
   - **User activity patterns** (which endpoints are hit, request volume, unusual access patterns)

## Output Format

Report findings in real-time as they occur:

```
[HH:MM:SS] ERROR  500 on POST /api/checkout — "Cannot read property 'id' of undefined"
                   → stack trace points to src/lib/stripe.ts:42
[HH:MM:SS] SLOW   GET /api/products — 3.2s response time (threshold: 2s)
[HH:MM:SS] AUTH   3 failed login attempts from same IP in 60s
[HH:MM:SS] OK     200 on GET /dashboard — normal traffic, 12 requests/min
```

## Severity Levels

| Level | Meaning | Action |
|-------|---------|--------|
| **ERROR** | Server errors, crashes, unhandled exceptions | Alert immediately — this needs fixing |
| **SLOW** | Response time above threshold | Flag for investigation |
| **AUTH** | Authentication/authorization anomalies | Flag — could be attack or bug |
| **WARN** | 4xx errors, deprecation warnings | Log for awareness |
| **OK** | Normal successful requests | Periodic summary only (don't spam) |

## Rules

- **Don't flood output** — Summarize OK traffic periodically (every 30s or every 50 requests), only surface individual events for ERROR/SLOW/AUTH/WARN
- **Deduplicate** — If the same error occurs repeatedly, report it once with a count ("seen 15 times in last 60s") instead of 15 separate lines
- **Correlate** — If you see a 500 error followed by retry attempts from the same client, group them as one incident
- **Stay running** — Keep monitoring until explicitly told to stop. This is meant to run alongside active testing.
- **Suggest fixes** — When you spot an error with an obvious cause, suggest the fix inline

## Environment Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `LOG_SOURCE` | Override auto-detection | `vercel`, `docker:myapp`, `file:/var/log/app.log` |
| `LOG_THRESHOLD_MS` | Slow request threshold (ms) | `2000` |
| `LOG_FILTER` | Only show logs matching pattern | `ERROR\|WARN` |

---
Nox
