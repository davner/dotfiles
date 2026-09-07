#!/bin/sh
# An iOS tone is an .m4a under a different extension. Both are kept because the
# two install routes disagree: Finder device sync takes the .m4r, GarageBand's
# import browser only lists the .m4a.
set -eu
src=$1
cp -- "$src" "${src%.*}.m4r"

# iOS refuses a text tone longer than 30s without explaining why, so say it here
# while the requested range is still on screen.
dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$src" 2>/dev/null || echo "")
case $dur in
  '' | *[!0-9.]*) exit 0 ;;
esac
if [ "${dur%%.*}" -ge 30 ]; then
  printf 'tone is %ss: past the 30s text-tone limit (ringtones allow 40s)\n' "$dur" >&2
fi
