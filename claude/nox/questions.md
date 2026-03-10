---
name: questions
description: Ask all clarifying questions before any implementation to remove ambiguity. Use before coding or architecture.
metadata:
  author: nox
  version: "1.6"
---

Review the current context. Before generating any code or solutions, ask every necessary clarifying question to remove all ambiguity. The goal: build it correctly in one shot instead of iterating through misunderstandings.

## When to Use

- Before any non-trivial implementation — especially when requirements feel vague
- When the user says "build me X" without specifying behavior, scope, or constraints
- Before `/nox:architect` — clarify first, design second
- When you're about to make assumptions that could waste hours if wrong

## Process

### Phase 1: Context Scan

Before asking anything, gather what you already know:
1. Read the project's CLAUDE.md, package.json/go.mod/Cargo.toml, and directory structure
2. Identify the tech stack, auth system, database, and deployment target
3. Check if similar features already exist in the codebase
4. Note any constraints mentioned in the user's request

### Phase 2: Question Generation

Generate questions across these 7 categories. Skip categories that are already answered by context. Prioritize by impact — ask the questions whose answers would most change your implementation.

**1. Scope & Boundaries**
- What's included vs explicitly out of scope?
- Is this a new feature, modification of existing, or replacement?
- What's the minimum viable version vs the ideal version?
- Does this need to work with existing data/users or is it greenfield?

**2. Data Flow & State**
- Where does the data come from? (user input, API, database, file)
- What's the shape of the data? (fields, types, relationships)
- How is state managed? (server, client, both)
- What happens to existing data during this change?

**3. UI/UX & Interactions**
- What should the user see? (layout, components, pages)
- What interactions are expected? (clicks, forms, drag-drop, real-time)
- Are there loading states, empty states, error states to handle?
- Does this need to be responsive? What breakpoints matter?

**4. Auth & Permissions**
- Who can access this? (all users, roles, owner-only)
- Are there different views based on role?
- Does this create, modify, or check permissions?

**5. Edge Cases & Error Handling**
- What happens when input is invalid, empty, or malicious?
- What if the external service is down?
- Are there rate limits, size limits, or quotas to enforce?
- What does the user see when something fails?

**6. Integration Points**
- What external services, APIs, or databases are involved?
- Are there webhooks, callbacks, or event triggers?
- Does this need to sync with anything else?

**7. Performance & Scale**
- Expected volume? (users, requests, data size)
- Response time targets? (real-time, seconds, async is fine)
- Caching needs? (CDN, in-memory, database-level)

### Phase 3: Prioritization

Sort your questions into three tiers:

```
BLOCKING — Cannot start without answers:
  1. [question]
  2. [question]

IMPORTANT — Could start but would likely need to redo work:
  3. [question]
  4. [question]

NICE TO KNOW — Can make reasonable assumptions:
  5. [question] (default assumption: X)
  6. [question] (default assumption: Y)
```

For "nice to know" questions, state your default assumption. The user can correct you or accept the default.

### Phase 4: Present and Wait

Output all questions in the prioritized format above. Then STOP. Do not:
- Start coding while waiting
- Answer your own questions
- Make assumptions on BLOCKING questions
- Combine questions to reduce the count (clarity > brevity)

Wait for answers. If the user answers only some questions, re-ask the unanswered BLOCKING ones before proceeding.

## Rules

- **Never skip this skill to save time** — the time saved by asking is always greater than the time spent iterating on wrong assumptions
- **Never ask questions you can answer from the codebase** — read the code first, ask about what isn't there
- **Max 10 questions total** — if you have more, you need to split the task, not ask more questions
- **One question per topic** — don't bundle "What auth system and what roles and what permissions?" into one question
- **Be specific** — "How should errors be handled?" is bad. "When Stripe returns a card_declined error, should the user see the raw error or a friendly message?" is good
- **Include context in questions** — "I see you're using Supabase RLS. Should this new table follow the same `(select auth.uid()) = user_id` pattern?" is better than "How should we handle permissions?"

---
Nox
