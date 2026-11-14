# What you get

Everything a rebuild puts on the Mac: packages, apps, shell setup, the font, and the macOS settings it changes.

The sources are [`home.nix`](../home.nix) for the packages and the shell, and [`configuration.nix`](../configuration.nix) for Homebrew and the macOS settings. `tests/docs.sh` fails when a package, brew or cask there has no row here.

## Nix packages

Installed for your user by home-manager, from `home.packages` in `home.nix`.

| Package | What it is for |
| --- | --- |
| `ripgrep` | Fast text search (`rg`) |
| `fd` | Fast file finder |
| `fzf` | Fuzzy finder for files, history and anything piped in |
| `jq` | Reads and edits JSON on the command line |
| `lazygit` | Git in a terminal UI |
| `neovim` | Terminal editor |
| `shellcheck` | Lints shell scripts; `./test.sh` uses it too |
| `nodejs` | Node.js, for JavaScript tools and `npx` |
| `pnpm` | Node package manager |
| `uv` | Python package and project manager; `uv tool install` puts tools in `~/.local/bin` |
| `yt-dlp` | Downloads audio and video from YouTube into iCloud (see below) |
| `ffmpeg` | Converts, trims and merges media for `yt-dlp` |
| `deno` | JavaScript runtime `yt-dlp` needs for YouTube's player check |
| `nerd-fonts.hack` | Hack Nerd Font, the font everything renders in |

## Homebrew

Installed by nix-darwin through Homebrew, from `configuration.nix`. Cleanup is `zap`, so anything not listed here is removed on the next rebuild ([ADR 0001](adr/0001-homebrew-cleanup-zap.md)). Every rebuild also upgrades what is installed ([ADR 0002](adr/0002-homebrew-upgrade-on-activation.md)).

| Name | Kind | What it is for |
| --- | --- | --- |
| `openmotif` | brew | The Motif GUI toolkit; installed on request and kept so `zap` does not remove it |
| `wezterm` | cask | The terminal |
| `claude-code@latest` | cask | Claude Code on the latest channel, which tracks the npm release; plain `claude-code` lags behind |

## Programs and shell setup

| Program | What the config sets |
| --- | --- |
| zsh | The shell. History suggestions show as grey text; `^f` (Ctrl-F) accepts one. Valid commands turn green as you type. |
| starship | The prompt: folder, git branch and status, how long the last command took, then `❯` on its own line (purple, or red after an error). |
| direnv | Loads a folder's `.envrc` when you `cd` in. With nix-direnv, a `use flake` there is cached, so it loads fast the second time. |
| git | Your name and email per Mac, `main` as the first branch, `git push` sets the upstream on the first push, and Git LFS. |
| gh | The GitHub CLI, over SSH. `gh co` checks out a pull request. |
| WezTerm | The terminal, from [`home/.config/wezterm/wezterm.lua`](../home/.config/wezterm/wezterm.lua): rose-pine-moon colors, Hack Nerd Font at 15 pt, a see-through blurred window, and no tab bar with one tab. `wezterm connect casa` opens tabs on the Mac mini home server that stay alive when the laptop disconnects. |
| yt-dlp | `--vid` for 1080p video CapCut can import, `--aud` for full audio, `-T` for an iOS tone, `--cut` to trim. Files land in `~/Documents/YouTube`, which iCloud syncs. Details in [`home/.config/yt-dlp/README.md`](../home/.config/yt-dlp/README.md). |

`EDITOR` is `code`, so tools that open an editor open VS Code. `~/.local/bin` is on `PATH`.

## Aliases and functions

The aliases are in `home.nix`; the functions are in [`home/.config/zsh/functions.zsh`](../home/.config/zsh/functions.zsh).

| Name | What it runs |
| --- | --- |
| `..` | `cd ..` |
| `add` | `git add .`, which stages everything. It is for you: agents are blocked from `git add .` and must stage files by name. |
| `push` | `git push` |
| `pull` | `git pull` |
| `m` | `git switch main` |
| `co` | Codex with `--full-auto` |
| `cc` | Claude Code with permission prompts skipped (`--dangerously-skip-permissions`) and remote control on. The session is named after the repo, so a second one in the same repo is `dotfiles-2`. Arguments after `cc` reach `claude`. |
| `cc-push` | Lets agents run a plain `git push` in this repo, or stops them. `on`, `off` and `status` set or read it; with no argument it flips. It writes the repo's own git config, so other repos are not affected. |
| `cc-flow` | Prints the ticket workflow as a table: which skill to run at each step. |

## Font

Hack Nerd Font (`nerd-fonts.hack`). Nerd Fonts add icons that terminal tools draw with. WezTerm uses it at 15 pt.

## macOS settings

From `system.defaults` in `configuration.nix`. Each applies on rebuild.

| Area | What changes |
| --- | --- |
| Appearance | Dark mode. The menu bar always shows. Scroll bars always show. |
| Dock | Hides until you point at it. Sits at the bottom. A minimized window goes into its app's icon. No recent apps. |
| Hot corners | Top left: Mission Control. Top right: Notification Center. Bottom left: show the desktop. Bottom right: put the display to sleep. |
| Stage Manager | When you turn it on: the strip of recent apps hides, and an app's windows show all at once. |
| Windows | New documents open as tabs. You can drag a window by holding anywhere on it. |
| Finder | Column view. Shows hidden files, every file extension, the path bar and the status bar. Folders sort first, on the desktop too. Columns resize to fit names. Items in the Trash are deleted after 30 days. No icons on the desktop. |
| Keyboard | Fast key repeat with a short delay before it starts. No automatic smart dashes. Automatic capitalization stays on. |
| Trackpad and mouse | Tap to click. Natural scrolling is off. Two-finger swipe goes back and forward. |
| Menu bar | Battery shows a percentage. |
| Calendar | Time zone support is on. |
| Screenshots | File names include the date and time. |
