---
description: Scan the current codebase, cluster de-facto design tokens, write a structurally valid DESIGN.md at project root. Uses the design-archeologist subagent for the scan. Validates with npx @google/design.md lint and iterates until valid.
allowed-tools: ["Read", "Write", "Bash", "Glob", "Grep"]
argument-hint: "[--overwrite]"
---

# /mddesign:harvest

Generate `DESIGN.md` from an existing codebase.

## What I do

1. **Pre-flight**: glob `DESIGN.md` at project root.
   - If exists and `--overwrite` not passed: refuse. Point user at `/mddesign:critique`.
   - Confirm `npx` is available via `bash -c "command -v npx"`.

2. **Dispatch design-archeologist**: call the `Agent` tool with `subagent_type: design-archeologist` and a prompt that contains a PhaseSpec for `harvest-<short-uuid>` (see skills/design-harvest/SKILL.md for the exact PhaseSpec shape).

3. **HITL gate at write time**: when the subagent returns `draft_design_md`, print it to the user and wait for the PreToolUse hook (named checkpoint: `before_design_md_write`) to approve the write.

4. **Write**: `Write` the draft to `DESIGN.md` at project root.

5. **Lint and iterate**:
   - `Bash: npx --yes @google/design.md lint DESIGN.md`
   - If exit 0, done.
   - If non-zero, capture output, re-dispatch design-archeologist with `lint_errors: <output>`. Loop up to 3 times.
   - After 3 failed iterations, print errors and stop.

6. **Append to progress.md**: under `### Phase harvest-<uuid> Result`, note token counts, lint status, and next step (`/mddesign:critique`).

## Arguments

- `--overwrite` — replace existing DESIGN.md. Requires explicit intent because this is a destructive-ish action.

## Boundaries

- Only writes DESIGN.md under the HITL gate.
- Never edits `task_plan.md`.
- Never reimplements Google's linter.

See skills/design-harvest/SKILL.md for full implementation details.
