---
name: armor
description: Add NOX-ARMOR protection headers to files and subsystems. Use when locking down battle-tested code against casual AI modification.
metadata:
  author: nox
  version: "1.6"
---

Add protection headers and safe-modification instructions to files and subsystems. Use when code is battle-tested and must not be casually modified by future agents or sessions.

## When to Use

- After stabilizing a critical subsystem (scanners, pipelines, engines, utilities)
- When a file has a history of being broken by AI "improvements"
- When the user says "lock this down", "protect this", or "armor this"
- After fixing a hard bug that should never be reintroduced
- On context files (CLAUDE.md, MEMORY.md) to prevent agent drift and bloat

## Arguments

`$ARGUMENTS` — Target: file path(s), directory, or subsystem name. If empty, ask what to protect.

## Process

### Step 1: Identify targets

If given a directory or subsystem name, find all critical files in it:
```bash
# Adapt to project language
find <path> -maxdepth 1 -type f \( -name "*.py" -o -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.md" -o -name "*.go" -o -name "*.rs" \)
```

For each file, read the first 30 lines to check if it already has a PROTECTED MODULE header or a `NOX-ARMOR` comment. Skip files that are already armored.

### Step 2: Gather context per file

For each unprotected file, understand:
1. **What it does** — read any existing docstring, header comment, or first 50 lines
2. **Who uses it** — grep for imports, references, or includes across the project
3. **What it depends on** — read the imports/requires section
4. **Known bugs** — check git log: `git log --oneline -20 -- <file>`
5. **Hardcoded safety values** — thresholds, caps, rate limits, critical constants that must not change

### Step 3: Write the protection header

Use the appropriate comment syntax for the file type:

**For code files (.py, .ts, .js, .go, .rs, etc.):**

Insert or replace the file's top-level docstring/comment with an expanded version:

```
<language-appropriate comment block>
<Original title line>
PROTECTED MODULE — DO NOT modify without explicit permission from the project owner.
<1-2 sentence description of what breaks if this file breaks.>

HARD RULES:
  - <Rule 1: specific thing that must not change, and WHY>
  - <Rule 2: another invariant>
  - <Rule 3: etc.>

KNOWN BUG HISTORY:
  - <date>: <what broke> — <root cause> (fixed)

<Rest of original docstring/comment>
</language-appropriate comment block>
```

**For context files (.md — CLAUDE.md, MEMORY.md, etc.):**

Insert at the very top of the file:

```markdown
<!-- NOX-ARMOR v1 | locked: <comma-separated locked section names> | max-lines: <number> | audit: <YYYY-MM-DD> -->
```

Then before each locked section, add:
```markdown
<!-- LOCKED — do not modify without explicit permission -->
```

Before mutable sections, add:
```markdown
<!-- MUTABLE — agents may update this section -->
```

**For config files (.json, .yaml, .toml, etc.):**

Add a top-level comment (if the format supports it) or a dedicated `_armor` key:
```json
{
  "_armor": "NOX-ARMOR v1 — do not modify keys marked LOCKED without explicit permission",
  ...
}
```

### Comment syntax reference

| Extension | Comment style |
|-----------|--------------|
| `.py` | `"""..."""` docstring or `# ...` |
| `.ts`, `.tsx`, `.js`, `.jsx` | `/**...*/` or `// ...` |
| `.go` | `// ...` block |
| `.rs` | `//! ...` (module-level) or `// ...` |
| `.md` | `<!-- ... -->` HTML comment |
| `.yaml`, `.yml` | `# ...` |
| `.toml` | `# ...` |
| `.json` | No native comments — use `_armor` key or companion `.armor.json` |
| `.sql` | `-- ...` |
| `.sh`, `.bash` | `# ...` |

### Rules for writing headers

