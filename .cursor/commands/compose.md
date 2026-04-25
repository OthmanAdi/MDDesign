---
description: One-shot wiring check for MDDesign. Verifies planning-with-files, DESIGN.md, code-memory-router, and Google linter are all reachable. Surfaces any missing piece with a one-line fix-it. Read-only.
allowed-tools: ["Read", "Bash", "Glob"]
---

# /mddesign:compose

Run me at the start of work on a new project. I verify that MDDesign's four arms are wired and tell you what to install if anything is missing. Read-only; I never modify the project.

## What I check

For the current project directory (CWD), I produce a status table and print it:

```
MDDesign compose check — <project name>
────────────────────────────────────────────────────────────

Arm               | Status  | Note
------------------|---------|--------------------------------------------
Planning          | <ok|x>  | task_plan.md / findings.md / progress.md
Design (read)     | <ok|x>  | DESIGN.md at project root
Design (harvest)  | <ok|x>  | npx @google/design.md lint reachable
Memory router     | <ok|x>  | code-memory-router slash command registered
Scratch tier      | <ok|x>  | .agents/memory/scratch/ directory writable

Recommended next step: <one-line action>
```

## How I check each arm

### Planning
- `Glob` for `task_plan.md` in CWD.
- If absent: note "missing. Use planning-with-files to initialize."
- If present but `findings.md` or `progress.md` missing, note "partial. Re-init or create the missing files."

### Design (read)
- `Glob` for `DESIGN.md` in CWD.
- If present: ok.
- If absent AND the project has UI files (`*.tsx|*.vue|*.svelte|*.html|*.css`): note "missing. Run `/mddesign:harvest` to generate one from your codebase."
- If absent AND no UI files detected: note "not applicable (no UI files detected)."

### Design (harvest toolchain)
- `Bash: npx --yes @google/design.md --version 2>/dev/null || echo "not-available"`
- If output contains `not-available`: note "npx @google/design.md not reachable. Run `/mddesign:setup` to install, or ensure Node and npx are on PATH."

### Memory router
- Look for `code-memory-router` SKILL.md in plugin cache or user skill dir.
- `Bash: ls "$HOME/.claude/skills/code-memory-router/SKILL.md" 2>/dev/null || ls "$HOME/.agents/skills/code-memory-router/SKILL.md" 2>/dev/null || ls "$HOME/.claude/plugins/cache/*/skills/code-memory-router/SKILL.md" 2>/dev/null || echo "not-found"`
- If not found: note "code-memory-router not installed. /mddesign:memory recall will fall back to scratch only. Run `/mddesign:setup`."

### Scratch tier
- `Bash: mkdir -p .agents/memory/scratch && [ -w .agents/memory/scratch ] && echo ok || echo notwritable`
- This is the only side effect: creating the scratch dir.

## Recommended next step logic

- All ok: "All arms wired. Start working. /mddesign:memory save and /mddesign:inject are available."
- DESIGN.md missing but harvest toolchain ok: "Run /mddesign:harvest to generate your DESIGN.md from the codebase."
- Planning missing: "Initialize planning-with-files first."
- code-memory-router missing: "Run /mddesign:setup to install it and unlock WHY/WHERE tiers."
- @google/design.md missing: "Run /mddesign:setup."

## Boundaries
- Never modifies anything except `.agents/memory/scratch/` (create if missing).
- Never writes to `task_plan.md`, `DESIGN.md`, `findings.md`, `progress.md`.
- Output is printed to the user; I do not silently fix anything.
