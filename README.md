# MDDesign

> Glue layer for AI coding agents. Composes planning-with-files, Google's DESIGN.md, memory routing, agent teams, and session handoff into one orchestrator. Cross-IDE. No replacements.

[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![IDE Support](https://img.shields.io/badge/IDE-Claude_Code_·_Cursor_·_Codex_·_Windsurf_·_Cline-green.svg)](#ide-support)
[![Version](https://img.shields.io/badge/version-0.1.0-orange.svg)](CHANGELOG.md)

---

## What it does

You already use planning-with-files. You already use DESIGN.md (or want to). You already manage memory and agent dispatch by hand. MDDesign is the missing layer that wires them together so your agent sees the right design tokens at the right moment, dispatches the right subagent for the right phase, and never loses context after `/clear`.

It does not replace any underlying tool. It composes them.

## Commands

| Command | What it does |
|---|---|
| **`/mddesign:setup`** | Detect missing dependencies, print exact install steps for your platform |
| **`/mddesign:doctor`** | Six-probe diagnostic. Use when something is broken |
| `/mddesign:compose` | One-shot wiring check at the start of a project |
| `/mddesign:harvest` | Scan your codebase, write a structurally valid `DESIGN.md` at project root |
| `/mddesign:critique` | Five-pass audit: structural / drift / a11y / completeness / consistency |
| `/mddesign:fix <id>` | Apply one finding from the critique. HITL gated. Re-lints after every edit. |
| `/mddesign:inject` | Manually inject `DESIGN.md` tokens into the active phase's `findings.md` |
| `/mddesign:handoff` | Force a session catchup or memory promotion. Survives `/clear`. |
| `/mddesign:memory` | Three-tier memory: scratch / WHERE (QMD) / WHY (MemPalace) |
| `/mddesign:team` | Dispatch a phase to a specialist subagent via PhaseSpec v1 |

## What you get over raw planning-with-files

- **Design tokens follow you.** Every UI prompt sees the relevant slice of `DESIGN.md` injected into `findings.md`. No more agents inventing hex codes.
- **Code-to-DESIGN.md harvest.** Most repos do not have a DESIGN.md. `/mddesign:harvest` scans your existing code and writes one. The on-ramp for every existing project, not just greenfield.
- **Sessions survive `/clear`.** Stop hook stamps a handoff. SessionStart hook reads the last stamp + the most recent decisions from MemPalace and rebuilds context in one paragraph.
- **Decisions persist forever.** Three-tier memory: scratch (file-tier, fast), WHERE (QMD, locational), WHY (MemPalace, decisions). Promotions to WHY are HITL gated.
- **Specialist subagents on demand.** Hand a phase to a `design-archeologist` for harvest, a `memory-keeper` for classification, an `executor` for the rest. PhaseSpec v1 is the only handoff format.

## Quickstart

### 1. Install

```bash
# Add the marketplace
/plugin marketplace add OthmanAdi/MDDesign

# Install the plugin
/plugin install mddesign@mddesign
```

### 2. Verify dependencies

```bash
/mddesign:setup
```

This walks you through every missing dependency with exact install steps. Safe to run multiple times.

Required:
- Node + `npx` (for `@google/design.md` lint)
- [`planning-with-files`](https://github.com/obra/planning-with-files) skill

Optional but recommended:
- [`code-memory-router`](https://github.com/OthmanAdi/code-memory-router) skill (powers WHY/WHERE tiers)
- MemPalace MCP (powers WHY tier persistence)
- QMD MCP (powers WHERE tier search)

### 3. Use it

```bash
# In any project
/mddesign:compose          # check the wiring
/mddesign:harvest          # generate DESIGN.md from your existing code
/mddesign:critique         # audit it for drift, a11y, completeness
```

That is the whole inner loop.

## How the pieces fit

```
your existing code
   │
   ▼
/mddesign:harvest ──► DESIGN.md  (Google Labs spec, lint-validated)
                        │
                        ▼
                   /mddesign:critique  ──► DESIGN.md.critique.md
                        │
                        ▼
on every UI phase, design-bridge auto-injects the relevant token slice
into findings.md "## Design Context" — your agent reads it on every turn

                        │
                        ▼
       /mddesign:team dispatch  ──► specialist subagent (PhaseSpec v1)
                        │
                        ▼
       /mddesign:memory   scratch  ◄── session ends, Stop hook fires
                          WHERE   ◄── QMD via code-memory-router
                          WHY     ◄── MemPalace, HITL gated

                        │
                        ▼
         /mddesign:handoff  ── SessionStart catchup pulls last
                              decisions back into context
```

Full architecture: [docs/architecture.md](docs/architecture.md).

## Core preservation rules

These are load-bearing. MDDesign exists *because* it does not violate them.

1. `planning-with-files` core untouched. Never write to `task_plan.md`.
2. `DESIGN.md` only written under explicit user action (`/mddesign:harvest` or `/mddesign:fix`).
3. Memory is a layer on top of `code-memory-router`, never a replacement.
4. Subagents share state via markdown on disk. No in-memory shared store.
5. Structural DESIGN.md validation delegated to `npx @google/design.md lint`. Never reimplement Google's linter.

## IDE support

| IDE | Sync dir | Skills | Agents | Commands | Hooks |
|---|---|---|---|---|---|
| Claude Code | (canonical) | yes | yes | yes | yes |
| Cursor | `.cursor/` | yes | yes | yes | manual |
| Codex CLI | `.codex/` | yes | yes | yes | manual |
| Windsurf | `.windsurf/` | yes | yes | yes | manual |
| Cline | `.clinerules/` | yes | no | no | n/a |
| OpenCode | `.opencode/` | yes | yes | yes | manual |

Mirrors regenerated by `python scripts/sync-ide-folders.py` before each release.

## Example

A walkthrough is in [examples/basic-react-app/](examples/basic-react-app/) showing what `task_plan.md`, `findings.md` (with the auto-injected `## Design Context` block), and a harvested `DESIGN.md` actually look like for a small React project.

## Project layout

```
MDDesign/
├── README.md
├── LICENSE                          Apache-2.0
├── CONTRIBUTING.md
├── CHANGELOG.md
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── hooks/
│   ├── hooks.json
│   ├── session-start/
│   ├── prompt-submit/
│   ├── pre-tool-use/
│   └── stop/
├── skills/
│   ├── design-bridge/SKILL.md       runtime: DESIGN.md → findings.md
│   ├── design-harvest/SKILL.md      harvest + critique + fix
│   ├── memory-layer/SKILL.md        three-tier memory
│   ├── session-handoff/SKILL.md     catchup + promote
│   └── team-dispatch/SKILL.md       PhaseSpec v1 dispatch
├── commands/                        slash commands (10)
├── agents/                          subagent definitions
├── docs/architecture.md
├── examples/basic-react-app/        walkthrough
├── tests/                           smoke tests (bash + PowerShell)
└── scripts/sync-ide-folders.py
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Short version: feature-branch PRs, no Co-Authored-By, smoke tests must pass on both bash and PowerShell.

## License

Apache-2.0. Same as Google Labs DESIGN.md and `planning-with-files`.
