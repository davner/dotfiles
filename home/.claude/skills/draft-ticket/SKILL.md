---
name: draft-ticket
description: Draft the text for a Shortcut epic, story, bug, chore, or spike - a title, a markdown description with acceptance criteria, and a recommendation for each sidebar field - ready to paste into the Create form. Use whenever the user asks for a ticket, story, epic, bug report, or spec to be written up, when work needs filing before it is built, or when an existing ticket is too thin to act on. Also drafts from work that already exists - the current diff, a named branch, a git worktree, or several of them at once, where several related branches become one epic with a story each. Also the drafting half of the `/ticket` loop's spec step. It never creates, edits, or transitions anything in Shortcut or Jira; its only write is the project's label record and a one-line pointer to it.
argument-hint: [epic|story|bug|chore|spike] <what the work is, a branch, or a worktree path>
model: opus
---

# Draft a Shortcut ticket

Produce the content a human pastes into Shortcut's Create Epic or Create Story
form. **Nothing here files, edits, or moves a ticket.** No API call, no browser,
no MCP write. The deliverable is text on screen; the user decides whether it
ever becomes a ticket. The one local write is the project's label record and
its pointer (section 5), and nothing else.

Write for the person who opens this cold at 2am six months from now, knowing
nothing about today's conversation. That reader is the only audience. A
description that only makes sense to someone who was in the room has failed.

## 0. No history, no meta, no padding

A ticket states what is true and what must become true. It never narrates how
it came to be written.

Cut on sight:

- **History.** What the code used to do, what was tried, who decided, when it
  changed, which release regressed it. Git and the ticket's own comments hold
  that. The one exception is a bug's Regression line, which is a fact the fix
  needs.
- **Meta conversation.** "As discussed", "per the sync", "you asked for",
  "following up on the review", "as I mentioned". Every reference to the
  request, the thread, the plan, or this session.
- **Padding.** Restating the title in the first sentence. "This ticket
  describes...". Hedges, apologies, and "should be straightforward".

The survivor test is the same one the repo applies to comments: **would this
sentence help a reader who has never seen the conversation that produced it?**
If not, delete it.

A rejected approach survives only when the reason survives with it, in the
present tense and without the story: "Polling is out - the endpoint rate-limits
at 60/min" stays; "we tried polling first but it didn't work" goes.

## 1. Find the facts before writing a word

A drafted ticket that invents its own justification is worse than no ticket,
because it looks authoritative. Every claim in the draft comes from one of three
places: the repo, the user, or an explicit gap marker.

- **Read the code.** Name real files, real symbols, real routes. `Explore` for
  a wide sweep; read the files directly when the target is known. A description
  that says "the auth module" when the repo says `src/session/guard.ts` costs
  the implementer the same search you just skipped.
- **Read the history.** `git log` and `git blame` on the area answer "why is it
  like this" more often than anyone expects, and a ticket that reverses a
  deliberate decision needs to say so.
- **Ask only what the repo cannot answer.** Who hits this, how often, what
  breaks if it waits, which of two behaviors is correct. Cap it at three
  numbered questions in one message, so the user can answer "1 and 3, skip 2".
- **Never guess the why.** If the business reason is genuinely unknown after
  asking, write `**TODO(you):** why this matters - I could not determine it` in
  the draft. A visible gap gets filled; a plausible invention does not.
- **Prose about the work is not evidence of the work.** A spec, a ticket file,
  a design doc, an epic plan, a PR description - each was written by someone who
  could be wrong, or right then and stale now. Every one is a lead to a file to
  open, exactly like a commit message. Where such a document and the code
  disagree, the code wins and the disagreement is worth reporting. A claim
  carried across from a document without being found in the code is a claim you
  invented, and it reads as verified because it sits in a ticket.

### When the work already exists: a branch or a worktree

"Draft a ticket for this branch" is a normal ask - work gets built before it
gets filed. The code is then the best source of facts available, and also the
most dangerous one.

