# users.sh owns the shape of the users attrset

`users.sh` is the only parser of the `users` attrset, and it holds `flake.nix` to a shape: one quoted username per line, each opening an attrset record, closed by the `# end users` marker. It uses nothing but bash, sed and awk because `bootstrap.sh` calls it seconds after nix is installed, when nix may not work yet. `test.sh` asserts the shape, since reformatting the attrset or dropping the marker breaks both scripts.

## Consequences

`users.sh add` writes an empty record, so every per-user field must stay optional where it is read. That is why `configuration.nix` defaults `hostPlatform` instead of indexing `cfg.system`: without the default, a fresh Mac sees a module-system stack trace instead of the missing-email error.
