---
version: alpha
name: basic-react-app
description: Harvested by MDDesign on 2026-04-25 from existing codebase.
colors:
  primary: '#4F46E5'
  primary-700: '#3730A3'
  secondary: '#10B981'
  accent: '#F59E0B'
  background: '#FFFFFF'
  surface: '#F8FAFC'
  text-on-primary: '#FFFFFF'
  text-primary: '#0F172A'
  text-muted: '#64748B'
  border: '#E2E8F0'
  focus-ring: '#818CF8'
  danger: '#EF4444'
typography:
  display:
    fontFamily: Inter
    fontSize: 48px
    fontWeight: 800
    lineHeight: 1.1
  heading:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: 700
    lineHeight: 1.25
  body:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.5
  button:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: 600
    lineHeight: 1.5
  caption:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: 400
    lineHeight: 1.4
rounded:
  none: 0px
  sm: 4px
  md: 6px
  lg: 12px
  full: 9999px
spacing:
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  2xl: 48px
components:
  button:
    backgroundColor: '{colors.primary}'
    textColor: '{colors.text-on-primary}'
    typography: '{typography.button}'
    rounded: '{rounded.md}'
    padding: '{spacing.sm} {spacing.md}'
  card:
    backgroundColor: '{colors.surface}'
    rounded: '{rounded.lg}'
    padding: '{spacing.md}'
    border: '{colors.border}'
---

# basic-react-app Design System

Harvested on 2026-04-25 from the existing codebase.

## Overview
A focused, accessibility-first system. Saturated indigo primary suggests bold action; high contrast text-primary on background passes WCAG AA. Single sans-serif (Inter) keeps the system tight.

## Colors
Primary indigo carries CTAs and links. Secondary emerald is reserved for success states. Surface and background separate elevated content from page chrome. Focus-ring is a deliberately distinct lighter indigo for keyboard accessibility.

| Token | Value | Role |
|---|---|---|
| primary | #4F46E5 | Main brand color, CTAs, links |
| primary-700 | #3730A3 | Hover state for primary |
| secondary | #10B981 | Success, confirmation |
| accent | #F59E0B | Highlights, badges |
| background | #FFFFFF | Page chrome |
| surface | #F8FAFC | Card backgrounds, elevated content |
| text-on-primary | #FFFFFF | Foreground on primary backgrounds |
| text-primary | #0F172A | Body text |
| text-muted | #64748B | Captions, metadata |
| border | #E2E8F0 | Default borders |
| focus-ring | #818CF8 | Keyboard focus indicator |
| danger | #EF4444 | Errors, destructive actions |

## Typography
Inter throughout. Five-step scale: display (48px) for hero, heading (24px) for sections, body (16px) for prose, button (16px/600), caption (13px) for metadata.

| Level | Family | Size | Weight | Line height |
|---|---|---|---|---|
| display | Inter | 48px | 800 | 1.1 |
| heading | Inter | 24px | 700 | 1.25 |
| body | Inter | 16px | 400 | 1.5 |
| button | Inter | 16px | 600 | 1.5 |
| caption | Inter | 13px | 400 | 1.4 |

## Layout
12-column grid, 1280px max container, 24px gutter. Spacing scale follows a near-doubling rhythm: 4 / 8 / 16 / 24 / 32 / 48.

## Elevation & Depth
No elevation tokens detected in code. Consider adding `shadow.sm/md/lg` if you introduce overlays or modals.

## Shapes
6px (`rounded.md`) is the dominant radius, used in 73% of buttons and inputs. Cards use `rounded.lg` (12px). Full pill (`rounded.full`) reserved for avatars and chips.

## Components

### Button
- `backgroundColor`: `{colors.primary}`
- `textColor`: `{colors.text-on-primary}`
- `typography`: `{typography.button}`
- `rounded`: `{rounded.md}`
- `padding`: `{spacing.sm} {spacing.md}`

### Card
- `backgroundColor`: `{colors.surface}`
- `rounded`: `{rounded.lg}`
- `padding`: `{spacing.md}`
- `border`: `{colors.border}`

## Do's and Don'ts
- DO use `colors.primary` for the main CTA on every page.
- DO compose components from declared tokens, never literal hex.
- DO add a `:focus-visible` state with `colors.focus-ring` on every interactive element.
- DON'T introduce a new color without adding it to the colors table first.
- DON'T mix radius scales within one component.
- DON'T set `fontSize` on buttons outside `typography.button`.

## Agent Prompt Guide

When generating UI for this project: default new buttons to the `Button` component spec above. Default new cards to the `Card` spec. Compose every color reference as `{colors.<name>}` in your token references; only inline the hex when writing the component's stylesheet, and only resolve from the declared color table.

The accent color (`#F59E0B`) is for badges and highlights only. Never use accent for body text or buttons. The danger color is destructive-only (delete, error, irreversible).

Every interactive element must have a visible `:focus-visible` outline using `{colors.focus-ring}`. The system optimizes for keyboard accessibility, not just mouse hover. When in doubt, copy the existing `BasePrimaryButton.tsx` pattern in `src/components/`.
