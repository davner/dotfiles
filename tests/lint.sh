#!/usr/bin/env bash
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "syntax and lint"
# From git, so a new script is linted without anyone listing it. Untracked
# files count too: the flake would miss them, but a typo in one should not.
SCRIPTS=()
while IFS= read -r s; do SCRIPTS+=("$s"); done < <(cd "$DIR" && git ls-files -co --exclude-standard '*.sh')
[ "${#SCRIPTS[@]}" -gt 0 ] || bad "git lists the shell scripts" "git ls-files found no *.sh in $DIR"
bash_scripts=()
for s in "${SCRIPTS[@]}"; do
  # zsh syntax is not bash syntax, and shellcheck does not read zsh at all.
  IFS= read -r shebang <"$DIR/$s"
  case "$shebang" in
    *zsh*)
      if err="$(zsh -n "$DIR/$s" 2>&1)"; then ok "zsh -n $s"; else bad "zsh -n $s" "$err"; fi
      continue
      ;;
  esac
  if err="$(bash -n "$DIR/$s" 2>&1)"; then ok "bash -n $s"; else bad "bash -n $s" "$err"; fi
  bash_scripts+=("$s")
done
have_shellcheck=""
command -v shellcheck >/dev/null 2>&1 && have_shellcheck=1
# One shellcheck for every file is the fast path; only a finding pays for a
# run per file, which is what names the file and prints the full report.
if [ -n "$have_shellcheck" ] && (cd "$DIR" && shellcheck "${bash_scripts[@]}" >/dev/null 2>&1); then
  for s in "${bash_scripts[@]}"; do ok "shellcheck $s"; done
elif [ -n "$have_shellcheck" ]; then
  for s in "${bash_scripts[@]}"; do
    if err="$(shellcheck "$DIR/$s" 2>&1)"; then ok "shellcheck $s"; else bad "shellcheck $s" "$err"; fi
  done
fi
[ -n "$have_shellcheck" ] || skip "shellcheck (nix develop --command ./test.sh installs it)"
# Catches a broken workflow before a push does, and shellchecks the `run:`
# blocks that CI would otherwise only fail on inside the runner.
if command -v actionlint >/dev/null 2>&1; then
  if err="$(cd "$DIR" && actionlint 2>&1)"; then ok "actionlint"; else bad "actionlint" "$err"; fi
  # A skill can ship workflow templates that a repo copies in, and actionlint
  # alone reads only .github/workflows.
  templates=()
  while IFS= read -r f; do templates+=("$f"); done < <(cd "$DIR" &&
    grep -rlE --include='*.yml' --include='*.yaml' '^jobs:' home/.claude/skills 2>/dev/null | sort)
  for t in ${templates[@]+"${templates[@]}"}; do
    if err="$(cd "$DIR" && actionlint "$t" 2>&1)"; then ok "actionlint $t"; else bad "actionlint $t" "$err"; fi
  done
else
  skip "actionlint (nix develop --command ./test.sh installs it)"
fi
# users.sh parses flake.nix by shape, so a reformat is the change that could
# break it silently.
if command -v nixfmt >/dev/null 2>&1; then
  if err="$(cd "$DIR" && git ls-files -z '*.nix' | xargs -0 nixfmt --check 2>&1)"; then
    ok "nixfmt"
  else
    bad "nixfmt" "$err (run: nix fmt)"
  fi
else
  skip "nixfmt (nix develop --command ./test.sh installs it)"
fi

finish
