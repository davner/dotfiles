#!/usr/bin/env bash
# Screenshots Markdown as GitHub renders it, light and dark. Run --help for options.
set -euo pipefail

usage() {
  cat <<'EOF'
Screenshot Markdown files as GitHub renders them, in light and in dark, to
check a docs change before pushing it.

usage: ./preview-docs.sh [--out DIR] FILE.md...
  --out DIR  where the screenshots go. Defaults to a new temporary folder.

Each FILE.md becomes FILE-light.png and FILE-dark.png in DIR, and each path is
printed. The HTML comes from GitHub's own Markdown API, so it needs `gh`
signed in and a network; the screenshots need Google Chrome, found at its
usual place in /Applications or wherever CHROME points.

Not shown as on GitHub: Mermaid diagrams stay code blocks, and alerts such as
> [!NOTE] stay plain quotes, since GitHub draws both with its own scripts.
EOF
}

CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
CSS="https://cdnjs.cloudflare.com/ajax/libs/github-markdown-css/5.5.1/github-markdown.min.css"
WIDTH=1012

die() { # exit code, message
  echo "preview-docs.sh: $2" >&2
  exit "$1"
}

# The API links each image to itself; inside <picture> that <a> makes a plain
# browser ignore the dark <source>, which github.com's own script avoids.
unwrap_picture_links() { # HTML on stdin -> the same, minus those links
  perl -0pe 's{<picture\b.*?</picture>}{ my $p = $&; $p =~ s#<a\b[^>]*>\s*(<img\b[^>]*>)\s*</a>#$1#g; $p }gse'
}

repo_of() { # folder -> owner/name, which the API resolves relative links against
  local nwo url
  if nwo="$(cd "$1" && gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)" && [ -n "$nwo" ]; then
    printf '%s\n' "$nwo"
    return
  fi
  url="$(git -C "$1" remote get-url origin 2>/dev/null)" || return 1
  url="${url%.git}"
  url="${url#*github.com[:/]}"
  [ "${url%%/*}" != "$url" ] || return 1
  printf '%s\n' "$url"
}

file_url() { # absolute folder -> its file:// URL, with the trailing slash <base> needs
  local p="$1"
  p="${p//%/%25}"
  p="${p// /%20}"
  p="${p//#/%23}"
  p="${p//\?/%3F}"
  printf 'file://%s/\n' "$p"
}

render() { # Markdown file, repo -> GitHub's HTML for it, ready for a plain browser
  local body
  # mode=gfm would turn every newline in a paragraph into <br>, as in a comment.
  body="$(gh api -X POST /markdown -f mode=markdown -f context="$2" -F text=@"$1")" || return 1
  unwrap_picture_links <<<"$body"
}

page() { # HTML body, the Markdown's absolute folder -> a standalone HTML page
  cat <<EOF
<!doctype html>
<html><head><meta charset="utf-8">
<base href="$(file_url "$2")">
<link rel="stylesheet" href="$CSS">
<style>
  body { margin: 0; background: #ffffff; }
  @media (prefers-color-scheme: dark) { body { background: #0d1117; } }
  .markdown-body { box-sizing: border-box; max-width: 980px; margin: 0 auto; padding: 32px 16px; }
</style>
<script>
  addEventListener("load", () => {
    document.documentElement.dataset.height = document.documentElement.scrollHeight;
  });
</script>
</head><body><article class="markdown-body">
EOF
  printf '%s\n</article></body></html>\n' "$1"
}

chrome() { # profile folder, args... -> headless Chrome, its log noise dropped
  "$CHROME" --headless --hide-scrollbars --no-first-run \
    --user-data-dir="$1" --virtual-time-budget=10000 "${@:2}" 2>/dev/null
}

shoot() { # html, png, height, flags... -> the screenshot, or a clear failure
  chrome "$TMP/profile" --window-size="$WIDTH,$3" "${@:4}" --screenshot="$2" "file://$1" >/dev/null || true
  [ -s "$2" ] || die 1 "Chrome wrote no screenshot to $2"
  printf '%s\n' "$2"
}

main() {
  local out="" files=() f
  while [ $# -gt 0 ]; do
    case "$1" in
      -h | --help)
        usage
        exit 0
        ;;
      -o | --out)
        [ $# -ge 2 ] || die 2 "--out needs a folder"
        out="$2"
        shift 2
        ;;
      --)
        shift
        files+=("$@")
        break
        ;;
      -*)
        usage >&2
        die 2 "unknown flag $1"
        ;;
      *)
        files+=("$1")
        shift
        ;;
    esac
  done
  if [ "${#files[@]}" -eq 0 ]; then
    usage >&2
    die 2 "no Markdown file given"
  fi
  local seen=" " name
  for f in "${files[@]}"; do
    [ -f "$f" ] || die 2 "no such file: $f"
    name="$(basename "$f" .md)"
    case "$seen" in
      *" $name "*) die 2 "two files would both write $name-light.png; preview them in separate runs" ;;
    esac
    seen+="$name "
  done

  command -v gh >/dev/null 2>&1 || die 1 "needs gh, the GitHub CLI, to render through GitHub's API"
  [ -x "$CHROME" ] || die 1 "needs Google Chrome at $CHROME, or CHROME set to its binary"
  command -v perl >/dev/null 2>&1 || die 1 "needs perl"

  [ -n "$out" ] || out="$(mktemp -d)"
  mkdir -p "$out"
  out="$(cd "$out" && pwd -P)"
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT

  local dir repo body html height
  for f in "${files[@]}"; do
    dir="$(cd "$(dirname "$f")" && pwd -P)"
    name="$(basename "$f" .md)"
    repo="$(repo_of "$dir")" || die 1 "cannot tell which GitHub repo $f belongs to"
    html="$TMP/$name.html"
    body="$(render "$f" "$repo")" || die 1 "GitHub's Markdown API failed for $f; is gh signed in?"
    page "$body" "$dir" >"$html"
    # The page measures itself once loaded, so the shot can hold all of it.
    height="$(chrome "$TMP/profile" --window-size="$WIDTH,800" --dump-dom "file://$html" |
      sed -nE 's/.*<html[^>]* data-height="([0-9]+)".*/\1/p' | head -n 1)" || true
    [ -n "$height" ] || die 1 "Chrome could not load $html"
    shoot "$html" "$out/$name-light.png" "$height" --blink-settings=preferredColorScheme=1
    # The blink setting alone leaves headless Chrome light.
    shoot "$html" "$out/$name-dark.png" "$height" --blink-settings=preferredColorScheme=0 --force-dark-mode
  done
}

# Sourced, as tests/preview-docs.sh does, it only defines the functions above.
[ "${BASH_SOURCE[0]}" != "$0" ] || main "$@"
