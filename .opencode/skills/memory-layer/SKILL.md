---
name: memory-layer
description: Three-tier memory layer for the orchestrator. Routes scratch (file-tier), WHERE (QMD), and WHY (MemPalace) through the existing code-memory-router slash command. Never edits planning files directly. Every WHY-tier promotion goes through the HITL gate.
user-invocable: true
allowed-tools: "Read Write Edit Bash Glob Grep"
metadata:
  version: "0.1.0"
  arm: memory
  tiers: ["scratch", "where", "why"]
---

# Memory Layer

Three-tier wrapper on top of `code-memory-router` plus a local file-tier scratchpad.

## Tiers

| Tier | Purpose | Backend | Lifetime |
|---|---|---|---|
| **scratch** | Volatile session notes, in-flight findings | `.agents/memory/scratch/<topic>.md` (file-tier) | Session, until promoted or `/mddesign:handoff promote` |
| **WHERE** | Locational queries (where is X, which file, which directory) | QMD via `/memory-router` | Project lifetime |
| **WHY** | Decisions, rationale, post-mortems, "we picked X because" | MemPalace drawers via `/memory-router` | Forever |

## Operations

### `/mddesign:memory save <text>` (default tier: scratch)

1. Determine the active topic. The active phase id from `task_plan.md` is the default topic. If no plan exists, use `general`.
2. Append `<text>` plus an ISO timestamp to `.agents/memory/scratch/<topic>.md`. Create parent directories if needed.
3. Print confirmation: "Saved to scratch / topic=<topic>".

### `/mddesign:memory save --tier why <text>`

1. Print the text to the user with a clear "About to promote to MemPalace WHY tier. Approve? [y/N]" line.
2. The PreToolUse hook intercepts the next Bash or `/memory-router` invocation (named checkpoint: `before_mempalace_write`).
3. On approval, invoke `/memory-router` with the canonical "save to MemPalace" pattern documented in code-memory-router's SKILL.md. Pass the text plus a project tag derived from CWD basename.
4. On the same approval, append a marker to `.agents/memory/scratch/<topic>.md`: "PROMOTED to MemPalace at <timestamp>." The original scratch entry stays in place for the rest of the session for context continuity.

### `/mddesign:memory recall <query>`

Routing rule:
- If the query starts with "where", "which file", "find", "locate", route to WHERE.
- If the query starts with "why", "decision", "history", "what did we decide", route to WHY.
- Otherwise, peek at scratch first; if nothing matches, fall back to WHERE.

Routing target:
- WHERE → invoke `/memory-router` and let the router dispatch to QMD.
- WHY → invoke `/memory-router` and let the router dispatch to MemPalace.
- scratch → grep `.agents/memory/scratch/**/*.md` for the query.

Always print the source tier next to each result so the user sees provenance.

## Stop hook integration

On Stop, the `memory-keeper` subagent runs and proposes promotions. This skill is the executor: when memory-keeper returns a list of WHY candidates, this skill drives `/mddesign:memory save --tier why` for each (each one HITL gated). Anything not promoted stays in scratch and is available for next session if `session-handoff` is configured.

## Core rules

- Never edit `task_plan.md`, `findings.md`, or `progress.md` directly. Memory is a separate file space.
- Never write to MemPalace without HITL approval.
- Never bypass `code-memory-router`. If you cannot reach it, fail loudly and tell the user to install `code-memory-router`.
- Scratch directory is `.agents/memory/scratch/`. Never put memory in `task_plan.md` or `findings.md`.

## External dependencies

- `code-memory-router` skill (the user's, required) — routes WHERE to QMD and WHY to MemPalace
- File-tier scratch needs no install
- Claude Memory Tool integration (Anthropic Messages API tool type `memory_20250818`) is reserved for v0.2 once it is exposed via MCP for cross-IDE use. v0.1.0 ships file-tier scratch as the substitute that works today on every coding agent.

## Example

User runs `/mddesign:memory save Decided to use Postgres over SQLite for the memory store, scaling concern.`

This skill:
1. Reads `task_plan.md` to find the active phase id (e.g., `phase-2-data-model`).
2. Appends to `.agents/memory/scratch/phase-2-data-model.md`:
   ```
   ## 2026-04-23T10:30:00Z
   Decided to use Postgres over SQLite for the memory store, scaling concern.
   ```
3. Prints "Saved to scratch / topic=phase-2-data-model"

Later in the session the user says `/mddesign:memory recall why postgres`. This skill:
1. Routes to WHY because of "why" prefix.
2. Invokes `/memory-router` to query MemPalace.
3. If MemPalace returns nothing yet, falls back to grep on `.agents/memory/scratch/**/*.md`.
4. Surfaces the entry above with `[source: scratch]` next to it.

On Stop, `memory-keeper` flags this entry as a WHY candidate. The user approves. This skill promotes via `/memory-router`. Next session, `/mddesign:memory recall why postgres` returns from MemPalace with `[source: WHY]`.
