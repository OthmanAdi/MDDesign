---
name: design-harvest
description: Harvests a DESIGN.md from an existing codebase, critiques it against the actual code, and applies safe quick-win fixes. Three modes harvest / critique / fix. Shells out to `npx @google/design.md lint` for structural validation; never reimplements Google's linter. The on-ramp that makes DESIGN.md adoptable for every existing repo, not just greenfield projects.
user-invocable: true
allowed-tools: "Read Write Edit Bash Glob Grep"
metadata:
  version: "0.1.0"
  arm: design
  modes: ["harvest", "critique", "fix"]
---

# Design Harvest

The on-ramp. Three modes.

## Mode 1: harvest (`/mddesign:harvest`)

Goal: produce a structurally valid `DESIGN.md` at project root from the existing codebase.

### Step 1: Pre-flight
- Glob for `DESIGN.md` at project root.
- If it exists and the user did NOT pass `--overwrite`, refuse: print "DESIGN.md already exists. Use `/mddesign:critique` instead, or pass `--overwrite` to replace."
- Confirm `npx` is available (`bash -c "command -v npx"`).

### Step 2: Dispatch the design-archeologist subagent
Call the `Agent` tool with `subagent_type: design-archeologist` and a prompt containing this PhaseSpec:

```yaml
phase_id: harvest-<short-uuid>
parent_plan_ref: ./task_plan.md
goal: Extract de-facto design tokens from this codebase and return a draft DESIGN.md body following the Google Labs spec.
done_when:
  - draft_design_md is non-empty
  - draft_design_md contains YAML frontmatter and 8 ordered markdown sections
  - draft_design_md includes a section #9 "Agent Prompt Guide"
inputs:
  files: []  # the subagent globs the project itself
tools_allowed: ["Read", "Glob", "Grep", "Bash"]
tools_denied: ["Write", "Edit", "WebFetch"]
budget:
  max_tool_calls: 200
  max_wall_seconds: 600
hitl_checkpoints:
  - before_returning_draft
return_contract:
  format: markdown+frontmatter
  fields: [summary, draft_design_md, open_questions]
```

The subagent has its own dedicated SKILL/agent definition at `agents/design-archeologist.md`.

### Step 3: Receive the draft, write to DESIGN.md
- Take the `draft_design_md` field from the subagent's return.
- `Write` it to `<project_root>/DESIGN.md`. This write goes through the PreToolUse HITL gate (named checkpoint: `before_design_md_write`).

### Step 4: Lint and iterate
Run:
```bash
npx --yes @google/design.md lint DESIGN.md
```

If exit code is 0, you are done.

If non-zero, capture the linter output. Re-dispatch design-archeologist with an additional input field `lint_errors: <output>` and instruction "fix every reported error and return a new draft." Loop up to 3 times. After 3 failed iterations, surface the final lint errors to the user and stop.

### Step 5: Append to progress.md
Append under `### Phase harvest-<short-uuid> Result`:
- Final lint status
- File path of DESIGN.md
- Token counts (colors: N, typography levels: N, spacing levels: N, components: N)
- One-line "next step" pointing the user to `/mddesign:critique`.

## Mode 2: critique (`/mddesign:critique`)

Goal: write `DESIGN.md.critique.md` adjacent to `DESIGN.md` with five audit passes.

### Step 1: Pre-flight
- Confirm `DESIGN.md` exists. If not, refuse with "No DESIGN.md found. Run `/mddesign:harvest` first."

### Step 2: Pass 1 — Structural (delegated)
```bash
npx --yes @google/design.md lint DESIGN.md --json
```
Capture findings. Severity comes from the linter.

