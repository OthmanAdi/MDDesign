#!/usr/bin/env bash
# MDDesign UserPromptSubmit hook
# Responsibilities:
#   1. If the active phase in task_plan.md mentions UI keywords AND DESIGN.md exists,
#      print a one-line nudge so the agent runs design-bridge.
#   2. Adaptive: stay silent on conversational turns to avoid noise.
# Output is injected into the agent's context for the current turn.
set -e

cwd="$(pwd)"

# No DESIGN.md or no plan? Nothing to bridge.
[ -f "$cwd/DESIGN.md" ] || exit 0
[ -f "$cwd/task_plan.md" ] || exit 0

# Find the in-progress phase in task_plan.md
active_phase_block=$(awk '
  /^### Phase/ { phase=$0; in_phase=1; capture=""; next }
  in_phase && /\*\*Status:\*\*/ {
    if ($0 ~ /in_progress/) { print phase; print capture; exit }
    in_phase=0; capture=""
  }
  in_phase { capture = capture "\n" $0 }
' "$cwd/task_plan.md" 2>/dev/null)

# No active phase? Skip.
[ -z "$active_phase_block" ] && exit 0

# UI keyword detection (case-insensitive)
ui_keywords="button|card|modal|dialog|layout|color|typography|spacing|form|input|page|screen|theme|brand|design|component|header|footer|sidebar|hero|cta|navigation|tooltip|toast|badge|tabs|menu"

if echo "$active_phase_block" | grep -iE "$ui_keywords" >/dev/null; then
  echo "[MDDesign] active phase touches UI. Read DESIGN.md and refresh findings.md '## Design Context' section before any UI write. See skills/design-bridge/SKILL.md for the inject pattern."
fi

exit 0
