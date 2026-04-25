---
name: team-dispatch
description: Turns a plan phase into a PhaseSpec v1 and dispatches it to a specialist subagent via the Agent tool. Subagent reads files itself, returns a structured result, the result is logged into progress.md. Markdown is the shared state; no in-memory shared store across agents.
user-invocable: true
allowed-tools: "Read Edit Bash"
metadata:
  version: "0.1.0"
  arm: teams
  contract: phasespec-v1
---

# Team Dispatch

Subagent dispatch arm. The PhaseSpec v1 contract is the only handoff format used between parent and child agents.

## PhaseSpec v1 (the contract)

```yaml
phase_id: <stable id, used as filename prefix and progress.md anchor>
parent_plan_ref: <pointer to task_plan.md#phase-N>
goal: <one sentence>
done_when:                       # testable exit criteria, no goalpost moving
  - <criterion 1>
  - <criterion 2>
inputs:
  files: [<read-only file refs>]
  memory_keys: [<keys for memory-layer recall>]
tools_allowed: [<list>]
tools_denied: [<list>]
budget:
  max_tool_calls: <int>
  max_wall_seconds: <int>
hitl_checkpoints: [<named checkpoint strings the child surfaces>]
return_contract:
  format: markdown+frontmatter
  fields: [summary, artifacts, open_questions, next_phase_hint]
```

Six load-bearing properties:

1. `parent_plan_ref` is a pointer (file path with anchor), not a copy of the phase text. The child reads the file itself.
2. `done_when` is testable. Without it, completion is hallucinatable.
3. `tools_allowed` and `tools_denied` map onto the Claude Code permission model and any other framework's permission story.
4. `hitl_checkpoints` are named strings the child surfaces by printing `HITL_CHECKPOINT: <name>` to stdout.
5. `return_contract` forces structured output. The child returns markdown with frontmatter; the parent parses it deterministically.
6. `phase_id` doubles as the filename prefix for any artifacts the child writes.

## Available subagents

Each is defined as `agents/<name>.md` in this plugin.

| Subagent | When to pick |
|---|---|
| `planner` | A phase exists in `task_plan.md` but has no PhaseSpec yet. The planner drafts one. |
| `executor` | Default. A PhaseSpec exists; the work is straightforward; one specialist runs it end to end. |
| `reviewer` | Auto-approve mode is on; we need a surrogate human to check the executor's return against `done_when`. |
| `memory-keeper` | Stop hook fired; we need to classify session output into scratch/WHERE/WHY. |
| `design-archeologist` | `/mddesign:harvest` invoked; long-running codebase scan needed. |

## Operation: `/mddesign:team dispatch <phase_id> [--agent <name>]`

### Step 1: Resolve the phase
- Read `task_plan.md`.
- Find the section header matching `phase_id` (case-insensitive).
- If not found, refuse.

### Step 2: Pick the subagent
- If `--agent <name>` was passed, use it.
- Else infer from the phase: phases with "design", "ui", "tokens" in the title default to `design-archeologist` if `/mddesign:harvest`-shaped, else `executor`. All others default to `executor`.

### Step 3: Build the PhaseSpec
- Pull `goal` from the phase title or first bullet.
- Pull `done_when` from the phase's "Status / Done When / Acceptance" section if it exists, else infer from the bullets and ask the user to confirm.
- Set `inputs.files` to `[task_plan.md, findings.md]` plus any files the phase mentions.
- Set `tools_allowed` to a sensible subset based on the phase (default: `Read Write Edit Bash Glob Grep`).
- Set `budget` defaults: `max_tool_calls: 80`, `max_wall_seconds: 600`.
- Set `hitl_checkpoints` to `[before_commit, before_destructive_edit]` plus phase-specific ones.

### Step 4: HITL gate before dispatch
- Print the full PhaseSpec to the user.
- The PreToolUse hook intercepts the next `Agent` tool invocation (named checkpoint: `before_subagent_dispatch`) and requires approval.

### Step 5: Dispatch
- Call the `Agent` tool with `subagent_type: <chosen subagent>` and a prompt that contains:
  - The full PhaseSpec YAML
  - Plain-English instruction: "You are running PhaseSpec phase-<id>. Read every file in inputs.files. Do the work. Return a markdown document with the four fields in return_contract. If you hit any hitl_checkpoint, print `HITL_CHECKPOINT: <name>` and stop."

### Step 6: Receive the return, validate
- Parse the subagent's final message.
- Verify it has the four required fields (`summary`, `artifacts`, `open_questions`, `next_phase_hint`).
- If invalid, log the failure and surface to user.

### Step 7: Write to progress.md
Append under `### Phase <phase_id> Result`:

```markdown
### Phase <phase_id> Result

**Subagent:** <name>
**Status:** complete | partial | blocked
**Wall time:** <seconds>
**Tool calls used:** <int>

#### Summary
<from return.summary>

#### Artifacts
<from return.artifacts>

#### Open questions
<from return.open_questions>

#### Next phase hint
<from return.next_phase_hint>
```

### Step 8: Optional review
- If auto-approve mode is on, dispatch `reviewer` with the executor's return + the PhaseSpec.
- If reviewer says `approve`, mark phase as complete in progress.md.
- If `reject`, append the reason to progress.md and surface to user.
- If `escalate`, halt and ask user.

## Core rules

- Subagents never edit `task_plan.md` directly. Only this skill writes to `progress.md`, and only under `### Phase <id> Result`.
- The PhaseSpec is the entire handoff. Subagents do not see the parent conversation.
- Markdown on disk is the shared state. No in-memory shared store across agents.
- Every dispatch goes through the `before_subagent_dispatch` HITL gate.
