# One darwinConfiguration per username

`flake.nix` exposes one `darwinConfigurations` entry per username in its `users` attrset, and `bootstrap.sh` and `rebuild.sh` pick the one matching whoever runs them. A single `user = "..."` value rewritten in place dirtied `flake.nix` on every switch between the work and personal Mac, and whichever value got committed broke the other machine. Entries are additive: adding a machine never removes a username. Each username maps to a record of what differs per machine (git address, platform), so a new Mac is one edit in one file.
