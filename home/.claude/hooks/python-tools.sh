#!/usr/bin/env bash
# Sourced by the Python hooks, so the two rules they share cannot drift apart.

tool_on() { # tool (ruff|ty), file -> success when that tool should run on the file
  local tool=$1 dir root switch
  dir=$(cd "$(dirname "$2")" 2>/dev/null && pwd -P) || return 1
  root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || return 1
  # The repo's own config, not the global one, so the choice is per repo.
  switch=$(git -C "$root" config --local --get "claude.$tool" 2>/dev/null)
  case $switch in
    false) return 1 ;;
    true) return 0 ;;
  esac
  while :; do
    case $tool in
      ruff) [[ -f $dir/ruff.toml || -f $dir/.ruff.toml ]] && return 0 ;;
      ty) [[ -f $dir/ty.toml ]] && return 0 ;;
    esac
    [[ -f $dir/pyproject.toml ]] && grep -q "^\[tool\.${tool}[].]" "$dir/pyproject.toml" && return 0
    [[ $dir != "$root" && $dir == "$root"/* ]] || return 1
    dir=$(dirname "$dir")
  done
}

tool_cmd() { # tool, repo root -> the command that runs it, one word per line; nothing when none
  if [[ -x $2/.venv/bin/$1 ]]; then
    printf '%s\n' "$2/.venv/bin/$1"
  elif command -v "$1" >/dev/null 2>&1; then
    printf '%s\n' "$1"
  elif command -v uvx >/dev/null 2>&1; then
    printf '%s\n' uvx "$1"
  fi
}
