# MDDesign SessionStart hook (PowerShell)
# Mirror of preamble.sh for native Windows PowerShell.
$ErrorActionPreference = "SilentlyContinue"

$cwd = (Get-Location).Path
$banner = "[MDDesign] active. arms: planning, design-bridge, design-harvest, memory-layer, team-dispatch, session-handoff."

$hasPlan = Test-Path (Join-Path $cwd "task_plan.md")
$hasDesign = Test-Path (Join-Path $cwd "DESIGN.md")

# Detect UI files (cap effort)
$uiPatterns = @("*.tsx","*.jsx","*.vue","*.svelte","*.html","*.css","*.scss")
$exclude = @("node_modules",".git","dist","build",".next")
$uiFiles = Get-ChildItem -Path $cwd -Include $uiPatterns -Recurse -Depth 4 -ErrorAction SilentlyContinue |
  Where-Object { $p = $_.FullName; -not ($exclude | Where-Object { $p -like "*\$_\*" }) } |
  Select-Object -First 1

$hasUi = $uiFiles -ne $null

Write-Output $banner

if ($hasPlan) {
  Write-Output "[MDDesign] planning-with-files detected (task_plan.md found). Run /mddesign:handoff catchup for full session preamble."
}

if ($hasDesign) {
  Write-Output "[MDDesign] DESIGN.md detected at project root. design-bridge will inject relevant tokens into findings.md on UI phases."
} elseif ($hasUi) {
  Write-Output "[MDDesign] No DESIGN.md found but UI files detected. Run /mddesign:harvest to generate a structurally valid DESIGN.md from your codebase."
}

# Ensure scratch dir exists
$scratchDir = Join-Path $cwd ".agents\memory\scratch"
if (-not (Test-Path $scratchDir)) {
  New-Item -ItemType Directory -Path $scratchDir -Force | Out-Null
}

exit 0
