#!/usr/bin/env bash
# shellcheck disable=SC2154  # lib.sh sets rc, listed and first
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "out-of-store symlink targets"
# mkOutOfStoreSymlink does not check its target, so a typo is a dangling link in
# $HOME that nothing reports. Templated targets are left to "links from the repo".
targets="$(sed -nE 's|.*mkOutOfStoreSymlink "\$\{dotfiles\}/([^"$]+)".*|\1|p' "$DIR/home.nix" | sort -u)"
if [ -z "$targets" ]; then
  bad "found mkOutOfStoreSymlink targets in home.nix" "the sed found nothing - did home.nix change shape?"
else
  while read -r t; do
    if [ -e "$DIR/$t" ]; then ok "$t exists"; else bad "$t exists" "home.nix links to a path this repo does not have"; fi
  done <<<"$targets"
fi

section "links from the repo"
# A flake sees only tracked files and mkOutOfStoreSymlink never checks its
# target, so a missed `git add` or a wrong path is a silently broken link.
entries() { # repo folder, find tests -> the names in it, sorted
  local d=$1
  shift
  find "$DIR/$d" -mindepth 1 -maxdepth 1 "$@" -exec basename {} \; | sort
}
link_target() { # links, user, home.file key -> the repo path it links to
  awk -F'\t' -v k="$3" -v p="ln -s /Users/$2/.dotfiles/" -v e=' $out' \
    '$1 == k && index($2, p) == 1 && substr($2, length($2) - length(e) + 1) == e {
      print substr($2, length(p) + 1, length($2) - length(p) - length(e)) }' <<<"$1"
}
linked_each() { # links, user, repo folder, home folder, names on disk
  local name missing="" extra why=()
  while read -r name; do
    [ -n "$name" ] || continue
    [ "$(link_target "$1" "$2" "$4/$name")" = "$3/$name" ] || missing="$missing $name"
  done <<<"$5"
  extra="$(awk -F'\t' -v d="$4/" 'index($1, d) == 1 { n = substr($1, length(d) + 1); if (n !~ /\//) print n }' <<<"$1" |
    grep -vxF -f <(printf '%s\n' "$5") | tr '\n' ' ')"
  [ -z "$missing" ] || why+=("not linked to its repo path:$missing - a flake sees only tracked files, git add it")
  [ -z "${extra// /}" ] || why+=("linked but not on disk: $extra")
  if [ "${#why[@]}" -eq 0 ]; then
    ok "$2: each entry of $3 is linked into ~/$4"
  else
    bad "$2: each entry of $3 is linked into ~/$4" "${why[@]}"
  fi
}
if full_only && require nix jq; then
  fixture_users
  # impeccable's paths are under skills/, where its own installer puts them.
  # shellcheck disable=SC2016  # the $HOME is the literal text being matched
  settings_runs="$(jq -r '.. | objects | .command? // empty' "$BASE" |
    grep -oE '(~|\$HOME|\$\{HOME\})/\.claude/[A-Za-z0-9._/-]+' |
    sed -E 's#^(~|\$HOME|\$\{HOME\})/##' | grep -v '^\.claude/skills/' | sort -u)"
  [ -n "$settings_runs" ] ||
    bad "found the ~/.claude paths settings.base.json runs" "none matched - did the commands change shape?"
  hooks_on_disk="$(entries home/.claude/hooks -type f)"
  rules_on_disk="$(entries home/.claude/rules -type f -name '*.md')"
  skills_on_disk="$(entries home/.claude/skills -type d)"
  while read -r u; do
    [ -n "$u" ] || continue
    # shellcheck disable=SC2016  # the ${} are Nix interpolation, not shell
    links="$(nix eval --raw "$DIR#darwinConfigurations.${u//./-}.config.home-manager.users.\"$u\".home.file" \
      --apply 'f: builtins.concatStringsSep "\n" (builtins.concatMap (n:
        let s = f.${n}.source; in
        if builtins.substring 0 8 n == ".claude/" && builtins.isAttrs s && s ? buildCommand
        then [ "${n}\t${s.buildCommand}" ] else [ ]) (builtins.attrNames f))' \
      2>"$WORK/stderr")"
    if [ -z "$links" ]; then
      bad "$u: home.file evaluates" "$(grep -v '^warning:' "$WORK/stderr" | head -5)"
      continue
    fi
    broken=""
    while read -r p; do
      [ -n "$p" ] || continue
      rel="$(link_target "$links" "$u" "$p")"
      if [ -z "$rel" ]; then
        broken="$broken ~/$p(no out-of-store link into ~/.dotfiles)"
      elif [ ! -f "$DIR/$rel" ] || [ ! -x "$DIR/$rel" ]; then
        broken="$broken ~/$p($rel is not an executable file)"
      elif ! git -C "$DIR" ls-files --error-unmatch -- "$rel" >/dev/null 2>&1; then
        broken="$broken ~/$p($rel is untracked)"
      fi
    done <<<"$settings_runs"
    if [ -z "$broken" ]; then
      ok "$u: everything settings.base.json runs is linked to an executable tracked file"
    else
      bad "$u: everything settings.base.json runs is linked to an executable tracked file" "$broken"
    fi
    linked_each "$links" "$u" home/.claude/hooks .claude/hooks "$hooks_on_disk"
    linked_each "$links" "$u" home/.claude/rules .claude/rules "$rules_on_disk"
    linked_each "$links" "$u" home/.claude/skills .claude/skills "$skills_on_disk"
  done <<<"$listed"
fi

finish
