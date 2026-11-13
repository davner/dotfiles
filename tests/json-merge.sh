#!/usr/bin/env bash
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "json merge"
JM="$DIR/home/json-merge.sh"
if require jq; then
  JW="$WORK/jm"
  mkdir -p "$JW"
  jm() { # args -> sets JM_RC and JM_ERR
    JM_ERR="$("$JM" "$@" 2>&1 >/dev/null)"
    JM_RC=$?
  }
  printf '%s\n' '{"a": 1, "n": {"x": 1, "y": 1}, "hooks": [1, 2]}' >"$JW/obj.base.json"
  printf '%s\n' '[{"key": "k", "command": "c", "when": "w"}, {"key": "k2", "command": "c2"}]' >"$JW/arr.base.json"

  jm deep "$JW/obj.base.json" "$JW/new/settings.json"
  if [ "$JM_RC" = 0 ] && jq -e '. == {"a": 1, "n": {"x": 1, "y": 1}, "hooks": [1, 2]}' "$JW/new/settings.json" >/dev/null 2>&1; then
    ok "deep: a missing target and its folder are created from the base"
  else
    bad "deep: a missing target and its folder are created from the base" "rc=$JM_RC" "$JM_ERR"
  fi
  jm append-unique key,command,when "$JW/arr.base.json" "$JW/new/keybindings.json"
  eq "append-unique: a missing target starts as an empty array" "2" "$(jq length "$JW/new/keybindings.json" 2>&1)"

  printf '%s\n' '{"a": 0, "mine": true, "n": {"x": 0, "z": 1}, "hooks": [9, 9, 9]}' >"$JW/s.json"
  jm deep "$JW/obj.base.json" "$JW/s.json"
  eq "deep: base wins a conflicting key and the target's other keys survive" \
    '1 true' "$(jq -r '"\(.a) \(.mine)"' "$JW/s.json")"
  eq "deep: nested objects merge key by key" '{"x":1,"y":1,"z":1}' "$(jq -cS .n "$JW/s.json")"
  eq "deep: base replaces an array outright" '[1,2]' "$(jq -c .hooks "$JW/s.json")"

  printf '%s\n' '{"real": true}' >"$JW/linked-to.json"
  ln -s "$JW/linked-to.json" "$JW/l1.json"
  ln -s "$JW/linked-to.json" "$JW/l2.json"
  jm --drop-link deep "$JW/obj.base.json" "$JW/l1.json"
  if [ ! -L "$JW/l1.json" ] && jq -e '.real and .a == 1' "$JW/l1.json" >/dev/null 2>&1 &&
    [ "$(cat "$JW/linked-to.json")" = '{"real": true}' ]; then
    ok "--drop-link: a leftover link becomes a real file that keeps what it pointed at"
  else
    bad "--drop-link: a leftover link becomes a real file that keeps what it pointed at" "$(cat "$JW/l1.json")"
  fi
  ln -s "$JW/gone.json" "$JW/l3.json"
  jm --drop-link deep "$JW/obj.base.json" "$JW/l3.json"
  if [ "$JM_RC" = 0 ] && [ ! -L "$JW/l3.json" ] && jq -e '.a == 1' "$JW/l3.json" >/dev/null 2>&1; then
    ok "--drop-link: a dangling link becomes a file built from the base"
  else
    bad "--drop-link: a dangling link becomes a file built from the base" "rc=$JM_RC" "$JM_ERR"
  fi
  jm deep "$JW/obj.base.json" "$JW/l2.json"
  if [ -L "$JW/l2.json" ] && jq -e '.real and .a == 1' "$JW/linked-to.json" >/dev/null 2>&1; then
    ok "without --drop-link a linked target is merged through the link"
  else
    bad "without --drop-link a linked target is merged through the link"
  fi

  printf '{} // mine\n' >"$JW/bad.json"
  jm deep "$JW/obj.base.json" "$JW/bad.json"
  if [ "$JM_RC" = 1 ] && [ "$(cat "$JW/bad.json")" = "{} // mine" ]; then
    ok "invalid JSON fails by default and leaves the file alone"
  else
    bad "invalid JSON fails by default and leaves the file alone" "rc=$JM_RC"
  fi
  contains "and the failure names the file" "$JM_ERR" "$JW/bad.json"
  jm --skip-invalid deep "$JW/obj.base.json" "$JW/bad.json"
  if [ "$JM_RC" = 0 ] && [ "$(cat "$JW/bad.json")" = "{} // mine" ]; then
    ok "--skip-invalid exits 0 and leaves the file alone"
  else
    bad "--skip-invalid exits 0 and leaves the file alone" "rc=$JM_RC"
  fi
  contains "and says it skipped" "$JM_ERR" "skipped"
  jm deep "$JW/no-such-base.json" "$JW/s2.json"
  if [ "$JM_RC" = 1 ] && [ ! -e "$JW/s2.json" ]; then
    ok "a missing base fails before touching the target"
  else
    bad "a missing base fails before touching the target" "rc=$JM_RC"
  fi

  printf '%s\n' '[{"key": "k", "command": "c", "when": "w", "args": "mine"}, {"key": "k", "command": "c", "when": "other"}]' >"$JW/kb.json"
  jm append-unique key,command,when "$JW/arr.base.json" "$JW/kb.json"
  eq "append-unique: an entry matching on every key is not added again" \
    "1" "$(jq '[.[] | select(.key == "k" and .when == "w")] | length' "$JW/kb.json")"
  eq "append-unique: the target's own version of it is kept" "mine" "$(jq -r '.[0].args' "$JW/kb.json")"
  eq "append-unique: an entry that differs only in when is kept" \
    "1" "$(jq '[.[] | select(.when == "other")] | length' "$JW/kb.json")"
  eq "append-unique: a base entry with no when is appended" "k2" "$(jq -r '.[-1].key' "$JW/kb.json")"
  before="$(cat "$JW/kb.json")"
  jm append-unique key,command,when "$JW/arr.base.json" "$JW/kb.json"
  eq "append-unique: a second run changes nothing" "$before" "$(cat "$JW/kb.json")"

  # A write that fails partway, as on a full disk, must leave the old file whole.
  jq -n '[range(400)] | map({key: "k\(.)", value: "padding padding padding"}) | from_entries' >"$JW/big.base.json"
  printf '%s\n' '{"mine": true}' >"$JW/full.json"
  (
    trap '' XFSZ
    ulimit -f 4
    "$JM" deep "$JW/big.base.json" "$JW/full.json"
  ) >/dev/null 2>&1
  full_rc=$?
  if [ "$full_rc" != 0 ] && [ "$(cat "$JW/full.json")" = '{"mine": true}' ]; then
    ok "a failed write fails and leaves the target as it was"
  else
    bad "a failed write fails and leaves the target as it was" "rc=$full_rc" "$(head -c 80 "$JW/full.json")"
  fi
  leftovers="$(find "$JW" -name '.json-merge.*')"
  eq "and leaves no temp file behind" "" "$leftovers"
  jm deep "$JW/obj.base.json" "$JW/l2.json"
  eq "a linked target is still a link after a rename-based write" "link" "$([ -L "$JW/l2.json" ] && echo link)"

  printf '%s\n' '[{"key": "d", "command": "c"}, {"key": "d", "command": "c"}]' >"$JW/dup.base.json"
  printf '%s\n' '[]' >"$JW/dup.json"
  jm append-unique key,command,when "$JW/dup.base.json" "$JW/dup.json"
  eq "append-unique: an entry repeated in the base is added once" "1" "$(jq length "$JW/dup.json")"

  # A fragment is folded into the base before the base is merged over the target.
  printf '%s\n' '{"a": 1, "permissions": {"deny": ["Bash(rm *)"]}}' >"$JW/fb.json"
  printf '%s\n' '{"enabledPlugins": {"p@m": true}}' >"$JW/frag1.json"
  printf '%s\n' '{"mine": true}' >"$JW/f1.json"
  jm --extend "$JW/frag1.json" deep "$JW/fb.json" "$JW/f1.json"
  eq "--extend: the fragment's keys land alongside the base's and the target's" \
    '{"a":1,"enabledPlugins":{"p@m":true},"mine":true,"permissions":{"deny":["Bash(rm *)"]}}' \
    "$(jq -cS . "$JW/f1.json" 2>&1)"
  # Arrays replace outright in the final merge, so a fragment that replaced one
  # would drop the base's deny rules from every machine that takes the fragment.
  printf '%s\n' '{"permissions": {"deny": ["Bash(curl *)", "Bash(rm *)"]}}' >"$JW/frag2.json"
  printf '%s\n' '{"permissions": {"deny": ["Bash(wget *)"]}}' >"$JW/frag3.json"
  printf '%s\n' '{}' >"$JW/f2.json"
  jm --extend "$JW/frag2.json" --extend "$JW/frag3.json" deep "$JW/fb.json" "$JW/f2.json"
  eq "--extend: a fragment's array extends the base's, in order, each entry once" \
    '["Bash(rm *)","Bash(curl *)","Bash(wget *)"]' "$(jq -c .permissions.deny "$JW/f2.json" 2>&1)"
  while IFS='|' read -r label frag; do
    [ -n "$label" ] || continue
    printf '%s\n' "$frag" >"$JW/frag4.json"
    printf '%s\n' '{"mine": true}' >"$JW/f3.json"
    jm --skip-invalid --extend "$JW/frag4.json" deep "$JW/fb.json" "$JW/f3.json"
    if [ "$JM_RC" = 1 ] && [ "$(cat "$JW/f3.json")" = '{"mine": true}' ]; then
      ok "--extend: a fragment that $label is refused, even with --skip-invalid, and the target is left alone"
    else
      bad "--extend: a fragment that $label is refused, even with --skip-invalid, and the target is left alone" \
        "rc=$JM_RC" "$(cat "$JW/f3.json")"
    fi
    contains "and the refusal names the fragment and the key" "$JM_ERR" "$JW/frag4.json: permissions"
  done <<'FRAGS'
