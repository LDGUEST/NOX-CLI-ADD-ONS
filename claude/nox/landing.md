Draft a conversion-focused landing page from scratch. This skill handles the full process: structure, copy, components, and responsive layout. Adapts to whatever stack the project uses.

## When to Use

- Starting a new product/project and need a public-facing page
- Replacing a placeholder or "coming soon" page with something real
- When the user says "make a landing page" or "we need a website"

## Arguments

`$ARGUMENTS` — Product/project description or target audience. If empty, infer from the codebase (README, package.json, existing copy).

## Process

### Phase 1: Stack Detection

Before writing any code, detect the project's framework:

```bash
# Check for framework indicators
ls package.json next.config.* vite.config.* astro.config.* svelte.config.* nuxt.config.* 2>/dev/null
```

| Detected | Use |
|----------|-----|
| `next.config.*` | Next.js App Router — `app/page.tsx` |
| `vite.config.*` | Vite + React — `src/App.tsx` or `src/pages/Landing.tsx` |
| `astro.config.*` | Astro — `src/pages/index.astro` |
| `svelte.config.*` | SvelteKit — `src/routes/+page.svelte` |
| Nothing detected | Default to Next.js App Router + TypeScript + Tailwind CSS |

Match the project's existing styling approach (Tailwind, CSS modules, styled-components). If no styling is set up, use Tailwind.

### Phase 2: Content Strategy

Before writing components, define what goes on the page. Answer these questions (from the codebase or by asking):

1. **What is this product?** — one sentence, no jargon
2. **Who is it for?** — specific persona, not "everyone"
3. **What's the #1 pain point it solves?** — the "before" state
4. **What's the transformation?** — the "after" state
5. **What should the visitor do?** — primary CTA (sign up, buy, download, join waitlist)

If you can't answer these from context, ask before proceeding.

### Phase 3: Section Architecture

Build the page with these sections in order. Each section has a job — skip sections that don't apply, but don't skip the job.

**1. Hero (above the fold)**
- Headline: 6-12 words, benefit-focused, no buzzwords
- Subheadline: 1-2 sentences expanding on the headline
- Primary CTA button: action verb + outcome ("Start building faster", not "Sign up")
- Visual: product screenshot, animated SVG, or illustration
- Social proof micro-element: "Used by X developers" or "Y stars on GitHub"

**2. Problem → Solution**
- State the pain point the audience recognizes (2-3 bullet points or short paragraph)
- Bridge to how the product solves it
- Keep it emotional — "You've wasted hours debugging deployment issues" not "Our tool optimizes CI/CD pipelines"

**3. Features / How It Works**
- 3-4 features max (not a feature dump)
- Each feature: icon + short title + one-sentence description
- Show, don't tell — use code snippets, terminal output, or screenshots if available
- Grid layout: 2x2 or 3-column on desktop, single column on mobile

**4. Social Proof**
- Testimonials, logos, GitHub stars, user count — whatever exists
- If nothing exists yet, use a stats section ("X skills", "Y hooks", "Z CLI support")
- Never fabricate testimonials or numbers

**5. CTA (repeat)**
- Same CTA as hero, different framing
- Address the main objection: "Free and open source", "No credit card required", "5-minute setup"

**6. Footer**
- Links: GitHub, docs, license, contact
- Copyright line
- Keep it minimal — 2-3 columns max

### Phase 4: Implementation

Write the actual components following these rules:

**File structure:**
```
// Single page with section components
app/page.tsx (or equivalent)
components/landing/
  Hero.tsx
  Problem.tsx
  Features.tsx
  SocialProof.tsx
  CTA.tsx
  Footer.tsx
```

**Code standards:**
- Functional components only — no class components
- Each component file under 100 lines (split if longer)
- Semantic HTML: `<main>`, `<section>`, `<header>`, `<footer>`, `<nav>`
- All text in the component (no CMS or i18n unless project already uses one)
- No external image URLs — use SVGs, CSS gradients, or placeholder divs

**Responsive breakpoints:**
- Mobile-first: default styles for `< 640px`
- Tablet: `sm:` / `md:` (640-1024px)
- Desktop: `lg:` / `xl:` (1024px+)
- Test mental model: does each section look good as a single column?

**Performance:**
- No client-side JavaScript unless interactive elements require it
- Use `loading="lazy"` on images below the fold
- Prefer CSS animations over JS animations
- Keep total page weight under 200KB (excluding images)

### Phase 5: SEO & Meta

Add to the page's `<head>` or metadata export:
- `<title>` — product name + value prop (under 60 chars)
- `<meta name="description">` — what the product does (under 160 chars)
- Open Graph tags: `og:title`, `og:description`, `og:image`, `og:url`
- Twitter card tags: `twitter:card`, `twitter:title`, `twitter:description`
- Canonical URL
- Favicon reference

### Phase 6: Review

Before presenting, verify:
- [ ] Every section has a clear job and delivers on it
- [ ] CTA appears at least twice (hero + bottom)
- [ ] Page reads well with all images removed (text carries the message)
- [ ] Mobile layout doesn't have horizontal scroll or overlapping elements
- [ ] No placeholder text left ("Lorem ipsum", "Company Name Here")
- [ ] Semantic HTML and accessible (alt text, ARIA labels on interactive elements)
- [ ] Files are under 100 lines each

## Rules

- **Content before code** — Phase 2 must happen before Phase 4. Don't start coding until you know what to say.
- **Benefits over features** — "Deploy in 30 seconds" beats "Automated CI/CD pipeline integration"
- **One CTA per page** — don't offer sign up AND download AND contact AND newsletter. Pick the one that matters most.
- **No stock photo vibes** — if you can't get a real product screenshot, use a code block, terminal output, or CSS-only graphic. Honest beats polished.
- **Match the project's voice** — if the README is casual, the landing page should be casual. If it's enterprise, be enterprise.
- **Ship the minimum** — a 5-section landing page that ships today beats a 12-section masterpiece that ships never.

---
Nox
