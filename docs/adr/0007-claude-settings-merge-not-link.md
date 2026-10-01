# Claude settings are merged, not linked

`home/.claude/settings.base.json` holds the durable half of Claude Code's user settings (hooks, `statusLine`, `skipDangerousModePermissionPrompt`, `agentPushNotifEnabled`), and a `home.activation` step deep-merges it over `~/.claude/settings.json` with `jq -s '.[0] * .[1]'`. `~/.claude/settings.json` is deliberately not symlinked: `/config`, `/model` and `/effort` write to it, so a link would route every mid-session preference change into this repo. Base wins on the keys it names, so a hook change reaches every machine on the next rebuild, and every other key survives.

## Consequences

- `model`, `effortLevel` and `theme` stay out of the base file: base wins, so a rebuild would revert the `/config` change. `test.sh` asserts both that those keys are absent and that `home.nix` does not link `settings.json`.
- Those three are therefore not version-controlled, and a fresh Mac uses Claude Code's defaults until one `/config`.
- A user-level `settings.local.json` is not a fix: Claude Code documents no `~/.claude/settings.local.json`. `/status` names the files actually read.
