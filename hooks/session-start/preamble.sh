#!/usr/bin/env bash
# MDDesign SessionStart hook
# Responsibilities:
#   1. Detect planning-with-files (task_plan.md exists?)
#   2. Detect DESIGN.md at project root
#   3. Print a one-line orientation banner so the agent knows MDDesign is active
#   4. Surface a nudge if the project has UI files but no DESIGN.md
# Output is injected into the agent's first turn.
# Cross-platform: works on Git Bash on Windows + Unix.
set -e

cwd="$(pwd)"
banner="[MDDesign] active. arms: planning, design-bridge, design-harvest, memory-layer, team-dispatch, session-handoff."

has_plan=0
has_design=0
has_ui=0

[ -f "$cwd/task_plan.md" ] && has_plan=1
[ -f "$cwd/DESIGN.md" ] && has_design=1

# Detect UI files (cap glob effort)
ui_count=$(find "$cwd" -maxdepth 4 \
  \( -name "*.tsx" -o -name "*.jsx" -o -name "*.vue" -o -name "*.svelte" -o -name "*.html" -o -name "*.css" -o -name "*.scss" \) \
  -not -path "*/node_modules/*" \
  -not -path "*/.git/*" \
  -not -path "*/dist/*" \
  -not -path "*/build/*" \
  -not -path "*/.next/*" \
  2>/dev/null | head -1 | wc -l | tr -d ' ')
[ "$ui_count" != "0" ] && has_ui=1

echo "$banner"

if [ "$has_plan" = "1" ]; then
  echo "[MDDesign] planning-with-files detected (task_plan.md found). Run /mddesign:handoff catchup for full session preamble."
fi

if [ "$has_design" = "1" ]; then
  echo "[MDDesign] DESIGN.md detected at project root. design-bridge will inject relevant tokens into findings.md on UI phases."
elif [ "$has_ui" = "1" ]; then
  echo "[MDDesign] No DESIGN.md found but UI files detected. Run /mddesign:harvest to generate a structurally valid DESIGN.md from your codebase."
fi

# Ensure scratch dir exists for memory-layer
mkdir -p "$cwd/.agents/memory/scratch" 2>/dev/null || true

exit 0
