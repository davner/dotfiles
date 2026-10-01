# home-manager backs up files instead of forcing

`home-manager.backupFileExtension = "backup"` in `flake.nix` moves a pre-existing dotfile aside instead of failing activation, and nothing is overwritten in place. `force = true` on file options was rejected because it silently destroys what was there. When activation reports that a `.backup` would itself be clobbered, an older backup is still on disk: read it, then delete it.
