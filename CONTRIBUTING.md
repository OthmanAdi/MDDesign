# Contributing to MDDesign

Short rules. The fewer the better.

## Adding an IDE port

To add MDDesign support for a new agent IDE:

1. Add a folder name + sync target to `IDE_TARGETS` in `scripts/sync-ide-folders.py`
2. Run `python scripts/sync-ide-folders.py` and confirm canonical `skills/`, `agents/`, `commands/` are mirrored into the new folder
3. If the IDE has a hook API, document its hook registration path in a one-paragraph note inside `docs/architecture.md` under "Multi-IDE distribution"
4. Test by copying the new IDE folder into a real project and confirming the skills are discoverable
5. Add a row to the IDE table in `README.md`

## Adding a new skill or command

1. Add it under `skills/<name>/SKILL.md` or `commands/<name>.md`
2. Run the smoke test: `bash tests/smoke.sh` (and `tests/smoke.ps1` on Windows)
3. Run `python scripts/sync-ide-folders.py` to regenerate IDE mirrors
4. Update the command table in `README.md`

Keep `SKILL.md` files under 500 lines.

## Reporting a bug

Open a GitHub issue with:

- Platform and version (Claude Code 1.x, Cursor x.y, Codex CLI, etc.)
- Shell (bash, zsh, Git Bash, PowerShell version)
- What you ran and what you expected
- Output of `/mddesign:doctor` if the agent is reachable, or the relevant lines from `~/.claude/settings.json` if it is not

## Pull request rules

- **No new runtime dependencies.** bash, PowerShell, and `npx` (for `@google/design.md`) are the only runtime tools allowed.
- **Cross-platform parity.** Every `.sh` script needs a matching `.ps1` script. The hooks try PowerShell first and fall back to bash, so both must produce equivalent output.
- **Smoke tests must pass.** `bash tests/smoke.sh` and `pwsh tests/smoke.ps1` must both exit 0 before merge.
- **Preserve user state.** When MDDesign is installed alongside a pre-existing hook setup in `~/.claude/settings.json`, the user's existing hooks must keep working. Test this: install with another plugin's hooks already registered, confirm both fire.
- **No `Co-Authored-By` in commits.** Contributors get credit in `CHANGELOG.md` and in a Thanks section, not in commit trailers.
- **Core preservation.** Never write to `task_plan.md`. `DESIGN.md` only via `/mddesign:harvest` or `/mddesign:fix`. Memory only via `code-memory-router`. If your PR breaks any of these, the design is wrong.

## License

By contributing you agree that your contribution is licensed under Apache-2.0.
