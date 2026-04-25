---
description: Apply a single safe quick win from DESIGN.md.critique.md. HITL gated. Re-lints DESIGN.md after every edit; reverts if lint regresses.
allowed-tools: ["Read", "Edit", "Bash"]
argument-hint: "<finding-id>"
---

# /mddesign:fix

Apply one finding's fix from `DESIGN.md.critique.md`.

## Flow

1. **Read the critique**: open `DESIGN.md.critique.md`, find the finding by id. If not found, refuse. If already `status: applied`, refuse.

2. **Show the proposed change**: print the finding and the proposed edit to the user.

3. **HITL gate**: the PreToolUse hook intercepts the next `Edit` (named checkpoint: `before_design_md_fix`) and waits for approval.

4. **Apply**: make the single edit on `DESIGN.md` (or on the named source file when the fix touches code).

5. **Re-lint**: `Bash: npx --yes @google/design.md lint DESIGN.md`.
   - If lint regresses, revert the edit and surface the error.
   - If lint passes, proceed.

6. **Update critique**: mark the finding `status: applied` in `DESIGN.md.critique.md`.

7. **Append to progress.md**: "Applied F<id>. DESIGN.md still passes lint."

## Arguments

- `<finding-id>` — required. Must match a finding in `DESIGN.md.critique.md`.

## Boundaries

- One finding at a time. Never batch-applies.
- Always HITL gated.
- Always re-lints. Never leaves DESIGN.md in a regressed state.

See skills/design-harvest/SKILL.md for the full logic.
