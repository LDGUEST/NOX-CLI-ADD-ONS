---
name: explain
description: Generates an onboarding guide for any codebase or subsystem — maps architecture, data flow, and key abstractions for new contributors. Use when someone needs to understand unfamiliar code fast.
argument-hint: "[scope]"
context: fork
agent: Explore
metadata:
  author: nox
  version: "2.5"
---

Generate a structured onboarding explanation of the specified codebase, module, or subsystem. Produce a guide that lets a new contributor understand the system and start working in it quickly.

## Process

1. **Determine scope** — If the user specifies a directory, module, or feature, focus there. If no scope given, explain the entire project.
2. **Scan project structure** — Map the directory tree, identify entry points, key configuration files, and the tech stack.
3. **Trace the architecture** — Identify layers (UI, API, data, services) and how they connect.
4. **Map data flow** — Follow a request from entry point through the system to the database/external service and back.
5. **Identify key abstractions** — The patterns, base classes, hooks, utilities, and conventions that a contributor must understand.
6. **Find the "start here" files** — The 3-5 files a new contributor should read first to understand the system.

## Output Structure

### 1. Project Overview
- What does this project do? (one paragraph)
- Tech stack summary (framework, language, database, auth, deployment)
- How to run it locally (commands, prerequisites, env setup)

### 2. Architecture Map

```
┌─────────────┐     ┌──────────────┐     ┌────────────┐
│  Frontend    │────▶│  API Layer   │────▶│  Database   │
│  (React)     │     │  (Next.js)   │     │  (Supabase) │
└─────────────┘     └──────────────┘     └────────────┘
        │                   │
        ▼                   ▼
  ┌───────────┐     ┌──────────────┐
  │  State     │     │  External    │
  │  (Zustand) │     │  APIs        │
  └───────────┘     └──────────────┘
```

Use ASCII diagrams to illustrate the architecture. Keep them simple and accurate.

### 3. Directory Guide

Explain what each top-level directory contains and its purpose:

```
src/
  app/          — Next.js App Router pages and layouts
  components/   — Shared UI components (Shadcn + custom)
  lib/          — Utility functions, API clients, config
  hooks/        — Custom React hooks
  types/        — TypeScript type definitions
  services/     — Business logic, separated from route handlers
```

### 4. Data Flow Walkthrough

Pick the most representative user action (e.g., "user creates a new post") and trace it step by step:

1. User clicks button in `src/components/CreatePostForm.tsx`
2. Form submits to `src/app/api/posts/route.ts`
3. Handler validates input with Zod schema
4. Calls `src/services/posts.ts` → `createPost()`
5. Inserts into `posts` table via Supabase client
6. Returns 201 with the new post data

### 5. Key Abstractions & Conventions

- Naming conventions (file names, component names, route structure)
- Auth pattern (how auth is checked, where guards live)
- Error handling pattern (how errors propagate, standard error format)
- State management approach
- Testing approach (if tests exist)

### 6. Start Here

List the 3-5 files a new contributor should read first, in order, with a one-line explanation of why:

1. `src/app/layout.tsx` — Root layout, shows all providers and global setup
2. `src/lib/supabase.ts` — Database client initialization, used everywhere
3. `src/middleware.ts` — Auth gate, controls which routes are protected
4. `src/app/api/posts/route.ts` — Representative API route, shows the full pattern
5. `src/components/PostCard.tsx` — Representative component, shows UI conventions

## Rules

- **Read the actual code** — Don't guess. Every claim in the guide must be verified by reading source files.
- **Be honest about gaps** — If something is unclear, confusing, or poorly organized, say so. This is an explanation, not marketing.
- **Skip boilerplate** — Don't explain `node_modules`, `tsconfig.json`, or other standard files unless they contain non-obvious customizations.
- **Calibrate depth** — A single utility file gets a paragraph. A complex subsystem gets its own data flow walkthrough.

---
Nox
