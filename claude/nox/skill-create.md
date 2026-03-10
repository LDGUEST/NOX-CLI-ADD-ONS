---
name: skill-create
description: Create a new NOX skill in the correct format across Claude Code, Gemini CLI, and Codex CLI.
---

Create a new Nox skill in the correct format across all three CLIs (Claude Code, Gemini CLI, Codex CLI). This meta-skill ensures consistent structure, naming, and quality when expanding the Nox skill pack.

## When to Use

- When you want to add a new slash command to the Nox skill pack
- When converting an ad-hoc workflow into a reusable skill
- When porting a skill from another tool or skill pack into Nox format

## Process

### Step 1: Define the Skill

Before writing anything, answer these questions:

1. **Name** — lowercase, hyphenated, 1-3 words (e.g., `monitorlive`, `quick-phase`, `skill-create`)
   - Must be unique — check existing skills in `claude/nox/` first
   - Should be a verb or verb-noun (action-oriented)
   - Avoid generic names like `check`, `run`, `do`

2. **One-line description** — what does this skill do in one sentence?
   - Used in help listings, Gemini YAML frontmatter, README catalog
   - Start with a verb: "Generate...", "Audit...", "Deploy..."
   - Max 100 characters

3. **Category** — where does it fit in the skill catalog?
   - Pipelines, Code Quality, Development Workflow, Architecture & Planning
   - DevOps & Infrastructure, Security, Multi-Agent & Session Management, Meta

4. **Trigger phrase** — what would a user say to invoke this?
   - "I want to..." / "Can you..." / "Run a..."
   - This becomes the example in the README

5. **Blocking or advisory?** — does this skill block progress on failure, or just warn?

6. **Prerequisites** — does it require a running server, specific tools, GSD, etc.?

### Step 2: Write the Skill Content

Follow this template structure:

```markdown
[Opening directive — 1-2 sentences describing what the skill does and when to use it]

## When to Use
[3-5 bullet points describing trigger conditions]

## Process / Protocol / Pipeline
[The main content — numbered steps, phases, or sections]
[Each section should be actionable — tell the agent exactly what to do]
[Include decision points — "if X, do Y; if Z, do W"]
[Include skip conditions — "skip this step if..."]

## Output Format
[Show exactly what the output should look like]
[Use code blocks with example output]

## Rules
[5-10 rules that prevent common mistakes]
[Include anti-patterns — "don't do X because..."]

## Environment Variables (if applicable)
[Table of configurable env vars]

---
Nox
```

**Quality bar for skill content:**
- Every instruction must be specific enough that a different AI model could follow it without interpretation
- Include at least one concrete example or sample output
- Rules section must prevent the 3 most common failure modes for this type of task
- No vague instructions ("be thorough", "check carefully") — always specify WHAT to check and HOW
- Skills should be self-contained — don't require reading external docs to understand the skill

### Step 3: Create Files in All Three Formats

All three formats use YAML frontmatter. Required fields: `name` + `description`. Optional: `compatibility`, `metadata`, `allowed-tools`, `disable-model-invocation`.

**Claude Code** — `claude/nox/<name>.md`
```yaml
---
name: <name>
description: <trigger-optimized description, max 150 chars>
# Add these only when relevant:
# disable-model-invocation: true   ← for dangerous ops (deploy, push, unloop, overwrite)
# compatibility: Requires git, docker, etc.
# metadata:
#   author: nox
#   version: "1.0"
---
```
This is the canonical version — write it first.

**Gemini CLI** — `gemini/skills/<name>/SKILL.md`
- Same frontmatter as Claude version
- Content identical below the frontmatter
- Can add `references/` subdirectory for heavy reference material (bash examples, output templates)

**Codex CLI** — `codex/skills/<name>/SKILL.md`
- Same frontmatter as Claude version
- Content identical below the frontmatter
- Can add `references/` subdirectory for heavy reference material

### Step 4: Register the Skill

Update these files to include the new skill:

1. **`claude/nox/help-forge.md`** — Add to the correct category table, increment skill count
2. **`gemini/skills/help-forge/SKILL.md`** — Same update with YAML frontmatter preserved
3. **`codex/skills/help-forge/SKILL.md`** — Same update
4. **`README.md`** — Add entry in the Skill Catalog section under the correct category. Include:
   - Skill name in bold with backticks
   - One-line description
   - Example usage in blockquote italics
   - 1-2 sentence explanation
5. **Update all skill counts** — README header, catalog header, structure section, install instructions

### Step 5: Validate

Before committing, verify:

- [ ] File exists at `claude/nox/<name>.md` with YAML frontmatter
- [ ] File exists at `gemini/skills/<name>/SKILL.md` with YAML frontmatter
- [ ] File exists at `codex/skills/<name>/SKILL.md` with YAML frontmatter
- [ ] All three files have matching `name` and `description` fields
- [ ] `disable-model-invocation: true` added if skill is dangerous (deploy, push, destructive ops)
- [ ] `compatibility` field added if skill needs specific tools (Playwright, Docker, etc.)
- [ ] `help-forge.md` updated in all 3 formats with matching skill count
- [ ] `README.md` updated with new skill entry and correct counts
- [ ] Content is identical across all 3 formats (below the frontmatter)
- [ ] Skill ends with `---\nNox` footer
- [ ] No references to specific users, machines, IPs, or private infrastructure
- [ ] Skill works standalone — doesn't require other Nox skills to function (may recommend them, but doesn't depend on them)
- [ ] If SKILL.md body exceeds 200 lines, move bash examples/templates to `references/` subdirectory

### Step 6: Deploy

After committing and pushing to GitHub:

1. Run `bash install.sh` on the local machine to install
2. If install.sh doesn't detect the CLI, copy manually:
   - Claude: `cp claude/nox/<name>.md ~/.claude/commands/nox/`
   - Gemini: `cp -r gemini/skills/<name> ~/.gemini/extensions/nox/skills/`
   - Codex: `cp -r codex/skills/<name> ~/.agents/skills/`
3. Verify the skill appears: type `/nox:` in the CLI and check autocomplete

## Naming Conventions

| Pattern | Example | When to Use |
|---------|---------|-------------|
| Single verb | `review`, `deploy`, `test` | Core actions |
| Verb-noun | `skill-create`, `monitorlive` | When the verb alone is ambiguous |
| Adjective-noun | `quick-phase`, `full-phase` | Pipeline variants |
| Don't use | `run-check`, `do-thing`, `my-skill` | Too generic or personal |

## Common Mistakes

- **Too vague** — "Analyze the code and provide feedback" → needs specific criteria, output format, severity levels
- **Too rigid** — Hardcoding file paths, model names, or framework assumptions → use auto-detection
- **No output format** — The agent doesn't know what "done" looks like → always include a sample output
- **No skip conditions** — Not every skill applies to every project → say when to skip
- **No rules section** — Without guardrails, agents will over-engineer, hallucinate, or go in circles
- **Forgetting a format** — Created for Claude but forgot Gemini and Codex → always create all 3 with matching frontmatter
- **Missing `disable-model-invocation`** — Dangerous skills (deploy, push, unloop, overwrite) must have this set to prevent accidental auto-triggering from natural language
- **Stale counts** — Updated help-forge but forgot to update README skill count → check all locations

---
Nox
