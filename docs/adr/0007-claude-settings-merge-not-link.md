# Claude settings are merged, not linked

`home/.claude/settings.base.json` holds the durable half of Claude Code's user settings (hooks, `permissions.deny`, `statusLine`, `skipDangerousModePermissionPrompt`, `agentPushNotifEnabled`, `worktree`), and a `home.activation` step deep-merges it over `~/.claude/settings.json` with `home/json-merge.sh deep`. `~/.claude/settings.json` is deliberately not symlinked: `/config`, `/model` and `/effort` write to it, so a link would route every mid-session preference change into this repo. Base wins on the keys it names, so a hook change lands on the next rebuild, and every other key survives.

## Consequences

- `model`, `effortLevel` and `theme` stay out of the base file: base wins, so a rebuild would revert the `/config` change. `tests/claude-settings.sh` asserts both that those keys are absent and that `home.nix` does not link `settings.json`.
- Those three are therefore not version-controlled, and a fresh Mac uses Claude Code's defaults until one `/config`.
- A user-level `settings.local.json` is not a fix: Claude Code documents no `~/.claude/settings.local.json`. `/status` names the files actually read.
- The merged base's arrays replace the local file's arrays outright, `permissions.deny` and each hook event alike. A hook or deny rule another tool appends to one of those in `settings.json` is dropped on the next rebuild; one meant to last goes in the base file.
