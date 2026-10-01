# Homebrew cleanup is zap

`homebrew.onActivation.cleanup = "zap"` in `configuration.nix` removes anything installed through Homebrew that the Nix config does not declare. It forces every package to be declared, which keeps the machine reproducible; `uninstall` or `none` would let ad-hoc installs pile up unseen.
