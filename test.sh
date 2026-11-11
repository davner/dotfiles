#!/usr/bin/env bash
# Runs each tests/*.sh, one file per module, in a bash of its own and sums the
# counts. Helpers and fixtures are in tests/lib.sh; nothing needs sudo or real $HOME.

# usage: ./test.sh [--fast] [NAME...]
#   --fast skips the nix evaluations; NAME runs only tests/NAME.sh.
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
usage() { sed -n '5,6s/^# \{0,1\}//p' "$DIR/test.sh"; }

FAST=""
names=()
for arg in "$@"; do
  case "$arg" in
    --fast) FAST=1 ;;
    -h | --help) usage; exit 0 ;;
    -*) echo "test.sh: unknown flag $arg" >&2; usage >&2; exit 2 ;;
    *) names+=("$arg") ;;
  esac
done

files=()
if [ "${#names[@]}" -eq 0 ]; then
  for f in "$DIR"/tests/*.sh; do
    [ "$(basename "$f")" = lib.sh ] || files+=("$f")
  done
else
  for n in "${names[@]}"; do
    n="${n##*/}"
    n="${n%.sh}"
    if [ "$n" = lib ] || [ ! -f "$DIR/tests/$n.sh" ]; then
      echo "test.sh: no test file tests/$n.sh" >&2
      exit 2
    fi
    files+=("$DIR/tests/$n.sh")
  done
fi

RESULTS="$(mktemp -d)"
trap 'rm -rf "$RESULTS"' EXIT
if [ -t 1 ]; then B=$'\033[1m'; G=$'\033[32m'; R=$'\033[31m'; Z=$'\033[0m'; else B=""; G=""; R=""; Z=""; fi

pass=0
fail=0
skipped=0
failures=()
for f in "${files[@]}"; do
  name="tests/$(basename "$f")"
  result="$RESULTS/$(basename "$f" .sh)"
  printf '\n%s== %s ==%s\n' "$B" "$name" "$Z"
  TEST_FAST="$FAST" TEST_RESULT="$result" bash "$f" </dev/null
  rc=$?
  p=0 fl=0 s=0 state=died
  [ -f "$result" ] && read -r p fl s state <"$result"
  if [ -f "$result.fails" ]; then
    while IFS= read -r line; do failures+=("$name: $line"); done <"$result.fails"
  fi
  # A file that stops early has skipped every check after the one it died on,
  # so it fails even when nothing it reached did.
  if [ "$state" != ended ]; then
    printf '  %sFAIL%s  %s stopped before its end (exit %s)\n' "$R" "$Z" "$name" "$rc"
    failures+=("$name: stopped before its end (exit $rc)")
    fl=$((fl + 1))
  fi
  pass=$((pass + p))
  fail=$((fail + fl))
  skipped=$((skipped + s))
done

if [ "${#failures[@]}" -gt 0 ]; then
  printf '\n%sFailures:%s\n' "$R" "$Z"
  printf '  %s\n' "${failures[@]}"
fi
printf '\n%s%d passed%s, %s%d failed%s, %d skipped\n' \
  "$G" "$pass" "$Z" "$([ "$fail" -gt 0 ] && printf '%s' "$R")" "$fail" "$Z" "$skipped"
[ "$fail" -eq 0 ]
