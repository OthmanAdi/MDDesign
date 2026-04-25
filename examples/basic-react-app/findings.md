# Findings

## Research

- `tailwindcss` is already installed (see package.json).
- `theme.ts` declares 8 colors and 6 font sizes.
- Largest single use of `#4F46E5` is in `src/Header.tsx` (12 occurrences).

## Design Context

> Auto-injected by MDDesign on 2026-04-25T05:42:00Z. Source: DESIGN.md.
> Phase trigger: phase-3-build-cta

### Tokens in scope
- `colors.primary = #4F46E5`
- `colors.primary-700 = #3730A3`
- `colors.text-on-primary = #FFFFFF`
- `colors.focus-ring = #818CF8`
- `rounded.md = 6px`
- `typography.button = { fontFamily: Inter, fontSize: 16px, fontWeight: 600, lineHeight: 1.5 }`
- `spacing.sm = 8px`
- `spacing.md = 16px`

### Component specs in scope
**Button** (from DESIGN.md):
- `backgroundColor`: `{colors.primary}`
- `textColor`: `{colors.text-on-primary}`
- `typography`: `{typography.button}`
- `rounded`: `{rounded.md}`
- `padding`: `{spacing.sm} {spacing.md}`
- `hover.backgroundColor`: `{colors.primary-700}`
- `focus.outline`: `2px solid {colors.focus-ring}`

### Do's and Don'ts (relevant excerpt)
- DO use `colors.primary` for the main page CTA on every page.
- DO compose button styles from declared tokens, never literal hex.
- DON'T set `fontSize` on buttons outside `typography.button`.
- DON'T introduce a new color without adding it to DESIGN.md first.

> If you stray from these tokens, name the deviation explicitly in findings.md before writing code.

## Open token questions
- None.
