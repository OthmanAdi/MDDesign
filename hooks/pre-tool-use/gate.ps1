# MDDesign PreToolUse hook (PowerShell)
# Mirror of gate.sh for native Windows PowerShell.
$ErrorActionPreference = "SilentlyContinue"

$payload = [Console]::In.ReadToEnd()
if ([string]::IsNullOrEmpty($payload)) { exit 0 }

# Extract file_path field
$match = [regex]::Match($payload, '"file_path"\s*:\s*"([^"]+)"')
if (-not $match.Success) { exit 0 }

$targetPath = $match.Groups[1].Value
if ([string]::IsNullOrEmpty($targetPath)) { exit 0 }

$cwd = (Get-Location).Path

# Checkpoint 1: writes to DESIGN.md
if ($targetPath -match '(^|[\\/])DESIGN\.md$') {
  Write-Output "[MDDesign HITL] CHECKPOINT before_design_md_write: about to modify DESIGN.md ($targetPath). Confirm with user before proceeding."
  exit 0
}

# Checkpoint 2: writes to UI files when DESIGN.md exists
if (Test-Path (Join-Path $cwd "DESIGN.md")) {
  if ($targetPath -imatch '\.(tsx|jsx|vue|svelte|html|css|scss)$') {
    Write-Output "[MDDesign HITL] CHECKPOINT before_ui_write: writing $targetPath. Verify findings.md '## Design Context' is fresh and the tokens you are using are declared in DESIGN.md."
    exit 0
  }
}

# Checkpoint 3: writes to task_plan.md
if ($targetPath -match '(^|[\\/])task_plan\.md$') {
  Write-Output "[MDDesign HITL] WARNING: writing task_plan.md. MDDesign skills should never edit task_plan.md directly. If this is planning-with-files itself, ignore. Otherwise, abort and use findings.md or progress.md."
  exit 0
}

exit 0
