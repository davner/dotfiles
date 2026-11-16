#!/usr/bin/env bash
# The merged file lands by rename, so a failed write leaves the old one whole. A linked
# target is resolved first, so the rename replaces the file it points at, not the link.
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
  # Checked against what has been added so far, so a base that repeats an entry adds it once.
  filter='($keys | split(",")) as $k
    | reduce .[1][] as $b (.[0]; if any(.[]; . as $a | all($k[]; $a[.] == $b[.])) then . else . + [$b] end)'
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
tmp=""
trap '[ -z "$tmp" ] || rm -f "$tmp"' EXIT
if [ -n "$drop_link" ] && [ -L "$target" ]; then
  # What the link pointed at is the user's settings, so it becomes the starting point.
  if [ -f "$target" ]; then
    tmp="$(mktemp "$(dirname "$target")/.json-merge.XXXXXX")" &&
      cp "$target" "$tmp" && mv -f "$tmp" "$target" || exit 1
    tmp=""
  else
    rm -f "$target" || exit 1
  fi
fi
real="$target"
while [ -L "$real" ]; do
  next="$(readlink "$real")" || exit 1
  case "$next" in
  /*) real="$next" ;;
  *) real="$(dirname "$real")/$next" ;;
  esac
done
if [ ! -f "$real" ]; then printf '%s\n' "$empty" >"$real" || exit 1; fi
if ! merged="$(jq -s --arg keys "$keys" "$filter" "$real" "$base" 2>/dev/null)"; then
  give_up "$target or $base is not plain JSON" "$(jq -s --arg keys "$keys" "$filter" "$real" "$base" 2>&1 >/dev/null)"
fi
# cp -p first so the new file keeps the old one's mode.
tmp="$(mktemp "$(dirname "$real")/.json-merge.XXXXXX")" &&
  cp -p "$real" "$tmp" &&
  printf '%s\n' "$merged" >"$tmp" &&
  mv -f "$tmp" "$real" || exit 1
tmp=""
