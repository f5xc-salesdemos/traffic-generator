# Claude Code Project Instructions

## Managed Files

Files in `.claude/governance.json` are managed by docs-control.
A hook blocks direct edits — open an issue in docs-control instead.

## Git Operations

Delegate ALL Git/GitHub operations to `f5xc-github-ops:github-ops`.
Never run `git commit`, `git push`, `gh pr create` directly.

```
Agent(
  subagent_type="f5xc-github-ops:github-ops",
  mode="bypassPermissions",
  prompt="<type>: <desc>\n\nFiles:\n- <list>\n\nWhy: <reason>"
)
```

`mode="bypassPermissions"` is required — without it, plan mode can
re-engage mid-workflow and strip the agent's Bash access, leaving
it stuck after the first step.

See `CONTRIBUTING.md` for project rules.
