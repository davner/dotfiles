#!/usr/bin/env bash
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "changelog"
# The changelog is read weeks after it is generated, so this is where a broken
# template shows. Shapes, not a snapshot, so a new commit never edits this file.
if ! command -v git-cliff >/dev/null 2>&1; then
  skip "git-cliff (nix develop --command ./test.sh installs it)"
else
  CL="$WORK/CHANGELOG.md"
  if err="$(cd "$DIR" && git-cliff -o "$CL" 2>&1 >/dev/null)"; then
    ok "cliff.toml and its template render"
  else
    bad "cliff.toml and its template render" "$err"
  fi

  headings="$(grep '^## ' "$CL")"
  eq "one heading per date" \
    "$(printf '%s\n' "$headings" | sort -u | wc -l | tr -d ' ')" \
    "$(printf '%s\n' "$headings" | wc -l | tr -d ' ')"

  # ISO dates sort lexically, so the header's "newest first" is checkable.
  if [ "$(printf '%s\n' "$headings" | sort -r)" = "$headings" ]; then
    ok "dates run newest first"
  else
    bad "dates run newest first" "$(printf '%s' "$headings" | tr '\n' ' ')"
  fi

  # Matched by sha rather than by subject, because a commit is free to talk
  # about merging, or about regenerating the changelog, without being one.
  leaked=""
  while IFS= read -r sha; do
    [ -n "$sha" ] || continue
    grep -qF "$sha" "$CL" && leaked="$leaked ${sha:0:7}"
  done < <(cd "$DIR" && git log --merges --format='%H')
  if [ -z "$leaked" ]; then
    ok "merge commits stay out"
  else
    bad "merge commits stay out" "reached the changelog:$leaked"
  fi

  leaked=""
  while IFS= read -r sha; do
    [ -n "$sha" ] || continue
    grep -qF "$sha" "$CL" && leaked="$leaked ${sha:0:7}"
  done < <(cd "$DIR" && git log --format='%H%x09%s' |
    awk -F'\t' '$2 == "docs: regenerate the changelog" {print $1}')
  if [ -z "$leaked" ]; then
    ok "the changelog bot's own commits stay out"
  else
    bad "the changelog bot's own commits stay out" "reached the changelog:$leaked"
  fi

  # The other half of that skip: wide enough to catch the bot, never wide
  # enough to swallow a real commit that happens to be about the changelog.
  expected="$(cd "$DIR" && git log --no-merges --format='%H%x09%s' |
    awk -F'\t' '$2 != "docs: regenerate the changelog" {print $1}')"
  missing=""
  while IFS= read -r sha; do
    [ -n "$sha" ] || continue
    grep -qF "$sha" "$CL" || missing="$missing ${sha:0:7}"
  done <<<"$expected"
  if [ -z "$missing" ]; then
    ok "every other commit reaches the changelog"
  else
    bad "every other commit reaches the changelog" "missing:$missing"
  fi

  eq "one entry per commit" \
    "$(printf '%s\n' "$expected" | grep -c .)" \
    "$(grep -c '^- \*\*' "$CL")"

  # An unconventional subject hands the template the whole message, which
  # breaks the entry across a paragraph and leaves its link on a line alone.
  if orphan="$(grep -n 'commit/' "$CL" | grep -v '^[0-9]*:- \*\*')"; then
    bad "every entry is one line" "$orphan"
  else
    ok "every entry is one line"
  fi
fi

finish
