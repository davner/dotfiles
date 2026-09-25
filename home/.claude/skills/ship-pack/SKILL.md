---
name: ship-pack
description: Hand over a finished batch of branches as one page - per branch, in merge order, its base, a running server to try it on, its line counts, and copy buttons for the PR title, the PR body, and the push and `gh pr create` commands. Use when a batch of branches is ready for PRs, when the `/ticket` loop has every ticket in a batch READY, or when the user asks for PR descriptions, servers to try each branch, or push commands. It never pushes, opens a PR, or merges; the page hands the user the commands.
argument-hint: [branch...] (in merge order; omit inside the /ticket loop)
---

# Ship a batch of branches

Everything the user will paste goes on one page, never in terminal text, since
the terminal's rendering is what breaks pasted markdown and quoting. Nothing
here pushes, opens a PR, or merges.

## 1. Inputs

The branches in merge order, and each one's own base: its ticket file's
`base` when there is one, otherwise the user's word or `git log`. A batch may
be a stack, parallel branches on main, or both, so a base is never inferred
from list position; ask when one is unclear. `git fetch` first; a base of
main means `origin/<main>`.

## 2. Servers

For each branch that has a worktree, in a project whose CLAUDE.md or README
names a serve command, run one from the worktree on a free port - the one
recorded in the ticket file when there is one. Check nothing listens on the
port first: a live server the ticket file records for that worktree is
reused, and anything else means another port. Confirm the server answers,
note when you observed it, and record its pid in the ticket file when there
is one so close-out stops it. Never touch a server you did not start, and
never create a worktree to get one. A branch with no serve command, no
worktree, or a server that will not answer says so on the page instead of a
URL.

## 3. Lines

Per branch, `git diff --numstat <base>...<branch>`, summed into code, tests,
and docs by the project's own naming for each. Lockfiles and generated files
are left out of all three and named instead.

## 4. PR text

Title: the branch's commit subject; with several commits, ask which subject
states the theme. Body: git-workflow's "PR bodies" rule.

## 5. The page

Publish one page with the harness's page-publishing tool; when there is none,
write it as a local HTML file and give its path. Per branch, in merge order:

- the branch, its tip (`git rev-parse --short`), and its base
- the server URL, when it was observed, and what to try there
- the line counts
- a Copy button each for the title, the body, and the commands:
  `git push -u origin <branch>` then
  `gh pr create --base <base> --head <branch>` with the title and body quoted
  for a shell paste

End the page with merge advice read from the repo's settings -
`gh api repos/<owner>/<repo>` for the allowed merge methods and
`delete_branch_on_merge`. Stacked PRs merge bottom first. With
`delete_branch_on_merge` on, GitHub moves the next stacked PR's base to main
once its parent merges; with it off, the user retargets that PR by hand.
After a squash merge the next branch still carries the parent's original
commits either way, so it is rebased with
`git rebase --onto origin/<main> <old parent tip> <branch>` before it merges,
where the old parent tip is the one recorded in the parent's ticket file under
`## Handoff`, or the tip this page shows for the parent.
