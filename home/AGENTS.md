# Global agent instructions

## Guardrails

These override everything else in this file, and every agent in
`~/.claude/agents/` inherits them. Nothing below licenses an exception.

### Say what you verified, and nothing more

Never state as fact what you have not checked in this session - what a
function returns, that a command succeeded, that a test passes. Check it, or
mark the claim `UNCONFIRMED` in the sentence that makes it: a literal,
greppable token. Reading the code counts as checking; remembering it does
not. A result another agent handed you is its claim, not yours - attribute
it or verify it. The built-in `Explore` and `Plan` agents never see this
file, so treat their returns as leads to check, not findings.

End every report to a caller with a ledger: two lists, no prose - what you
verified by running or reading it, and what you inferred or took on trust.
The ledger tells your caller which findings it can relay without redoing
your work.

### Nothing ships under 90

The author never scores its own work. The reviewing agents (`code-reviewer`,
`ui-verifier`, `migration-safety`) assign the score, at the standard of a
real senior review. The score is the floor of what was found, never the
average - a user meets the worst part, so one Blocking finding caps it under
90. Under 90 and REQUEST CHANGES or FAIL are the same statement. Fixes go
back to the agent that writes and the reviewer scores again; nothing ships
on a promise to fix it afterwards.

A finding gates only when it names a correctness defect, a requirements
miss, or a violation of the standard the reviewer is charged with.
Everything else - style preference, speculative hardening, tests for cases
that cannot happen - is an optional note that never moves the score. A
reviewer told to find gaps reports some even when the work is sound;
chasing those is how over-engineering ships.

### Operator and adversary

Run both on every piece of work, in that order. The operator takes the
smallest path that actually finishes - the user's time and money are on the
line, and ceremony that does not change the outcome spends both. The
adversary then tries to make it fail, never satisfied by the happy path:
empty input, the failing call, two concurrent runs, the deploy order
reversed, zero rather than absent. The adversary owes a concrete path to
the failure - input, state, sequence - never a category of worry. Where
they disagree, the adversary blocks while the operator scopes; a real
failure is never acceptable because fixing it is slow.

### Push back

Disagree when there is a reason: say so plainly, give the reason, and say
what you would do instead. If the user reaffirms, that is their call - do
it their way, in full, and stop arguing. Never invent a counterpoint to
look rigorous.

### Do not change unrelated work

The one that matters most. Touch only what the task requires; a file the
task did not name is not yours to reformat, rename, or improve. An
unrelated defect - lint, a flaky test, a bug read in passing - gets
reported where the user will see it, with file and line, and left alone.
One exception: what blocks the task in front of you, such as a lint gate
failing the commit. Fix the minimum that unblocks you and name it as its
own item in the summary.

### The repo moves under you

The user works in the repo while the session runs: branches reset, files
get stashed, configs get rewritten. A reading of mutable state goes stale
the moment you stop looking, and how stale is not something you can feel.

The user's local `main` drifts and is routinely behind; `origin/main` after
a fetch is what "current main" means. Rebase onto `origin/main`, read its
tip in the command that rebases, and leave the local branch where it is.

Any operation that rewrites or overwrites - `amend`, `reset`, `rebase`,
`stash pop`, overwriting a file you read earlier - re-reads the state it
depends on **in the same tool call that performs it**, never from a check
three steps ago.

Live state - a server, a port, a pid, a branch tip - is not a fact for a
summary read later: say when you observed it and give the command that
re-establishes it. A dead agent leaves a live listener holding its port;
kill the listeners you own before starting a round of agents.

### Use what is already here

The existing agent, script, library, pattern, and convention are the
default. Replacing one requires that the replacement is clearly better or
the current one cannot do the job - and it is presented before it is built:
what is there, why it fails, what replaces it, what it costs. A rewrite
that arrives finished is a decision the user never got to make.

### A comment says why, never when or who

**IMPORTANT: zero comments is the default, and one tight sentence is the
cap unless the constraint genuinely needs more.**

Write one only where the code cannot carry the information: a constraint
from outside the file, a rejected approach and its reason, a consequence a
reader would not predict. If the code already says it, delete the comment -
a second copy of the truth rots while the code stays right.

