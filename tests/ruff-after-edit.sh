#!/usr/bin/env bash
# shellcheck disable=SC2154  # lib.sh sets rc and err
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "ruff after edit hook"
# It runs behind `[ ! -x ... ] ||` on every write, so a break is silent, and a
# hook that rewrites files in a repo that never chose ruff is worse than none.
HOOK="$DIR/home/.claude/hooks/ruff-after-edit.sh"
if require jq git; then
  # Only these on PATH, so a ruff or uvx on this machine cannot stand in for the stub.
  SYS="$WORK/sys"
  mkdir -p "$SYS"
  for c in bash jq git dirname readlink grep cat; do ln -s "$(command -v "$c")" "$SYS/$c"; done
  FAKE="$WORK/fake"
  mkdir -p "$FAKE"
  LOG="$WORK/ruff-log"
  stub_ruff() { # path -> a ruff that logs each call and fails check on BADLINT
    cat >"$1" <<EOF
#!/usr/bin/env bash
{ printf '%s|%s' "$1" "\$PWD"; printf '|%s' "\$@"; printf '\n'; } >>"$LOG"
if [ "\$1" = check ]; then
  for a in "\$@"; do
    if [ -f "\$a" ] && grep -q BADLINT "\$a"; then echo "\$a:1:1: F821 BADLINT is undefined"; exit 1; fi
  done
fi
exit 0
EOF
    chmod +x "$1"
  }
  stub_ruff "$FAKE/ruff"
  TPATH="$FAKE:$SYS"
  fire() { PATH="$TPATH" "$HOOK"; }
  n=0
  new_repo() { # -> sets REPO to a fresh git repo, physical path
    n=$((n + 1))
    REPO="$WORK/repo$n"
    mkdir -p "$REPO"
    git init -q "$REPO"
    REPO="$(cd "$REPO" && pwd -P)"
  }
  edit() { # file -> runs the hook on a Write payload for it
    local p
    json_str p "$1"
    : >"$LOG"
    hook fire "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":$p,\"content\":\"\"}}"
  }
  calls() { cat "$LOG"; }

  new_repo
  printf '[tool.ruff]\nline-length = 88\n' >"$REPO/pyproject.toml"
  printf 'x=1\n' >"$REPO/a.py"
  edit "$REPO/a.py"
  want_exit "a configured repo exits 0 on a clean file" 0 "$rc"
  eq "ruff fixes, formats, then checks exactly that file from the repo root" \
    "$FAKE/ruff|$REPO|check|--fix|--force-exclude|--|$REPO/a.py
$FAKE/ruff|$REPO|format|--force-exclude|--|$REPO/a.py
$FAKE/ruff|$REPO|check|--no-fix|--force-exclude|--|$REPO/a.py" "$(calls)"

  printf 'BADLINT\n' >"$REPO/bad.py"
  edit "$REPO/bad.py"
  want_exit "a lint error left after fixing exits 2" 2 "$rc"
  contains "the message names the file" "$err" "$REPO/bad.py"
  contains "the message carries ruff's output" "$err" "F821 BADLINT is undefined"
  contains "the message gives the command to rerun" "$err" "ruff check --fix"

  edit "$REPO/notes.md"
  want_exit "a non-Python path exits 0" 0 "$rc"
  eq "a non-Python path never reaches ruff" "" "$(calls)"

  edit "$REPO/gone.py"
  eq "a file that does not exist never reaches ruff" "" "$(calls)"

  printf 'x=1\n' >"$REPO/two words.py"
  edit "$REPO/two words.py"
  eq "a name with a space reaches ruff as one argument" \
    "$FAKE/ruff|$REPO|check|--fix|--force-exclude|--|$REPO/two words.py
