# Metals gets each folder's JDK from its own settings

Superseded: `metals-java-home` is work-only and left this repo for the private work layer, which carries this decision. Kept for the reasoning.

In a multi-root VS Code workspace, the direnv extension loads one `.envrc` for the whole window, and its maintainer has said per-folder loading is not possible ([direnv-vscode#590](https://github.com/direnv/direnv-vscode/issues/590)). Metals then runs `sbt bloopInstall` on its own fallback JDK, and a build that needs a newer JDK imports no build targets. `metals.javaHome` has `machine-overridable` scope, so a folder's own `.vscode/settings.json` can set it, and Metals reads its settings per folder. `metals-java-home` (from `home/vscode/metals-java-home.sh`, linked into `~/.local/bin`) writes each folder's flake `JAVA_HOME` there, taking folders or a `.code-workspace` file.

## Consequences

- The value is a `/nix/store` path. It goes stale only when a flake changes its JDK; rerun `metals-java-home` then. nix-direnv's GC root keeps the old path alive until then.
- It runs by hand, not on rebuild: activation does not know which repos are open together, and evaluating their flakes would slow every rebuild.
- It refuses a git-tracked `.vscode/settings.json`, so a machine path never reaches a shared repo, and skips a hand-commented one, as ADR 0010 does.
- Rejected: one shared `.envrc` above the repos (they pin different Node versions); `metals.sbtScript` wrapping `direnv exec` (window scope, so it can't vary per folder); sbt's own build server via `.bsp/sbt.json` (slower than Bloop, and the file is not gitignored in every repo).
