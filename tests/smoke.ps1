# MDDesign smoke test (PowerShell, native Windows)
# Verifies every hook runs and prints expected output.
# Usage: powershell.exe -ExecutionPolicy Bypass -File tests\smoke.ps1
$ErrorActionPreference = "Stop"

$ROOT = Resolve-Path (Join-Path $PSScriptRoot "..")
$TMP  = Join-Path ([System.IO.Path]::GetTempPath()) ("mddesign-smoke-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $TMP -Force | Out-Null

$PASS = 0
$FAIL = 0

function Probe-OK([string]$msg)   { Write-Host "  OK: $msg"; $script:PASS++ }
function Probe-Fail([string]$msg) { Write-Host "  FAIL: $msg" -ForegroundColor Red; $script:FAIL++ }

Write-Host "=== MDDesign smoke test (PowerShell) ==="
Write-Host "Plugin root: $ROOT"
Write-Host "Tmp project: $TMP"
Write-Host ""

try {
  Push-Location $TMP

  # ─── Probe 1: hooks.json structure ────────────────────────────────
  Write-Host "[1] hooks/hooks.json structure"
  $hjson = Get-Content (Join-Path $ROOT "hooks\hooks.json") -Raw
  if ($hjson -match '"hooks"' -and $hjson -match '"description"') { Probe-OK "hooks.json has 'hooks' wrapper and 'description'" } else { Probe-Fail "hooks.json missing wrapper" }

  # ─── Probe 2: SessionStart hook (no plan, no DESIGN.md) ───────────
  Write-Host "[2] SessionStart hook from empty project"
  $out = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $ROOT "hooks\session-start\preamble.ps1") 2>&1
  if ($out -match '\[MDDesign\] active') { Probe-OK "banner printed" } else { Probe-Fail "no banner" }
  if (Test-Path ".agents\memory\scratch") { Probe-OK "scratch dir created" } else { Probe-Fail "scratch dir not created" }

  # ─── Probe 3: SessionStart hook with task_plan.md ─────────────────
  Write-Host "[3] SessionStart hook with planning files"
  Set-Content -Path "task_plan.md" -Value "# Task Plan"
  $out = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $ROOT "hooks\session-start\preamble.ps1") 2>&1
  if ($out -match 'planning-with-files detected') { Probe-OK "detected planning-with-files" } else { Probe-Fail "did not detect planning" }

  # ─── Probe 4: SessionStart hook with UI file but no DESIGN.md ─────
  Write-Host "[4] SessionStart hook with UI file but no DESIGN.md"
  New-Item -ItemType Directory -Path "src" -Force | Out-Null
  Set-Content -Path "src\App.tsx" -Value "export default function() { return null; }"
  $out = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $ROOT "hooks\session-start\preamble.ps1") 2>&1
  if ($out -match '/mddesign:harvest') { Probe-OK "nudges /mddesign:harvest" } else { Probe-Fail "did not nudge harvest" }

  # ─── Probe 5: SessionStart with DESIGN.md present ─────────────────
  Write-Host "[5] SessionStart with DESIGN.md present"
  Set-Content -Path "DESIGN.md" -Value "---"
  $out = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $ROOT "hooks\session-start\preamble.ps1") 2>&1
  if ($out -match 'DESIGN.md detected') { Probe-OK "detected DESIGN.md" } else { Probe-Fail "did not detect DESIGN.md" }

  # ─── Probe 6: Stop hook appends handoff stamp ─────────────────────
  Write-Host "[6] Stop hook"
  Set-Content -Path "progress.md" -Value "# Progress"
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $ROOT "hooks\stop\promote.ps1") 2>&1 | Out-Null
  $progress = Get-Content "progress.md" -Raw
  if ($progress -match 'Handoff') { Probe-OK "Stop hook appended Handoff stamp" } else { Probe-Fail "no Handoff stamp" }

  # ─── Probe 7: PreToolUse hook gates DESIGN.md write ───────────────
  Write-Host "[7] PreToolUse hook on DESIGN.md path"
  $payload = '{"tool_name":"Write","tool_input":{"file_path":"C:\\tmp\\DESIGN.md"}}'
  $out = $payload | & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $ROOT "hooks\pre-tool-use\gate.ps1") 2>&1
  if ($out -match 'before_design_md_write') { Probe-OK "DESIGN.md write checkpoint fired" } else { Probe-Fail "no checkpoint on DESIGN.md write" }

  # ─── Probe 8: command files exist ─────────────────────────────────
  Write-Host "[8] commands/ has new namespaced files"
  foreach ($c in @("harvest","critique","fix","inject","compose","handoff","memory","team","setup","doctor")) {
    if (Test-Path (Join-Path $ROOT "commands\$c.md")) { Probe-OK "commands/$c.md present" } else { Probe-Fail "commands/$c.md MISSING" }
  }

  # ─── Probe 9: no stale /design: references in canonical files ─────
  Write-Host "[9] no stale /design: references in canonical SKILLS"
  $stale = Get-ChildItem -Recurse -Path (Join-Path $ROOT "skills"),(Join-Path $ROOT "agents"),(Join-Path $ROOT "docs") -File -Filter *.md `
    | Select-String -Pattern '/design:[a-z]+' -List
  $stale2 = Select-String -Path (Join-Path $ROOT "AGENTS.md") -Pattern '/design:[a-z]+' -List -ErrorAction SilentlyContinue
  if (-not $stale -and -not $stale2) { Probe-OK "no stale /design: references" } else { Probe-Fail "found stale /design: references" }

  # ─── Probe 10: @google/design.md lint reachable ───────────────────
  Write-Host "[10] @google/design.md lint reachable"
  if (Get-Command npx -ErrorAction SilentlyContinue) {
    $designMd = @'
---
version: alpha
name: probe
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
'@
    Set-Content -Path "probe.md" -Value $designMd
    & npx --yes @google/design.md lint probe.md 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { Probe-OK "@google/design.md lint passes on minimal valid file" } else { Probe-Fail "@google/design.md lint failed" }
  } else { Probe-Fail "npx not on PATH" }

  Write-Host ""
  Write-Host "=== Result: $PASS passed / $FAIL failed ==="
  if ($FAIL -gt 0) { exit 1 } else { exit 0 }

} finally {
  Pop-Location
  Remove-Item -Recurse -Force $TMP -ErrorAction SilentlyContinue
}
