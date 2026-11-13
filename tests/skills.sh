#!/usr/bin/env bash
# shellcheck disable=SC2154  # lib.sh sets rc, listed and first
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "skills"
SKILLS_DIR="$DIR/home/.claude/skills"
on_disk="$(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)"
# Claude Code invokes a skill by the `name` in its frontmatter, not its folder.
mismatched=""
for d in $on_disk; do
  n="$(sed -nE 's/^name: *(.+)$/\1/p' "$SKILLS_DIR/$d/SKILL.md" 2>/dev/null | head -1)"
  [ "$n" = "$d" ] || mismatched="$mismatched $d(name:$n)"
done
if [ -z "$mismatched" ]; then
  ok "every skill's name matches its folder"
else
  bad "every skill's name matches its folder" "$mismatched"
fi
# The README table is how a human learns a skill exists, and nothing else
# notices when it stops matching what is on disk.
in_readme="$(sed -n '/^### Skills$/,/^### /p' "$DIR/README.md" |
  grep -oE 'home/\.claude/skills/[a-z0-9-]+/SKILL\.md' |
  sed -E 's|home/\.claude/skills/([^/]+)/SKILL\.md|\1|' | sort -u)"
missing="$(comm -23 <(echo "$on_disk") <(echo "$in_readme") | tr '\n' ' ')"
phantom="$(comm -13 <(echo "$on_disk") <(echo "$in_readme") | tr '\n' ' ')"
if [ -z "${missing// /}" ]; then
  ok "README documents every skill"
else
  bad "README documents every skill" "on disk but not in the table: $missing"
fi
if [ -z "${phantom// /}" ]; then
  ok "the README skill table has no phantom rows"
else
  bad "the README skill table has no phantom rows" "in the table but not on disk: $phantom"
fi

# A headless run reads these skills with nobody there to answer their stop
# points, so each one must say what to do in place of asking.
headless_skills="grilling to-tickets to-spec implement-spec code-review domain-modeling"
for s in $headless_skills; do
  if grep -qE '^#+ When headless:' "$SKILLS_DIR/$s/SKILL.md"; then
    ok "$s has a When headless: section"
  else
    bad "$s has a When headless: section" "no '## When headless:' heading in $s/SKILL.md"
  fi
done
# The cut-offs in grilling's headless rule rest on these notes; a reader who
# doubts a number needs the evidence one link away.
headless="$(sed -n '/^#* *When headless:/,$p' "$SKILLS_DIR/grilling/SKILL.md")"
for note in agent-decision-confidence agent-retry-limits; do
  if [ -f "$DIR/docs/research/$note.md" ] && grep -qF "docs/research/$note.md" <<<"$headless"; then
    ok "grilling's headless section links docs/research/$note.md"
  else
    bad "grilling's headless section links docs/research/$note.md" \
      "the note must exist in the repo and be named in the section"
  fi
done

section "third-party skills"
# Third-party skills come from flake inputs, so an upstream move or rename is
# a link to nothing, or to a skill Claude knows by another name.
if full_only && require nix; then
  fixture_users
  while read -r u; do
    [ -n "$u" ] || continue
    # shellcheck disable=SC2016  # the ${} are Nix interpolation, not shell
    tp="$(nix eval --raw "$DIR#darwinConfigurations.${u//./-}.config.home-manager.users.\"$u\".home.file" \
      --apply 'f: builtins.concatStringsSep "\n" (map (n: "${n}\t${toString f.${n}.source}")
        (builtins.filter (n: builtins.match "\\.(claude|agents)/skills/[^/]+" n != null) (builtins.attrNames f)))' \
      2>"$WORK/stderr")"
    if [ -z "$tp" ]; then
      bad "$u: third-party skills evaluate" "$(grep -v '^warning:' "$WORK/stderr" | head -5)"
      continue
    fi
    claude_tp="" agents_tp="" broken=""
    while IFS=$'\t' read -r link src; do
      name="${link##*/}"
      case "$link" in
        .claude/*) grep -qxF "$name" <<<"$on_disk" && continue; claude_tp="$claude_tp $name" ;;
        .agents/*) agents_tp="$agents_tp $name" ;;
      esac
      n="$(sed -nE 's/^name: *(.+)$/\1/p' "$src/SKILL.md" 2>/dev/null | head -1)"
      [ "$n" = "$name" ] || broken="$broken $link(name:${n:-no SKILL.md})"
    done <<<"$tp"
    if [ -n "$claude_tp" ] && [ "$claude_tp" = "$agents_tp" ]; then
      ok "$u: third-party skills are linked into both skill folders"
    else
      bad "$u: third-party skills are linked into both skill folders" \
        ".claude/skills:${claude_tp:- none}" ".agents/skills:${agents_tp:- none}"
    fi
    if [ -z "$broken" ]; then
      ok "$u: every third-party link holds a SKILL.md named for it"
    else
      bad "$u: every third-party link holds a SKILL.md named for it" "$broken"
    fi
  done <<<"$listed"
fi

finish
