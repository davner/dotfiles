#!/usr/bin/env bash
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "installed page"
PAGE="$DIR/docs/installed.md"
# The page is how a human learns what lands on the machine, and nothing else
# notices when a package is added without a line there.
packages="$(awk '/home\.packages = with pkgs; \[/{f=1; next} f && /^ *\];/{exit} f' "$DIR/home.nix" |
  sed -E 's/#.*//; s/^ +//; s/ +$//' | grep -v '^$')"
casks="$(awk '/^ *(brews|casks) = \[/{f=1; next} f && /^ *\];/{f=0} f' "$DIR/configuration.nix" |
  sed -nE 's/^ *"([^"]+)".*/\1/p')"
unnamed() { # names -> those the page does not name in backticks
  local n
  for n in $1; do grep -qF "\`$n\`" "$PAGE" 2>/dev/null || printf '%s ' "$n"; done
}
inventory() { # check name, what the list holds, names
  local missing
  if [ -z "$3" ]; then
    bad "$1" "read no $2 from the Nix files; has their layout changed?"
    return
  fi
  missing="$(unnamed "$3")"
  if [ -z "$missing" ]; then
    ok "$1"
  else
    bad "$1" "not in docs/installed.md as \`name\`: $missing"
  fi
}
inventory "docs/installed.md names every package" "home.packages" "$packages"
inventory "docs/installed.md names every brew and cask" "brews or casks" "$casks"

section "relative links"
# Markdown links, reference definitions and the src, srcset and href of inline
# HTML such as <picture>. Code is skipped, since a link shown as code is an example.
link_targets() { # file -> one target per line
  # shellcheck disable=SC2016  # the backticks are Markdown, not command substitution
  awk '/^ *(```|~~~)/{code=!code; next} !code' "$1" |
    sed -E 's/`[^`]*`//g' |
    grep -oE '\]\([^)]*\)|^ {0,3}\[[^]]+\]: *[^ ]+|(src|srcset|href)="[^"]*"' |
    sed -E 's/^\]\(//; s/\)$//; s/^ *\[[^]]+\]: *//; s/^(src|srcset|href)="//; s/"$//; s/,.*//; s/^ +//' |
    sed -E 's/^<([^>]*)>.*/\1/; s/ .*//'
}
broken_links() { # files, relative to the repo root -> "file: link" for each that resolves to nothing
  local f t path
  for f in "$@"; do
    while IFS= read -r t; do
      case "$t" in '' | '#'* | //* | [a-zA-Z]*:*) continue ;; esac
      path="${t%%#*}"
      path="${path%%\?*}"
      path="${path//%20/ }"
      # GitHub resolves a leading slash from the repo root, not the filesystem's.
      case "$path" in /*) path=".$path" ;; *) path="$(dirname "$f")/$path" ;; esac
      [ -e "$path" ] || printf '%s: %s\n' "$f" "$t"
    done < <(link_targets "$f")
  done
}

FIX="$WORK/links"
mkdir -p "$FIX/docs/adr"
touch "$FIX/AGENTS.md" "$FIX/docs/adr/0001-x.md"
cat >"$FIX/docs/page.md" <<'EOF'
[ok](adr/0001-x.md) [up](../AGENTS.md#installing) [root](/AGENTS.md) [web](https://example.com/x) [here](#top)
[t](adr/0001-x.md "a title") [angle](<adr/0001-x.md>) [mail](mailto:a@b.c)
Shown as code: `[x](inline-missing.md)`
```md
[x](fenced-missing.md)
```
[gone](adr/0002-missing.md)
<picture><source srcset="adr/0001-x.md" media="x"><img src="img-missing.svg" alt=""></picture>
[ref]: ref-missing.md
EOF
eq "a broken relative link is reported with its file and link" \
  "docs/page.md: adr/0002-missing.md
docs/page.md: img-missing.svg
docs/page.md: ref-missing.md" "$(cd "$FIX" && broken_links docs/page.md)"

pages=()
while IFS= read -r p; do pages+=("$p"); done < <(cd "$DIR" && { echo README.md; find docs -name '*.md' | sort; })
broken="$(cd "$DIR" && broken_links "${pages[@]}")"
if [ -z "$broken" ]; then
  ok "every relative link in README.md and docs/ resolves (${#pages[@]} pages)"
else
  bad "every relative link in README.md and docs/ resolves" "${broken//$'\n'/ | }"
fi

section "docs index"
# GitHub shows docs/README.md under the folder listing, so a page it leaves out
# is one nobody browsing finds.
unindexed=""
for p in "${pages[@]}"; do
  case "$p" in README.md | docs/README.md) continue ;; esac
  grep -qF "](${p#docs/})" "$DIR/docs/README.md" || unindexed+="$p "
done
if [ -z "$unindexed" ]; then
  ok "docs/README.md links every page under docs/"
else
  bad "docs/README.md links every page under docs/" "not linked: $unindexed"
fi

finish
