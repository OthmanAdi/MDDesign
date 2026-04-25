---
description: Walk the user through installing every MDDesign dependency. Detects what is missing, prints exact install commands for the current platform, and verifies after each step. Safe to run multiple times.
allowed-tools: ["Read", "Bash", "Glob"]
---

# /mddesign:setup

First-run setup. Detects what is missing on this machine and walks the user through installing it. Idempotent — safe to run any time.

## What I check, in order

| Dependency | Required | What it gives you |
|---|---|---|
| `node` + `npx` | required | DESIGN.md linter (Google's `@google/design.md`) |
| `@google/design.md` | required | structural validation for harvest and critique |
| `planning-with-files` skill | required | task_plan.md / findings.md / progress.md |
| `code-memory-router` skill | optional but recommended | three-tier memory routing (scratch / WHERE / WHY) |
| `MemPalace` MCP | optional | persistent WHY-tier decisions |
| `QMD` MCP | optional | WHERE-tier code/doc search |

## Flow

For each dependency, run the detection probe. If missing, print a one-paragraph install block tailored to the user's platform (Windows / macOS / Linux). After printing the install block, **stop and wait for the user to say "done" or "skip"** before moving to the next dependency.

### Step 1: Node + npx

```bash
command -v node && command -v npx
```

If absent:

> **Node is not on PATH.**
>
> Install Node.js LTS from https://nodejs.org. On Windows: download the Windows Installer (.msi). On macOS: `brew install node`. On Linux: use your distro's package manager or nvm.
>
> After installing, restart your terminal and run `/mddesign:setup` again.

### Step 2: `@google/design.md`

```bash
npx --yes @google/design.md lint --help 2>&1 | head -1
```

If empty or error: nothing to install per se (npx fetches on demand). Verify cache works by:

```bash
mkdir -p /tmp/mddesign-probe && cd /tmp/mddesign-probe && cat > DESIGN.md <<'EOF'
---
version: alpha
name: Probe
colors:
  primary: '#000000'
typography:
  body:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.5
rounded:
  md: 8px
spacing:
  md: 16px
components:
  button:
    backgroundColor: '{colors.primary}'
---
# Probe
## Overview
test
## Colors
test
## Typography
test
## Layout
test
## Elevation & Depth
test
## Shapes
test
## Components
test
## Do's and Don'ts
test
EOF
npx --yes @google/design.md lint DESIGN.md
echo "EXIT: $?"
```

If exit 0: ok. If non-zero with a real error: print the error and ask the user to share it (likely npm registry or proxy issue).

### Step 3: `planning-with-files` skill

```bash
ls "$HOME/.claude/skills/planning-with-files/SKILL.md" 2>/dev/null \
  || ls "$HOME/.agents/skills/planning-with-files/SKILL.md" 2>/dev/null \
  || ls "$HOME/.claude/plugins/cache/"*"/planning-with-files/"*"/SKILL.md" 2>/dev/null \
  || echo "MISSING"
```

If `MISSING`:

> **planning-with-files is required but not installed.**
>
> It is a Claude Code plugin. Install with:
> ```
> /plugin marketplace add obra/planning-with-files
> /plugin install planning-with-files@planning-with-files
> ```
> Or, if your harness does not have the plugin command yet, clone the repo and copy `skills/planning-with-files/` into `~/.claude/skills/`.
>
> Source: https://github.com/obra/planning-with-files

### Step 4: `code-memory-router` skill (optional)

```bash
ls "$HOME/.claude/skills/code-memory-router/SKILL.md" 2>/dev/null \
  || ls "$HOME/.agents/skills/code-memory-router/SKILL.md" 2>/dev/null \
  || ls "$HOME/.claude/plugins/cache/"*"/code-memory-router/"*"/SKILL.md" 2>/dev/null \
  || echo "MISSING"
```

If `MISSING`:

> **code-memory-router is optional but recommended.**
>
> Without it, `/mddesign:memory recall` only searches the local scratch tier. WHY (MemPalace) and WHERE (QMD) tiers are unreachable.
>
> Install:
> ```
> /plugin marketplace add OthmanAdi/code-memory-router
> /plugin install code-memory-router@code-memory-router
> ```
> Or clone https://github.com/OthmanAdi/code-memory-router and copy `SKILL.md` into `~/.claude/skills/code-memory-router/`.

### Step 5: MemPalace MCP (optional)

```bash
grep -q '"mempalace"' "$HOME/.claude/settings.json" 2>/dev/null && echo "configured" || echo "MISSING"
```

If `MISSING`:

> **MemPalace MCP is optional. It powers the WHY tier.**
>
> Install: see https://github.com/Anthropic/mempalace (or the user's local README). Requires Python and a venv. Once installed, add to `~/.claude/settings.json` under `mcpServers`:
> ```json
> "mempalace": {
>   "command": "<path to python.exe>",
>   "args": ["-m", "mempalace.mcp_server", "--palace", "<path to your palace dir>"]
> }
> ```

### Step 6: QMD MCP (optional)

```bash
grep -q '"qmd"' "$HOME/.claude/settings.json" 2>/dev/null && echo "configured" || echo "MISSING"
```

If `MISSING`:

> **QMD MCP is optional. It powers the WHERE tier.**
>
> Install: `npm i -g @tobilu/qmd`. Then add to `~/.claude/settings.json` under `mcpServers`:
> ```json
> "qmd": {
>   "command": "node",
>   "args": ["<path to qmd>/dist/cli/qmd.js", "mcp"]
> }
> ```

## After all checks

Print a final summary:

```
MDDesign setup — final state
────────────────────────────
node + npx           : <ok|x>
@google/design.md    : <ok|x>
planning-with-files  : <ok|x>
code-memory-router   : <ok|x>     (optional)
MemPalace MCP        : <ok|x>     (optional)
QMD MCP              : <ok|x>     (optional)

Required state: <READY | NOT READY>
Next: run /mddesign:doctor for a deeper diagnostic, or /mddesign:compose at the start of your next project.
```

## Boundaries

- Read-only on the system. I print install instructions; I do NOT install anything automatically.
- Never modifies settings.json. The user copies the JSON snippets in themselves.
- Idempotent. Safe to run as many times as needed.
