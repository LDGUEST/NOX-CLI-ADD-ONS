---
name: security
description: Performs a comprehensive security assessment — OWASP Top 10 static analysis with optional live penetration testing. Use before releases or when auditing code for vulnerabilities.
argument-hint: "[scope]"
context: fork
agent: general-purpose
metadata:
  author: nox
  version: "1.6"
---

Perform a comprehensive security assessment of this codebase. This skill combines static analysis (OWASP Top 10 scan) with optional live penetration testing.

**Guardrails Active:** [Nox Guardrails](/nox:guardrails) are enforced — secret scanning on all file writes, branch protection on commits, and test regression tracking.

## Mode Selection

Ask the user which mode to run:

- **Scan** (default) — Static code analysis against OWASP Top 10. Fast, no running app needed.
- **Pentest** — Full white-box penetration test against a running application. Requires authorization and a live target URL.
- **Full** — Both scan and pentest in sequence.

---

## Mode: Scan (Static Analysis)

### OWASP Top 10 Checklist

#### A01: Broken Access Control
- [ ] Missing authorization checks on endpoints
- [ ] IDOR (Insecure Direct Object Reference) vulnerabilities
- [ ] Missing CORS configuration or overly permissive origins
- [ ] Privilege escalation paths

#### A02: Cryptographic Failures
- [ ] Sensitive data transmitted without TLS
- [ ] Weak hashing algorithms (MD5, SHA1 for passwords)
- [ ] Hardcoded secrets, API keys, credentials in source code
- [ ] Secrets in client-side code or public environment variables

#### A03: Injection
- [ ] SQL injection (raw string interpolation in queries)
- [ ] Command injection (unsanitized input in shell commands)
- [ ] XSS (unescaped user input in HTML/templates)
- [ ] Path traversal (user input in file paths)

#### A04: Insecure Design
- [ ] Missing rate limiting on auth endpoints
- [ ] No account lockout after failed attempts
- [ ] Missing CSRF protection on state-changing operations

#### A05: Security Misconfiguration
- [ ] Debug mode enabled in production config
- [ ] Default credentials or configurations
- [ ] Unnecessary features, ports, or services exposed
- [ ] Missing security headers (CSP, HSTS, X-Frame-Options)

#### A06: Vulnerable Components
- [ ] Run `npm audit` / `pip audit` / equivalent for known CVEs
- [ ] Outdated dependencies with known vulnerabilities
- [ ] Unmaintained or abandoned dependencies

#### A07: Auth Failures
- [ ] Weak password policies
- [ ] Missing MFA options
- [ ] Session tokens in URLs
- [ ] JWT misconfiguration (alg:none, weak secrets, no expiry)

#### A08: Data Integrity Failures
- [ ] Unsigned updates or deployments
- [ ] Missing integrity checks on critical data

#### A09: Logging & Monitoring Gaps
- [ ] Sensitive data logged (tokens, passwords, PII)
- [ ] Missing audit logs for critical operations
- [ ] No alerting on suspicious activity

#### A10: SSRF
- [ ] User-supplied URLs fetched server-side without validation
- [ ] Internal service endpoints exposed

### Scan Output Format

For each finding:
```
[CRITICAL|HIGH|MEDIUM|LOW] Category — Brief description
  Location: file.ts:42
  Risk: What an attacker could do
  Fix: Specific remediation steps
```

---

## Mode: Pentest (Live Penetration Test)

**Philosophy: No Exploit, No Report.** Only report findings with reproducible proof-of-concept. Zero false positives.

**Authorization:** Confirm the user owns or has explicit permission to test the target before proceeding.

### Phase 1: Code Intelligence (White-Box Recon)

Read source code systematically. Do NOT test anything yet — map the terrain.

**Run these analyses in parallel using sub-agents:**

1. **Architecture Scanner** — Framework, ORM, auth library, session mechanism, middleware stack, database type
2. **Entry Point Mapper** — Every HTTP endpoint, API route, WebSocket handler. For each: method, path, auth required, parameters, validation
3. **Security Pattern Hunter** — Raw SQL, shell exec, file read/write, template rendering with user input, URL fetching, deserialization, crypto usage, hardcoded secrets

**Deliverable:** Write `pentest_recon.md` with tech stack, endpoint inventory, auth architecture, input vector catalog.

### Phase 2: Attack Surface Mapping (Live Recon)

Interact with the running application using `curl` and browser automation.

1. Hit every endpoint from Phase 1. Record responses, headers, cookies, redirects
2. Walk through auth flows. Map token lifecycle
3. Inspect session properties (HttpOnly, Secure, SameSite, JWT structure)
4. Send malformed input to each endpoint. Record error handling quality

**Deliverable:** Append live behavior, session properties, attack priority ranking to `pentest_recon.md`.

### Phase 3: Vulnerability Analysis (5 Categories, Parallel)

For each category, trace data flow from source (user input) to sink (dangerous function).

1. **Injection** — SQLi, Command Injection, LFI, SSTI, Path Traversal
2. **Cross-Site Scripting** — Reflected, Stored, DOM-based
3. **Authentication & Session** — 9-point checklist (transport, rate limiting, cookie flags, token expiry, session fixation, password policy, enumeration, reset flow, OAuth)
4. **SSRF** — Internal service access, protocol handling, validation bypass
5. **Authorization** — Horizontal (IDOR), Vertical (privilege escalation), Context (workflow bypass)

**Deliverable:** Write `pentest_vulns.md` with each finding: endpoint, source, sink, sanitization, verdict, witness payload.

### Phase 4: Exploitation (Prove Every Finding)

For every VULNERABLE finding, attempt actual exploitation.

**Proof Levels:**
- Level 1: Injection point confirmed (error messages, timing)
- Level 2: Structure manipulated (boolean blind, UNION succeeds)
- Level 3: Impact demonstrated (data extracted, XSS fires, auth bypassed) — **MINIMUM for EXPLOITED**
- Level 4: Critical impact (admin access, RCE, full database dump)

**Rules:**
- Use `curl` for manual request crafting
- Minimum 3 distinct payload attempts before "not exploitable"
- If blocked by WAF, try 5+ bypass variations
- Document every attempt
- **NEVER report a vulnerability you could not actually exploit**

### Phase 5: Final Report

Compile `PENTEST_REPORT.md` with: executive summary, results table by category, exploited vulnerabilities with full PoCs, blocked findings, remediation priority.

## Important

- **Get explicit authorization** before pentesting any application
- **Never test production systems** without approval — use staging/local
- **Never exfiltrate real user data** — stop at proving the vulnerability exists
- **Rate limit your testing** — don't DoS the target
- This skill is for **defensive security** — helping developers find and fix vulnerabilities in their own applications

---
Nox
