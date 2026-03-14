---
name: uxtest
description: Performs comprehensive UX testing via Playwright — user journeys, responsive design, accessibility, and interaction bugs. Use when verifying UI quality before a release or after major frontend changes.
argument-hint: "[url-or-component]"
context: fork
agent: general-purpose
metadata:
  author: nox
  version: "1.6"
---

Perform comprehensive interactive UX testing using Playwright. This goes far beyond screenshot checks — it simulates real user journeys, tests responsive behavior, validates accessibility, and catches interaction bugs that static analysis and unit tests miss entirely.

## When to Use

- After building or modifying any user-facing feature
- Before any production deploy of UI changes
- When the user says "test the UX", "check the frontend", "does this look right?"
- As part of `/nox:full-phase` when deeper visual testing is needed beyond the UX Gate screenshot
- When debugging a reported UI bug — reproduce it systematically

## Testing Protocol

### Phase 1: Discovery

Before testing, understand what you're testing:

1. **Identify the app URL** — `localhost:3000`, `$DEPLOY_URL`, or ask the user
2. **Detect the stack** — Next.js, React, Vue, Svelte, plain HTML (check package.json, framework markers)
3. **Map the routes** — Read the router config, sitemap, or crawl from the homepage
4. **Identify critical user flows** — login, signup, checkout, main dashboard, CRUD operations
5. **Check for existing test fixtures** — seed data, test accounts, mock APIs

### Phase 2: Visual Audit (every affected page)

For each page/route affected by recent changes:

**Responsive breakpoints** — Screenshot at:
- Mobile: 375×812 (iPhone SE / small)
- Tablet: 768×1024 (iPad)
- Desktop: 1280×800 (standard)
- Wide: 1920×1080 (full HD)

**Visual checks per breakpoint:**
- [ ] Layout doesn't break — no horizontal scroll, no overlapping elements
- [ ] Text is readable — no truncation, no overflow, proper contrast
- [ ] Images load and are sized correctly — no broken images, no layout shift
- [ ] Navigation is accessible — hamburger menu works on mobile, all links visible
- [ ] Interactive elements are tappable — buttons have adequate touch targets (min 44×44px)
- [ ] Forms are usable — labels visible, inputs not cut off, error states shown
- [ ] Dark mode (if applicable) — check both themes
- [ ] Loading states — skeleton screens, spinners, or progressive loading visible
- [ ] Empty states — what does the page look like with no data?
- [ ] Error states — what does the page look like when the API fails?

### Phase 3: Interaction Testing (critical flows)

Use Playwright to simulate real user behavior. For each critical flow:

**Navigation:**
- Click every link on the page — verify no dead links (404s)
- Test browser back/forward — does state persist correctly?
- Test deep linking — can you land directly on a sub-route and have it work?

**Forms:**
- Submit with valid data — verify success state
- Submit with empty required fields — verify validation messages appear
- Submit with invalid data (wrong email format, too-short password) — verify inline errors
- Tab through all fields — verify focus order is logical
- Test paste into fields — verify it works (some custom inputs break this)
- Test autofill — verify browser autofill doesn't break the layout

**Interactive elements:**
- Click every button — verify it does something (no dead buttons)
- Test dropdowns, modals, tooltips — verify they open, position correctly, and close
- Test keyboard navigation — can you reach every interactive element with Tab?
- Test Escape key — does it close modals, dropdowns, popovers?
- Test double-click prevention — does clicking "Submit" twice cause duplicate submissions?

**Dynamic content:**
- Scroll to bottom — does infinite scroll / pagination work?
- Test search — does it filter results, handle empty results, clear properly?
- Test sorting — does it sort correctly, persist across navigation?
- Test real-time updates — if applicable, do WebSocket/SSE updates render correctly?

### Phase 4: Accessibility Audit

Run these checks on every affected page:

**Automated:**
- Run Axe accessibility scanner via Playwright (`@axe-core/playwright`)
- Check for: missing alt text, low contrast, missing form labels, missing ARIA roles, heading hierarchy violations

**Manual/interactive:**
- [ ] Keyboard-only navigation — can you complete the critical flow without a mouse?
- [ ] Focus indicators visible — can you see where you are when tabbing?
- [ ] Screen reader landmarks — does the page have proper `<main>`, `<nav>`, `<header>`, `<footer>`?
- [ ] Color not the only indicator — do error states use more than just red? (icons, text, borders)
- [ ] Zoom to 200% — does the layout still work?

### Phase 5: Performance Snapshot

While Playwright is running, capture:
- **Page load time** — `performance.timing` via `page.evaluate()`
- **Largest Contentful Paint** — via Performance Observer
- **Cumulative Layout Shift** — how much does the page jump during load?
- **JavaScript errors** — capture all `console.error` events during the test run
- **Network failures** — any failed API calls, 4xx/5xx responses, CORS errors
- **Bundle observations** — count total network requests, total transfer size

## Output Format

```
UX TEST REPORT — [app name] — [date]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PAGES TESTED: [count]
FLOWS TESTED: [count]
BREAKPOINTS: 4 (375px / 768px / 1280px / 1920px)

CRITICAL ISSUES (must fix):
  1. [page] — [description] — [screenshot reference]
  2. ...

WARNINGS (should fix):
  1. [page] — [description]
  2. ...

ACCESSIBILITY:
  Violations: [count]
  [list of violations with severity]

PERFORMANCE:
  LCP: [time]ms
  CLS: [score]
  JS Errors: [count]
  Failed Requests: [count]

FLOW RESULTS:
  ✅ Login flow — passed (3 steps, 1.2s)
  ✅ Dashboard load — passed (2.1s)
  ❌ Checkout flow — FAILED at step 3 (payment form doesn't submit)
  ⚠️ Search — works but slow (4.3s for results)

SCREENSHOTS: [list of saved screenshots with descriptions]
```

## Rules

- **Always test on at least 2 breakpoints** — desktop and mobile minimum. Most UI bugs are responsive bugs.
- **Test the actual app, not assumptions** — don't skip testing because "it should work." Run the test.
- **Save screenshots** — every visual issue should have a screenshot for reference. Save to project root or `/tmp/`.
- **Report honestly** — if something looks off but isn't technically broken, still flag it. UX is about feel, not just function.
- **Don't fix during testing** — complete the full audit first, then fix. Fixing mid-test causes you to miss things.
- **Test with real-ish data** — empty states are important but also test with realistic content lengths, image sizes, and data volumes.

---
Nox
