#!/usr/bin/env bash
# The one reading of a shell command that guard-bash.sh and skill-gate.sh share,
# so a quoting or heredoc fix reaches every rule in both hooks at once.
set -uo pipefail

if [[ ${1-} == --help || ${1-} == -h ]]; then
  cat <<'EOF'
usage: shell-parse.sh < command

Reads one shell command on stdin and prints one record per line:

  w WORD      a word of the command, quotes removed
  a NAME=VAL  an assignment before the command's first word
  > PATH      an output redirect target
  < PATH      an input redirect target
  h TEXT      text fed to stdin: a heredoc body or a here-string
  e [SCOPE]   the end of a statement

A statement is a simple command: separators, pipes and newlines end one.
Commands inside ( ), $( ), backticks and <( ) are statements of their own,
listed after the statement they sit in, and the word that holds a $( ) keeps
its source text. SCOPE names the subshell a statement runs in, as a path such
as 1 or 1/2, and is empty at the top level. Reserved words such as if, then,
do, ! and { are dropped where they open a command. Text inside quotes, a
heredoc body or a comment is never a statement.

In TEXT a backslash is written \\ and a newline \n, so printf %b restores it.
EOF
  exit 0
fi

# awk, since a per-character bash loop over a long heredoc would outrun a hook's 5 s timeout.
# shellcheck disable=SC2016
exec awk '
function escb(s,   out, k) {
  out = ""
  while ((k = index(s, "\\")) > 0) { out = out substr(s, 1, k) "\\"; s = substr(s, k + 1) }
  return out s
}
function esc(s,   parts, m, j, out) {
  m = split(s, parts, "\n")
  out = escb(parts[1])
  for (j = 2; j <= m; j++) out = out "\\n" escb(parts[j])
  return out
}
function newstmt() { st = ++nst; scope_of[st] = scope }
function emit(kind, text) { out[st] = out[st] kind " " esc(text) "\n" }
function flush() {
  if (!inword) return
  if (redir == 3) hb[st] = hb[st] "h " esc(cur "\n") "\n"
  else if (redir) emit(redir == 1 ? ">" : "<", cur)
  else if (!nwords && cur ~ /^[A-Za-z_][A-Za-z0-9_]*=/ && (qpos < 0 || qpos >= index(cur, "="))) {
    emit("a", cur); nassign++
  } else if (!nwords && !nassign && qpos < 0 && cur ~ /^([{}!]|if|then|else|elif|fi|do|done|while|until)$/) {
  } else { emit("w", cur); nwords++ }
  cur = ""; inword = 0; redir = 0; qpos = -1
}
function end_stmt() { flush(); redir = 0; nwords = 0; nassign = 0; newstmt() }
function push(kind) {
  D_cur[depth] = cur; D_inword[depth] = inword; D_redir[depth] = redir; D_nwords[depth] = nwords
  D_nassign[depth] = nassign; D_q[depth] = q; D_qpos[depth] = qpos; D_st[depth] = st; D_scope[depth] = scope
  depth++; KD[depth] = kind
  cur = ""; inword = 0; redir = 0; nwords = 0; nassign = 0; q = ""; qpos = -1
  scope = (scope == "" ? "" : scope "/") (++nscope)
  newstmt()
  R_buf[depth] = ""; R_start[depth] = i
}
function pop() {
  end_stmt()
  depth--
  cur = D_cur[depth]; inword = D_inword[depth]; redir = D_redir[depth]; nwords = D_nwords[depth]
  nassign = D_nassign[depth]; q = D_q[depth]; qpos = D_qpos[depth]; st = D_st[depth]; scope = D_scope[depth]
}
# The closing character is at i; the word that opened the substitution gets its source back.
function close_sub(   text) {
  text = R_buf[depth] substr(line, R_start[depth], i - R_start[depth] + 1)
  pop()
  cur = cur text; inword = 1; i++
}
function closing(p, o, cl,   d, ch) {
  d = 0
  for (; p <= n; p++) {
    ch = substr(line, p, 1)
    if (ch == o) d++
    else if (ch == cl && --d == 0) return p
  }
  return n
}
function dollar(   nx, k) {
  nx = substr(line, i + 1, 1)
  if (nx == "(" && substr(line, i + 2, 1) == "(") {
    k = closing(i + 1, "(", ")"); cur = cur substr(line, i, k - i + 1); inword = 1; i = k + 1; return 1
  }
  if (nx == "(") { cur = cur "$("; inword = 1; i += 2; push("$"); return 1 }
  if (nx == "{") {
    k = closing(i + 1, "{", "}"); cur = cur substr(line, i, k - i + 1); inword = 1; i = k + 1; return 1
  }
  return 0
}
function fd_number() { if (inword && qpos < 0 && cur ~ /^[0-9]+$/) { cur = ""; inword = 0 } }
function heredoc(   d, s, c) {
  s = 0
  if (substr(line, i, 1) == "-") { s = 1; i++ }
  while (substr(line, i, 1) ~ /[ \t]/) i++
  d = ""
  while (i <= n) {
    c = substr(line, i, 1)
    if (c ~ /[ \t;|&<>()]/) break
    if (c == "\047" || c == "\"") {
      i++
      while (i <= n && substr(line, i, 1) != c) { d = d substr(line, i, 1); i++ }
    } else if (c == "\\") {
      i++; d = d substr(line, i, 1)
    } else d = d c
    i++
  }
  delim[++nd] = d; strip[nd] = s; hst[nd] = st
}
function raw_line(text,   k) { for (k = 1; k <= depth; k++) if (KD[k] != "(") { R_buf[k] = R_buf[k] text "\n"; R_start[k] = 1 } }
function raw_rest(   k) { for (k = 1; k <= depth; k++) if (KD[k] != "(") { R_buf[k] = R_buf[k] substr(line, R_start[k]) "\n"; R_start[k] = 1 } }
BEGIN { hd = 1; depth = 0; qpos = -1; scope = ""; newstmt() }
body {
  raw_line($0)
  l = $0
  if (strip[hd]) sub(/^\t+/, "", l)
  if (l == delim[hd]) {
    hb[hst[hd]] = hb[hst[hd]] "h " cb "\n"; cb = ""
    if (++hd > nd) { body = 0; nd = 0; hd = 1 }
  } else cb = cb escb(l) "\\n"
  next
}
{
  line = $0; n = length(line); i = 1; cont = 0
  while (i <= n) {
    c = substr(line, i, 1)
    if (q == "\047") { if (c == q) q = ""; else cur = cur c; i++; continue }
    if (q == "\"") {
      if (c == "\\" && i == n) { cont = 1; i++; continue }
      if (c == "\\" && index("$`\"\\", substr(line, i + 1, 1))) { cur = cur substr(line, i + 1, 1); i += 2; continue }
      if (c == "$" && dollar()) continue
      if (c == "`") {
        if (KD[depth] == "`") close_sub(); else { cur = cur c; i++; push("`") }
        continue
      }
      if (c == q) q = ""; else cur = cur c
      i++; continue
    }
    if (c == "\\") {
      if (i == n) cont = 1
      else { if (qpos < 0) qpos = length(cur); cur = cur substr(line, i + 1, 1); inword = 1 }
      i += 2; continue
    }
    if (c == "\047" || c == "\"") { if (qpos < 0) qpos = length(cur); q = c; inword = 1; i++; continue }
    if (c == " " || c == "\t") { flush(); i++; continue }
    if (c == "#" && !inword) break
    if (c == "$" && dollar()) continue
    if (c == "`") {
      if (KD[depth] == "`") close_sub(); else { cur = cur c; inword = 1; i++; push("`") }
      continue
    }
    if (c == "(") {
      # An array assignment, whose parentheses hold words rather than a command.
      if (inword && cur ~ /^[A-Za-z_][A-Za-z0-9_]*\+?=$/) {
        k = closing(i, "(", ")"); cur = cur substr(line, i, k - i + 1); i = k + 1; continue
      }
      flush(); i++; push("("); continue
    }
    if (c == ")") {
      # Only `name()` puts a word before `(`, and the body after it opens a command.
      if (KD[depth] == "(") { i++; pop(); if (nwords) end_stmt() }
      else if (depth > 0 && KD[depth] != "`") close_sub()
      else { end_stmt(); i++ }
      continue
    }
    if ((c == "<" || c == ">") && substr(line, i + 1, 1) == "(") {
      fd_number(); flush(); cur = c "("; inword = 1; i += 2; push("$"); continue
    }
    if (c == "&" && substr(line, i + 1, 1) == ">") { flush(); i++; continue }
    if (c ~ /[;|&]/) { end_stmt(); i++; continue }
    if (c == ">") {
      fd_number(); flush(); i++
      if (substr(line, i, 1) ~ /[>|]/) i++
      if (substr(line, i, 1) == "&") {
        i++
        if (substr(line, i, 1) ~ /[0-9-]/) { while (substr(line, i, 1) ~ /[0-9-]/) i++; continue }
      }
      redir = 1; continue
    }
    if (c == "<") {
      fd_number(); flush(); i++
      if (substr(line, i, 2) == "<<") { i += 2; redir = 3; continue }
      if (substr(line, i, 1) == "<") { i++; heredoc(); continue }
      if (substr(line, i, 1) == "&") { i++; while (substr(line, i, 1) ~ /[0-9-]/) i++; continue }
      redir = 2; continue
    }
    cur = cur c; inword = 1; i++
  }
  raw_rest()
  if (q) { if (!cont) cur = cur "\n"; next }
  if (cont) next
  end_stmt()
  if (nd >= hd) body = 1
}
END {
  if (body && cb != "") hb[hst[hd]] = hb[hst[hd]] "h " cb "\n"
  while (depth > 0) pop()
  end_stmt()
  for (s = 1; s <= nst; s++)
    if (out[s] != "" || hb[s] != "") printf "%s%se%s\n", out[s], hb[s], (scope_of[s] == "" ? "" : " " scope_of[s])
}'
