# Example: basic-react-app

A minimal walkthrough showing what MDDesign produces inside a small React project.

## Files

| File | Purpose |
|---|---|
| `task_plan.md` | planning-with-files plan with one UI phase |
| `findings.md` | shows the auto-injected `## Design Context` block from `design-bridge` |
| `progress.md` | shows a `### Phase Result` and a `### Handoff` stamp |
| `DESIGN.md` | a structurally valid Google Labs DESIGN.md harvested by `/mddesign:harvest` |
| `src/components/Button.tsx` | sample UI file that the harvest scanned |

## Replay it yourself

From a fresh React project:

```bash
# 1. Initialize planning
# (use the planning-with-files plugin to create task_plan.md / findings.md / progress.md)

# 2. Generate DESIGN.md from the existing code
/mddesign:harvest

# 3. Audit it
/mddesign:critique

# 4. Apply a quick win
/mddesign:fix F1

# 5. Open a UI phase in task_plan.md and ask the agent to build something
# design-bridge auto-injects the relevant tokens into findings.md "## Design Context"
```

## What you should see

- **Before MDDesign**: agent generates UI code with literal hex values, drifts from your design system silently.
- **After MDDesign**: every UI prompt includes the relevant tokens from `DESIGN.md` in the agent's attention window via `findings.md`. The agent uses `colors.primary` instead of `#3B82F6`. Critique catches drift before it ships.

This example is a minimal proof. For a real project, the wins compound: `/mddesign:handoff` makes sessions durable across `/clear`, `/mddesign:memory` lets you record decisions, `/mddesign:team` dispatches deep work to specialist subagents.