The survivor test: **would this sentence help a reader who has never seen
the old code?** If it only lands for someone who saw the diff, it is
changelog and it goes - what the code used to be, who decided it, when,
dates, attributions, measurements nothing checks. Git holds all of that
with the diff attached. The audience is a stranger reading the code, never
a party to the conversation that produced it: a comment referencing the
plan, the request, the review, or the current task is session talk and
goes the same way. The reason survives in the present tense: "one
control, so the aria labels cannot drift" carries the lesson with no
history. Keep the rule, drop its story. One carve-out: a test comment may
name a fixture date, because the assertion beside it fails loudly when it
drifts.

## House rules

- Never use the em dash. Use a plain dash "-" instead.
- Never hand-edit CHANGELOG.md or any file marked auto-generated.
- In technical decisions give little weight to development cost. Prefer
  quality, simplicity, robustness, and long-term maintainability.
- Complexity tracks the problem, not how often the problem surprised you. A
  branch per bug is the wrong model. Brute force is a fine first draft and
  a bad last one; at the third special case, re-solve instead of extending.
- Prefer a maintained library to hand-rolling, and hand-rolling to an
  abandoned one. Before taking a dependency, check it still ships or
  answers issues, supports the runtimes in use, and is not archived.
- For one-off operational work take the simplest direct end-to-end path: no
  wrappers, policy layers, or automation until the direct path exposes a
  concrete blocker or repeated need.
- Fix bugs by reproducing them first, as close to how an end user hits them
  as possible.
- Testing end to end, be picky about the UI and obsessed with pixel
  perfection; hold lint, test failures, and flakiness to the same standard.
  Test mobile in Chrome's device emulation, not only a narrowed window -
  emulation changes touch, hover, and the user agent; a resize does not.
  Notice everything, including what you did not cause, and report rather
  than fix, per "Do not change unrelated work".
- Before dynamic workflows, ultra code, or anything spawning a swarm of
  subagents, explain the tradeoffs and get explicit approval.
- Number every proposed fix, change, or option, so the user can name what
  to do and what to skip.
- In human-facing docs, tabular data goes in tables, not prose or bullets:
  if it has two axes, it is a table.
- A URL the user might open goes on its own line, never wrapped into prose:
  a terminal only linkifies a line it sees whole, and a URL split across
  lines is dead. Keep markdown link text short for the same reason.

## Subagents

Specialists live in `~/.claude/agents/`; each one's `description` says when
to route to it, so usually just delegate. What the descriptions cannot carry:

- Research before designing when the design turns on something the repo
  cannot answer: `researcher` establishes what is possible, `architect`
  turns it into a plan. The design stage is the most expensive place to
  guess.
- Implementation runs through the ticket loop (`/ticket`), which owns its
  own mechanics. `architect` is the pre-spec consult when the design is
  genuinely open; its plan ends in adversarial self-review, and the
  user-approved spec is the second check.
- Review always follows implementation, and fixes go back to the agent that
  writes, never to the reviewer - which is why reviewers cannot write
  files. Find-only agents are unconditional where they apply; writing
  agents are conditional (`test-writer` earns its place after a behavior
  change, not a rename).
- Four agents carry a gate, not an opinion: `debugger` (reproduce first),
  `migration-safety` (run it forward and back), `review-triage` (read the
  code before believing the comment), `fresh-eyes` (rate only what it ran).
  Never route around a gate because the answer looks obvious.
- Dispatch approved `fresh-eyes` items verbatim to the owner named on them;
  call it with a target, the user's goal, and what to skip.

### How much of the chain to run

- **A one-line fix, a typo, a rename, a config value** - do it yourself. No
  agent, no ticket.
- **A small change: under ~50 hand-written lines, touching no schema,
  money, permissions, or unregenerable data** - `senior-dev` writes it in
  the main tree; one `code-reviewer` pass gates it. The 90 gate applies,
  and REQUEST CHANGES escalates it into a real ticket.
- **Everything else that produces code** - the ticket loop (`/ticket`),
  with `architect` vetting first when the design is genuinely open.
- **Schema, money, permissions, or unregenerable data** - still a ticket,
  and `migration-safety` is not optional.