**The trap: a diff turns into a changelog.** Reading commits and writing
"refactored the session guard, added a retry helper" produces a description
that narrates the work instead of stating the problem, which section 0 bans
outright. The diff tells you *what changed*; the ticket still has to say *what
was wrong* and *what is true when this lands*. Commit messages and PR titles
are leads to the code, never lines to paste.

Establishing what the work is:

| Target | Read it with |
| --- | --- |
| Uncommitted work here | `git status --short`, `git diff`, `git diff --staged` |
| A branch | `git fetch` first, then `git diff origin/main...origin/<branch>` and `git log --oneline origin/main..origin/<branch>` |
| A worktree | The same against the bare `<branch>`, with `git -C <path>`. `git worktree list` says what exists and where |
| Several at once | One pass each, then section 2 decides whether they are one epic or unrelated tickets |

Four things to get right:

1. **Three dots for the diff.** `origin/main...origin/<branch>` is the branch's
   own changes against the merge base. Two dots drags in everything main gained
   meanwhile and inflates the ticket with work nobody on this branch did. Note
   that `log` is the other way round: two dots there gives the branch's own
   commits, three dots adds main's.
2. **`origin/main`, after a fetch, is what "main" means.** A local `main` is
   routinely behind, and diffing against a stale one invents scope.
3. **Name the remote ref unless you know a local one exists.** A branch someone
   else pushed has no local ref until it is checked out, and a bare `<branch>`
   then fails with `fatal: ambiguous argument`. `origin/<branch>` always
   resolves after a fetch and means the same thing. A worktree is the exception:
   `git worktree add` creates a real local branch, so inside one the bare name
   is right.
4. **A worktree is missing its gitignored files.** Dependencies, generated
   code, and local env files are absent there, so "this is broken" read off a
   worktree may be the worktree, not the branch.

Branch state is live. Record the tip you read - `git rev-parse --short
origin/<branch>`, or the bare name inside a worktree - and say in the draft when
you observed it, so a reader who finds the branch moved knows which version the
ticket describes.

Several branches or worktrees at once:

- They share a goal, and each ships on its own: **one epic, one story per
  branch.** The epic's Scope list names the slices, not the branch names - a
  branch name is an implementation detail that dies at merge.
- They do not share a goal: **separate tickets.** Say so rather than inventing
  an epic to hold unrelated work.
- Put the branch in the story's External Links or a `Branch:` line, so the
  connection survives without the description becoming git history.

Two facts the code cannot give you, and both usually need asking: **why this
matters** and **whether the branch is the whole story or a first slice**. A
branch shows what someone did, never what they meant or what they left.

## 2. Pick the artifact

| Draft | When |
| --- | --- |
| **Epic** | The work needs more than one story, and the stories ship and demo separately. An epic is a container with a shared goal, not a big story. |
| **Story (Feature)** | One vertical slice a user or caller can observe. If it fits one reviewable branch, it is a story. |
| **Story (Bug)** | Shipped behavior is wrong. Reproduction is the point of the ticket. |
| **Story (Chore)** | Real work that does not change the product: upgrades, refactors, tooling, cleanup. Do not dress it as a user story. |
| **Spike** | The answer is unknown and the ticket buys the answer. Chore type, timeboxed, and its deliverable is a decision written down, never code. |

If a "story" needs more than one of these, it is an epic. If an "epic" fits in
one branch, it is a story. Say which you chose and why in one line before the
draft, so the user can overrule it cheaply.

**When a refactor carries a visible change**, settle the type in two steps:

1. **Does this change the product?** No - Chore, and stop here. This step is
   Shortcut's own test and it is mechanical: it ends the argument.
2. Yes - then does the change *correct* behavior that was wrong (**Bug**), or
   deliver behavior that is newly intended (**Feature**)? This step is a
   judgment, not a lookup, and it often turns on whether the old behavior
   contradicted something the product already did. Show the evidence for the
   call rather than asserting it.

The refactor being the author's whole motivation does not enter into it. A
board reader wants one thing from the type field: will a user see something
different. A cleanup that quietly changes a label is the case that type field
exists for.

