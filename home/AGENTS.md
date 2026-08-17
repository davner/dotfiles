# Global agent instructions

- Never use the em dash "—". Use plain dash "-" instead
- Never manually modify CHANGELOG.md files or any files that are marked as auto-generated
- When making technical decisions, do not give much weight to development cost.
  Instead, prefer quality, simplicity, robustness, scalability, and long term maintainability.
- Complexity should track the problem, not the number of times the problem surprised you.
  Code that gained a branch per bug has the wrong model, and the next branch will not fix it.
  Brute force is a fine first draft and a bad last one: it is how you learn the shape of the
  problem, not what you ship. When the third special case shows up, re-solve instead of extending.
- Prefer a maintained library to hand-rolling, and hand-rolling to an abandoned library.
  Before taking a dependency, check that it still ships or answers issues, that it supports the
  runtime versions in use, and that it is not archived or deprecated. Quiet is not the same as
  dead, since a small library can simply be finished, so judge it on whether it still works and
  whether reported bugs get answers rather than on how busy its commit graph looks.
- For one-off or infrequent operational work, start with the simplest direct end-to-end path. Do not build wrappers, control planes, policy layers, custom verifiers, or automation unless the direct path exposes a concrete blocker or repeated need that justifies the added machinery.
- When doing bug fixes, always start with reproducing the bug in an E2E setting as closely aligned with how an end user would experience it as possible.
  This makes sure you find the real problem so your fix will actually solve it.
- When end-to-end testing a product, be picky about the UI you see and be obsessed with pixel perfection.
  If something clearly looks off, even if it is not directly related to what you are doing, try to get it fixed along the way.
- Apply that same high standard to engineering excellence: lint, test failures, and test flakiness.
  If you see one, even if it is not caused by what you are working on right now, still get it fixed.
- Before using "dynamic workflows", "ultra code" or any harness feature that immediately spawns a large swarm of subagents, always explain the tradeoffs and ask the user for explicit approval.

## Subagents

Specialists live in `~/.claude/agents/` (symlinked from `home/.claude/agents/`).
Each one's `description` says when to route to it, so usually just delegate.
Three habits the descriptions cannot express on their own:

- Research before designing, when the design turns on something the repo cannot
  answer. `researcher` establishes what is possible and what already exists,
  and `architect` turns that into a plan for this codebase. Guessing at the
  design stage is the most expensive place to guess.
- Design before building. Once a change crosses more than one file or adds a
  boundary, `architect` plans and `senior-dev` implements the plan. Below that
  line, see how much of the chain to run - the pipeline is not free and small
  work should not pay for it.
- Nothing self-certifies, including the plan. `architect`'s plan goes to
  `plan-reviewer` before code is written against it, and revisions go back to
  `architect`. Code that `senior-dev` wrote goes to `code-reviewer` before it is
  called done, frontend work goes to `ui-verifier`, and any schema change or
  backfill goes to `migration-safety`. Fixes go back to the agent that writes,
  never to the reviewer, which is why the reviewing agents cannot write files.
  The ones that only find are unconditional wherever they apply, because they
  cost time and nothing else and no diff is small enough to be worth skipping
  them for. The ones that write are conditional, because what they add is
  surface area you keep: `test-writer` earns its place after a fix that changed
  behavior and not after a rename, since a test that asserts nothing costs more
  than it catches.

Independent agents can run in parallel, but review always follows implementation.

Three of these carry a gate rather than an opinion, and the gate is the reason
they exist. `debugger` may not propose a fix before it has reproduced the
failure. `migration-safety` may not approve a migration before it has run it
forward and reversed it against a disposable local database. `review-triage` may
not put a review comment in the fix pile before it has read the code and decided
the comment is right. Do not route around any of them because the answer looks
obvious.

### How much of the chain to run

The full chain is for work that is expensive to get wrong, not for everything.
Match the ceremony to the change:

- **A one-line fix, a typo, a rename, a config value** - do it yourself. No
  agent. Reaching for the roster here costs more than the change.
- **A change confined to one file, where the fix is already obvious** - straight
  to `senior-dev`, then `code-reviewer`. No design stage; there is nothing to
  design.
- **A change that crosses files or adds a boundary** - the full chain, starting
  at `architect`.
- **Anything touching a schema, money, permissions, or data you cannot
  regenerate** - the full chain, and `migration-safety` is not optional.

When it is genuinely unclear which of these applies, it is the third one.

### Finishing work

Documentation is part of a change, not a follow-up. A change is not done when
the tests pass; it is done when nothing in the repo describes the old
behavior. So when work finishes, or when part of it finishes:

- Every doc the change made wrong gets fixed in the same unit of work.
- Every plan, TODO, roadmap item, or milestone note the change completed gets
  closed or deleted, and one that it half-completed gets split so the remaining
  half is still visible. A finished plan left in place is indistinguishable
  from an ignored one, which is how these accumulate.
