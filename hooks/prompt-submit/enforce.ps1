# MDDesign UserPromptSubmit hook (PowerShell)
# Mirror of enforce.sh for native Windows PowerShell.
$ErrorActionPreference = "SilentlyContinue"

$cwd = (Get-Location).Path
$designPath = Join-Path $cwd "DESIGN.md"
$planPath = Join-Path $cwd "task_plan.md"

if (-not (Test-Path $designPath)) { exit 0 }
if (-not (Test-Path $planPath)) { exit 0 }

$plan = Get-Content $planPath -Raw

# Find the in-progress phase block
$pattern = '(?ms)^### Phase[^\r\n]*?\r?\n.*?\*\*Status:\*\*\s*in_progress.*?(?=^### Phase|\z)'
$match = [regex]::Match($plan, $pattern)
if (-not $match.Success) { exit 0 }

$phaseBlock = $match.Value

$uiKeywords = "button|card|modal|dialog|layout|color|typography|spacing|form|input|page|screen|theme|brand|design|component|header|footer|sidebar|hero|cta|navigation|tooltip|toast|badge|tabs|menu"

if ($phaseBlock -imatch $uiKeywords) {
  Write-Output "[MDDesign] active phase touches UI. Read DESIGN.md and refresh findings.md '## Design Context' section before any UI write. See skills/design-bridge/SKILL.md for the inject pattern."
}

exit 0