**Default to two tickets.** A refactor plus a visible change is two pieces of
work that happened to land together, and they split cleanly: a Chore for the
restructuring, and a Bug or Feature for what the user sees. Draft both, and say
that one branch delivers them.

The reason to prefer the split is not tidiness. **A merged ticket has no valid
description shape** - section 4's templates are one per type, and a Bug's
reproduction block does not describe a refactor while a Chore's scope does not
describe broken behavior. If the user wants one ticket anyway, that is their
call, and the shape is: the type of the visible half, the Bug or Feature
template as the body, and one `## Also in this change` section listing the
refactor's scope and its acceptance criteria. Say plainly that the ticket is
carrying two themes, so nobody reads the type field as the whole story.

Splitting an epic: slice vertically, by user-visible outcome, never by layer.
`SPIDR` and the other splitting patterns are in
[references/standards.md](references/standards.md).

## 3. Titles

One line, under ~80 characters, specific enough to be searchable and to stand
alone in a board column with nothing around it.

- State the outcome, not the implementation. `Password reset email arrives
  within 60 seconds` beats `Add SQS queue to mailer`. The exception is a chore,
  where the implementation *is* the outcome.
- A bug title names the broken behavior and where: `Disabled filter on Agents
  redirects to an undefined page`. Not `Filter bug`.
- No ticket-type prefixes (`[BUG]`, `FE:`). Shortcut has a Type field and a
  Team field; duplicating them in the title only costs column width.
- **Do not open with the service, repo, or app name.** The board is already
  grouped by team, so every title in the column repeats it and the reader scans
  past the first two words to reach the difference. This holds whether the name
  is punctuated as a prefix or absorbed into the sentence - `resource-ui: drop
  the SSO session` and `resource-ui keeps an SSO session and sends the user's
  token to Resource` cost the same width for the same nothing. Lead with the
  behavior: `SSO session survives logout and leaks the user token downstream`.
- The grammatical subject is the behavior or the user, not the system that
  owns the code. A title whose subject is a service name is almost always the
  previous bullet wearing a verb.
- **Name a component only where it disambiguates**, and then inside the
  sentence rather than in front of it: two services in one epic, or a name that
  a reader would otherwise get wrong. `Token refresh races the logout redirect
  in the Resource callback` earns its noun; `resource-ui` in front of a ticket
  filed to the resource-ui team does not.
- No trailing period. No "we should".

## 4. Description templates

The Create form's own toolbar offers headings, bold, italic, inline code,
links, checklists, and ordered and unordered lists, so those are safe. Tables
are not on that toolbar and Shortcut's docs do not say descriptions render
markdown at all, so prefer a list to a table and let the Preview tab settle any
doubt. Omit a section rather than filling it with "N/A" - an empty heading is
noise, and a missing one reads as "not relevant".

### Epic

```markdown
## Why now
<The problem or opportunity, and what it is costing. One short paragraph.>

## Outcome
<What is true when this epic closes, observable from outside the code.>

## Scope
- <Story-sized slice>
- <Story-sized slice>

## Out of scope
- <The thing a reader will otherwise assume is included>

## Open questions
- <Decision still owed, and who owes it>
```

### Story (Feature)

The user-story sentence earns its place when there is a real actor whose goal
differs from the team's. When the actor would be "as a developer, I want the
code to be cleaner", it is a Chore - drop the sentence and write plain prose.
The format is a tool for surfacing a user's motive, not a tax.

