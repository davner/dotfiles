#!/usr/bin/env bash
# Writes in place, not by rename, so a linked target is written through unless --drop-link.
set -uo pipefail

usage() {
  cat >&2 <<'EOF'
usage: json-merge.sh [--skip-invalid] [--drop-link] deep <base> <target>
       json-merge.sh [--skip-invalid] [--drop-link] append-unique <key,key,...> <base> <target>

deep           objects: base wins on the keys it names, nested objects merge
append-unique  arrays: append each base entry no target entry matches on all keys
--skip-invalid warn and exit 0 when a file is not plain JSON, instead of exit 1
--drop-link    replace a target that is a symlink with a real file
EOF
  exit 2
}

skip_invalid=""
drop_link=""
while [ $# -gt 0 ]; do
  case "$1" in
  --skip-invalid) skip_invalid=1 ;;
  --drop-link) drop_link=1 ;;
  -*) usage ;;
  *) break ;;
  esac
  shift
done

mode="${1-}"
keys=""
case "$mode" in
deep)
  [ $# -eq 3 ] || usage
  empty='{}'
  filter='.[0] * .[1]'
  ;;
append-unique)
  [ $# -eq 4 ] && [ -n "$2" ] || usage
  keys="$2"
  shift
  empty='[]'
  # shellcheck disable=SC2016  # jq variables, not shell ones
  filter='($keys | split(",")) as $k | .[0] as $t
    | $t + [.[1][] as $b | select(all($t[]; . as $a | any($k[]; $a[.] != $b[.]))) | $b]'
  ;;
*) usage ;;
esac
base="$2"
target="$3"

give_up() { # message [detail]
  if [ -n "$skip_invalid" ]; then
    echo "json-merge: $1, skipped" >&2
    exit 0
  fi
  echo "json-merge: $1" >&2
  [ -z "${2-}" ] || printf '%s\n' "$2" >&2
  exit 1
}

[ -f "$base" ] || give_up "$base is missing"
mkdir -p "$(dirname "$target")" || exit 1
if [ -n "$drop_link" ] && [ -L "$target" ]; then rm -f "$target" || exit 1; fi
if [ ! -f "$target" ]; then printf '%s\n' "$empty" >"$target" || exit 1; fi
if ! merged="$(jq -s --arg keys "$keys" "$filter" "$target" "$base" 2>/dev/null)"; then
  give_up "$target or $base is not plain JSON" "$(jq -s --arg keys "$keys" "$filter" "$target" "$base" 2>&1 >/dev/null)"
fi
printf '%s\n' "$merged" >"$target" || exit 1