nulls the base's array|{"permissions": {"deny": null}}
swaps the base's array for a string|{"permissions": {"deny": "Bash(rm *)"}}
nulls the base's object|{"permissions": null}
swaps the base's object for an array|{"permissions": []}
FRAGS
  printf '%s\n' '[]' >"$JW/frag5.json"
  jm --extend "$JW/frag5.json" deep "$JW/fb.json" "$JW/f3.json"
  want_exit "--extend: a fragment that is not an object is refused" 1 "$JM_RC"
  jm --extend "$JW/gone.json" deep "$JW/fb.json" "$JW/f3.json"
  if [ "$JM_RC" = 1 ] && [ "$(cat "$JW/f3.json")" = '{"mine": true}' ]; then
    ok "--extend: a missing fragment fails before touching the target"
  else
    bad "--extend: a missing fragment fails before touching the target" "rc=$JM_RC"
  fi
  contains "and names it" "$JM_ERR" "$JW/gone.json"
  printf '{} // mine\n' >"$JW/frag6.json"
  jm --extend "$JW/frag6.json" deep "$JW/fb.json" "$JW/f3.json"
  want_exit "--extend: a fragment that is not plain JSON fails" 1 "$JM_RC"
  contains "and names it" "$JM_ERR" "$JW/frag6.json"

  for args in "" "deep" "deep $JW/obj.base.json" "append-unique $JW/arr.base.json $JW/x.json" "--bogus deep a b" "shallow a b"; do
    # shellcheck disable=SC2086 # each case is deliberately split into words
    jm $args
    eq "usage error exits 2: json-merge.sh ${args//$JW\//}" "2" "$JM_RC"
  done
fi

finish
