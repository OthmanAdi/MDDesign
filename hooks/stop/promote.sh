#!/usr/bin/env bash
# MDDesign Stop hook
# Responsibilities:
#   1. Print a one-line nudge so the agent dispatches memory-keeper to
#      classify the session output.
#   2. Append a Handoff stamp to progress.md as the catchup anchor for
#      next session.
# Hook output is injected into the agent's context as the final pre-stop
# message; the agent decides whether to actually run memory-keeper.
set -e

cwd="$(pwd)"

# Only act if we have a plan to handoff against
[ -f "$cwd/task_plan.md" ] || exit 0

# Append a minimal Handoff stamp to progress.md if it exists
if [ -f "$cwd/progress.md" ]; then
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date)
  printf "\n### Handoff %s\n\n_Session ended. Next session: run \`/mddesign:handoff catchup\` for full preamble._\n" "$ts" >> "$cwd/progress.md" 2>/dev/null || true
fi

echo "[MDDesign] session-end. Consider dispatching memory-keeper subagent to classify recent decisions for promotion to MemPalace WHY tier. Manual: /mddesign:handoff promote."

exit 0
