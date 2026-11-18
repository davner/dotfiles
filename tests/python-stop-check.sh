#!/usr/bin/env bash
# shellcheck disable=SC2154  # lib.sh sets rc and err
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "python stop check hook"
# It runs behind `[ ! -x ... ] ||` at every stop, so a break is silent, and a
# check that rewrites files would reformat the owner's own work under them.
HOOK="$DIR/home/.claude/hooks/python-stop-check.sh"
if require jq git; then
  # Only these on PATH, so a ruff, ty or uvx on this machine cannot stand in for a stub.
  SYS="$WORK/sys"
  mkdir -p "$SYS"
  for c in bash jq git dirname readlink grep cat cut; do ln -s "$(command -v "$c")" "$SYS/$c"; done
  FAKE="$WORK/fake"
  mkdir -p "$FAKE"
  LOG="$WORK/tool-log"
  # Each stub logs its call and fails on a marker in any file it is given.
  stub() { # path, marker for check, marker for format --check
    cat >"$1" <<EOF
#!/usr/bin/env bash
{ printf '%s' "\${0##*/}"; printf '|%s' "\$@"; printf '\n'; } >>"$LOG"
marker=$2
[ "\$1 \$2" = "format --check" ] && marker=$3
for a in "\$@"; do
  if [ -f "\$a" ] && grep -q "\$marker" "\$a"; then echo "\$a:1:1: \$marker found"; exit 1; fi
done
exit 0
EOF
    chmod +x "$1"
  }
  stub "$FAKE/ruff" BADLINT UNFORMATTED
  stub "$FAKE/ty" BADTYPE NEVERMATCHES
  TPATH="$FAKE:$SYS"
  fire() { PATH="$TPATH" "$HOOK"; }
  n=0
  new_repo() { # config file contents for pyproject.toml -> sets REPO to a fresh repo with one commit
    n=$((n + 1))
    REPO="$WORK/repo$n"
    mkdir -p "$REPO"
    git init -q "$REPO"
    REPO="$(cd "$REPO" && pwd -P)"
    git -C "$REPO" config user.email t@example.com
    git -C "$REPO" config user.name t
    printf '%b' "$1" >"$REPO/pyproject.toml"
    git -C "$REPO" add -A
    git -C "$REPO" commit -qm init
  }
  commit() { git -C "$REPO" add -A && git -C "$REPO" commit -qm c; }
  stop() { # [stop_hook_active] -> runs the hook on a Stop payload with cwd in REPO
    local c
    json_str c "$REPO"
    : >"$LOG"
    hook fire "{\"hook_event_name\":\"Stop\",\"stop_hook_active\":${1:-false},\"cwd\":$c}"
  }
  calls() { cat "$LOG"; }

  new_repo '[tool.ruff]\n'
  printf 'x = 1\n' >"$REPO/a.py"
  commit
  printf 'x=1  # UNFORMATTED\n' >"$REPO/a.py"
  stop
  want_exit "an unformatted modified file exits 2" 2 "$rc"
  contains "the message names the file" "$err" "a.py"
  contains "the message gives the format command" "$err" "ruff format"
  eq "the file is unchanged on disk" "x=1  # UNFORMATTED" "$(cat "$REPO/a.py")"

  printf 'BADLINT\n' >"$REPO/a.py"
  stop
  want_exit "a lint error in a modified file exits 2" 2 "$rc"
  contains "the message carries ruff's output" "$err" "a.py:1:1: BADLINT found"
  contains "the message gives the lint fix command" "$err" "ruff check --fix a.py"
  contains "the message says not to silence it with a blanket suppression" "$err" "blanket"
  eq "the file is unchanged after a lint error" "BADLINT" "$(cat "$REPO/a.py")"
  eq "ruff runs only read-only, from the repo root" "" \
    "$(grep -E -e '--fix|\|format\|([^-]|$)' "$LOG" | grep -v -e '--check')"

  printf 'x = 2\n' >"$REPO/a.py"
  stop
  want_exit "a clean modified file exits 0" 0 "$rc"
  eq "a clean file says nothing" "" "$err"
  contains "a clean file was checked" "$(calls)" "ruff|check|--no-fix|--force-exclude|--|a.py"
  contains "a clean file was format-checked" "$(calls)" "ruff|format|--check|--force-exclude|--|a.py"

  printf 'BADLINT\n' >"$REPO/a.py"
  stop true
  want_exit "stop_hook_active true exits 0 on a failing file" 0 "$rc"
  eq "stop_hook_active true calls no tool" "" "$(calls)"

  git -C "$REPO" checkout -q -- a.py
  printf 'notes\n' >"$REPO/notes.md"
  stop
  want_exit "no changed Python file exits 0" 0 "$rc"
  eq "no changed Python file calls no tool" "" "$(calls)"

  OUT="$WORK/outside"
  mkdir -p "$OUT"
  printf '[tool.ruff]\n' >"$OUT/pyproject.toml"
  printf 'BADLINT\n' >"$OUT/a.py"
  SAVED=$REPO REPO=$OUT
  stop
  want_exit "a folder outside any git repo exits 0" 0 "$rc"
  eq "a folder outside any git repo calls no tool" "" "$(calls)"
  REPO=$SAVED

  new_repo '[tool.ruff]\n'
  printf 'x = 1\n' >"$REPO/gone.py"
  printf 'x = 1\n' >"$REPO/old.py"
  printf 'x = 1\n' >"$REPO/keep.py"
  # Read past the rename's old path as an entry, "oldkeep.py" would name keep.py.
  printf 'x = 2\n' >"$REPO/oldkeep.py"
  commit
  git -C "$REPO" rm -q gone.py
  git -C "$REPO" mv old.py renamed.py
  git -C "$REPO" mv oldkeep.py moved.py
  mkdir -p "$REPO/pkg/sub"
  printf 'x = 1\n' >"$REPO/pkg/sub/new.py"
  printf 'x = 1\n' >"$REPO/two words.py"
  printf 'x = 1\n' >"$REPO/stub.pyi"
  stop
  want_exit "clean renamed, untracked and spaced files exit 0" 0 "$rc"
  eq "each changed file is checked by its current path, one argument each, deletions skipped" \
    "ruff|check|--no-fix|--force-exclude|--|moved.py
