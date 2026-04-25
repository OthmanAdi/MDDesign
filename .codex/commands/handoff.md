---
description: Force a session catchup or a memory promotion outside the hook lifecycle. Default is catchup (read-only); promote is HITL gated.
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep"]
argument-hint: "[catchup|promote]"
---

# /mddesign:handoff

Manual session handoff operations.

## Subcommands

### `/mddesign:handoff catchup` (default)
Runs the SessionStart catchup logic now. Read-only.

1. Read `task_plan.md`, `findings.md`, `progress.md`.
2. Glob `.agents/memory/scratch/**/*.md`, read recent entries.
3. Recall last WHY from MemPalace via `/memory-router`.
4. Print a one-paragraph "where we are" preamble.
5. Surface any nudges (missing DESIGN.md, missing planning files, missing memory router).

### `/mddesign:handoff promote`
Runs the Stop promotion logic now. Useful before a planned `/clear`.

1. Dispatch `memory-keeper` subagent to classify recent work.
2. For each WHY candidate, HITL gate (named checkpoint: `before_mempalace_write`).
3. On approval, `memory-layer` skill drives `/memory-router` save.
4. Append `### Handoff <timestamp>` to `progress.md`.

## Usage examples

```
/mddesign:handoff                 # same as catchup
/mddesign:handoff catchup         # read planning + scratch + last WHY, print preamble
/mddesign:handoff promote         # pre-emptive stop promotion before /clear
```

## Boundaries

- catchup never writes.
- promote writes only under HITL approval.
- Never edits `task_plan.md`.

See skills/session-handoff/SKILL.md for full logic.
