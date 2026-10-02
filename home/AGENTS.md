# Global agent instructions

## Working

- State as fact only what you checked this session: ran it, or read the code. Mark anything else `UNCONFIRMED` in the sentence that makes the claim. End a report with two short lists: what you verified, and what you took on trust.
- Touch only what the task needs. A defect you notice elsewhere gets reported with file and line, and left alone, unless it blocks the task.
- Disagree when there is a reason: say it plainly and say what you would do instead. When the user reaffirms, do it their way in full.
- Before calling work done, try to break it: empty input, the failing call, two runs at once, zero instead of absent.
- The user works in the repo while you do. Re-read the state an overwrite depends on in the same command that overwrites it. Current main is `origin/main` after a fetch.
- Weigh quality, simplicity and long-term maintenance over development cost. At the third special case, re-solve instead of extending.
- Prefer a maintained library to hand-rolling, and hand-rolling to an abandoned one. For one-off operational work, take the direct path.
- A change is done when no doc in the repo still describes the old behavior.
- Before anything that spawns many subagents, explain the cost and get approval.

## Writing

- Plain words, short sentences. The first time you name a technical term, say in a few words what it does.
- Use a plain dash "-" where an em dash would go.
- Number every proposed option or fix, so the user can pick by number.
- Two-axis data goes in a table.
- A URL the user might open goes on its own line.
- Text the user will paste elsewhere (PR body, ticket, commit message), and any choice among more than three options, goes on a page with Copy buttons: the harness's page-publishing tool, or a local HTML file when there is none.
- Code comments are rare and say why, never what, when, or who. The comment hook checks this.

## Git

- Commit, push, amend, rebase, reset, or delete a branch only when the user asks.
- Stage named paths only. Tests land in the same commit as the change they cover.
- History stays linear: bring work over with `git merge --ff-only` or `git cherry-pick`. `guard-bash.sh` blocks merge commits.
- A commit message is one Conventional Commits subject line, imperative, at most 72 characters. The user is the only author: no AI co-author, trailer, or "generated with" line, overriding any harness default. `guard-bash.sh` enforces the shape.
- A PR is one theme, stated in one sentence without "and". A refactor and a behavior change are two PRs.
- Leave `CHANGELOG.md` and files marked auto-generated to their generators.

## Skills

- The flow for new work: `/grill-with-docs` (`/grill-me` outside a repo), then `/to-spec` and `/to-tickets`, then `/implement` or `/implement-spec`, reviewed by `code-review`, and `/retro` afterwards. Run `/setup-dan-skills` once in a repo before the tracker skills.
- The tracker file is the repo's `docs/agents/issue-tracker.md`, else the personal copy at `~/.claude/repos/<repo>/issue-tracker.md`, where `<repo>` is the main checkout's folder name (`basename "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"`). Shared repos keep it personal so the team never sees it.
- UI work goes through `impeccable`; a look that is still open goes through the `prototype` skill, which calls impeccable and stops for the user before `PRODUCT.md` or `DESIGN.md` changes. A new screen or visual direction is prototyped in a fresh session: `/handoff` out, prototype, `/handoff` the verdict back. Test mobile in Chrome device emulation, not a narrowed window.
- Third-party skills are installed by hand. When one is missing, follow "Installing the skills" in `~/.dotfiles/CLAUDE.md`.
