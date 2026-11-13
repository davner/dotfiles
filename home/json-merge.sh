#!/usr/bin/env bash
# The merged file lands by rename, so a failed write leaves the old one whole. A linked
# target is resolved first, so the rename replaces the file it points at, not the link.
set -uo pipefail

usage() {
  cat >&2 <<'EOF'
usage: json-merge.sh [--skip-invalid] [--drop-link] [--extend <fragment>]... deep <base> <target>
       json-merge.sh [--skip-invalid] [--drop-link] append-unique <key,key,...> <base> <target>

deep           objects: base wins on the keys it names, nested objects merge
append-unique  arrays: append each base entry no target entry matches on all keys
--skip-invalid warn and exit 0 when a file is not plain JSON, instead of exit 1
--drop-link    replace a target that is a symlink with a real file
--extend       deep only: fold this fragment into the base first; repeatable, in order
EOF
  exit 2
}

skip_invalid=""
drop_link=""
extends=()
while [ $# -gt 0 ]; do
  case "$1" in
  --skip-invalid) skip_invalid=1 ;;
  --drop-link) drop_link=1 ;;
  --extend)
    [ $# -ge 2 ] || usage
    extends+=("$2")
    shift
    ;;
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
  # shellcheck disable=SC2016  # jq variables, not shell ones
  # A fragment only adds: an array or object the base sets is extended, never
  # replaced, since the final merge would carry the replacement over the target.
  filter='def extend($f; $p; $name):
      if type == "object" and ($f | type) == "object" then
        reduce ($f | to_entries[]) as $e (.;
          .[$e.key] |= if . == null then $e.value else extend($e.value; $p + [$e.key]; $name) end)
      elif type == "array" and ($f | type) == "array" then
        reduce $f[] as $x (.; if any(.[]; . == $x) then . else . + [$x] end)
      elif type == "array" or type == "object" then
        "\($name): \(if $p == [] then "the top level" else $p | join(".") end) is an \(type) in the base, and a fragment may only extend it, not replace it with \($f | type)\n"
        | halt_error(3)
      else $f end;
    . as $all
    | .[0] * reduce range(2; length) as $i (.[1]; extend($all[$i]; []; $ARGS.positional[$i - 2]))'
  ;;
append-unique)
  [ $# -eq 4 ] && [ -n "$2" ] && [ ${#extends[@]} -eq 0 ] || usage
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
for f in ${extends[@]+"${extends[@]}"}; do
  [ -f "$f" ] || give_up "$f is missing"
  jq -e 'type == "object"' "$f" >/dev/null 2>&1 || give_up "$f is not a plain JSON object"
done
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
merge() { jq -s --arg keys "$keys" "$filter" "$real" "$base" ${extends[@]+"${extends[@]}"} --args ${extends[@]+"${extends[@]}"}; }
merged="$(merge 2>/dev/null)"
case $? in
0) ;;
# A refused fragment is a mistake in the config, not a file to skip.
3)
  echo "json-merge: $(merge 2>&1 >/dev/null)" >&2
  exit 1
  ;;
*) give_up "$target or $base is not plain JSON" "$(merge 2>&1 >/dev/null)" ;;
esac
# cp -p first so the new file keeps the old one's mode.
tmp="$(mktemp "$(dirname "$real")/.json-merge.XXXXXX")" &&
  cp -p "$real" "$tmp" &&
  printf '%s\n' "$merged" >"$tmp" &&
  mv -f "$tmp" "$real" || exit 1
tmp=""
