# MDDesign Architecture

## Overview

MDDesign is an orchestrator. It composes existing tools (planning-with-files, DESIGN.md, code-memory-router) without altering their core, and adds the layers between them: design fusion, three-tier memory, agent-team dispatch with PhaseSpec, session handoff, and code-to-DESIGN.md harvest with critique.

## Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│  EXISTING CODEBASE                                               │
│  src/**/*.{tsx,vue,svelte,css,...} + tailwind.config + theme.ts  │
└──────────────────┬───────────────────────────────────────────────┘
                   │
                   │  /mddesign:harvest
                   ▼
┌──────────────────────────────────────────────────────────────────┐
│  design-harvest skill                                            │
│   ├─ team-dispatch → design-archeologist subagent                │
│   │    scans, clusters tokens, names them, returns draft         │
│   ├─ HITL gate (before_design_md_write)                          │
│   ├─ Write DESIGN.md at project root                             │
│   └─ npx @google/design.md lint → iterate up to 3 times          │
└──────────────────┬───────────────────────────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────────────────────────┐
│  DESIGN.md (Google Labs spec, alpha)                             │
│  YAML frontmatter + 8 ordered sections + Agent Prompt Guide      │
└──────┬─────────────────────────────────────────────────┬─────────┘
       │                                                 │
       │  /mddesign:critique                               │  every UI phase
       ▼                                                 ▼
┌──────────────────────────────────┐    ┌─────────────────────────────────┐
│  DESIGN.md.critique.md           │    │  design-bridge skill            │
│   1. structural (Google lint)    │    │   Detect UI keyword in active   │
│   2. drift (declared vs used)    │    │   phase, extract relevant       │
│   3. a11y (focus, motion, AAA)   │    │   token slice, append to        │
│   4. completeness (states, dark) │    │   findings.md "## Design        │
│   5. consistency (scale gaps)    │    │   Context"                      │
│  Each finding has /mddesign:fix    │    │                                 │
└──────────────────────────────────┘    └─────────────────────────────────┘
                                                          │
                                                          │
                                          team-dispatch ◄─┘
                                          │
                                          ▼
                  ┌────────────────────────────────────────────────┐
                  │  PhaseSpec v1 dispatch                         │
                  │   planner → executor → reviewer                │
                  │   plus design-archeologist for harvest         │
                  │   plus memory-keeper on Stop                   │
                  │   markdown on disk = shared state              │
                  └────────────────────────────────────────────────┘
                                          │
                                          ▼
                  ┌────────────────────────────────────────────────┐
                  │  memory-layer (3 tiers via code-memory-router) │
                  │   scratch (.agents/memory/scratch/)            │
                  │   WHERE  (QMD)                                 │
                  │   WHY    (MemPalace, HITL gated)               │
                  └────────────────────────────────────────────────┘
                                          │
                                          ▼
                  ┌────────────────────────────────────────────────┐
                  │  session-handoff                               │
                  │   SessionStart catchup (read planning + scratch│
                  │   + last MemPalace recall)                     │
                  │   Stop promotion (memory-keeper classifies)    │
                  │   Manual: /mddesign:handoff catchup, /mddesign:handoff promote   │
                  └────────────────────────────────────────────────┘
```

## Five core-preservation rules

1. `planning-with-files` core untouched. MDDesign only appends to `findings.md` (under `## Design Context`) and to `progress.md` (under `### Phase <id> Result` and `### Handoff <ts>`). Never writes to `task_plan.md`.
2. `DESIGN.md` only written under explicit user action (`/mddesign:harvest` or `/mddesign:fix`).
3. Memory is a layer on top of `code-memory-router`. MDDesign calls the router; never bypasses or replaces it.
4. Subagents share state via markdown on disk. PhaseSpec v1 is the dispatch contract. No in-memory shared store.
5. Structural DESIGN.md validation delegated to `npx @google/design.md lint`. Never reimplemented.

## PhaseSpec v1 contract

The handoff format between parent and child agents.

```yaml
phase_id: <stable id>
parent_plan_ref: <pointer to task_plan.md#phase-N>
goal: <one sentence>
done_when: [<testable criterion>, ...]
inputs:
  files: [<read-only file refs>]
  memory_keys: [<keys for memory recall>]
tools_allowed: [<list>]
tools_denied: [<list>]
budget:
  max_tool_calls: <int>
  max_wall_seconds: <int>
hitl_checkpoints: [<named strings>]
return_contract:
  format: markdown+frontmatter
  fields: [summary, artifacts, open_questions, next_phase_hint]
```

See `skills/team-dispatch/SKILL.md` for the full schema and the dispatch logic.

## Hook lifecycle

| Hook | Script | Purpose |
|---|---|---|
| SessionStart | hooks/session-start/preamble.{sh,ps1} | Detect planning + DESIGN.md, print orientation banner, nudge `/mddesign:harvest` if UI but no DESIGN.md, ensure scratch dir exists. |
| UserPromptSubmit | hooks/prompt-submit/enforce.{sh,ps1} | If active phase mentions UI keywords and DESIGN.md exists, print a one-line bridge nudge. |
| PreToolUse (Write\|Edit) | hooks/pre-tool-use/gate.{sh,ps1} | Inspect target file path, surface HITL checkpoint banner for DESIGN.md writes, UI file writes, and stray task_plan.md writes. |
| Stop | hooks/stop/promote.{sh,ps1} | Append `### Handoff <ts>` stamp to progress.md, print memory-keeper dispatch nudge. |

All hooks ship cross-platform (Bash for Unix and Git Bash, PowerShell for native Windows). hooks.json tries PowerShell first, falls back to Bash.

## Multi-IDE distribution

Day-1 mirrors generated by `scripts/sync-ide-folders.py`:

| IDE | Mirror dir | Skills | Agents | Commands |
|---|---|---|---|---|
| Codex CLI | `.codex/` | yes | yes | yes |
| Cursor | `.cursor/` | yes | yes | yes |
| Windsurf | `.windsurf/` | yes | yes | yes |
| Cline | `.clinerules/` | yes | no | no |
| OpenCode | `.opencode/` | yes | yes | yes |

Run `python scripts/sync-ide-folders.py` after editing any canonical skill/agent/command.

## File-ownership matrix

| File | Owned by | MDDesign access |
|---|---|---|
| `task_plan.md` | planning-with-files | read only |
| `findings.md` | planning-with-files | append `## Design Context` only |
| `progress.md` | planning-with-files | append `### Phase <id> Result`, `### Handoff <ts>` only |
| `DESIGN.md` (project root) | user OR `/mddesign:harvest` | read; write only via harvest/fix under HITL |
| `DESIGN.md.critique.md` | `design-harvest` | full ownership |
| `.agents/memory/scratch/` | `memory-layer` | full ownership |
| `.agents/skills/` | other plugins | not touched |

## External dependencies

| Dep | Required | Purpose |
|---|---|---|
| `planning-with-files` skill | required | owns task_plan/findings/progress |
| `code-memory-router` skill | required | routes WHERE → QMD, WHY → MemPalace |
| `MemPalace` + `QMD` | implied via router | actual memory backends |
| `@google/design.md` | optional but recommended | structural lint via `npx`; harvest and critique need it |
| `Claude Memory Tool` | reserved for v0.2 | per-session scratchpad once exposed via MCP |
