---
name: overwrite
description: Replaces all prior context and decisions about a specific component with the latest input as the new source of truth. Use when changing direction on a feature, overriding earlier architecture choices, or telling the agent to forget the old approach and start fresh.
disable-model-invocation: true
argument-hint: "[component]"
metadata:
  author: nox
  version: "1.6"
---

Treat my latest input as an absolute state update. Overwrite and purge any conflicting previous context, rules, or architectural decisions we've discussed regarding this specific component.

Do not stack this information on top of old data — this is the new, definitive source of truth.

Briefly confirm exactly what outdated assumptions you are discarding so I know our context is perfectly clean before we proceed.

---
Nox