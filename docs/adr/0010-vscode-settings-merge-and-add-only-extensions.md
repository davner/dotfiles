# VS Code settings are merged, extensions are add-only

`home/vscode/settings.base.json` and `keybindings.base.json` are merged into `~/Library/Application Support/Code/User/` on every rebuild by `home/json-merge.sh`, the script that also merges Claude's settings (ADR 0007), and are never linked: the settings UI writes to those files, so a link would route every toggle into this repo. Settings deep-merge with base winning on the keys it names; keybindings are appended only when no entry with the same `key`, `command` and `when` already exists, because a keybindings file is an array and a replace would drop bindings made in the UI.

`home/vscode/extensions.json` lists the extensions of each profile (`Default`, `Web`, `Scala`, `Python`), and `extensions.sh` installs the missing ones with `code --profile`. It never uninstalls, so trying an extension does not mean editing this repo first.

## Consequences

- Profiles are created in the VS Code UI, not by the script. A profile the `code` CLI creates gets its own empty settings instead of sharing Default's, so the script reports a missing profile and moves on.
- VS Code allows comments and trailing commas in its JSON; `jq` does not. A hand-commented `settings.json` or `keybindings.json` is skipped with a warning rather than rewritten (`--skip-invalid`); Claude's merge stops the rebuild instead.
- Removing an extension from a profile is two steps: delete it from `extensions.json`, then uninstall it in VS Code.
- Settings Sync is off: this repo is the sync.
- Neither step fails the activation. VS Code missing, the marketplace down, or a profile not yet created each print a line and the rebuild carries on.