ruff|check|--no-fix|--force-exclude|--|pkg/sub/new.py
ruff|check|--no-fix|--force-exclude|--|renamed.py
ruff|check|--no-fix|--force-exclude|--|stub.pyi
ruff|check|--no-fix|--force-exclude|--|two words.py" \
    "$(grep '^ruff|check|' "$LOG" | LC_ALL=C sort)"
  printf 'UNFORMATTED\n' >"$REPO/two words.py"
  stop
  want_exit "a failing file whose name has a space exits 2" 2 "$rc"
  contains "the fix command quotes a name with a space" "$err" 'ruff format two\ words.py'

  eq "ty stays away from a repo with no ty config" "" "$(grep '^ty|' "$LOG")"
  git -C "$REPO" config --local claude.ty true
  printf 'BADTYPE\n' >"$REPO/two words.py"
  stop
  want_exit "claude.ty true runs ty, and a type error exits 2" 2 "$rc"
  contains "ty gets the file as one argument" "$(calls)" "ty|check|--|two words.py"
  contains "the message carries ty's output" "$err" "two words.py:1:1: BADTYPE found"
  contains "the message says to fix the type error" "$err" "fix the type error"
  git -C "$REPO" config --local claude.ty false
  printf '[tool.ruff]\n[tool.ty]\n' >"$REPO/pyproject.toml"
  stop
  want_exit "claude.ty false exits 0 on a type error" 0 "$rc"
  eq "claude.ty false keeps ty away from a configured repo" "" "$(grep '^ty|' "$LOG")"
  git -C "$REPO" config --local --unset claude.ty
  stop
  want_exit "a [tool.ty] table turns ty on" 2 "$rc"

  new_repo ''
  : >"$REPO/ty.toml"
  printf 'BADLINT\n' >"$REPO/a.py"
  stop
  want_exit "ruff stays off without ruff config" 0 "$rc"
  eq "ty.toml alone runs ty and not ruff" "ty|check|--|a.py" "$(calls)"
  git -C "$REPO" config --local claude.ruff true
  stop
  want_exit "claude.ruff true runs ruff without config" 2 "$rc"
  git -C "$REPO" config --local claude.ruff false
  printf '[tool.ruff]\n' >"$REPO/pyproject.toml"
  stop
  want_exit "claude.ruff false exits 0 on a lint error" 0 "$rc"
  eq "claude.ruff false keeps ruff away from a configured repo" "" "$(grep '^ruff|' "$LOG")"

  new_repo '[tool.ruff]\n'
  printf 'import os  # noqa\nx = 1\n' >"$REPO/old.py"
  printf 'y = 1  # type: ignore\n' >"$REPO/moved_from.py"
  commit
  printf 'import os  # noqa\nx = 2\n' >"$REPO/old.py"
  git -C "$REPO" mv moved_from.py moved_to.py
  stop
  want_exit "a blanket suppression already committed is not flagged" 0 "$rc"
  while IFS='|' read -r want line; do
    [ -n "$want" ] || continue
    git -C "$REPO" checkout -q -- old.py
    printf 'import os\n%s\n' "$line" >>"$REPO/old.py"
    stop
    if [ "$want" = flag ]; then
      want_exit "flagged on an added line: $line" 2 "$rc"
      contains "the message quotes it: $line" "$err" "$line"
    else
      want_exit "allowed on an added line: $line" 0 "$rc"
    fi
  done <<'LINES'