$FAKE/ruff|$REPO|format|--force-exclude|--|$REPO/two words.py
$FAKE/ruff|$REPO|check|--no-fix|--force-exclude|--|$REPO/two words.py" "$(calls)"

  git -C "$REPO" config --local claude.ruff false
  edit "$REPO/bad.py"
  want_exit "claude.ruff false exits 0" 0 "$rc"
  eq "claude.ruff false keeps ruff away from a configured repo" "" "$(calls)"

  new_repo
  printf 'BADLINT\n' >"$REPO/a.py"
  edit "$REPO/a.py"
  want_exit "a repo with no ruff config exits 0" 0 "$rc"
  eq "a repo with no ruff config never reaches ruff" "" "$(calls)"
  printf '[project]\nname = "x"\n' >"$REPO/pyproject.toml"
  edit "$REPO/a.py"
  eq "a pyproject.toml without a ruff table is not config" "" "$(calls)"

  git -C "$REPO" config --local claude.ruff true
  edit "$REPO/a.py"
  want_exit "claude.ruff true runs ruff without config" 2 "$rc"

  new_repo
  mkdir -p "$REPO/svc/pkg/deep"
  printf '[tool.ruff.lint]\nselect = ["F"]\n' >"$REPO/svc/pyproject.toml"
  printf 'x=1\n' >"$REPO/svc/pkg/deep/m.py"
  edit "$REPO/svc/pkg/deep/m.py"
  contains "config in a parent folder of the file turns ruff on" "$(calls)" "|check|"
  printf 'x=1\n' >"$REPO/top.py"
  edit "$REPO/top.py"
  eq "config below the file's folder does not count" "" "$(calls)"

  new_repo
  : >"$REPO/ruff.toml"
  mkdir -p "$REPO/.venv/bin"
  stub_ruff "$REPO/.venv/bin/ruff"
  printf 'x=1\n' >"$REPO/a.py"
  edit "$REPO/a.py"
  eq "the repo's .venv/bin/ruff wins over the one on PATH" \
    "$REPO/.venv/bin/ruff|$REPO|check|--fix|--force-exclude|--|$REPO/a.py
$REPO/.venv/bin/ruff|$REPO|format|--force-exclude|--|$REPO/a.py
$REPO/.venv/bin/ruff|$REPO|check|--no-fix|--force-exclude|--|$REPO/a.py" "$(calls)"

  new_repo
  : >"$REPO/.ruff.toml"
  printf 'x=1\n' >"$REPO/a.py"
  NOUVX="$WORK/nouvx"
  mkdir -p "$NOUVX"
  cat >"$NOUVX/uvx" <<EOF
#!/usr/bin/env bash
printf 'uvx' >>"$LOG"; printf '|%s' "\$@" >>"$LOG"; printf '\n' >>"$LOG"
EOF
  chmod +x "$NOUVX/uvx"
  TPATH="$NOUVX:$SYS"
  edit "$REPO/a.py"
  contains "uvx runs ruff when neither the venv nor PATH has it" "$(calls)" "uvx|ruff|check|--fix|--force-exclude|--|$REPO/a.py"
  TPATH="$SYS"
  edit "$REPO/a.py"
  want_exit "no ruff anywhere exits 0" 0 "$rc"
  TPATH="$FAKE:$SYS"

  OUT="$WORK/outside"
  mkdir -p "$OUT"
  printf 'BADLINT\n' >"$OUT/a.py"
  : >"$OUT/ruff.toml"
  edit "$OUT/a.py"
  want_exit "a file outside any git repo exits 0" 0 "$rc"
  eq "a file outside any git repo never reaches ruff" "" "$(calls)"

  section "ruff after edit hook, real ruff"
  REAL=()
  if command -v ruff >/dev/null 2>&1; then
    REAL=("$(command -v ruff)")
  elif command -v uvx >/dev/null 2>&1 && uvx --offline ruff --version >/dev/null 2>&1; then
    REAL=("$(command -v uvx)" --offline ruff)
  fi
  if [ "${#REAL[@]}" -gt 0 ]; then
    mkdir -p "$FAKE/real"
    { printf '#!/usr/bin/env bash\nexec'; printf ' %q' "${REAL[@]}"; printf ' "$@"\n'; } >"$FAKE/real/ruff"
    chmod +x "$FAKE/real/ruff"
    TPATH="$FAKE/real:$SYS:$PATH"
    new_repo
    printf '[tool.ruff]\n' >"$REPO/pyproject.toml"
    printf 'import os\nx  =  1\n' >"$REPO/a.py"
    edit "$REPO/a.py"
    want_exit "real ruff: a fixable file exits 0" 0 "$rc"
    eq "real ruff: the file is formatted and the unused import removed" "x = 1" "$(cat "$REPO/a.py")"
    printf 'print(undefined_name)\n' >"$REPO/b.py"
    edit "$REPO/b.py"
    want_exit "real ruff: an undefined name exits 2" 2 "$rc"
    contains "real ruff: the message carries the rule" "$err" "F821"
    TPATH="$FAKE:$SYS"
  else
    skip "ruff after edit hook, real ruff (needs ruff on PATH or uvx with ruff cached)"
  fi
fi

finish
