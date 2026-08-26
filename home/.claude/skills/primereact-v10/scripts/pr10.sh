#!/usr/bin/env bash
# pr10.sh - read the PrimeReact v10 API from the version you actually have installed.
#
# The installed .d.ts files are version-exact by construction, which makes them a
# better source than any documentation or recollection. This script makes them
# readable without pulling thousands of lines into context (DataTable alone is
# 2069 lines).
#
# Usage:
#   pr10.sh version                 what is actually installed, and where
#   pr10.sh list                    every component module present
#   pr10.sh find <regex>            components whose name matches
#   pr10.sh props <component>       the Props interface, with JSDoc
#   pr10.sh prop <component> <name> one prop, with its JSDoc and default
#   pr10.sh events <component>      only the callback props
#   pr10.sh types <component>       exported interfaces and type aliases
#   pr10.sh raw <component>         path to the .d.ts, for reading directly
#
# Every subcommand exits 0 with a diagnostic on stdout when it cannot find
# something, so this is safe to use inside a SKILL.md injection block, where a
# non-zero exit aborts the whole skill invocation.

set -uo pipefail

find_root() {
  local dir="${PWD}"
  while [ "${dir}" != "/" ]; do
    if [ -d "${dir}/node_modules/primereact" ]; then
      printf '%s\n' "${dir}/node_modules/primereact"
      return 0
    fi
    dir="$(dirname "${dir}")"
  done
  return 1
}

ROOT="$(find_root || true)"

need_root() {
  if [ -z "${ROOT}" ]; then
    echo "primereact is not installed anywhere at or above ${PWD}."
    echo "Run this from inside the project, or install dependencies first."
    return 1
  fi
  return 0
}

# Every shipped module, by directory. Deliberately NOT keyed on the presence of a
# matching <name>.d.ts: several real modules (focustrap, portal, keyfilter,
# passthrough) name their declaration file differently or ship none, and filtering
# on .d.ts silently hides them.
modules() {
  find "${ROOT}" -mindepth 1 -maxdepth 1 -type d 2>/dev/null \
    | sed 's|.*/||' \
    | grep -vE '^(resources|icons)$' \
    | sort -u
}

dts_for() {
  local comp
  comp="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  local f="${ROOT}/${comp}/${comp}.d.ts"
  if [ -f "${f}" ]; then printf '%s\n' "${f}"; return 0; fi
  # tolerate the common spelling drift between docs and module names
  local alt
  alt="$(modules | grep -ix "${comp}" | head -1)"
  if [ -n "${alt}" ] && [ -f "${ROOT}/${alt}/${alt}.d.ts" ]; then
    printf '%s\n' "${ROOT}/${alt}/${alt}.d.ts"; return 0
  fi
  return 1
}

# Print an interface block, brace-balanced, starting at the first match.
block() {
  local file="$1" pattern="$2"
  awk -v pat="${pattern}" '
    !inb && $0 ~ pat { inb=1; depth=0 }
    inb {
      print
      n=gsub(/\{/,"{"); depth+=n
      m=gsub(/\}/,"}"); depth-=m
      if (depth<=0 && n+m>0) exit
    }
  ' "${file}"
}

cmd="${1:-help}"; shift || true

case "${cmd}" in
  version)
    if [ -z "${ROOT}" ]; then
      echo '{"installed":null,"note":"no primereact resolved from this directory"}'
      exit 0
    fi
    node -p "
      const fs=require('fs');
      const j=f=>{try{return JSON.parse(fs.readFileSync(f,'utf8'))}catch(e){return {}}};
      const pk=j('${ROOT}/package.json');
      const app=j(require('path').join('${ROOT}','..','..','package.json'));
      JSON.stringify({
        installed: pk.version||null,
        declared: (app.dependencies||{}).primereact||(app.devDependencies||{}).primereact||null,
        primeicons: (app.dependencies||{}).primeicons||null,
        react: (app.dependencies||{}).react||null,
        path: '${ROOT}'
      },null,2)
    " 2>/dev/null || echo "{\"installed\":\"unknown\",\"path\":\"${ROOT}\"}"
    ;;

  list)
    need_root || exit 0
    modules
    ;;

  find)
    need_root || exit 0
    pat="${1:-.}"
    modules | grep -i -- "${pat}" || echo "no module matches /${pat}/"
    ;;

  props)
    need_root || exit 0
    comp="${1:-}"
    [ -z "${comp}" ] && { echo "usage: pr10.sh props <component>"; exit 0; }
    f="$(dts_for "${comp}")" || { echo "no .d.ts for '${comp}'. Try: pr10.sh find ${comp}"; exit 0; }
    echo "// ${f}"
    block "${f}" 'export interface .*Props' || echo "no Props interface found in ${f}"
    ;;

  prop)
    need_root || exit 0
    comp="${1:-}"; name="${2:-}"
    [ -z "${name}" ] && { echo "usage: pr10.sh prop <component> <propName>"; exit 0; }
    f="$(dts_for "${comp}")" || { echo "no .d.ts for '${comp}'"; exit 0; }
    echo "// ${f}"
    # grab the JSDoc block immediately preceding the prop plus the prop line
    awk -v want="${name}" '
      /\/\*\*/ { doc=""; ind=1 }
      ind { doc = doc $0 "\n" }
      /\*\// { ind=0 }
      $0 ~ "^[[:space:]]*" want "\\??[:(]" { printf "%s%s\n", doc, $0; doc="" }
    ' "${f}" | head -40
    ;;

  events)
    need_root || exit 0
    comp="${1:-}"
    f="$(dts_for "${comp}")" || { echo "no .d.ts for '${comp}'"; exit 0; }
    echo "// ${f} - callback props"
    grep -nE '^[[:space:]]*on[A-Z][A-Za-z]*\??[:(]' "${f}" || echo "no on* callbacks declared"
    ;;

  types)
    need_root || exit 0
    comp="${1:-}"
    f="$(dts_for "${comp}")" || { echo "no .d.ts for '${comp}'"; exit 0; }
    echo "// ${f} - exported types"
    grep -nE '^export (declare )?(interface|type|class|function|const) ' "${f}" || echo "none"
    ;;

  raw)
    need_root || exit 0
    comp="${1:-}"
    f="$(dts_for "${comp}")" || { echo "no .d.ts for '${comp}'"; exit 0; }
    printf '%s\n' "${f}"
    ;;

  *)
    sed -n '2,25p' "$0" | sed 's|^# \{0,1\}||'
    ;;
esac
exit 0
