#!/usr/bin/env bash
# shellcheck disable=SC2154  # lib.sh sets rc, listed and first
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "users attrset"
markers="$(grep -cF '# end users' "$DIR/flake.nix")"
eq "flake.nix has exactly one '# end users' marker" "1" "$markers"

fixture_users
if [ -n "$listed" ]; then
  ok "users.sh list returns usernames"
else
  bad "users.sh list returns usernames" "$(cat "$WORK/users-stderr")"
fi
eq "no duplicate usernames" "$(printf '%s\n' "$listed" | sort -u | wc -l | tr -d ' ')" \
  "$(printf '%s\n' "$listed" | wc -l | tr -d ' ')"

bogus="$(printf '%s\n' "$listed" | grep -vE '^[A-Za-z0-9._-]+$')"
eq "every username is attribute-safe once dots are dashed" "" "$bogus"

if "$DIR/users.sh" has "$first"; then
  ok "users.sh has \"$first\""
else
  bad "users.sh has \"$first\"" "expected exit 0"
fi
if "$DIR/users.sh" has definitely-not-a-real-user 2>/dev/null; then
  bad "users.sh rejects an unlisted name" "expected non-zero exit"
else
  ok "users.sh rejects an unlisted name"
fi

section "users.sh add (on a copy, never the real flake.nix)"
fixture_copy

run "$DIR/users.sh" add "new.user" "$COPY"
eq "add exits 0" "0" "$RUN_RC"
eq "add appends after the existing entries" "$listed
new.user" "$("$DIR/users.sh" list "$COPY")"
eq "add leaves the file mode alone" "644" "$(filemode "$COPY")"

sum_before="$(shasum "$COPY" | cut -d' ' -f1)"
run "$DIR/users.sh" add "new.user" "$COPY"
eq "adding the same name twice changes nothing" "$sum_before" "$(shasum "$COPY" | cut -d' ' -f1)"

run "$DIR/users.sh" add 'bad name"' "$COPY"
eq "add refuses a name that would break the Nix string" "1" "$RUN_RC"
eq "refused add left the file alone" "$sum_before" "$(shasum "$COPY" | cut -d' ' -f1)"

NOMARK="$WORK/nomarker.nix"
grep -vF '# end users' "$COPY" >"$NOMARK"
run "$DIR/users.sh" add "someone" "$NOMARK"
eq "add refuses when the marker is gone" "1" "$RUN_RC"
contains "add says why it refused" "$RUN_ERR" "nowhere to append"

if command -v nix-instantiate >/dev/null 2>&1; then
  if err="$(nix-instantiate --parse "$COPY" 2>&1 >/dev/null)"; then
    ok "flake.nix still parses as Nix after two adds"
  else
    bad "flake.nix still parses as Nix after two adds" "$err"
  fi
else
  skip "post-add Nix parse (nix-instantiate not found)"
fi

finish
