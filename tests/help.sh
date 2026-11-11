#!/usr/bin/env bash
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "--help"
# Every script's: a help text printed as a line range of the source leaks the
# script itself, `set -euo pipefail` and all, the moment a line moves.
for s in bootstrap.sh rebuild.sh users.sh home/.claude/hooks/shell-parse.sh; do
  run env -u SUDO_USER "$DIR/$s" --help
  eq "$s --help exits 0" "0" "$RUN_RC"
  contains "$s --help prints usage" "$RUN_OUT" "usage:"
  case "$RUN_OUT" in
    *'set -e'* | *'#!/'* | *$'\n#'*)
      bad "$s --help prints prose, not source" "leaked a line of the script itself"
      ;;
    *) ok "$s --help prints prose, not source" ;;
  esac
  eq "$s --help never reaches sudo" "" "$SUDO_ARGS"
done

run env -u SUDO_USER "$DIR/users.sh"
eq "users.sh with no command exits 2" "2" "$RUN_RC"
contains "users.sh with no command explains itself" "$RUN_ERR" "usage:"

finish
