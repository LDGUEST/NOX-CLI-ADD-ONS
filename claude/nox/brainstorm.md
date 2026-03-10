---
name: brainstorm
description: Structured ideation before architecture or code. Forces broad solution-space exploration before committing to an approach.
metadata:
  author: nox
  version: "1.6"
---

Structured ideation and divergent thinking before any architecture or code. This skill forces you to explore the solution space broadly before converging on a single approach. It prevents the most expensive engineering mistake: building the wrong thing well.

## When to Use

- Before `/nox:architect` — brainstorm first, architect second
- When the task has multiple valid approaches and you're not sure which is best
- When requirements are vague ("make it faster", "add auth", "improve UX")
- When you're about to build something complex and want to pressure-test the idea

## Process

### Phase 1: Problem Framing (don't skip this)

Before generating solutions, nail down the actual problem:

1. **State the problem in one sentence** — if you can't, the problem isn't clear enough
2. **Who has this problem?** — end user, developer, ops team, business?
3. **What happens if we do nothing?** — establishes urgency and priority
4. **What does "done" look like?** — concrete success criteria, not vibes
5. **What are the constraints?** — time, budget, tech stack, backward compatibility, team size

Output a **Problem Brief**:
```
PROBLEM: [one sentence]
WHO: [affected party]
IMPACT OF INACTION: [what breaks or degrades]
SUCCESS CRITERIA: [measurable outcomes]
CONSTRAINTS: [hard limits]
```

### Phase 2: Divergent Exploration (generate breadth)

Generate **at least 3 fundamentally different approaches**. Not variations on a theme — genuinely different strategies. For each approach:

1. **Name it** — a memorable 2-3 word label (e.g., "Event-Driven Pipeline", "Brute Force Cron", "Client-Side Only")
2. **Core idea** — one paragraph explaining the approach
3. **Architecture sketch** — key components and how they connect (text diagram)
4. **Tech choices** — specific libraries, services, patterns
5. **Tradeoffs** — what you gain and what you sacrifice
6. **Risk factors** — what could go wrong, what's unknown
7. **Effort estimate** — T-shirt size (S/M/L/XL) with reasoning
8. **Killer question** — the one question that would kill this approach if answered badly

Push yourself to include at least one unconventional approach — the "what if we did it completely differently?" option. Often the best solution isn't the first one that comes to mind.

### Phase 3: Evaluation Matrix

Score each approach on these dimensions (1-5):

| Dimension | Weight | Description |
|-----------|--------|-------------|
| **Correctness** | 5x | Does it actually solve the stated problem? |
| **Simplicity** | 4x | How simple is the implementation and maintenance? |
| **Speed to ship** | 3x | How quickly can we get a working version? |
| **Scalability** | 2x | Will it handle 10x growth without rewrite? |
| **Reversibility** | 3x | How easy is it to change course if this is wrong? |
| **Team fit** | 2x | Does it match the team's existing skills and stack? |
| **User impact** | 4x | How much does the end user benefit? |

Calculate weighted scores. Present as a comparison table.

### Phase 4: Convergence

Based on the evaluation:

1. **Recommend one approach** with clear reasoning
2. **Identify the top risk** and propose a mitigation
3. **Define the minimum viable slice** — what's the smallest version we can build to validate the approach?
4. **List open questions** that need answers before committing
5. **Suggest a kill criterion** — "If X happens during implementation, abandon this approach and switch to Y"

### Phase 5: Handoff to Architecture

Output a structured brief for `/nox:architect`:

```
RECOMMENDED APPROACH: [name]
CORE IDEA: [one paragraph]
KEY COMPONENTS: [list]
TECH CHOICES: [list with reasoning]
OPEN QUESTIONS: [list]
MINIMUM VIABLE SLICE: [description]
KILL CRITERION: [when to pivot]
```

## Rules

- **No code in this phase** — not even pseudocode. This is pure thinking.
- **No premature convergence** — don't pick a winner until Phase 3 is complete. The goal of Phase 2 is quantity and diversity, not quality.
- **Challenge assumptions** — for each approach, ask "what if the opposite were true?"
- **Time-box yourself** — if you've been in Phase 2 for more than 10 minutes on a single approach, move on. Breadth beats depth here.
- **Include the obvious AND the weird** — the conventional approach and at least one that feels uncomfortable. The weird ones often reveal insights even if they're not the winner.
- **Pause after Phase 4** — present the recommendation and wait for approval before handing off to architect.

## Anti-Patterns to Avoid

- **Solution shopping** — don't start with "I want to use X" and work backward to justify it
- **Analysis paralysis** — 3-5 approaches is plenty. Don't generate 12.
- **Groupthink with yourself** — if all your approaches look similar, you haven't diverged enough
- **Ignoring constraints** — a brilliant solution that violates a hard constraint is worthless
- **Premature optimization** — "but what about scale?" is not relevant for a prototype

---
Nox
