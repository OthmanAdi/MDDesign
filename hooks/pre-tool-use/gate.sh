#!/usr/bin/env bash
# MDDesign PreToolUse hook
# Responsibilities:
#   Surface a HITL prompt at named checkpoints. Reads the tool invocation
#   from stdin (Claude Code passes the tool call as JSON), inspects the
#   target file path, and prints a checkpoint banner if matched.
#   Exit code 0 = allow tool to proceed (Claude will see the banner and
#   should pause for user confirmation).
#   This hook is informational; actual blocking would require exit code 2.
#   v0.1.0 ships informational mode; blocking mode lands in v0.2.
set -e

# Read the tool call payload from stdin
payload=$(cat 2>/dev/null || echo "{}")

# Extract the file_path field if present (cheap grep, not jq, for portability)
target_path=$(echo "$payload" | grep -oE '"file_path"\s*:\s*"[^"]+"' | head -1 | sed -E 's/.*"file_path"\s*:\s*"([^"]+)".*/\1/')

# Empty path? Nothing to gate.
[ -z "$target_path" ] && exit 0

# Checkpoint 1: writes to DESIGN.md
if echo "$target_path" | grep -E '(^|/)DESIGN\.md$' >/dev/null; then
  echo "[MDDesign HITL] CHECKPOINT before_design_md_write: about to modify DESIGN.md ($target_path). Confirm with user before proceeding."
  exit 0
fi

# Checkpoint 2: writes to UI files (when DESIGN.md exists)
if [ -f "$(pwd)/DESIGN.md" ]; then
  if echo "$target_path" | grep -iE '\.(tsx|jsx|vue|svelte|html|css|scss)$' >/dev/null; then
    echo "[MDDesign HITL] CHECKPOINT before_ui_write: writing $target_path. Verify findings.md '## Design Context' is fresh and the tokens you are using are declared in DESIGN.md."
    exit 0
  fi
fi

# Checkpoint 3: writes to task_plan.md (only planning-with-files should do this)
if echo "$target_path" | grep -E '(^|/)task_plan\.md$' >/dev/null; then
  echo "[MDDesign HITL] WARNING: writing task_plan.md. MDDesign skills should never edit task_plan.md directly. If this is planning-with-files itself, ignore. Otherwise, abort and use findings.md or progress.md."
  exit 0
fi

exit 0
