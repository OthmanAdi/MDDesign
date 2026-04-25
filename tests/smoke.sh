#!/usr/bin/env bash
# MDDesign smoke test (bash / Git Bash on Windows)
# Verifies every hook runs and prints expected output.
# Usage: bash tests/smoke.sh
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap "rm -rf '$TMP'" EXIT

PASS=0
FAIL=0

ok() { echo "  OK: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "=== MDDesign smoke test ==="
echo "Plugin root: $ROOT"
echo "Tmp project: $TMP"
echo ""

# ─── Probe 1: hooks.json structure ────────────────────────────────
echo "[1] hooks/hooks.json structure"
if grep -q '"hooks"' "$ROOT/hooks/hooks.json" && grep -q '"description"' "$ROOT/hooks/hooks.json"; then
  ok "hooks.json has 'hooks' wrapper and 'description'"
else
  fail "hooks.json missing wrapper or description"
fi

# ─── Probe 2: SessionStart hook (no plan, no DESIGN.md) ───────────
echo "[2] SessionStart hook from empty project"
cd "$TMP"
OUT=$(bash "$ROOT/hooks/session-start/preamble.sh" 2>&1)
echo "$OUT" | grep -q "\[MDDesign\] active" && ok "banner printed" || fail "no banner"
[ -d ".agents/memory/scratch" ] && ok "scratch dir created" || fail "scratch dir not created"

# ─── Probe 3: SessionStart hook with task_plan.md ─────────────────
echo "[3] SessionStart hook with planning files"
echo "# Task Plan" > task_plan.md
OUT=$(bash "$ROOT/hooks/session-start/preamble.sh" 2>&1)
echo "$OUT" | grep -q "planning-with-files detected" && ok "detected planning-with-files" || fail "did not detect planning"

# ─── Probe 4: SessionStart hook with UI file but no DESIGN.md ─────
echo "[4] SessionStart hook with UI file but no DESIGN.md"
mkdir -p src && touch src/App.tsx
OUT=$(bash "$ROOT/hooks/session-start/preamble.sh" 2>&1)
echo "$OUT" | grep -q "/mddesign:harvest" && ok "nudges /mddesign:harvest" || fail "did not nudge harvest"

# ─── Probe 5: SessionStart hook with DESIGN.md present ────────────
echo "[5] SessionStart hook with DESIGN.md present"
echo "---" > DESIGN.md
OUT=$(bash "$ROOT/hooks/session-start/preamble.sh" 2>&1)
echo "$OUT" | grep -q "DESIGN.md detected" && ok "detected DESIGN.md" || fail "did not detect DESIGN.md"

# ─── Probe 6: Stop hook appends handoff stamp ─────────────────────
echo "[6] Stop hook"
echo "# Progress" > progress.md
bash "$ROOT/hooks/stop/promote.sh" >/dev/null 2>&1
grep -q "Handoff" progress.md && ok "Stop hook appended Handoff stamp" || fail "no Handoff stamp"

# ─── Probe 7: PreToolUse hook gates DESIGN.md write ───────────────
echo "[7] PreToolUse hook on DESIGN.md path"
PAYLOAD='{"tool_name":"Write","tool_input":{"file_path":"/tmp/DESIGN.md"}}'
OUT=$(echo "$PAYLOAD" | bash "$ROOT/hooks/pre-tool-use/gate.sh" 2>&1)
echo "$OUT" | grep -q "before_design_md_write" && ok "DESIGN.md write checkpoint fired" || fail "no checkpoint on DESIGN.md write"

# ─── Probe 8: command files exist with namespaced names ───────────
echo "[8] commands/ has new namespaced files"
for c in harvest critique fix inject compose handoff memory team setup doctor; do
  [ -f "$ROOT/commands/$c.md" ] && ok "commands/$c.md present" || fail "commands/$c.md MISSING"
done

# ─── Probe 9: no stale /design: references in canonical files ─────
echo "[9] no stale /design: references in canonical SKILLS"
if grep -rE "/design:[a-z]+" "$ROOT/skills" "$ROOT/agents" "$ROOT/AGENTS.md" "$ROOT/docs" >/dev/null 2>&1; then
  fail "found stale /design: references"
  grep -rE "/design:[a-z]+" "$ROOT/skills" "$ROOT/agents" "$ROOT/AGENTS.md" "$ROOT/docs" 2>/dev/null | head -3
else
  ok "no stale /design: references"
fi

# ─── Probe 10: @google/design.md lint reachable ───────────────────
echo "[10] @google/design.md lint reachable"
if command -v npx >/dev/null; then
  cat > probe.md <<'EOF'
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
EOF
  if npx --yes @google/design.md lint probe.md >/dev/null 2>&1; then
    ok "@google/design.md lint passes on minimal valid file"
  else
    fail "@google/design.md lint failed"
  fi
else
  fail "npx not on PATH"
fi

echo ""
echo "=== Result: $PASS passed / $FAIL failed ==="
[ "$FAIL" -eq 0 ] || exit 1
exit 0