flag|x = 1  # noqa
flag|x = 1  # NOQA
flag|x = 1  # noqa:
flag|x = 1  # noqa E501
allow|x = 1  # noqa: E501
allow|x = 1  # noqa:E501,F401
flag|x = 1  # type: ignore
flag|x = 1  # type:ignore
allow|x = 1  # type: ignore[attr-defined]
allow|x = 1  # a note on noqa and type ignore
LINES
  git -C "$REPO" checkout -q -- old.py
  printf 'z = 3  # noqa\n' >>"$REPO/old.py"
  git -C "$REPO" add old.py
  stop
  want_exit "a staged blanket suppression is flagged" 2 "$rc"
  contains "the staged one is named by file" "$err" "old.py:"
  git -C "$REPO" reset -q
  git -C "$REPO" checkout -q -- old.py
  printf 'w = 4  # type: ignore\n' >"$REPO/fresh.py"
  stop
  want_exit "a blanket suppression in an untracked file is flagged" 2 "$rc"
  contains "the untracked file is named" "$err" "fresh.py:"
  contains "the message asks for a coded suppression" "$err" "noqa: <code>"

  new_repo ''
  printf 'w = 4  # type: ignore\n' >"$REPO/fresh.py"
  stop
  want_exit "suppressions are not scanned where neither tool is on" 0 "$rc"

  new_repo '[tool.ruff]\n[tool.ty]\n'
  printf 'BADLINT\nUNFORMATTED\nBADTYPE\n' >"$REPO/a.py"
  TPATH="$SYS"
  stop
  want_exit "no ruff or ty anywhere exits 0" 0 "$rc"
  eq "no ruff or ty anywhere says nothing" "" "$err"
  TPATH="$FAKE:$SYS"
  stop
  want_exit "every finding in one file exits 2" 2 "$rc"
  contains "lint, format and type findings are all reported" "$err" \
    "BADLINT found
Fix: ruff check --fix a.py
a.py:1:1: UNFORMATTED found
Fix: ruff format a.py
a.py:1:1: BADTYPE found"

  section "python stop check hook, real ruff"
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
    new_repo '[tool.ruff]\n'
    printf 'import os\nx  =  1\n' >"$REPO/a.py"
    stop
    want_exit "real ruff: an unused import and bad spacing exit 2" 2 "$rc"
    contains "real ruff: the lint rule is reported" "$err" "F401"
    contains "real ruff: the format check is reported" "$err" "Fix: ruff format a.py"
    eq "real ruff: the file is unchanged" "import os
x  =  1" "$(cat "$REPO/a.py")"
    printf 'x = 1\n' >"$REPO/a.py"
    stop
    want_exit "real ruff: a clean file exits 0" 0 "$rc"
    # A repo's `fix = true` makes a bare `ruff check` rewrite the file, which
    # would strip a blanket noqa before the scan could see it.
    new_repo '[tool.ruff]\nfix = true\n'
    printf 'import os\nx = 1\n' >"$REPO/a.py"
    stop
    want_exit "real ruff: fix = true still reports the unused import" 2 "$rc"
    eq "real ruff: fix = true leaves the file byte-identical" "$(printf 'import os\nx = 1\nEOF')" \
      "$(cat "$REPO/a.py"; printf EOF)"
    TPATH="$FAKE:$SYS"
  else
    skip "python stop check hook, real ruff (needs ruff on PATH or uvx with ruff cached)"
  fi

  section "python stop check hook, real ty"
  REAL=()
  if command -v ty >/dev/null 2>&1; then
    REAL=("$(command -v ty)")
  elif command -v uvx >/dev/null 2>&1 && uvx --offline ty --version >/dev/null 2>&1; then
    REAL=("$(command -v uvx)" --offline ty)
  fi
  if [ "${#REAL[@]}" -gt 0 ]; then
    mkdir -p "$FAKE/realty"
    { printf '#!/usr/bin/env bash\nexec'; printf ' %q' "${REAL[@]}"; printf ' "$@"\n'; } >"$FAKE/realty/ty"
    chmod +x "$FAKE/realty/ty"
    TPATH="$FAKE/realty:$SYS:$PATH"
    new_repo '[tool.ty]\n'
    printf 'x: int = "one"\n' >"$REPO/a.py"
    stop
    want_exit "real ty: a type error exits 2" 2 "$rc"
    contains "real ty: the rule is reported" "$err" "invalid-assignment"
    printf 'x: int = 1\n' >"$REPO/a.py"
    stop
    want_exit "real ty: a clean file exits 0" 0 "$rc"
    TPATH="$FAKE:$SYS"
  else
    skip "python stop check hook, real ty (needs ty on PATH or uvx with ty cached)"
  fi
fi

finish