**Uniformity rule:** be uniform *within* a type, never across the backlog.
Every Feature story takes the same shape, every Bug takes the same shape, and a
Chore is not bent into either. Forcing one template over all three is what
produces "As a developer, I want a database index" (Cohn's named smell); making
each ticket its own genre is what makes a backlog unreadable.

The means is **"I want to <do something>"**, not "I want <a feature>". The
mutation into feature-naming is what turns a story back into a requirements
document (Marcano on the Connextra original).

```markdown
As a <actor>, I want to <do something> so that <benefit>.

## Context
<Where this lives in the code, what exists today, the constraint that shapes
the solution. Link files as `path/to/file.ts:42`.>

## Acceptance criteria
- [ ] <Binary, observable, testable by someone who did not write it>
- [ ] <...>

## Out of scope
- <...>

## Notes
<Links, designs, related tickets. A ruled-out approach only with the
constraint that rules it out, stated in the present tense.>
```

Acceptance criteria are the contract, and they are where most tickets fail:

1. Each one is a **check a reviewer can run**, pass or fail, no judgment call.
   "Handles errors gracefully" is not a criterion. "A 500 from the payments API
   shows the retry banner and does not clear the cart" is.
2. They describe **behavior, not steps**. If a criterion names a function to
   write, it belongs in Notes.
3. Include the unhappy paths that matter: empty, failing, unauthorized,
   concurrent, already-done. One or two, chosen because they are real, not a
   sweep of everything imaginable.
4. As many as are useful and no more. There is no defensible magic number -
   the real rule is Cohn's: **if the list is long, the story is too large.**
   Split it instead of trimming the criteria.
5. Never restate a Definition-of-Done item as a criterion. "Tests pass", "code
   reviewed", "deployed to staging" apply to every ticket the team ships;
   repeating them here buries the two or three that are specific to this one.
6. Reach for `Given / When / Then` only when the criterion turns on specific
   state, or when the team actually automates the scenarios. A flat checklist
   is the default because it is faster to read, and GWT without automation
   behind it is ceremony.

### Story (Bug)

```markdown
## Summary
<What is broken, where, and who it affects. One or two sentences.>

## Steps to reproduce
1. <Exact, from a known starting state - logged in as what, on which page>
2. <...>

## Expected
<What should happen after those steps.>

## Actual
<What does happen. Include the error text or console output verbatim.>

## Environment
<Branch or version, browser/OS, account or role, data conditions. Only what
changes the outcome.>

## Evidence
<Screenshot, GIF, log excerpt, Sentry link. Say where the user should attach
it if you cannot produce it.>

## Impact
- **Severity:** <what it breaks, and whether a workaround exists>
- **Frequency:** <every time / intermittently / once, and under what conditions>
- **Affected:** <who, and roughly how many>
- **Regression:** <the change or release it started at, or "not a regression">

## Notes
<Suspected cause if the code supports one, with `file:line`. Label it a
suspicion. Related tickets.>
```

**Severity always goes in the description.** Shortcut has no severity field,
and severity is not priority: a crash down a path nobody walks is high severity
and low priority, and a reader who only sees Priority cannot recover that. The
severity line answers "how bad when it happens", the frequency line answers
"how often", and the person setting Priority needs both.

Reproduce it before writing it whenever the repo allows. A bug ticket whose
steps were never run is a guess with a template around it. If you could not
reproduce, say exactly that in Actual and name what you tried.

A regression gets a **new** ticket linked to the original, never a reopened
one. The closed ticket is the record of the first fix; reopening it destroys
that and mixes two causes into one history.

### Chore and Spike

Chore: what changes, why now, how a reviewer confirms nothing else moved.
Acceptance criteria are still binary - "the build passes with `foo@3` and no
`@ts-expect-error` remains" is one.

Spike: the question, the timebox, and the artifact that ends it (a written
recommendation, a decision record, a throwaway branch that gets deleted). A
spike whose acceptance criterion is "we understand it better" never closes.

## 5. The sidebar fields

Recommend a value for the fields the work determines. Leave the fields only the
user or the team can know as "yours to set" rather than inventing them.

| Field | Epic | Story | What to do |
| --- | --- | --- | --- |
| Title | yes | yes | Section 3. |
| Description | yes | yes | Section 4. |
| Type | - | yes | Feature / Bug / Chore. Recommend it; it drives how the team reads the board. |
| Epic | - | yes | Name the epic if one exists or you are drafting it in the same pass. |
| Estimate | - | yes | Points, only if the team's scale is known from the conversation or the repo. Otherwise say "unestimated - your call". Never invent a scale. |
| Priority | - | yes | A workspace custom field, not a Shortcut built-in. Recommend it for bugs, where impact and frequency are already in the draft. Otherwise leave it. There is no Severity field at all - that goes in the description. |
| Labels | maybe | maybe | Reuse a recorded label when one fits. Propose a new one only for a cross-cutting concern no recorded label covers, shown as `name (new - one-line meaning)`. |
| Relationships | - | maybe | Blocks / blocked by / duplicates, when a real dependency exists. |
| External Links | maybe | maybe | The PR, the Sentry issue, the design, the doc. Drafting from a branch or worktree, this carries the branch, its tip, and when you observed the tip - section 1 requires it and this row is where it actually gets written. |
| Sub-tasks / Checklist | - | maybe | Only when the story genuinely has ordered steps. Acceptance criteria are not sub-tasks. |
| Objective | maybe | - | Leave it; the user knows which objective this rolls up to. |
| Team, Workflow, State, Owner, Requester, Iteration, Project, Dates, Followers | - | - | Yours to set. Never recommend these. |

**The label record.** A project's labels live in `.claude/ticket-labels.md`
at its root, one entry per label, sorted by name: `- name - use when <one-line
meaning>`. Read it before recommending labels; a missing file means none are
recorded. A proposed label is appended in the same run, after checking the
record for a near-duplicate - a plural, a synonym - and reusing that instead.
Never propose one that duplicates what Type, Priority, Estimate, or another
field already holds, since a label that repeats a field drifts from it. The
user creates labels in Shortcut when filing, never this skill, so an entry can
name a label nobody created.

The pointer is one line naming the record in the project's `CLAUDE.md`, added
when absent - in the link's target when `CLAUDE.md` is a symlink, in `AGENTS.md`
when only that exists, and in a new `CLAUDE.md` when neither does.

## 6. How to present it

Terminal rendering destroys the markdown the user is about to paste, so every
value that gets pasted goes inside a fenced block as raw markdown. One block per
field. Never a single block containing the whole ticket.

Order: the artifact choice and its reasoning, briefly - one line where the
call is obvious, a short paragraph where a split is being recommended - then
the **Title** block, then
**Description** block, then the field table, then one line naming any label
appended to the record, then a short **Could not
determine** list naming each gap and who can close it. Then stop. Do not offer
to file it.

Drafting an epic and its stories together: the epic first, complete, then each
story as its own pair of blocks under its own heading.

## 7. Check before presenting

Run this against the draft and fix what fails. Do not show the user the
checklist.

1. Would someone with no context act correctly on this alone?
2. Is every acceptance criterion binary, behavioral, and checkable by a third
   party?
3. Is the *why* in there, and is it sourced rather than invented?
4. Does the title survive alone in a board column, and do its first two
   words carry information the Team field does not already give?
5. Does the scope have an edge? An "out of scope" line is how a reader knows
   you thought about one.
6. Is every file, symbol, link, and error string real and verified, not
   plausible?
7. Does any sentence narrate history, reference the conversation, or restate
   the title? Section 0 - cut it.
8. Story: does it pass INVEST ([references/standards.md](references/standards.md))?
   Bug: could a stranger reproduce it from the steps as written?

## 8. Inside the `/ticket` loop

`/ticket new` calls this skill for the spec step's paste-ready **Title** and
**Description**, then adds its own engineering half - contracts, files expected
to change, tests required, out of scope - and stops for the user to file it. The
loop's rules still govern: nothing files anything in Shortcut, and the user's
reply with the ticket code is the only approval that exists.

Called on its own, the skill ends at section 6 and no ticket loop starts.

## 9. Jira

The same drafts paste into Jira. Shortcut Story maps to a Jira Story, Bug to
Bug, Chore to Task, Epic to Epic; Estimate maps to Story Points and Type is
Jira's Issue Type. Jira's description field is ADF rather than markdown, so
paste into the editor and let it convert, or use the editor's markdown paste.
Nothing else in this skill changes.
