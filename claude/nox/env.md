---
name: env
description: Audits environment variables — finds missing vars, detects leaked secrets, generates .env.example, and compares environments. Use when debugging config issues or hardening a project.
argument-hint: "[action]"
context: fork
agent: general-purpose
metadata:
  author: nox
  version: "2.5"
---

Environment variable auditor. Cross-reference code references against actual .env files, detect secrets exposure, and generate safe configuration templates.

## Actions

| Action | When to use |
|--------|-------------|
| `audit` | Full scan — find missing vars, leaked secrets, misconfigurations |
| `generate` | Create a `.env.example` from code references |
| `compare` | Diff env vars between environments (dev vs prod, local vs Vercel) |

If no action specified, default to `audit`.

---

## Action: Audit

### Step 1: Collect All Referenced Variables

Scan the entire codebase for env var references:

- `process.env.VAR_NAME` (Node.js)
- `os.environ["VAR_NAME"]` / `os.getenv("VAR_NAME")` (Python)
- `env::var("VAR_NAME")` (Rust)
- `Deno.env.get("VAR_NAME")` (Deno)
- `import.meta.env.VAR_NAME` (Vite)
- `System.getenv("VAR_NAME")` (Java)

### Step 2: Collect All Defined Variables

Read from all env files: `.env`, `.env.local`, `.env.development`, `.env.production`, `.env.example`, `.env.test`

### Step 3: Cross-Reference

Report:

| Category | Description |
|----------|-------------|
| **Missing** | Referenced in code but not defined in any .env file |
| **Unused** | Defined in .env but never referenced in code |
| **No default** | Referenced without a fallback value and not in .env.example |

### Step 4: Secrets Scan

Flag these as critical:

- **Hardcoded secrets** — API keys, tokens, passwords directly in source code (not env files)
- **Client-side exposure** — Server secrets using `NEXT_PUBLIC_`, `VITE_`, or `REACT_APP_` prefix
- **Committed env files** — `.env` or `.env.local` tracked by git (check `.gitignore`)
- **Service keys in wrong context** — `SUPABASE_SERVICE_ROLE_KEY` imported in client-side code
- **Secrets in logs** — `console.log` / `print` statements that output env vars

### Step 5: Framework Compliance

Check framework-specific rules:

- **Next.js** — Client vars must use `NEXT_PUBLIC_` prefix. Server-only vars must NOT have it.
- **Vite** — Client vars must use `VITE_` prefix.
- **Supabase** — `SUPABASE_SERVICE_ROLE_KEY` must never appear in client bundles or `NEXT_PUBLIC_` vars.

## Action: Generate

Create a `.env.example` file:

1. Collect all referenced env vars from code
2. Group by service (Database, Auth, Payments, Email, etc.)
3. Use placeholder values that indicate the expected format:
   ```
   # Database (Supabase)
   NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
   NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
   SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

   # Auth (Auth0)
   AUTH0_SECRET=use-openssl-rand-hex-32
   AUTH0_BASE_URL=http://localhost:3000
   ```
4. Add comments explaining each variable's purpose
5. Never include actual secret values — use descriptive placeholders

## Action: Compare

Compare env var sets between two sources:

- `.env.local` vs `.env.production`
- Local `.env` vs Vercel dashboard (if `vercel env pull` is available)
- `.env.example` vs actual `.env` (find vars the developer forgot to set)

Report as a diff table:

```
ENV COMPARISON: .env.local vs .env.production
=============================================
Variable                    Local    Production   Status
NEXT_PUBLIC_SUPABASE_URL    set      set          OK
STRIPE_WEBHOOK_SECRET       set      MISSING      CRITICAL
DEBUG_MODE                  "true"   not set      Warning (dev-only?)
```

## Output Format

```
ENV AUDIT REPORT
================
Variables found:    X referenced, Y defined
Missing:            X variables
Unused:             X variables
Secrets issues:     X critical, X warnings

CRITICAL FINDINGS:
- [file:line] STRIPE_SECRET_KEY hardcoded in src/lib/stripe.ts
- [file:line] SUPABASE_SERVICE_ROLE_KEY used in client component

MISSING VARIABLES:
- RESEND_API_KEY — referenced in src/lib/email.ts but not in any .env file

RECOMMENDATIONS:
1. ...
```

---
Nox
