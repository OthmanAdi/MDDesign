---
name: session-handoff
description: Makes sessions durable across `/clear`, machine reboots, and IDE switches. SessionStart catchup pulls scratch + last MemPalace recall + planning files into context. Stop promotion writes a handoff note and runs memory-keeper. Manual `/mddesign:handoff` re-runs either at any time.
user-invocable: true
allowed-tools: "Read Write Edit Bash Glob Grep"
metadata:
  version: "0.1.0"
  arm: handoff
  triggers: ["session-start", "stop", "manual"]
---

# Session Handoff

Bridges sessions. The user's session ends; the next session picks up exactly where the last one left off.

## SessionStart catchup

Triggered automatically by the SessionStart hook. Manually invokable via `/mddesign:handoff catchup`.

### Step 1: Read planning files
- `Read` `task_plan.md` if it exists. Note the active phase id and its bullets.
- `Read` `findings.md` if it exists. Note any `## Design Context` block.
- `Read` `progress.md` if it exists. Note the most recent `### Phase <id> Result` and the most recent `### Handoff <timestamp>` entry.

### Step 2: Read scratch
- Glob `.agents/memory/scratch/**/*.md`.
- For each scratch file, read the last ISO-timestamped entry.

### Step 3: Recall last WHY
- Invoke `/memory-router` with a query like "recent decisions for project <CWD basename>".
- The router dispatches to MemPalace; returns the most recent WHY entries for this project.

### Step 4: Synthesize the preamble
Build a one-paragraph (4-6 sentence) "where we left off" that names:
- The active phase and its current status
- The most recent decision (from WHY)
- Any open questions from the last `### Phase Result`
- Any in-flight scratch entries

Print this preamble to the user as your first message.

### Step 5: Surface nudges
- If the project has UI files (`*.tsx|*.vue|*.svelte`) but no `DESIGN.md`, print: "No DESIGN.md found. Run `/mddesign:harvest` to generate one."
- If `task_plan.md` does not exist, print: "No task_plan.md. Use planning-with-files to create one before starting work."
- If `code-memory-router` slash command is not registered, print: "code-memory-router not detected. Memory operations will fall back to scratch only."

## Stop promotion

Triggered automatically by the Stop hook. Manually invokable via `/mddesign:handoff promote`.

### Step 1: Dispatch memory-keeper
Call the `Agent` tool with `subagent_type: memory-keeper`. Pass:
- A pointer to `progress.md` (last 50 lines)
- A pointer to `findings.md`
- A pointer to `.agents/memory/scratch/`

Memory-keeper returns a list of promotion candidates with tier classifications.

### Step 2: HITL on each promotion
For each WHY candidate:
- Print the candidate text and the proposed MemPalace drawer path.
- Wait for the PreToolUse hook (named checkpoint: `before_mempalace_write`) to require approval.
- On approval, the `memory-layer` skill performs the actual `/memory-router` invocation.
- On rejection, leave the entry in scratch.

### Step 3: Write the handoff note
Append to `progress.md`:

```markdown
### Handoff <ISO timestamp>

**Active phase at session end:** <id>
**Status:** <status>
**Promoted to WHY:** <count> entries
**Open questions:**
- <list>

**Resume next session by:**
- <one-line action>
```

This block is what SessionStart catchup reads first next time.

## Manual handoff

| Subcommand | What it does |
|---|---|
| `/mddesign:handoff` (no arg) | Runs catchup. |
| `/mddesign:handoff catchup` | Runs catchup. |
| `/mddesign:handoff promote` | Runs Stop promotion. Useful before a planned `/clear`. |

## Core rules

- Never touch `task_plan.md` directly. Read only.
- Never write to MemPalace without HITL.
- Catchup is read-only. Only the promotion step writes (and only under HITL).
- The handoff note in `progress.md` always lives under `### Handoff <timestamp>` for easy grep.

## Example

User ends Tuesday session mid-Phase 3. Stop fires. Memory-keeper proposes 2 WHY candidates ("decided X for reason Y" and "rejected approach Z"). User approves both. Plugin writes:

```markdown
### Handoff 2026-04-23T18:42:11Z

**Active phase at session end:** phase-3-build-cta
**Status:** in_progress, button component scaffolded but a11y not yet checked
**Promoted to WHY:** 2 entries
**Open questions:**
- Should the focus ring use colors.primary or colors.accent?

**Resume next session by:**
- Read findings.md "## Design Context", then run /mddesign:critique to check the button against DESIGN.md tokens.
```

Wednesday morning, user opens a new session. `/clear` happened or the laptop rebooted. SessionStart fires. Catchup synthesises:

> Last session ended in Phase 3 (build-cta), button scaffolded but a11y not yet checked. Decisions promoted: chose primary color for CTA based on contrast vs accent. Open question: focus ring color (primary vs accent). Suggested next step: read findings.md "## Design Context" then `/mddesign:critique`.

User reads, says "ok continue". The agent already has every piece of context it needs.