### Step 3: Pass 2 — Drift
- Read `DESIGN.md` and parse the YAML frontmatter token table.
- Glob the project for UI files (`**/*.{tsx,jsx,vue,svelte,html,css,scss}` plus `tailwind.config.*`).
- For each declared token (color, font, radius, spacing), grep the project for actual usage.
- Findings:
  - **Orphan**: declared token never used in code.
  - **Leak**: a hex color, font name, or radius value used in code that does not resolve to any declared token.
  - **Near-duplicate**: two declared colors within ΔE < 5 (or two radii within 1px of each other).

### Step 4: Pass 3 — Accessibility
- For every declared color pair where one is a `*background*` and one is a `*text*` token, compute WCAG AA contrast. Flag below 4.5:1 (normal text) or 3:1 (large text).
- Check whether `colors.focus-ring` exists. If not, finding: "Missing focus-ring token; users tabbing through cannot see focus."
- Check whether any motion or animation tokens are declared. If yes, check whether a `prefers-reduced-motion` fallback section is present in DESIGN.md. If not, finding.

### Step 5: Pass 4 — Completeness
- For each component declared, check whether `hover`, `active`, `focus`, `disabled`, and `error` variants are defined. Flag missing variants.
- Check whether dark-mode color counterparts exist (a parallel `colors-dark.*` block or `@media (prefers-color-scheme: dark)` overrides).
- Check whether responsive breakpoints are declared.

### Step 6: Pass 5 — Consistency
- Check spacing scale: are values geometrically progressing (e.g., 4, 8, 16, 32) or are there orphan values (e.g., 4, 8, 11, 32)?
- Check radius scale: same.
- Check font-size scale: same.

### Step 7: Write the critique
Write `DESIGN.md.critique.md` at project root, adjacent to `DESIGN.md`. Format:

```markdown
# DESIGN.md Critique

> Generated by MDDesign on <ISO timestamp>. Five audit passes.

## Summary
<N findings: P0 P1 P2 P3 counts>

## Findings

### F1 [P0 / structural / google-lint] Missing primary color
DESIGN.md has no `colors.primary` token. Required by Google linter rule 2.
Fix: declare `colors.primary` in the YAML frontmatter.
`/mddesign:fix F1`

### F2 [P1 / drift / leak] Hex color #FF6B6B used 14 times in code, not declared
Locations: src/components/Alert.tsx:23, src/components/Toast.tsx:11, ...
Fix: add `colors.danger = #FF6B6B` to DESIGN.md and replace literal usage.
`/mddesign:fix F2`

<...>
```

Each finding has a stable `F<N>` id, a severity (P0 P1 P2 P3), a category, a one-line description, evidence, a proposed fix, and the `/mddesign:fix <id>` slash command.

### Step 8: Append to progress.md
Append a one-line summary and a pointer to the critique file.

## Mode 3: fix (`/mddesign:fix <finding-id>`)

Goal: apply ONE finding's fix from the critique.

### Step 1: Read the critique
- Open `DESIGN.md.critique.md`, find the finding by id.
- If not found, refuse.
- If status is already `applied`, refuse.

### Step 2: Show the proposed change
- Print the finding to the user.
- The PreToolUse hook will intercept the next Write or Edit (named checkpoint: `before_design_md_fix`) and require approval.

### Step 3: Apply
- Make the single edit on `DESIGN.md` (or, when the fix touches code, the named source file).
- After every edit, re-run `npx --yes @google/design.md lint DESIGN.md`. If lint regresses, revert the edit and surface the error.

### Step 4: Update the critique
- Mark the finding `status: applied` in `DESIGN.md.critique.md`.
- Append to `progress.md`: "Applied F<id>. DESIGN.md still passes lint."

## Core rules

- Never write to `DESIGN.md` outside `/mddesign:harvest` and `/mddesign:fix`.
- Always write `DESIGN.md` at project root, not anywhere else.
- Never reimplement what `npx @google/design.md lint` does.
- Always honour the HITL gate.
- Never edit `task_plan.md`. Append to `progress.md` only.

## External dependency

`@google/design.md` (npm, Apache 2.0). Use `npx --yes @google/design.md ...`. No global install required at consume time.