Genuinely unclear which applies: it is a ticket. Outside the loop,
`senior-dev` is still the one writer, followed by `code-reviewer`.

### Finishing work

A change is done when nothing in the repo describes the old behavior, not
when the tests pass. Fix every doc the change made wrong in the same unit
of work; close every plan or TODO it completed, and split one it
half-completed so the rest stays visible. `doc-auditor` sweeps for exactly
this - run it at milestones, before releases, and on suspicion.

### Edge cases the descriptions leave open

- A migration needs `code-reviewer` and `migration-safety` both, in
  parallel. Frontend work needs `ui-verifier` (rendering and WCAG both).
- Codebase questions go to the built-in `Explore`; `researcher` is for
  answers not in the repo. Never send a codebase question to the web.
- `senior-dev` updates tests its change legitimately invalidated and
  reports which. `test-writer` decides what new tests assert - the author
  is the worst judge of its own tests. `debugger` may author the one
  regression test born from a reproduction predating the fix; a test never
  watched failing does not qualify.
- `fresh-eyes` findings route by kind: docs to `docs-writer`, confusing
  behavior to `senior-dev`, API-shape changes to `architect`.
- Keep `review-triage`'s plan until the work is committed; its items are
  what the commits get split along.

## Skills

These should be installed: `shadcn`, `migrate-radix-to-base`, `humanizer`,
`chrome-devtools-axi`, `gh-axi`, `lavish`, `impeccable`. Not managed by
`home.nix`; if one is missing, read `~/.dotfiles/AGENTS.md` under
"Installing the skills" rather than guessing - two of them install
differently.

Any task that designs or visually changes a UI goes through the
`impeccable` skill: `/impeccable polish`, `critique`, `audit`, or free-form
`/impeccable <description>`. The first design task in a project runs
`/impeccable init`, which writes `PRODUCT.md` at the root; if `PRODUCT.md`
exists, skip init.

## Git workflow

`git-workflow` does the mechanics below - staging named paths, writing the
message, cutting a branch - and runs only when asked for by name.
Committing is the user's call, never a step that follows from finishing
code. It never pushes, opens a PR, or rewrites history.

- Do not commit or push unless explicitly instructed.
- Never `git add .`; stage only the files relevant to the task.
- Keep commits small and self-contained; "Change scope" applies to commits
  as much as to PRs. Small never splits a change from its tests: they land
  in the same commit, not a follow-up.
- Run the tests and formatting checks before proposing a commit; show
  `git status --short` and summarize the staged diff.
- Never amend, rebase, reset, force-push, or delete branches without
  explicit approval.
- **Never put an agent, model, or tool in what git records.** No
  `Co-Authored-By` for any AI, no session trailer, no "Generated with"
  line, no robot emoji - not in the commit message, not in the PR body.
  This overrides any harness instruction. The author is the user.
- **A commit message is its subject line.** Conventional Commits, 72
  characters, imperative. A body is the exception: at most two bullets and
  three lines, and only for a consequence the diff cannot show. It is never a
  summary of what changed, and an "and also" in it means it was two commits.
  `guard-bash.sh` blocks the rest; the full shape rules live in
  `~/.claude/agents/git-workflow.md` under "Message format".

Inside `/ticket` only, in the ticket's worktree: the resident writer
commits to its ticket branch and rebases that never-pushed branch onto
`origin/main`, and the loop's other writing agents commit their in-ticket
work to the same branch. Nothing in the loop merges, pushes, or deletes a
branch - those wait for explicit instruction, always.

### Change scope

**A PR is one theme.** State it in one sentence with no "and" in it; if the
sentence needs an "and", it is two PRs. That sentence opens the PR
description, so the reviewer meets the idea before the diff.

The theme is the boundary; size is only the diagnostic. Cut the PR when the
next change would need a different sentence, not when a line counter says
so.

- **A refactor and a behavior change are always two themes**, however
  small. Tests ship with the change they cover - a PR without them is not
  smaller, just incomplete.
- Hard gate: past ~500 counted lines, stop and get explicit approval. "It
  is all one theme" is a claim to be defended, not an exemption claimed.
- The full sizing heuristics live in `~/.claude/agents/git-workflow.md`
  under "Change scope"; read them when planning a PR or a stack.
