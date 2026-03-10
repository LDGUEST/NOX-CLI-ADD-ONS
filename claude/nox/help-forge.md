---
name: help-forge
description: List all available NOX skills with descriptions and usage examples.
metadata:
  author: nox
  version: "1.6"
---

List all available Nox skills. For each one, provide:
- The skill name (slash command)
- A one-line description of what it does
- When to use it

## Nox Skills Catalog (33 skills + 8 agents + 19 hooks)

### Pipelines
| Skill | Description |
|-------|-------------|
| `/nox:full-phase` | Plan-to-ship pipeline — 6 quality gate agents dispatch in parallel |
| `/nox:quick-phase` | Lightweight plan-to-commit for prototypes and internal tools |

### Code Quality
| Skill | Description |
|-------|-------------|
| `/nox:audit` | Deep technical audit — bugs, security, perf, dead code, accessibility, dependency health |
| `/nox:review` | PR-style code review with severity ratings, suggested fixes, and complexity check |
| `/nox:refactor` | Targeted refactoring with behavior-preserving safety net |
| `/nox:perf` | Performance profiling — bundle size, queries, rendering, memory |
| `/nox:uxtest` | Comprehensive Playwright UX testing — visual audit, interactions, accessibility, performance |
| `/nox:prompt` | Audit and optimize LLM prompts for reliability, cost, safety, and output quality |

### Development Workflow
| Skill | Description |
|-------|-------------|
| `/nox:tdd` | Red-green-refactor enforcement — test-first development and test generation |
| `/nox:commit` | Generate Conventional Commits message from staged changes |
| `/nox:changelog` | Generate CHANGELOG.md from git history |
| `/nox:iterate` | Autonomous sub-agent execution with verification loop |

### Architecture & Planning
| Skill | Description |
|-------|-------------|
| `/nox:brainstorm` | Structured divergent thinking — explore 3+ approaches before converging on architecture |
| `/nox:architect` | Design-first gate — no code until architecture is approved |
| `/nox:questions` | Extract all clarifying questions before writing any code |
| `/nox:landing` | Draft a conversion-focused landing page from scratch |

### DevOps & Infrastructure
| Skill | Description |
|-------|-------------|
| `/nox:cicd` | Generate CI/CD workflow with auto-detected framework support |
| `/nox:deploy` | 5-step deploy protocol: preflight → backup → deploy → verify → report |
| `/nox:push` | Push to production with platform auto-detection and retry logic |
| `/nox:diagnose` | Cross-machine system health check, status report, and error investigation |
| `/nox:monitorlive` | Real-time log monitoring — watches live traffic, surfaces errors and anomalies during testing |
| `/nox:migrate` | Database migration generator — auto-detects ORM and framework |

### Security
| Skill | Description |
|-------|-------------|
| `/nox:security` | OWASP Top 10 security scan with remediation guidance — includes scan and pentest modes |

### Multi-Agent & Session Management
| Skill | Description |
|-------|-------------|
| `/nox:syncagents` | Safe multi-agent repo sync (stash, pull, merge) |
| `/nox:handoff` | End-of-session knowledge capture and transfer protocol |
| `/nox:unloop` | Unattended autonomous repair with zero-regression mandate |
| `/nox:overwrite` | Context reset — purge stale assumptions, set new truth |
| `/nox:help-forge` | This catalog |

### Context Engineering
| Skill | Description |
|-------|-------------|
| `/nox:armor` | Add protection headers and safe-modification instructions to files and subsystems |
| `/nox:context-engineer` | Discover, audit, and govern all AI context files — health scoring, armor enforcement, cross-project sync |

### Meta
| Skill | Description |
|-------|-------------|
| `/nox:update` | Check for updates and install latest skills from GitHub |
| `/nox:skill-create` | Create a new Nox skill in the correct format across all 3 CLIs |
| `/nox:guardrails` | Safety guardrails — inline checks that mirror Claude Code hooks for Gemini/Codex users |

### Agents (subagents dispatched by `/nox:full-phase`)
| Agent | Role |
|-------|------|
| `nox-reviewer` | Cross-file code review — correctness, security, performance, design, tests |
| `nox-security-scanner` | OWASP Top 10 static analysis with CWE references |
| `nox-pentester` | Live exploitation — 5-phase white-box pentest with proof-of-concept |
| `nox-dep-auditor` | CVE detection, outdated packages, license compliance, supply chain risk |
| `nox-perf-profiler` | N+1 queries, bundle size, memory leaks, Core Web Vitals |
| `nox-ux-tester` | Playwright screenshots at 4 breakpoints, interaction testing, accessibility |
| `nox-prompt-auditor` | LLM prompt audit across 8 dimensions with cost estimates (standalone) |
| `nox-monitor` | Background log monitoring with anomaly detection (standalone) |

### MCP Server
All skills and agents are also available via MCP. Any MCP-compatible client can invoke `nox_list`, `nox_skill`, or `nox_agent`.

---
Nox
