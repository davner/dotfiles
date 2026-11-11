#!/usr/bin/env bash
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "metals-java-home"
MJH="$DIR/home/vscode/metals-java-home.sh"
if require jq git; then
  MW="$WORK/mjh"
  mkdir -p "$MW/stub" "$MW/jdk" "$MW/ws/a/.vscode" "$MW/ws/b" "$MW/ws/nojava" "$MW/ws/tracked/.vscode" "$MW/ws/commented/.vscode"
  # Stands in for direnv: a folder's JAVA_HOME is whatever its .fake-java-home names.
  cat >"$MW/stub/direnv" <<'EOF'
#!/usr/bin/env bash
[ "$1" = exec ] && [ -f "$2/.fake-java-home" ] && cat "$2/.fake-java-home"
exit 0
EOF
  chmod +x "$MW/stub/direnv"
  for d in a nojava tracked commented; do touch "$MW/ws/$d/.envrc"; done
  for d in a tracked commented; do printf '%s' "$MW/jdk" >"$MW/ws/$d/.fake-java-home"; done
  printf '{"files.watcherExclude": {"**/target/**": true}}\n' >"$MW/ws/a/.vscode/settings.json"
  printf '{} // mine\n' >"$MW/ws/commented/.vscode/settings.json"
  printf '{}\n' >"$MW/ws/tracked/.vscode/settings.json"
  git -C "$MW/ws/tracked" init -q && git -C "$MW/ws/tracked" add .vscode/settings.json
  printf '{"folders": [{"path": "a"}, {"path": "b"}, {"path": "nojava"}]}\n' >"$MW/ws/x.code-workspace"
  run_mjh() { PATH="$MW/stub:$PATH" "$MJH" "$@" >"$MW/out" 2>&1; }

  run_mjh "$MW/ws/x.code-workspace"
  rc=$?
  run_mjh "$MW/ws/x.code-workspace"
  if [ "$rc" = 0 ] && jq -e --arg jh "$MW/jdk" '."metals.javaHome" == $jh and ."files.watcherExclude"."**/target/**" == true and length == 2' "$MW/ws/a/.vscode/settings.json" >/dev/null 2>&1; then
    ok "metals-java-home sets javaHome from a workspace file, keeps other keys, and reruns cleanly"
  else
    bad "metals-java-home sets javaHome from a workspace file, keeps other keys, and reruns cleanly" "rc=$rc" "$(cat "$MW/out")"
  fi
  if [ ! -e "$MW/ws/b/.vscode" ] && [ ! -e "$MW/ws/nojava/.vscode" ]; then
    ok "metals-java-home leaves folders without .envrc or JAVA_HOME alone"
  else
    bad "metals-java-home leaves folders without .envrc or JAVA_HOME alone"
  fi
  run_mjh "$MW/ws/tracked"
  rc=$?
  if [ "$rc" != 0 ] && [ "$(cat "$MW/ws/tracked/.vscode/settings.json")" = "{}" ]; then
    ok "metals-java-home refuses a git-tracked settings.json"
  else
    bad "metals-java-home refuses a git-tracked settings.json" "a nix store path would reach the team"
  fi
  run_mjh "$MW/ws/commented"
  rc=$?
  if [ "$rc" != 0 ] && [ "$(cat "$MW/ws/commented/.vscode/settings.json")" = "{} // mine" ]; then
    ok "metals-java-home skips a hand-commented settings.json"
  else
    bad "metals-java-home skips a hand-commented settings.json"
  fi
  if run_mjh; then bad "metals-java-home with no arguments fails"; else ok "metals-java-home with no arguments fails"; fi
fi
if grep -q 'mkOutOfStoreSymlink.*metals-java-home.sh' "$DIR/home.nix"; then
  ok "home.nix puts metals-java-home on PATH"
else
  bad "home.nix puts metals-java-home on PATH"
fi

finish
