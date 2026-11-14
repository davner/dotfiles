#!/usr/bin/env bash
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "arguments"
# Checked before gh and Chrome are looked for, so a typo is named even on a
# machine without them.
run "$DIR/preview-docs.sh" --out "$WORK/shots" "$WORK/no-such.md"
eq "a missing file exits 2" "2" "$RUN_RC"
contains "a missing file is named" "$RUN_ERR" "$WORK/no-such.md"
eq "a missing file writes nothing" "" "$RUN_OUT"

mkdir -p "$WORK/a" "$WORK/b"
touch "$WORK/a/README.md" "$WORK/b/README.md"
run "$DIR/preview-docs.sh" --out "$WORK/shots" "$WORK/a/README.md" "$WORK/b/README.md"
eq "two files with one name exit 2" "2" "$RUN_RC"
contains "two files with one name are refused before either is shot" "$RUN_ERR" "README-light.png"

section "failures"
fixture_stub
# Fails only the render, so the run gets past finding the repo.
cat >"$STUB/gh" <<'EOF'
#!/usr/bin/env bash
[ "$1" = api ] || { echo owner/repo; exit 0; }
echo "gh: Bad credentials (HTTP 401)" >&2
exit 1
EOF
chmod +x "$STUB/gh"
run env CHROME=/usr/bin/true "$DIR/preview-docs.sh" --out "$WORK/shots" "$DIR/README.md"
rm -f "$STUB/gh"
eq "a failed render exits 1" "1" "$RUN_RC"
contains "a failed render says the API failed" "$RUN_ERR" "Markdown API failed"
eq "a failed render prints no screenshot" "" "$RUN_OUT"

section "picture links"
# Sourced, the script defines its functions and runs nothing. In a subshell,
# since it also turns on set -e, which this file deliberately leaves off.
unwrap() { (source "$DIR/preview-docs.sh" && unwrap_picture_links); }
# What GitHub's Markdown API returned for README.md's banner, and a linked
# image outside any <picture>, which GitHub's page keeps as a link.
in='<themed-picture data-catalyst-inline="true"><picture>
  <source media="(prefers-color-scheme: dark)" srcset="dark.svg">
  <a target="_blank" rel="noopener noreferrer" href="light.svg"><img src="light.svg" alt="x" width="100%" style="max-width: 100%;"></a>
</picture></themed-picture>
<p><a href="big.png"><img src="small.png" alt="y"></a></p>'
eq "an image inside <picture> loses its link, and one outside keeps it" \
  '<themed-picture data-catalyst-inline="true"><picture>
  <source media="(prefers-color-scheme: dark)" srcset="dark.svg">
  <img src="light.svg" alt="x" width="100%" style="max-width: 100%;">
</picture></themed-picture>
<p><a href="big.png"><img src="small.png" alt="y"></a></p>' "$(unwrap <<<"$in")"

finish