- Be SPECIFIC. "Do not change thresholds" is bad. "RATE_LIMIT=100 — do NOT lower, was 50 before and caused cascade failures" is good.
- Reference REAL incidents from git history. If there's no bug history, write "No known incidents yet" — do NOT fabricate.
- Name downstream consequences. "If this breaks, X, Y, and Z all fail."
- Include exact values for caps, thresholds, and limits that are safety-critical.
- For context files, ask the user which sections to lock vs leave mutable.

### Step 4: Update the nearest CLAUDE.md

Find the nearest CLAUDE.md (same directory or parent). Add or update:

1. **Protected Modules table** — list every protected file with what breaks if touched
2. **"How To Safely Modify" section** if it doesn't exist:

```markdown
## How To Safely Modify Protected Files

### Step 1: Read before you write
1. Read this CLAUDE.md
2. Read the PROTECTED header in the target file
3. Read the function/section you're changing + surrounding context
4. Search for all callers/consumers of what you're modifying

### Step 2: Make SURGICAL changes
- Edit ONLY the function/block needed. Do NOT touch surrounding code.
- Do NOT rename functions, change signatures, or reorder parameters.
- Do NOT "improve" imports, formatting, or variable names you didn't need to change.
- If adding a feature, ADD new functions — do NOT modify existing signatures.

### Step 3: Verify before commit
- Run the project's test suite
- Verify syntax: use the language-appropriate linter/parser
- Manually test the affected flow

### Common safe changes (no approval needed)
- <list things agents CAN do freely — ask user>

### Changes that ALWAYS need approval
- <list things that require explicit permission — ask user>
```

3. **Known Bug History table** if incidents exist

### Step 5: Update root context (if major subsystem)

If the armored subsystem is significant (>5 files, critical path), add a one-line rule to the project root `CLAUDE.md`:
```
- **<SUBSYSTEM> IS PROTECTED** — N files have PROTECTED headers. Read <path>/CLAUDE.md before touching any file.
```

### Step 6: Verify and report

Run language-appropriate syntax checks on all modified files:
- Python: `python3 -c "import ast; ast.parse(open('FILE').read())"`
- TypeScript/JavaScript: `npx tsc --noEmit` or `node -c FILE`
- Go: `go vet ./...`
- Rust: `cargo check`
- Markdown: verify the armor comment is valid HTML comment syntax
- Other: at minimum, confirm the file is parseable

## Output

After armoring, print:

```
ARMOR REPORT
━━━━━━━━━━━━
Files armored: N
  ✓ file1.ts (NEW — added protection header)
  ✓ file2.md (NEW — added NOX-ARMOR + locked 3 sections)
  ⊘ file3.py (SKIP — already protected)

CLAUDE.md updates:
  ✓ path/CLAUDE.md — added Protected Modules table + safe modification protocol
  ✓ CLAUDE.md (root) — added protection rule

Verification: all N files pass syntax/lint check
```

## Rules

- Don't remove or downgrade existing PROTECTED headers — armor only ever increases, never weakens.
- Skip test files unless the user specifically asks. Tests need to be easy to change; locking them defeats the purpose.
- Read the file's git history before writing the KNOWN BUG HISTORY section. Fabricated incidents destroy the credibility of the header.
- The safe modification protocol matters as much as the protection header itself — a locked file with no guidance on how to safely change it just frustrates future agents.
- For context files (.md), ask the user which sections to lock vs leave mutable. Assuming locks on the wrong sections creates more problems than it solves.
- The NOX-ARMOR comment in markdown must be a valid HTML comment on line 1 — invalid syntax means Claude won't detect it as armored.
- Armor headers are guardrails, not bureaucracy. Write them to be helpful, not intimidating.
- Global system files (`~/.claude/CLAUDE.md`, `~/.claude/settings.json`, `~/.gemini/GEMINI.md`) are read-only. Only modify project-scoped files (`./CLAUDE.md`, `./MEMORY.md`, `./DEBUGGING.md`). If the user asks to modify a global file, explain why and redirect them to do it manually.

---
Nox
