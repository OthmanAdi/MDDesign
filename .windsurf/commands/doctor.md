---
description: Deep diagnostic. Checks every MDDesign dependency, verifies hooks fire, validates the lint toolchain, tests scratch directory write, and prints a fix-it for every failure. Use when something is broken or before publishing to confirm a clean install.
allowed-tools: ["Read", "Bash", "Glob"]
---

# /mddesign:doctor

Diagnostic mode. Goes deeper than `/mddesign:compose`. Use when something is not working, or before reporting a bug.

## What I run

Six probes. Each prints `OK` or `FAIL: <one-line cause> → <fix>`.

### Probe 1: Toolchain
- `node --version` (need v18+)
- `npx --version`
- `bash --version`
- On Windows: `powershell.exe -Command '$PSVersionTable.PSVersion'`

Fail mode: print install link for Node + note that Git Bash ships with Git for Windows.

### Probe 2: `@google/design.md` linter exec
- Create a temp dir with a known-valid DESIGN.md (same minimal sample as `/mddesign:setup`).
- Run `npx --yes @google/design.md lint DESIGN.md`.
- Verify exit code is 0.

Fail mode: print the actual stderr. Most common cause is an offline/proxy block on npm registry.

### Probe 3: Required skills present
- `planning-with-files` SKILL.md present in any of: `~/.claude/skills/`, `~/.agents/skills/`, `~/.claude/plugins/cache/`.
- `code-memory-router` SKILL.md (optional but warn if missing).

Fail mode: redirect to `/mddesign:setup`.

### Probe 4: Hooks registered
- Read `~/.claude/settings.json`.
- Verify `enabledPlugins` contains an `mddesign@*: true` entry, OR
- Verify the user has manually enabled the plugin via `/plugin install`.

Fail mode: print the exact `enabledPlugins` snippet to add.

### Probe 5: Scratch tier writable
- `mkdir -p .agents/memory/scratch && touch .agents/memory/scratch/.probe && rm .agents/memory/scratch/.probe`.

Fail mode: usually a permissions issue in the project dir. Print `chmod`-style fix on Unix, or tell user to check the project folder is not read-only on Windows.

### Probe 6: Hook scripts executable + responding
- Locate plugin install path: `ls $HOME/.claude/plugins/cache/*/mddesign/*/hooks/session-start/` (best-effort).
- Run `preamble.sh` or `preamble.ps1` in dry mode and capture stdout.
- Verify it printed the `[MDDesign] active.` banner.

Fail mode: print the path it tried, the actual stdout, and whether the file exists.

## Output format

```
MDDesign doctor — <ISO timestamp>
────────────────────────────────────────────────

Probe 1 — Toolchain                  : <OK|FAIL>
Probe 2 — @google/design.md lint     : <OK|FAIL>
Probe 3 — Required skills            : <OK|FAIL>
Probe 4 — Hooks registered           : <OK|FAIL>
Probe 5 — Scratch tier writable      : <OK|FAIL>
Probe 6 — Hook script execution      : <OK|FAIL>

Verdict: <HEALTHY | DEGRADED | BROKEN>

Failures:
  • Probe N: <cause>
    Fix: <one-line action>

Next: <suggested action>
```

## Boundaries

- Read-only on settings.json (parses, never writes).
- Creates and immediately removes a probe file in the scratch dir; otherwise no side effects.
- Never installs anything. For installs, use `/mddesign:setup`.
