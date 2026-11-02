#!/bin/zsh
# The page must draw frame N alone when opened as page.html?frame=N&bg=<bg>&px=<render size>.
set -euo pipefail

usage() {
  print -u2 "Usage: render-gif.sh [-r render_px] [-s out_px] [-c colors] [-d dither] [-h frame:ms ...] [-q key=value] <page.html> <out.gif> <frames> <frame_ms> <bg>"
  exit 2
}
zparseopts -D -E -F -- r:=opt_render s:=opt_size c:=opt_colors d:=opt_dither h+:=opt_hold q:=opt_query 2>/dev/null || usage
(( $# == 5 )) || usage

page=${1:A}
out=${2:A}
frames=$3
frame_ms=$4
bg=$5
render=${opt_render[-1]:-300}
size=${opt_size[-1]:-$render}
colors=${opt_colors[-1]:-64}
dither=${opt_dither[-1]:-bayer:bayer_scale=3}
extra=${opt_query[-1]:-}
[[ -z $extra || $extra =~ '^[a-z]+=[a-z0-9]+$' ]] || usage
typeset -A hold
for h in ${opt_hold:#-h}; do
  [[ $h == <->:<-> ]] || usage
  hold[${h%%:*}]=${h#*:}
done

chrome=(~/Library/Caches/ms-playwright/chromium_headless_shell-*/chrome-headless-shell-mac-*/chrome-headless-shell(N))
(( ${#chrome} )) || { print -u2 "No headless Chromium. Run: npx playwright install chromium-headless-shell"; exit 1; }
chrome=${chrome[-1]}

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

for (( i = 0; i < frames; i++ )); do
  "$chrome" --headless --hide-scrollbars \
    --use-angle=swiftshader --enable-unsafe-swiftshader \
    --window-size=$render,$render --default-background-color=00000000 \
    --virtual-time-budget=5000 \
    --screenshot="$work/$(printf 'f%02d' $i).png" \
    "file://$page?frame=$i&bg=$bg&px=$render${extra:+&$extra}" >/dev/null 2>&1
done

shrink=""
(( size == render )) || shrink="scale=${size}:${size}:flags=area,"
ffmpeg -v error -y -framerate "1000/$frame_ms" -i "$work/f%02d.png" \
  -vf "${shrink}split[a][b];[a]palettegen=max_colors=${colors}:reserve_transparent=1[p];[b][p]paletteuse=dither=${dither}:alpha_threshold=128" \
  -loop 0 "$out"

# Patch per-frame delays in place: ffmpeg writes one even rate, and rests need longer frames.
delays=()
for (( i = 0; i < frames; i++ )); do delays+=(${hold[$i]:-$frame_ms}); done
python3 - "$out" $delays <<'EOF'
import sys
path, delays = sys.argv[1], [round(int(ms) / 10) for ms in sys.argv[2:]]
b = bytearray(open(path, 'rb').read())
i = 13 + ((3 << ((b[10] & 7) + 1)) if b[10] & 0x80 else 0)
frame = 0
def skip_subblocks(i):
    while b[i]:
        i += b[i] + 1
    return i + 1
while b[i] != 0x3B:
    if b[i] == 0x21:
        if b[i + 1] == 0xF9:
            b[i + 4:i + 6] = delays[min(frame, len(delays) - 1)].to_bytes(2, 'little')
            frame += 1
        i = skip_subblocks(i + 2)
    elif b[i] == 0x2C:
        flags = b[i + 9]
        i += 10 + ((3 << ((flags & 7) + 1)) if flags & 0x80 else 0)
        i = skip_subblocks(i + 1)
    else:
        sys.exit(f'Unexpected GIF block 0x{b[i]:02x} at byte {i}')
if frame != len(delays):
    sys.exit(f'GIF has {frame} frames, expected {len(delays)}')
open(path, 'wb').write(b)
EOF

print "$out"
