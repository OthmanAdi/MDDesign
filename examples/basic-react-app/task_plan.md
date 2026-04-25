# Task Plan: Landing Page CTA

## Goal
Build the primary landing page CTA button using the project's design tokens.

## Success Criteria
- [x] DESIGN.md exists at project root
- [ ] Button component uses `colors.primary` token (no literal hex)
- [ ] Hover state uses `colors.primary-700` token
- [ ] Focus ring meets WCAG AA contrast
- [ ] Component passes `/mddesign:critique` with no P0 findings

## Phases

### Phase 1: Harvest DESIGN.md
**Status:** complete
Run `/mddesign:harvest` to scan the existing src/ for de-facto tokens.

### Phase 2: Critique baseline
**Status:** complete
Run `/mddesign:critique`. F2 flagged a literal `#FF6B6B` in src/Alert.tsx as a leak.

### Phase 3: Build CTA button
**Status:** in_progress
Build `src/components/Button.tsx` using only declared tokens. design-bridge will auto-inject the relevant slice into findings.md when this phase becomes active.

Touched: tokens, color, button, cta — design-bridge UI keywords.

### Phase 4: Add hover and focus states
**Status:** pending
