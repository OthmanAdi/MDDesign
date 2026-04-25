---
description: Manual one-shot inject of relevant DESIGN.md tokens into the current phase's findings.md "## Design Context" section. Useful before starting a UI subtask.
allowed-tools: ["Read", "Edit", "Glob"]
---

# /mddesign:inject

Manually run the `design-bridge` skill's token-inject logic.

## What I do

1. `Glob` `DESIGN.md` at project root. If absent, surface `/mddesign:harvest` nudge and stop.
2. `Read` `task_plan.md` to identify the active phase.
3. Extract the token slice relevant to the active phase (using the same heuristics as the UserPromptSubmit hook).
4. `Edit` `findings.md` to add or replace the `## Design Context` block with the current slice.

Full logic in skills/design-bridge/SKILL.md.

## Why use this instead of waiting for the hook

The UserPromptSubmit hook only fires on UI-keyword detection. If you know you are about to start a UI task but your prompt does not have obvious UI keywords, `/mddesign:inject` gets the context into findings.md preemptively.

## Boundaries

- Never edits `DESIGN.md` or `task_plan.md`.
- Only edits `findings.md` under the `## Design Context` section.
