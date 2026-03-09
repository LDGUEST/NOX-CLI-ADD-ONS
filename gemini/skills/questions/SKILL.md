---
name: questions
description: Extract all clarifying questions before writing any code — remove ambiguity in one shot
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
1. Read the project's context files, package.json/go.mod/Cargo.toml, and directory structure
2. Identify the tech stack, auth system, database, and deployment target
3. Check if similar features already exist in the codebase
4. Note any constraints mentioned in the user's request

### Phase 2: Question Generation

Generate questions across these categories. Skip categories already answered by context. Prioritize by impact.

- **Scope & Boundaries** — What's included vs out of scope? New feature, modification, or replacement? MVP vs ideal?
- **Data Flow & State** — Where does data come from? What shape? How is state managed?
- **UI/UX & Interactions** — What should the user see? What interactions? Loading/empty/error states?
- **Auth & Permissions** — Who can access this? Different views per role?
- **Edge Cases & Error Handling** — Invalid input? External service down? Rate limits?
- **Integration Points** — External services, webhooks, event triggers?
- **Performance & Scale** — Expected volume? Response time targets? Caching needs?

### Phase 3: Prioritize and Present

Sort questions into three tiers:

```
BLOCKING — Cannot start without answers:
  1. [question]

IMPORTANT — Could start but would likely redo work:
  2. [question]

NICE TO KNOW — Can make reasonable assumptions:
  3. [question] (default assumption: X)
```

For "nice to know" questions, state your default assumption. Then STOP and wait for answers. Do not start coding, answer your own questions, or make assumptions on BLOCKING items.

## Rules

- **Never skip this skill to save time** — asking is always faster than iterating on wrong assumptions
- **Never ask questions you can answer from the codebase** — read the code first
- **Max 10 questions total** — if you have more, the task needs splitting
- **One question per topic** — don't bundle multiple concerns into one question
- **Be specific** — "When Stripe returns card_declined, should the user see the raw error or a friendly message?" not "How should errors work?"
- **Include context** — "I see you're using Supabase RLS. Should this new table follow the same pattern?" is better than "How should we handle permissions?"

---
Nox
