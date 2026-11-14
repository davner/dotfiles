# Issue tracker: GitHub

Work for this repo is tracked as GitHub issues in `<owner/repo>`, on the board below. Specs and tickets stay local markdown for the agents' own use; the board holds one issue per PR, plus the TODO list. Board order is the priority: there are no priority labels.

## Board

- Owner: `<owner>` (the login in the board URL)
- Number: `<number>`
- URL: <board url>
- Status flow: Backlog, Ready, In progress, In review, Done. The board's built-in workflows set Done when an issue closes or its PR merges, and Backlog when an item is added by hand.

Every `gh project` command below takes `<number> --owner <owner>`.

## Labels

- Triage: `needs-triage` (waiting for the maintainer), `needs-info` (waiting on an answer), `ready-for-agent` (fully specified, an agent can pick it up), `ready-for-human` (a human implements it), `wontfix`.
- Kind, the Conventional Commit type of the PR that closes it: `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `chore`.
- Other: `todo` (a TODO item), `breaking`, `dependencies`, `skip-changelog` (a PR that needs no changelog fragment), `duplicate`.

Their colours and descriptions live in `setup-dan-skills/scripts/labels.sh`; re-run it to restore the set.

## Locations

- Scratch folder: `<scratch>` (specs and tickets; <gitignored | committed>)
- One feature per directory: `<scratch>/<feature-slug>/`
- The spec is `<scratch>/<feature-slug>/spec.md`
- Tickets are one file per ticket at `<scratch>/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01`, never a single combined tickets file
- The TODO list is the open issues labelled `todo`

## Filing an issue

Every issue goes onto the board with its labels and a starting Status, in three calls:

```sh
url=$(gh issue create --title "<title>" --label <label> [--label <label>...] --body-file <body.md>)
gh project item-add <number> --owner <owner> --url "$url"
gh project item-edit <number> --owner <owner> --url "$url" --field Status --value <Status>
```

## When a skill says "publish to the issue tracker"

1. Write the spec or ticket files under `<scratch>/<feature-slug>/`, creating the directory if needed. A ticket's blocking edges are a `Blocked by:` line naming ticket numbers and titles. The spec is never filed, and triage lives on the issues as labels.
2. Once the tickets are approved, file one issue per PR group as "Filing an issue" says, titled with the PR title, labelled with its kind and `ready-for-agent`, in Status Ready. File them in PR order, so an earlier issue's number exists for a later one's body. The body names the group's ticket files and spells out `Blocked by #N` as text.
3. Write `Tracker: #N` near the top of each ticket file in that group.

## When a skill says "add to the TODO list"

Work that surfaces mid-session but belongs to no current spec becomes an issue as "Filing an issue" says, labelled `todo`, in Status Backlog. The body carries what a fresh session needs to pick it up:

```markdown
- From: <the session or spec it came out of>
- Why: <the problem, in a sentence or two>
- Known: <decisions already made; files, ADRs, or tickets involved>
- Next: <the first step, and the skill to start with>
```

Read the list with `gh issue list --label todo --state open`. When a session starts work on an item, name it to the user. When its work is done, close it: `gh issue close N --comment "<what did it>"`. When the user drops it: `gh issue close N --reason "not planned" --comment "dropped: <reason>"`.

## Tracker IDs

- Issues look like `#123` in `<owner/repo>`.
- A ticket file carries a `Tracker: #N` line near the top once its group is filed, so commit messages and PR bodies that cite `#N` lead back to it.

## When a skill says "fetch the relevant ticket"

Read the file at the referenced path. Given `#N` instead, read `gh issue view N --comments` and the ticket files whose `Tracker:` line is `#N`. Given neither, ask for the path.

## When a skill says "move an item"

```sh
gh project item-edit <number> --owner <owner> --url <issue url> --field Status --value "<Backlog | Ready | In progress | In review | Done>"
```

Move to In progress when work on the issue starts, and to In review when its PR opens. Done is the board's job.

## When a skill says "park an item"

Add the `needs-info` label and a comment holding the question and its numbered options, so the user sees why:

```sh
gh issue edit N --add-label needs-info
gh issue comment N --body-file <question.md>
```

The Status stays where it was.

## When a skill says "next-up"

The topmost Ready item labelled `ready-for-agent`, in board order:

```sh
gh project item-list <number> --owner <owner> --limit 1000 --format json \
  --query 'is:issue is:open status:Ready label:ready-for-agent' \
  --jq '.items[0].content | "#\(.number) \(.title)"'
```

Empty output means nothing is ready.

## When a skill says "close" or "resolve" a ticket

Set `Status: done` in the ticket file. The issue closes when its PR merges, through the `Closes #N` line that opens the PR body. Where no PR is allowed, close it yourself: `gh issue close N --comment "<what landed, and where>"`.

## Agent PRs

- Agents open PRs: <yes | no>. A PR's body starts with `Closes #N`; move the issue to In review when it opens.
- Agents merge their own PRs once CI passes: <yes: `gh pr merge --auto --squash` after every review finding is fixed | no: the user merges | no: the repo has no CI, and auto-merge needs it>. A merge squashes to the PR title, so the title is the Conventional Commit subject.
<Releases, when the repo ships them:>
- Each PR adds a changelog fragment `changes/<issue#>.<type>.md`, type one of `breaking`, `feat`, `fix`, `perf`, `docs`, `chore`, or carries the `skip-changelog` label.

### Releasing

When asked to release version `<version>`:

1. `git fetch origin`, then branch `release-v<version>` from the default branch.
2. Run `uvx towncrier build --yes --version <version>` and commit the result as `chore(release): v<version>`, the branch's one commit.
3. Open a PR with that title, labelled `skip-changelog`; when agents open no PRs, hand the branch to the user.

Once it merges, the release workflow creates the tag and GitHub release `v<version>`. Nothing is pushed to the default branch by hand.
<end Releases>
