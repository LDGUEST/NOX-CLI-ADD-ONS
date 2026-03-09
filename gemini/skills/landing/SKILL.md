---
name: landing
description: Draft a conversion-focused landing page from scratch — structure, copy, components, responsive layout
---

Draft a conversion-focused landing page from scratch. Handles the full process: structure, copy, components, and responsive layout. Adapts to whatever stack the project uses.

## When to Use

- Starting a new product/project and need a public-facing page
- Replacing a placeholder or "coming soon" page with something real
- When the user says "make a landing page" or "we need a website"

## Arguments

`$ARGUMENTS` — Product/project description or target audience. If empty, infer from the codebase (README, package.json, existing copy).

## Process

### Phase 1: Stack Detection

Detect the project's framework before writing any code:

| Detected | Use |
|----------|-----|
| `next.config.*` | Next.js App Router — `app/page.tsx` |
| `vite.config.*` | Vite + React — `src/App.tsx` or `src/pages/Landing.tsx` |
| `astro.config.*` | Astro — `src/pages/index.astro` |
| `svelte.config.*` | SvelteKit — `src/routes/+page.svelte` |
| Nothing detected | Default to Next.js App Router + TypeScript + Tailwind CSS |

Match the project's existing styling approach. If none set up, use Tailwind.

### Phase 2: Content Strategy

Before writing components, answer these (from codebase or by asking):
1. **What is this product?** — one sentence, no jargon
2. **Who is it for?** — specific persona, not "everyone"
3. **What pain point does it solve?** — the "before" state
4. **What's the transformation?** — the "after" state
5. **What should the visitor do?** — primary CTA (sign up, buy, download, join waitlist)

### Phase 3: Section Architecture

Build the page with these sections. Each has a job — skip sections that don't apply.

1. **Hero** — Headline (6-12 words, benefit-focused), subheadline, primary CTA button (action verb + outcome), visual, social proof micro-element
2. **Problem -> Solution** — State the pain point, bridge to how the product solves it. Keep it emotional.
3. **Features / How It Works** — 3-4 features max, each with icon + title + one sentence. Grid layout.
4. **Social Proof** — Testimonials, logos, stats. Never fabricate.
5. **CTA (repeat)** — Same CTA, different framing. Address the main objection.
6. **Footer** — Links (GitHub, docs, license), copyright. Minimal.

### Phase 4: Implementation

- Functional components only, each file under 100 lines
- Semantic HTML: `<main>`, `<section>`, `<header>`, `<footer>`, `<nav>`
- Mobile-first responsive: default < 640px, `sm:`/`md:` 640-1024px, `lg:`/`xl:` 1024px+
- No client-side JS unless interactive elements require it
- CSS animations over JS animations. Page weight under 200KB.

### Phase 5: SEO & Meta

Add: `<title>`, `<meta description>`, Open Graph tags, Twitter card tags, canonical URL, favicon reference.

### Phase 6: Review

- [ ] Every section has a clear job
- [ ] CTA appears at least twice (hero + bottom)
- [ ] Page reads well with all images removed
- [ ] No horizontal scroll on mobile
- [ ] No placeholder text left
- [ ] Semantic HTML and accessible

## Rules

- **Content before code** — Phase 2 before Phase 4. Don't code until you know what to say.
- **Benefits over features** — "Deploy in 30 seconds" beats "Automated CI/CD pipeline integration"
- **One CTA per page** — don't offer sign up AND download AND newsletter. Pick one.
- **No stock photo vibes** — use code blocks, terminal output, or CSS-only graphics if no real screenshots
- **Match the project's voice** — casual README = casual landing page
- **Ship the minimum** — 5-section page that ships today beats 12-section masterpiece that ships never

---
Nox