- A published package gets its reference checked against the code whenever the
  public surface moves: exported names, signatures, defaults, flags, env vars,
  supported versions.

`doc-auditor` does this sweep. Run it at the end of a milestone, before a
release, and any time the planning documents have gone a while without being
reconciled. It is read-only and cheap to run, so run it on suspicion rather
than on certainty.

### Who owns what, where the edges blur

- **Docs.** `senior-dev` writes the docstrings and comments inside the code it
  writes. `docs-writer` owns everything a reader sees from outside: pages,
  READMEs, guides, examples. `doc-auditor` finds which documents stopped being
  true and hands `docs-writer` the list, the same way `code-reviewer` hands
  findings to `senior-dev`. Point `docs-writer` at a known-wrong doc; run
  `doc-auditor` when the question is what has gone stale.
- **Migrations.** `code-reviewer` reads a migration as code and its APPROVE
  never covers it. `migration-safety` runs it. A diff with a migration needs
  both, and they can run at the same time.
- **Searching.** `researcher` is for answers that are not in the repo. The
  built-in `Explore` is for answers that are. Do not send a codebase question
  to the web.
- **Tests.** `senior-dev` runs the suite and fixes what it broke.
  `test-writer` writes new tests, because the author of the code is the worst
  judge of whether its tests would catch anything. A test that fails or flakes
  for a reason nobody has established yet is `debugger`'s, not `test-writer`'s:
  the cause has to be known before a test can be the answer.
- **Review, in and out.** `code-reviewer` produces findings on code written in
  this session. `review-triage` reads a review that arrived from a PR on GitHub
  and turns it into a plan, which makes it the only agent that reads state from
  outside the repo. It finds, it does not fix: its plan goes to `senior-dev` the
  same way `code-reviewer`'s findings do, and what comes back goes through
  `code-reviewer` before it is done, because a review response is production
  code and self-certifies no more than anything else. Keep the plan until the
  work is committed - its items are what the commits get split along.

## Skills

Skills that should be installed, if not, install them.
- `shadcn` - add, search, compose, style, and debug shadcn/ui components; registries, presets, `--preset` codes, and any project with a `components.json`.
- `migrate-radix-to-base` - migrate a shadcn or React project from Radix UI to Base UI.
- `humanizer` - strip AI tells from writing so it reads as human-written.
- `chrome-devtools-axi` - drive a real Chrome session: navigate, inspect, screenshot, and debug a page.
- `gh-axi` - operate GitHub from the CLI: issues, PRs, CI runs, releases, Projects.
- `lavish` - turn a plan, diff, or report into a reviewable HTML artifact.

These are not managed by `home.nix`, so a rebuild neither installs nor removes
them. They are installed by hand with `npx skills add`, which normally writes to
`~/.agents/skills/` and symlinks into `~/.claude/skills/`. Do not rely on that
layout when looking for one: `shadcn` and `migrate-radix-to-base` are real
directories under `~/.claude/skills/` with no `~/.agents/` entry at all, and
only the other four are symlinks. Check both locations. On a fresh machine,
run:

```sh
npx skills add shadcn-ui/ui -g -y -s shadcn -s migrate-radix-to-base
npx skills add blader/humanizer -g -y -s humanizer
npx skills add kunchenguid/chrome-devtools-axi -g -y -s chrome-devtools-axi
npx skills add kunchenguid/gh-axi -g -y -s gh-axi
npx skills add kunchenguid/lavish-axi -g -y -s lavish
```

`-s` does not take a comma-separated list; repeat the flag per skill. Ignore
the `PromptScript does not support global skill installation` warnings, which
come from an unrelated agent target. `npx skills update -g` upgrades them.

`skill-creator` and `find-skills` are also sitting in `~/.agents/skills/` but
are not symlinked into `~/.claude/skills/`, so they are installed and inert.
They are deliberately left out of the list above: link one only if you decide
you want it, rather than assuming its presence on disk means it is in use.

## Git workflow

`git-workflow` does the mechanics below - staging named paths, writing the
commit message, cutting a branch - and it is the one agent nothing routes to on
its own. Committing is the user's call, not a step that follows from finishing
code, so it runs when it is asked for by name and not otherwise. It never
pushes, opens a PR, or rewrites history.

- Do not commit or push changes unless explicitly instructed.
- Never use `git add .`; stage only the files relevant to the current task.
- Before proposing a commit, run the appropriate tests and formatting checks.
- Show `git status --short` and summarize the staged diff.
- Use Conventional Commits messages (`type(scope): summary`). If a ticket ID (e.g. `GPP-123`) appears in the branch name or was given earlier in conversation, use it as the scope, e.g. `fix(GPP-123): fix for this thing`.
- Never auto-add your agent name as a commit co-author.
- Never amend, rebase, reset, force-push, or delete branches without explicit approval.