#!/bin/zsh
# Renders a few chosen frames at once and tiles them, for checking a pose in seconds instead of a full render.
set -euo pipefail

usage() {
  print -u2 "Usage: preview.sh [-p px] [-b bg] [-q key=value] <page.html> <out.png> <frame> [frame ...]"
  exit 2
}
zparseopts -D -E -F -- p:=opt_px b:=opt_bg q:=opt_query 2>/dev/null || usage
(( $# >= 3 )) || usage

page=${1:A}
out=${2:A}
shift 2
frames=("$@")
px=${opt_px[-1]:-400}
bg=${opt_bg[-1]:-white}
extra=${opt_query[-1]:-}
[[ -z $extra || $extra =~ '^[a-z]+=[a-z0-9]+$' ]] || usage
for f in $frames; do [[ $f == <-> ]] || usage; done

chrome=(~/Library/Caches/ms-playwright/chromium_headless_shell-*/chrome-headless-shell-mac-*/chrome-headless-shell(N))
(( ${#chrome} )) || { print -u2 "No headless Chromium. Run: npx playwright install chromium-headless-shell"; exit 1; }
chrome=${chrome[-1]}

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

for f in $frames; do
  "$chrome" --headless --hide-scrollbars \
    --use-angle=swiftshader --enable-unsafe-swiftshader \
    --window-size=$px,$px --default-background-color=00000000 \
    --virtual-time-budget=5000 \
    --screenshot="$work/$(printf 'f%03d' $f).png" \
    "file://$page?frame=$f&bg=$bg&px=$px${extra:+&$extra}" >/dev/null 2>&1 &
done
wait

inputs=()
for f in $frames; do inputs+=(-i "$work/$(printf 'f%03d' $f).png"); done
if (( ${#frames} == 1 )); then
  cp "$work/$(printf 'f%03d' ${frames[1]}).png" "$out"
else
  ffmpeg -v error -y $inputs -filter_complex "hstack=inputs=${#frames}" "$out"
fi
print "$out  (frames ${frames[*]}, left to right)"
