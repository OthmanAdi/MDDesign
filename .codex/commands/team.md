---
description: Dispatch a phase to a specialist subagent via PhaseSpec v1. Auto-picks the subagent if not specified. HITL gated before dispatch. Result appended to progress.md under "Phase <id> Result".
allowed-tools: ["Read", "Edit", "Bash"]
argument-hint: "dispatch <phase_id> [--agent planner|executor|reviewer|memory-keeper|design-archeologist]"
---

# /mddesign:team

Subagent dispatch.

## Subcommands

### `/mddesign:team dispatch <phase_id>`
Auto-picks the subagent:
- Phases with "design" / "ui" / "tokens" in the title and a harvest-shaped intent → `design-archeologist`
- Phases with no existing PhaseSpec → `planner` (returns the spec, then you re-dispatch with `--agent executor`)
- All others → `executor`

### `/mddesign:team dispatch <phase_id> --agent <name>`
Force a specific subagent. Values:
- `planner` — draft a PhaseSpec from the phase
- `executor` — run the PhaseSpec end to end
- `reviewer` — audit another's return against `done_when`
- `memory-keeper` — classify recent session output (usually called by Stop hook)
- `design-archeologist` — scan codebase for `/mddesign:harvest`

## Flow

1. Read `task_plan.md`, resolve the phase.
2. Build the PhaseSpec (team-dispatch skill logic).
3. HITL gate (named checkpoint: `before_subagent_dispatch`).
4. Call `Agent` tool with the chosen `subagent_type`.
5. Parse the structured return.
6. Append to `progress.md` under `### Phase <phase_id> Result`.
7. If auto-approve is on, dispatch `reviewer`.

## Boundaries

- Subagents never edit `task_plan.md`.
- All dispatches HITL gated.
- Markdown is the shared state across agents; no in-memory store.

See skills/team-dispatch/SKILL.md for the full PhaseSpec v1 schema and dispatch logic.
