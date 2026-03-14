---
name: perf
description: Profiles the codebase for performance issues and proposes concrete optimizations with impact estimates. Use when diagnosing slow queries, bundle bloat, memory leaks, or rendering bottlenecks.
argument-hint: "[area-or-file]"
context: fork
agent: general-purpose
metadata:
  author: nox
  version: "1.6"
---

Profile the codebase for performance issues and propose concrete optimizations.

## Analysis Areas

### Frontend (if applicable)
- **Bundle size** — Large imports, tree-shaking failures, duplicate dependencies
- **Render performance** — Unnecessary re-renders, missing memoization, expensive computations in render
- **Loading** — Unoptimized images, missing lazy loading, render-blocking resources
- **Core Web Vitals** — LCP, FID/INP, CLS impact assessment

### Backend
- **Database queries** — N+1 queries, missing indexes, full table scans, unoptimized JOINs
- **Memory** — Leaks, unbounded caches, large object retention
- **Concurrency** — Blocking operations, missing async/await, thread pool exhaustion
- **I/O** — Unnecessary file reads, unstreamed responses, missing connection pooling

### API Layer
- **Response size** — Over-fetching, missing pagination, no field selection
- **Caching** — Missing cache headers, redundant fetches, stale-while-revalidate opportunities
- **Batching** — Multiple sequential requests that could be batched or parallelized

## Output Format

For each finding:
```
[HIGH|MEDIUM|LOW] Category — Description
  Location: file.ts:42
  Impact: What's slow and by how much (estimated)
  Fix: Specific optimization with code example
  Tradeoff: What you give up (if anything)
```

## Rules

- Measure before optimizing — don't guess at bottlenecks
- Focus on the critical path first
- Only suggest optimizations with meaningful impact
- Never sacrifice readability for micro-optimizations
- Include before/after comparison when possible

---
Nox