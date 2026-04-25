---
description: Save or recall via the three-tier memory layer. Routes to scratch (file-tier), WHERE (QMD via code-memory-router), or WHY (MemPalace via code-memory-router). Every WHY-tier write goes through the HITL gate.
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep"]
argument-hint: "save [--tier scratch|where|why] <text> | recall <query>"
---

# /mddesign:memory

Three-tier memory operations.

## Save

### `/mddesign:memory save <text>` (default tier: scratch)
Appends to `.agents/memory/scratch/<topic>.md` where `<topic>` is the active phase id from `task_plan.md`, or `general` if no plan. Fast, low-stakes, session-scoped.

### `/mddesign:memory save --tier why <text>`
Proposes a promotion to MemPalace WHY tier. HITL gate before write. On approval, invokes `/memory-router` with MemPalace save pattern.

### `/mddesign:memory save --tier where <text>`
WHERE is populated by QMD automatically when it indexes project markdown. Explicit write is rarely needed; this sub-command exists for completeness and is rate-limited to one-line annotations.

## Recall

### `/mddesign:memory recall <query>`
Routes based on query prefix:
- "where", "which file", "find", "locate" → WHERE via `/memory-router`
- "why", "decision", "history", "what did we decide" → WHY via `/memory-router`
- Otherwise → peek at scratch first, fall back to WHERE

Always prints the source tier next to each result.

## Boundaries

- Never edits `task_plan.md`, `findings.md`, or `progress.md`.
- Scratch lives in `.agents/memory/scratch/`. Never elsewhere.
- MemPalace writes always HITL gated.

See skills/memory-layer/SKILL.md for full routing logic and conventions.
