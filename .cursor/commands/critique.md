---
description: Audit DESIGN.md against the actual code. Writes DESIGN.md.critique.md adjacent to DESIGN.md with five audit passes structural / drift / accessibility / completeness / consistency. Each finding has a stable id and a /mddesign:fix suggestion.
allowed-tools: ["Read", "Write", "Bash", "Glob", "Grep"]
---

# /mddesign:critique

Five-pass audit of the project's `DESIGN.md` against the actual code.

## Passes

1. **Structural** — delegate to `npx @google/design.md lint --json`. 7 Google linter rules.
2. **Drift** — tokens declared but never used (orphans), colors/fonts used in code but not declared (leaks), near-duplicate tokens (ΔE < 5 for colors, ±1px for radii).
3. **Accessibility** — WCAG AA/AAA contrast on declared color pairs, missing focus-ring token, missing reduced-motion fallback when animation tokens exist.
4. **Completeness** — component states (hover/active/focus/disabled/error), dark-mode counterparts, responsive breakpoints.
5. **Consistency** — spacing/radius/font-size scales check for geometric progression.

## Output

Writes `DESIGN.md.critique.md` at project root, adjacent to DESIGN.md. Each finding has:

- Stable id (`F1`, `F2`, ...)
- Severity (P0 P1 P2 P3)
- Category (structural / drift / accessibility / completeness / consistency)
- Short title
- Evidence (file paths, line numbers, counts)
- Proposed fix
- `/mddesign:fix <id>` slash command

Appends a one-line summary to `progress.md`.

## Pre-flight

- `Glob` `DESIGN.md` at project root. If absent, refuse with "Run `/mddesign:harvest` first."
- Verify `npx` reachable.

## Boundaries

- Read-only on `DESIGN.md` (no edits).
- Writes only `DESIGN.md.critique.md` (and appends to `progress.md`).
- Never calls `/mddesign:fix` itself; that is a separate user action.

See skills/design-harvest/SKILL.md for the full five-pass logic.
