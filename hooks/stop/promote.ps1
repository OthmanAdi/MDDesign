# MDDesign Stop hook (PowerShell)
# Mirror of promote.sh for native Windows PowerShell.
$ErrorActionPreference = "SilentlyContinue"

$cwd = (Get-Location).Path
$planPath = Join-Path $cwd "task_plan.md"
$progressPath = Join-Path $cwd "progress.md"

if (-not (Test-Path $planPath)) { exit 0 }

if (Test-Path $progressPath) {
  $ts = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ" -AsUTC
  $stamp = "`n### Handoff $ts`n`n_Session ended. Next session: run ``/mddesign:handoff catchup`` for full preamble._`n"
  Add-Content -Path $progressPath -Value $stamp -ErrorAction SilentlyContinue
}

Write-Output "[MDDesign] session-end. Consider dispatching memory-keeper subagent to classify recent decisions for promotion to MemPalace WHY tier. Manual: /mddesign:handoff promote."

exit 0
