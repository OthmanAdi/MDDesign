# AGENTS.md — MDDesign

Orientation file for any coding agent working in this repo or in a project that has MDDesign installed.

## What MDDesign is

An orchestrator plugin. It composes `planning-with-files` and `DESIGN.md` (both unchanged) and adds memory routing, agent-team dispatch, session handoff, and code-to-DESIGN.md harvest with critique.

## What MDDesign is not

A replacement for any of those tools. If you find yourself rewriting `planning-with-files` behavior, the `DESIGN.md` spec, or the `code-memory-router` API, stop. That is out of scope.

## Files in a project that uses MDDesign

| File | Owner | MDDesign access |
|---|---|---|
| `task_plan.md` | planning-with-files | read only |
| `findings.md` | planning-with-files | append to `## Design Context` only |
| `progress.md` | planning-with-files | append to `### Phase <id> Result` only |
| `DESIGN.md` (root) | user OR `/mddesign:harvest` | read; write only via `/mddesign:harvest` and `/mddesign:fix` |
| `DESIGN.md.critique.md` | `design-harvest` | full ownership |
| `.agents/memory/scratch/` | `memory-layer` | full ownership |

## Hook lifecycle

| Hook | What it does |
|---|---|
| SessionStart | Detect planning-with-files + DESIGN.md, run catchup, nudge `/mddesign:harvest` if UI files but no DESIGN.md. |
| UserPromptSubmit | If active phase mentions UI keywords and DESIGN.md exists, fire `design-bridge` to inject the relevant tokens into findings.md. |
| PreToolUse | HITL gate at named checkpoints (UI file writes, subagent dispatch, MemPalace promotion, DESIGN.md writes). |
| Stop | Run `memory-keeper` to classify session output and promote stable rationale to MemPalace via HITL. |

## Subagents

| Name | Purpose |
|---|---|
| `planner` | Drafts a PhaseSpec from a plan phase. |
| `executor` | Consumes a PhaseSpec, returns a structured result. |
| `reviewer` | HITL surrogate when auto-approve is on. |
| `memory-keeper` | Classifies session output into scratch / WHERE / WHY tiers. |
| `design-archeologist` | Long-running codebase scan for `/mddesign:harvest`. |

PhaseSpec v1 is the dispatch contract. See `skills/team-dispatch/SKILL.md`.

## License

Apache-2.0
