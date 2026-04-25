---
name: design-bridge
description: Continuously bridges DESIGN.md into the active planning phase. When the user is working on a UI phase, reads the project's DESIGN.md, extracts the relevant token slice, and appends it to findings.md under "## Design Context" so the agent sees design constraints in its attention window. Never edits DESIGN.md, never edits task_plan.md. Idles when DESIGN.md is absent.
user-invocable: false
allowed-tools: "Read Edit Glob Grep"
metadata:
  version: "0.1.0"
  arm: design
  mode: bridge
---

# Design Bridge

Runtime companion. Lives between `DESIGN.md` and `findings.md`.

## When you (Claude) should run this skill

You are running this skill when ANY of the following is true:

1. The active phase in `task_plan.md` mentions UI keywords (button, card, modal, layout, color, typography, spacing, dialog, navigation, form, input, page, screen, theme, brand, design, component, header, footer, sidebar, hero, cta).
2. The user just asked you to build, change, or review a UI element.
3. The PreToolUse hook fired before a `Write` or `Edit` against a file matching `*.tsx|*.jsx|*.vue|*.svelte|*.html|*.css|*.scss`.
4. The user explicitly ran `/mddesign:inject`.

## What to do

### Step 1: Detect DESIGN.md
- Glob for `DESIGN.md` at the project root (CWD).
- If absent, do nothing. Surface a one-line note ONLY if the user explicitly invoked the skill: "No DESIGN.md found at project root. Run `/mddesign:harvest` to generate one from your codebase."

### Step 2: Detect the relevant token slice
- Read `DESIGN.md` once.
- Identify the token categories the current task touches. Heuristics:
  - "button|cta|link" → components.button, colors.primary, colors.secondary, typography (button), rounded
  - "card|panel|tile" → components.card, colors.surface, rounded, spacing
  - "modal|dialog|overlay" → components.modal, colors.surface, rounded, elevation
  - "form|input|field" → components.input, colors.border, typography (body), rounded
  - "color|theme|palette" → all colors
  - "type|font|heading" → all typography
  - "layout|grid|spacing" → spacing scale, layout section
  - default → colors (primary, secondary), typography (heading, body)

### Step 3: Find the existing "## Design Context" block in findings.md
- Read `findings.md`.
- Look for a section header `## Design Context` (case-sensitive).
- If absent, you will append a fresh block.
- If present, you will replace the block contents.

### Step 4: Build the new block

The block format:
```markdown
## Design Context

> Auto-injected by MDDesign on <ISO timestamp>. Source: DESIGN.md.
> Phase trigger: <phase id or "manual">

### Tokens in scope
<bulleted list of token references with values, format `colors.primary = #3B82F6`>

### Component specs in scope
<for each touched component, copy its spec from DESIGN.md verbatim>

### Do's and Don'ts (relevant excerpt)
<copy the relevant Do/Don't lines from DESIGN.md if any>

> If you stray from these tokens, name the deviation explicitly in findings.md before writing code.
```

### Step 5: Write the block back to findings.md
- Use `Edit` with the old block as `old_string` and your new block as `new_string`.
- If no existing block, use `Edit` to append: `old_string` is the file's last existing line, `new_string` is the same line followed by `\n\n## Design Context\n...`.

## What you must never do

- Never `Write` or `Edit` `DESIGN.md`. Reading only. Harvest is a different skill.
- Never `Write` or `Edit` `task_plan.md`. Read only.
- Never extract or invent tokens not present in DESIGN.md. If a token is missing, surface it under `### Open token questions` in findings.md.
- Never run if DESIGN.md is absent and the user did not explicitly invoke this skill.

## Example

`task_plan.md` Phase 3 says "Build the primary CTA button on the landing page." DESIGN.md declares `colors.primary = #4F46E5`, `components.button.backgroundColor = {colors.primary}`, `rounded.md = 6px`. After this skill runs, `findings.md` gains:

```markdown
## Design Context

> Auto-injected by MDDesign on 2026-04-23T10:14:00Z. Source: DESIGN.md.
> Phase trigger: phase-3

### Tokens in scope
- `colors.primary = #4F46E5`
- `colors.text-on-primary = #FFFFFF`
- `rounded.md = 6px`
- `typography.button = { fontFamily: Inter, fontSize: 16px, fontWeight: 600 }`

### Component specs in scope
**Button** (from DESIGN.md):
- backgroundColor: `{colors.primary}`
- textColor: `{colors.text-on-primary}`
- typography: `{typography.button}`
- rounded: `{rounded.md}`
- hover.backgroundColor: `{colors.primary-700}`

### Do's and Don'ts (relevant excerpt)
- Always use the primary color for the main page CTA.
- Never set fontSize on buttons outside the declared typography.button token.

> If you stray from these tokens, name the deviation explicitly in findings.md before writing code.
```

The agent now sees these constraints on every subsequent prompt because findings.md is in the planning-with-files attention loop.
