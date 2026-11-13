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

# Autopilot opens each skill by its installed path with nobody there to answer,
# so a name it lists must resolve, and a skill it marks (headless) must say what
# to do in place of asking. Only first-party names resolve here: the fast run
# cannot see what the flake installs.
autopilot="$SKILLS_DIR/autopilot/SKILL.md"
opens="$(awk '/^## /{f=($0=="## Skills it opens")} f' "$autopilot" 2>/dev/null)"
# shellcheck disable=SC2016  # the backticks are Markdown, not command substitution
opened="$(sed -nE 's/^- `([a-z0-9-]+)`.*/\1/p' <<<"$opens")"
# shellcheck disable=SC2016  # the backticks are Markdown, not command substitution
headless_skills="$(sed -nE 's/^- `([a-z0-9-]+)` \(headless\).*/\1/p' <<<"$opens")"
if [ -n "$opened" ] && [ -n "$headless_skills" ]; then
  ok "autopilot lists the skills it opens"
else
  bad "autopilot lists the skills it opens" \
    "no '- \`name\`' lines, some marked (headless), under '## Skills it opens' in autopilot/SKILL.md"
fi
for s in $opened; do
  if [ -f "$SKILLS_DIR/$s/SKILL.md" ]; then
    ok "autopilot opens $s, a first-party skill"
  else
    bad "autopilot opens $s, a first-party skill" "no home/.claude/skills/$s/SKILL.md"
  fi
done
for s in $headless_skills; do
  if grep -qE '^#+ When headless:' "$SKILLS_DIR/$s/SKILL.md"; then
    ok "$s has a When headless: section"
  else
    bad "$s has a When headless: section" "no '## When headless:' heading in $s/SKILL.md"
  fi
done
# The cut-offs in each rule rest on a research note; a reader who doubts a
# number needs the evidence one link away, beside the rule it backs.
links_note() {
  local skill="$1" heading="$2" note="$3" body
  body="$(awk -v h="$heading" '/^## /{f=(index($0, h)==4)} f' "$SKILLS_DIR/$skill/SKILL.md")"
  if [ -f "$DIR/docs/research/$note.md" ] && grep -qF "docs/research/$note.md" <<<"$body"; then
    ok "$skill's $heading section links docs/research/$note.md"
  else
    bad "$skill's $heading section links docs/research/$note.md" \
      "the note must exist in the repo and be named in the section"
  fi
}
links_note grilling "When headless:" agent-decision-confidence
links_note autopilot "The retry rule" agent-retry-limits

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
