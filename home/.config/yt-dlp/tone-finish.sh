#!/bin/sh
# An iOS tone is an .m4a under a different extension, and Finder device sync is
# the route that installs one, so the download is renamed rather than kept.
set -eu
src=$1

# Probed before the rename, since ffprobe wants a path that still exists. iOS
# refuses a text tone longer than 30s without explaining why, so say it here
# while the requested range is still on screen.
dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$src" 2>/dev/null || echo "")
mv -- "$src" "${src%.*}.m4r"
case $dur in
  '' | *[!0-9.]*) exit 0 ;;
esac
if [ "${dur%%.*}" -ge 30 ]; then
  printf 'tone is %ss: past the 30s text-tone limit (ringtones allow 40s)\n' "$dur" >&2
fi
