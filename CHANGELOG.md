# Changelog

All notable changes to MDDesign are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-04-25

### Added
- First public release.
- Five core skills: `design-bridge`, `design-harvest`, `memory-layer`, `session-handoff`, `team-dispatch`.
- Ten slash commands: `setup`, `doctor`, `compose`, `harvest`, `critique`, `fix`, `inject`, `handoff`, `memory`, `team`.
- Five subagents: `planner`, `executor`, `reviewer`, `memory-keeper`, `design-archeologist`.
- Cross-platform hooks (bash + PowerShell) for SessionStart, UserPromptSubmit, PreToolUse, Stop.
- Day-1 IDE mirrors: Claude Code, Cursor, Codex CLI, Windsurf, Cline, OpenCode.
- Smoke tests in both bash and PowerShell. 20 probes.
- Walkthrough example at `examples/basic-react-app/`.
- PhaseSpec v1 dispatch contract documented in `skills/team-dispatch/SKILL.md`.

### Notes
- Required runtime: Node + `npx` (for `@google/design.md` lint).
- Required companion skill: `planning-with-files`.
- Optional companion: `code-memory-router` (unlocks WHY/WHERE memory tiers).
- HITL gates in v0.1.0 are informational. Blocking mode reserved for v0.2.
