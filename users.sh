#!/usr/bin/env bash
# The one place that reads and extends flake.nix's users list. bootstrap.sh and
# rebuild.sh both go through this, so the list is parsed exactly one way and
# there is a single thing for test.sh to hold to the format.
#
# usage: ./users.sh list [FLAKE]          print every configured username
#        ./users.sh has USERNAME [FLAKE]  exit 0 if configured, 1 if not
#        ./users.sh add USERNAME [FLAKE]  append it, no-op if already there
#
# FLAKE defaults to this repo's flake.nix. This deliberately depends on nothing
# but bash, sed and awk: bootstrap.sh calls it on a machine where nix may have
# been installed seconds ago and may not work yet.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

usage() {
  cat <<'EOF'
usage: ./users.sh list [FLAKE]          print every configured username
       ./users.sh has USERNAME [FLAKE]  exit 0 if configured, 1 if not
       ./users.sh add USERNAME [FLAKE]  append it, no-op if already there

FLAKE defaults to this repo's flake.nix.
EOF
}

# Every quoted string between the list opening and its end marker.
extract() {
  local out
  out="$(sed -nE '/users = \[/,/# end users/ s/^[[:space:]]*"([^"]+)".*/\1/p' "$1")"
  if [ -z "$out" ]; then
    echo "${0##*/}: found no usernames in $1" >&2
    echo "  The list has to stay one quoted username per line between" >&2
    echo "  'users = [' and the '# end users' marker." >&2
    return 1
  fi
  printf '%s\n' "$out"
}

cmd="${1-}"
[ $# -gt 0 ] && shift

case "$cmd" in
  list)
    extract "${1:-$DIR/flake.nix}"
    ;;

  has)
    name="${1:?has needs a username}"
    printf '%s\n' "$(extract "${2:-$DIR/flake.nix}")" | grep -qxF "$name"
    ;;

  add)
    name="${1:?add needs a username}"
    flake="${2:-$DIR/flake.nix}"
    # The name is about to become a Nix string literal and a flake attribute.
    if ! printf '%s' "$name" | grep -qE '^[A-Za-z0-9._-]+$'; then
      echo "${0##*/}: refusing to add \"$name\": expected only letters," >&2
      echo "  digits, dot, underscore and dash." >&2
      exit 1
    fi
    existing="$(extract "$flake")"
    if printf '%s\n' "$existing" | grep -qxF "$name"; then
      exit 0
    fi
    if ! grep -qF '# end users' "$flake"; then
      echo "${0##*/}: no '# end users' marker in $flake, nowhere to append" >&2
      exit 1
    fi
    # Indent to match the marker line, so this survives the list being
    # reindented. Rewrite through a variable rather than a temp file and mv,
    # which would leave flake.nix owned by mktemp's 0600.
    updated="$(awk -v u="$name" '
      /# end users/ && !added {
        match($0, /^[ \t]*/)
        printf "%s  \"%s\"\n", substr($0, 1, RLENGTH), u
        added = 1
      }
      { print }
    ' "$flake")"
    printf '%s\n' "$updated" >"$flake"
    ;;

  -h | --help | help)
    usage
    ;;

  "")
    usage >&2
    exit 2
    ;;

  *)
    echo "${0##*/}: unknown command \"$cmd\"" >&2
    usage >&2
    exit 2
    ;;
esac
