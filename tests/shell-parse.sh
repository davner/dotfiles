#!/usr/bin/env bash
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

section "shell parser"
# Both Bash hooks read a command through this, so a case it gets wrong is a
# rule in each of them that fires on plain text or misses a real command.
PARSER="$DIR/home/.claude/hooks/shell-parse.sh"
parses() { # name, command, expected records
  eq "parses $1" "$3" "$(printf '%s' "$2" | "$PARSER" 2>&1)"
}
# shellcheck disable=SC2016  # unexpanded text is what is under test
{
  parses "quotes and an escaped space" 'echo "a b" '\''c;d'\'' e\ f' $'w echo\nw a b\nw c;d\nw e f\ne'
  parses "escaped separators as words" 'echo a\;b \&\& c' $'w echo\nw a;b\nw &&\nw c\ne'
  parses "escapes inside double quotes" 'echo "a\"b\$c\d"' $'w echo\nw a"b$c\\\\d\ne'
  parses "pipes, &&, ||, ; and newlines" $'a | b && c || d; e\nf' $'w a\ne\nw b\ne\nw c\ne\nw d\ne\nw e\ne\nw f\ne'
  parses "assignments before the first word only" 'A=1 B="x y" cmd C=2' $'a A=1\na B=x y\nw cmd\nw C=2\ne'
  parses "a quoted assignment as a word" '"A=1" cmd' $'w A=1\nw cmd\ne'
  parses "redirects" 'cmd >out 2>>err <in 2>&1 &>all >|clob' $'w cmd\n> out\n> err\n< in\n> all\n> clob\ne'
  parses "a redirect glued to the word before it" 'echo x>a.ts' $'w echo\nw x\n> a.ts\ne'
  parses "a quoted heredoc as data" $'cat <<\'EOF\' >f\nline $x; git add .\nEOF\nnext' \
    $'w cat\n> f\nh line $x; git add .\\n\ne\nw next\ne'
  parses "a double-quoted heredoc delimiter" $'cat <<"EOF"\na\nEOF' $'w cat\nh a\\n\ne'
  parses "a bare heredoc delimiter" $'cat <<EOF\na\nEOF' $'w cat\nh a\\n\ne'
  parses "<<- stripping tabs" $'cat <<-EOF\n\tone\n\tEOF\nnext' $'w cat\nh one\\n\ne\nw next\ne'
  parses "two heredocs, each on its statement" $'cat <<A; cat <<B\na\nA\nb\nB' $'w cat\nh a\\n\ne\nw cat\nh b\\n\ne'
  parses "a delimiter as a substring" $'cat <<END\nENDING\nEND' $'w cat\nh ENDING\\n\ne'
  parses "a here-string" 'cat <<<"hi there"' $'w cat\nh hi there\\n\ne'
  parses "a subshell" '(cd x && git push); y' $'w cd\nw x\ne 1\nw git\nw push\ne 1\nw y\ne'
  parses "\$( ) inside double quotes" 'echo "$(git status)" done' \
    $'w echo\nw $(git status)\nw done\ne\nw git\nw status\ne 1'
  parses "backticks" 'echo `date`' $'w echo\nw `date`\ne\nw date\ne 1'
  parses "nested \$( )" 'a $(b $(c))' $'w a\nw $(b $(c))\ne\nw b\nw $(c)\ne 1\nw c\ne 1/2'
  parses "process substitution" 'diff <(a) >(b)' $'w diff\nw <(a)\nw >(b)\ne\nw a\ne 1\nw b\ne 2'
  parses "braces and reserved words" '{ git add .; } && if a; then b; fi' \
    $'w git\nw add\nw .\ne\nw a\ne\nw b\ne'
  parses "a function body" 'f() { g; }' $'w f\ne\nw g\ne'
  parses "a comment" 'echo a # git add .' $'w echo\nw a\ne'
  parses "arithmetic and parameter expansion" 'echo $((1+2)) ${a//;/,}' $'w echo\nw $((1+2))\nw ${a//;/,}\ne'
  parses "a heredoc inside \$( )" $'git commit -m "$(cat <<\'EOF\'\nfix: x\nEOF\n)"' \
    $'w git\nw commit\nw -m\nw $(cat <<\'EOF\'\\nfix: x\\nEOF\\n)\ne\nw cat\nh fix: x\\n\ne 1'
  parses "a newline inside quotes" $'echo "a\nb"' $'w echo\nw a\\nb\ne'
  parses "a backslash" "echo 'a\\b'" $'w echo\nw a\\\\b\ne'
  parses "a line continuation" $'echo a \\\nb' $'w echo\nw a\nw b\ne'
  parses "an empty command" '' ''
}

finish
