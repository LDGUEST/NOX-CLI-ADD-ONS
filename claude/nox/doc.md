---
name: doc
description: Generates documentation from code — JSDoc, docstrings, README sections, API docs. Use when code lacks inline docs or you need to produce a documentation artifact.
disable-model-invocation: true
argument-hint: "[target]"
metadata:
  author: nox
  version: "2.5"
---

Generate documentation for the specified target (file, directory, module, or function). Detect the project language and produce docs that match existing conventions.

## Process

1. **Detect project language and doc style** — Check existing docs for format conventions (JSDoc, TSDoc, Python docstrings, Rust doc comments, Go godoc, etc.)
2. **Scan the target** — Identify all exported functions, classes, types, interfaces, and constants
3. **Skip already-documented code** — Only generate docs for items that are missing or have incomplete documentation
4. **Generate inline docs** — Write documentation directly above each undocumented export
5. **Optionally generate a README section** — If the user requests it or the module has no README entry

## Detection Rules

| Language | Doc Format | Trigger |
|----------|-----------|---------|
| TypeScript/JavaScript | TSDoc / JSDoc (`/** */`) | `.ts`, `.tsx`, `.js`, `.jsx` |
| Python | Google-style docstrings | `.py` |
| Rust | `///` doc comments | `.rs` |
| Go | `//` godoc comments | `.go` |
| Other | Infer from existing docs or use `/** */` | fallback |

## What to Document

- **Functions/Methods** — Purpose, parameters (name, type, description), return value, throws/raises
- **Classes/Interfaces** — Purpose, usage example if non-obvious
- **Type aliases / Enums** — What each variant or property represents
- **Constants** — Why this value, not just what it is
- **Modules** — Top-of-file summary when the filename isn't self-explanatory

## Rules

- **Match existing style** — If the project uses `@param` tags, use them. If it uses inline descriptions, do that. Never mix styles within a project.
- **Be concise** — One sentence for simple functions. Longer docs only when behavior is non-obvious.
- **Skip trivial code** — Getters, setters, and self-evident one-liners don't need docs.
- **Include examples** — Only when the function signature doesn't make usage obvious (complex generics, overloaded behavior, side effects).
- **Never fabricate behavior** — Document what the code actually does, not what you think it should do. Read the implementation.

## Output

- Present the documented code inline (show the doc comment + function signature, not the full body)
- If generating a README section, format as Markdown with a table of exports
- Wait for approval before writing changes to files

---
Nox
