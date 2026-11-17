---
type: research
updated: 2026-11-16
---

# How maintainers use GitHub Issues, boards and labels, and what this repo should change

2026-11-16. Question: how do maintainers of well-run open source repos, and of solo or personal repos, use GitHub Issues, Projects (v2) boards and labels in practice? And should the setup this repo already chose change?

The setup under review is the GitHub tracker in `setup-dan-skills`: `issue-tracker-github.md`, `scripts/labels.sh` and `scripts/board.sh`. In short: board Status is Backlog, Ready, In progress, In review, Done; triage labels `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`; kind labels `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `chore`; other labels `todo`, `breaking`, `dependencies`, `skip-changelog`, `duplicate`; no priority labels, board order is priority; one issue per PR group; specs and ticket files stay in a gitignored `.scratch/`. This repo ships no releases and has no changelog ([ADR 0011](../adr/0011-history-is-the-merged-pr-list.md)).

Tags: **UNCONFIRMED** marks a claim I could not check at its primary source this session, or a judgment of mine. GitHub docs pages were read as Markdown through `docs.github.com/api/article/body`, which shows no page date; dates below come from GitHub changelog posts. Project docs were read from their raw files on GitHub. `gh` facts were checked against `gh` 2.103.2 help output on this machine.

## Answer

- **GitHub changed a lot in 2025-2026, and most of it now reaches personal accounts.** Issue types and issue fields became available to personal accounts on 2026-11-11, five days ago. Sub-issues and issue dependencies (blocked by / blocking) are on every repo, and `gh` sets all three from the command line since v2.94.0 (2026-06-10).
- **Big projects use prefixed label families.** Kubernetes uses `kind/`, `priority/`, `triage/`, `sig/`, `lifecycle/`. Rust uses `T-` (team), `C-` (category), `A-` (area), `S-` (status), `P-` (priority), `E-` (call for help). Smaller projects (uv, ruff) use a handful of plain labels such as `bug`, `help wanted`, `needs-decision`.
- **Projects that track state in labels usually have no board for it.** Rust's `S-*` labels and VS Code's milestone-based flow do the job a board Status field would. GitHub's own advice is one source of truth per fact. This repo's split, Status for "where" and labels for "who" and "waiting on what", fits that, with two overlaps noted below.
- **No public convention for agent labels exists outside skill repos.** `ready-for-agent` comes from Matt Pocock's `triage` skill. GitHub's own Copilot docs use no label: you assign the issue to Copilot, and the issue body is the prompt.
- **For a solo repo, issue templates, milestones and iteration fields add little.** They exist to steer outside reporters or to plan releases and time-boxes, none of which this repo has.
- **Some current labels repeat what GitHub now does natively.** `duplicate` and `wontfix` match close reasons, `Blocked by #N` as text matches issue dependencies, and `skip-changelog` has no job in a repo without a changelog.

The recommendations are at the end.

## 1. Label taxonomies

### 1.1 What well-known projects do

| Project | Kind / type | Triage | Priority | Status | Area / owner | Source |
|---|---|---|---|---|---|---|
| Kubernetes | `kind/bug`, `kind/feature`, `kind/support`... | `needs-triage` (auto-applied), `triage/accepted`, `triage/needs-information` | `priority/critical-urgent` ... `priority/backlog` | `lifecycle/stale`, `lifecycle/frozen` | `sig/*`, `area/*` | [issue-triage.md](https://github.com/kubernetes/community/blob/master/contributors/guide/issue-triage.md), [labels.md](https://github.com/kubernetes/test-infra/blob/master/label_sync/labels.md) |
| Rust | `C-bug`, `C-discussion`, `C-tracking-issue`... | `S-needs-info`, `S-needs-repro`, `I-prioritize` | `P-*` | `S-*` (e.g. `S-has-bisection`, `S-waiting-on-LLVM`) | `T-*` team, `A-*` area | [issue-triaging.md](https://github.com/rust-lang/rust-forge/blob/master/src/release/issue-triaging.md) |
| VS Code | `bug`, `feature-request`, `debt`, `under-discussion` | `needs more info` (bot closes after 7 days) | none; milestones instead | milestones `Backlog`, `Backlog Candidates`, iteration milestones | feature-area labels | [Issues-Triaging](https://github.com/microsoft/vscode/wiki/Issues-Triaging), [Issue-Tracking](https://github.com/microsoft/vscode/wiki/Issue-Tracking) |
| Node.js | (PR-focused) | `tsc-agenda` | none | `author ready`, `stale`, `never-stale` | subsystem labels | [collaborator-guide.md](https://github.com/nodejs/node/blob/main/doc/contributing/collaborator-guide.md) |
| uv / ruff (Astral) | `bug` | `needs-decision`, `needs-design` ("not good candidates for contribution") | none | none | none named | [uv CONTRIBUTING](https://github.com/astral-sh/uv/blob/main/CONTRIBUTING.md), [ruff CONTRIBUTING](https://github.com/astral-sh/ruff/blob/main/CONTRIBUTING.md) |

Patterns:

- **Kind labels are near universal.** Kubernetes says the kind label is "usually applied by the person submitting the issue", and its issue templates "aim to steer people to the right kind" ([issue-triage.md](https://github.com/kubernetes/community/blob/master/contributors/guide/issue-triage.md)).
- **"Needs info" is the most common triage label.** Kubernetes, Rust and VS Code all have one, and VS Code's bot closes the issue if nobody answers in 7 days ([Issues-Triaging](https://github.com/microsoft/vscode/wiki/Issues-Triaging)).
- **Priority labels appear only where many people share one backlog.** Kubernetes defines five levels with staffing rules; Rust applies `P-*` through a separate procedure. Astral and VS Code have none.
- **Release labels drive changelogs where releases exist.** Node applies `semver-major` and `notable-change` to PRs. Ruff's release workflow can "detect the next version from pull request labels" ([ruff CONTRIBUTING](https://github.com/astral-sh/ruff/blob/main/CONTRIBUTING.md)).

### 1.2 Conventional Commit kind labels

The Conventional Commits spec defines only `feat` and `fix`. Other types are allowed, and it points to `@commitlint/config-conventional` (Angular-based), which suggests `build`, `chore`, `ci`, `docs`, `style`, `refactor`, `perf`, `test`. It says extra types "have no implicit effect in Semantic Versioning" ([spec v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)). A breaking change is a `!` after the type or a `BREAKING CHANGE:` footer, on any type.

None of the projects above names its kind labels after commit types. Mapping kind labels to commit types is this setup's own choice (**UNCONFIRMED** that any large project does it). It has one clear benefit here: the PR that closes an issue squashes to its title, so the label and the title prefix should agree. It has one cost: the label repeats what the PR title already says.

### 1.3 Avoiding status labels that repeat a board Status

GitHub's Projects best-practices page: "maintain a single source of truth", and labels, assignees and milestones already flow into the project automatically ([best practices](https://docs.github.com/en/issues/planning-and-tracking-with-projects/learning-about-projects/best-practices-for-projects)). Rust and VS Code avoid the problem by not having a board Status: Rust keeps state in `S-*` labels, VS Code in milestones and queries.

How this setup maps onto that:

| Label | Overlaps Status? | Comment |
|---|---|---|
| `ready-for-agent`, `ready-for-human` | Partly, with Ready | They say *who* does the work, not *where* it is. Next-up needs both (`status:Ready label:ready-for-agent`). Fine as is. |
| `needs-info` | No | A waiting flag that sits on any Status. Kubernetes and Rust do the same. |
| `needs-triage` | Yes, with Backlog | Every hand-added or auto-added item lands in Backlog. Nothing in the skills applies `needs-triage` (checked with grep). Kubernetes applies it by bot to every new issue. |
| `todo` | Yes, with Backlog | Filed into Backlog. It marks origin ("surfaced mid-session"), which Status cannot. Fine as is. |
| `wontfix` | With closing | GitHub's close reason "not planned" says the same. The tracker already closes dropped TODOs with `--reason "not planned"`. |

## 2. Issue types, issue fields, sub-issues, dependencies

- **Issue types** classify issues "across your organization and user-owned repositories", up to 25. Every organization and user account gets the defaults task, bug and feature ([managing issue types](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/managing-issue-types)). Personal accounts got them on 2026-11-11 ([changelog](https://github.blog/changelog/2026-11-11-issue-types-and-fields-are-available-for-personal-accounts/)); before that they were organization only (sub-issues and types went GA for organizations on 2025-04-09, [changelog](https://github.blog/changelog/2025-04-09-evolving-github-issues-and-projects/)). They are set in account settings under Planning, so one set covers all of an account's repos. `gh issue create --type` and `gh issue edit --type` set them.
- **Issue types apply to issues only.** Labels apply to issues, PRs and discussions ([managing labels](https://docs.github.com/en/issues/using-labels-and-milestones-to-track-work/managing-labels)). A kind label can sit on the PR too; an issue type cannot.
- **Whether `labels.sh` could script user-level types** through the REST or GraphQL API: the changelog says the APIs manage them, but I did not find the endpoint for a personal account (**UNCONFIRMED**).
- **Issue fields** arrived for personal accounts the same day. Turning them on creates four defaults: Priority (Urgent, High, Medium, Low), Effort, Start date and Target date. Values live on the issue and show in every project. GitHub advises against keeping a project field and an issue field for the same idea, "for example, two 'Priority' fields" ([managing issue fields](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/managing-issue-fields)). Whether the defaults are created on this account without opting in, I could not see from the page (**UNCONFIRMED**).
- **Sub-issues**: up to 100 per parent, eight levels deep, across repositories. `gh issue create --parent N` and `gh issue edit --add-sub-issue` manage them ([adding sub-issues](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/adding-sub-issues)). The old tasklists page now redirects to the sub-issues page, so sub-issues replace tasklist tracking. Projects can show "Parent issue" and "Sub-issue progress" fields ([progress fields](https://docs.github.com/en/issues/planning-and-tracking-with-projects/understanding-fields/about-parent-issue-and-sub-issue-progress-fields)). That page still says "If your organization uses sub-issues"; sub-issues work on personal repos in practice (**UNCONFIRMED** as a documented statement).
- **Issue dependencies**: "Mark as blocked by" and "Mark as blocking" in the issue sidebar; blocked issues show a "Blocked" icon on boards and issue lists. `gh issue create --blocked-by N`, `gh issue edit --add-blocked-by N`, and `gh issue view --json blockedBy,blocking` ([creating issue dependencies](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/creating-issue-dependencies); CLI since v2.94.0, [changelog 2026-06-10](https://github.blog/changelog/2026-06-10-manage-sub-issues-types-and-dependencies-from-github-cli/)). Whether a project view filter can exclude blocked items, so next-up skips them, I did not find (**UNCONFIRMED**).
- **Issue artifacts** (public preview): named, versioned Markdown, plans, links or HTML attached to an issue, readable by agents through `gh issue artifact` ([using artifacts](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/using-artifacts-with-issues)). They could hold a spec on the issue, but in a public repo that publishes what `.scratch/` keeps private.

Do types replace kind labels? For an organization with many repos, GitHub clearly intends them to. For this setup, not yet: they are five days old on personal accounts, cover issues only, and may not be scriptable from `labels.sh`. Every personal account now has the default Bug, Task, Feature types, so an issue can carry both a type and a kind label that disagree (**UNCONFIRMED** whether the types show on issues that never set one; the docs say a type shows only once added).

## 3. Projects v2

### 3.1 Status flow and built-in workflows

- A new project turns on two workflows: closed items are set to Done, and merged PRs are set to Done. Others can set Status when an item is added, or close an issue when its Status changes ([built-in automations](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-built-in-automations)).
- **Auto-add** adds new or updated items that match a filter (`is`, `label`, `reason`, `assignee`, `no`). It does not add existing items. GitHub Free allows 1 auto-add workflow, Pro 5 ([adding items automatically](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/adding-items-automatically)). Whether the limit counts per project or per account, the page does not say (**UNCONFIRMED**); `board.sh` needs one per board either way.
- **Auto-archive** filters on `is`, `reason` and `updated`, for example `updated:<@today-14d`. Turning it on also archives items that already match. A project holds up to 50,000 items including the archive ([archiving items automatically](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/archiving-items-automatically)).
- **Copying** a project copies views, custom fields, draft issues and "configured workflows (except any auto-add workflows)", and the new owner can be a personal account ([copying a project](https://docs.github.com/en/issues/planning-and-tracking-with-projects/creating-projects/copying-an-existing-project)). This is exactly what `board.sh` relies on: the template carries every workflow but auto-add, which the user turns on per board.
- A single-select field can have a default value that new items get ([single select fields](https://docs.github.com/en/issues/planning-and-tracking-with-projects/understanding-fields/about-single-select-fields)). Whether the built-in Status field accepts one, which would replace the "Item added: set Backlog" workflow, I did not confirm (**UNCONFIRMED**).

### 3.2 Organization only vs personal

| Feature | Personal account | Source |
|---|---|---|
| Projects, views, custom fields, built-in workflows | Yes | [about projects](https://docs.github.com/en/issues/planning-and-tracking-with-projects/learning-about-projects/about-projects) |
| Marking a project as a template, recommended templates | No, organization only; personal accounts copy a project instead | [project templates](https://docs.github.com/en/issues/planning-and-tracking-with-projects/managing-your-project/managing-project-templates-in-your-organization) |
| Auto-add workflows | Yes, 1 on Free, 5 on Pro | [adding items automatically](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/adding-items-automatically) |
| Issue types and issue fields | Yes, since 2026-11-11 | [changelog](https://github.blog/changelog/2026-11-11-issue-types-and-fields-are-available-for-personal-accounts/) |
| Branch-protection bypass lists | No, organization only (**UNCONFIRMED**: not re-read this session) | [about protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches) |

### 3.3 Iteration and priority fields

Iteration fields set repeating time-boxes, can be filtered with `@current` or `@next`, and feed the roadmap layout ([iteration fields](https://docs.github.com/en/issues/planning-and-tracking-with-projects/understanding-fields/about-iteration-fields)). GitHub's best-practices page suggests a single-select Priority field ([best practices](https://docs.github.com/en/issues/planning-and-tracking-with-projects/learning-about-projects/best-practices-for-projects)). Neither helps a one-person repo with no sprints. Board order as priority is a valid choice: it needs no field, and the next-up query reads it directly.

## 4. Issue templates and issue forms

- Templates live in `.github/ISSUE_TEMPLATE/`. Markdown templates and YAML issue forms both take `labels`, `assignees`, `type`, and forms also `projects`, applied to every issue made from them. Issue forms are still "in public preview" ([configuring templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository), [issue form syntax](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms)).
- `config.yml` with `blank_issues_enabled: false` hides the blank issue from Read and Triage roles; people with write access still see it, marked "Maintainers only". `contact_links` sends people elsewhere ([configuring templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository)).
- `gh issue create --template` uses a template only when asked; with `--title` and `--body-file`, as the tracker files issues, no template applies (from `gh issue create --help`).
- **Safety point:** labels in a template are applied for anyone who uses it, while applying a label by hand needs triage access ([managing labels](https://docs.github.com/en/issues/using-labels-and-milestones-to-track-work/managing-labels)). A template must never carry `ready-for-agent`, or any outside reporter could hand work to an unattended agent. Copilot automations ignore people without write access by default for the same reason ([automations](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent/create-automations)).

For a solo repo, templates matter only if outsiders file issues. In this public repo that is possible but rare (**UNCONFIRMED**, judgment). One small form that applies `needs-triage` would make that label mean something.

## 5. Milestones

A milestone groups issues and PRs and shows a due date, percent complete and a drag-to-order list ([about milestones](https://docs.github.com/en/issues/using-labels-and-milestones-to-track-work/about-milestones)). VS Code uses them as its whole flow: `Backlog Candidates` for feature requests awaiting 20 upvotes, `Backlog` for accepted, and one milestone per iteration ([Issues-Triaging](https://github.com/microsoft/vscode/wiki/Issues-Triaging), [Issue-Tracking](https://github.com/microsoft/vscode/wiki/Issue-Tracking)). Kubernetes ties them to release cycles. A repo with no releases and no time-boxes has no use for them, and the board order already gives a ranked list.

## 6. Linking PRs to issues and squash merge

- `close`, `closes`, `closed`, `fix(es/ed)`, `resolve(s/d)` followed by `#N` in a PR body link the PR and close the issue on merge. Colons and uppercase work. Keywords count only when the PR targets the **default branch** ([linking a PR](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/linking-a-pull-request-to-an-issue)).
- A keyword in a commit message also closes the issue on merge to the default branch, but the PR "will not be listed as a linked pull request" (same page).
- The Development sidebar links up to ten issues to a PR by hand. Keyword links can be removed only by editing the PR body (same page).
- **Squash-merge implication:** `repo-settings.sh` sets the squash commit to the PR title with a blank body. The `Closes #N` line therefore never reaches `git log`; the link and the auto-close come from the PR body, which works because PRs here target `main`. Someone reading `git log` alone gets back to the issue only through the PR number GitHub adds to a squashed title (**UNCONFIRMED**: the docs I read do not state the `(#123)` suffix).
- Squash merge "works best for short-lived branches" ([PR merges](https://docs.github.com/en/pull-requests/reference/pull-request-merges)), which one issue per PR group fits.
- GitHub can close an issue as a duplicate of another (since [2024-12-12](https://github.blog/changelog/2024-12-12-github-issues-projects-close-issue-as-a-duplicate-rest-api-for-sub-issues-and-more/)), from `gh issue close N --duplicate-of M` or `--reason duplicate`; a "Duplicate of #N" comment does the same for issues and PRs ([marking duplicates](https://docs.github.com/en/issues/tracking-your-work-with-issues/administering-issues/marking-issues-or-pull-requests-as-a-duplicate)).

## 7. AI coding agents and issues

- **Copilot's cloud agent** (formerly "coding agent") starts when you assign an issue to Copilot. It "gets sent the issue title, description, any comments that currently exist", and "will not be aware of ... any further comments" after assignment ([using Copilot in the cloud](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent/use-cloud-agent-on-github)). This matches the choice to put the ticket text in the issue body.
- GitHub's advice on issues for the agent: "think of the issue you assign to Copilot as a prompt", with a clear problem, "complete acceptance criteria", and which files to change. Keep for yourself tasks that are broad, sensitive, ambiguous, or that you want to learn from ([best practices](https://docs.github.com/en/copilot/tutorials/cloud-agent/get-the-best-results)). The GitHub blog adds: write the issue for someone new to the codebase, and split large work into "multiple, independent, smaller tasks" ([WRAP, 2025-12-26](https://github.blog/ai-and-ml/github-copilot/wrap-up-your-backlog-with-github-copilot-coding-agent/); [assigning issues, 2025-06-06](https://github.blog/ai-and-ml/github-copilot/assigning-and-completing-issues-with-coding-agent-in-github-copilot/)).
- The new Copilot cloud experience needs a paid Copilot plan from 2026-10-28 ([about Copilot on GitHub](https://docs.github.com/en/copilot/concepts/agents/cloud-agent/about-cloud-agent)). Copilot automations can run on events such as an issue being opened, and can label issues ([automations](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent/create-automations)). Neither is needed here: Claude Code skills drive the board.
- **Label conventions for agents:** GitHub documents none. `good first issue` is for first-time human contributors and feeds the repo's `contribute` page ([managing labels](https://docs.github.com/en/issues/using-labels-and-milestones-to-track-work/managing-labels), [encouraging contributions](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/encouraging-helpful-contributions-to-your-project-with-labels)). The `ready-for-agent` / `ready-for-human` pair comes from Matt Pocock's `triage` skill, where five state roles form the whole state machine and "every triaged issue should carry exactly one category role and one state role" ([triage SKILL.md](https://github.com/mattpocock/skills/blob/main/skills/engineering/triage/SKILL.md), [triage-labels.md](https://github.com/mattpocock/skills/blob/main/skills/engineering/setup-matt-pocock-skills/triage-labels.md)). That model has no board; this setup puts the flow on the board and keeps the roles as labels.
- Some large projects push the other way: Astral does "not allow autonomous agents to be used for contributing" ([Astral AI policy](https://github.com/astral-sh/.github/blob/main/AI_POLICY.md)). That governs outside contributors, not a maintainer's own agents.

## 8. This repo today

Read-only checks this session: the repo still carries GitHub's ten default labels (none of the agreed set yet), has no project board for it, no issues, and four merged `chore(deps): nix flake update` PRs. `update.yml` opens that PR without any label. Its `docs/agents/issue-tracker.md` still describes the Shortcut tracker. No skill other than the tracker file applies `needs-triage`, `ready-for-human`, `wontfix`, `breaking`, `dependencies` or `duplicate`; `skip-changelog` is used only by `setup-dan-skills/changelog/README.md` for towncrier repos.

## Recommendations

### For this repo

1. **Leave `skip-changelog` out of this repo.** It exists to exempt a PR from a towncrier fragment check, and this repo has no changelog ([ADR 0011](../adr/0011-history-is-the-merged-pr-list.md)). Trade-off: needs shared recommendation 2, or a hand delete after `labels.sh` runs.
2. **Have `update.yml` add `--label dependencies` to its `gh pr create`.** That gives the label a job, and it matches Dependabot's default of labelling every PR `dependencies` ([Dependabot options](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference)). Trade-off: the label must exist first, or the PR step may fail (**UNCONFIRMED**).
3. **Keep the default Priority issue field out of play.** Check Settings > Planning > Issue fields on the account and delete Priority and Effort if they exist, so board order stays the one priority ([issue fields](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/managing-issue-fields), [single source of truth](https://docs.github.com/en/issues/planning-and-tracking-with-projects/learning-about-projects/best-practices-for-projects)). Trade-off: account-wide, so it also removes them from every other personal repo.
4. **Keep as is: no milestones, no iteration field, no issue templates.** None has a job without releases, time-boxes or outside reporters (sections 3.3, 4, 5). Trade-off: an outsider's issue arrives unlabelled in Backlog and waits for you, which is safe since agents only take `ready-for-agent`.

### For the shared setup-dan-skills scripts

1. **File blocking edges as real dependencies.** In "publish to the issue tracker", pass `--blocked-by N` to `gh issue create` instead of writing `Blocked by #N` as text ([issue dependencies](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/creating-issue-dependencies)). The board then shows a Blocked icon, and agents can read `--json blockedBy`. Trade-off: needs `gh` 2.94.0 or later; a next-up filter that skips blocked items is **UNCONFIRMED**, so next-up may need a `blockedBy` check per candidate.
2. **Create `skip-changelog` only where a changelog needs it.** In `labels.sh`, add it only when the repo has `towncrier.toml`. Trade-off: the label set differs by repo, so `issue-tracker-github.md` must say when the label exists.
3. **Stop creating `duplicate`; close with `gh issue close N --duplicate-of M`.** GitHub records the reason and the link natively ([changelog 2024-12-12](https://github.blog/changelog/2024-12-12-github-issues-projects-close-issue-as-a-duplicate-rest-api-for-sub-issues-and-more/)). Add `duplicate` to the delete-if-unused list. Trade-off: a duplicate PR is marked with a "Duplicate of #N" comment instead of a label.
4. **Replace `wontfix` with the "not planned" close reason**, which the tracker already uses for dropped TODOs. Trade-off: breaks the one-to-one map with Matt Pocock's five triage roles, and an issue cannot be "won't fix" while still open.
5. **Write down the Status/label split in `issue-tracker-github.md`.** Status says where an item is; `ready-for-*` says who does it; `needs-info` says it waits on an answer; `todo` says where it came from. Say that `needs-triage` is applied only by an issue form for outside reporters, never by agents, and that untriaged otherwise means "Backlog with no `ready-*` label" ([single source of truth](https://docs.github.com/en/issues/planning-and-tracking-with-projects/learning-about-projects/best-practices-for-projects); Kubernetes auto-applies `needs-triage`). Trade-off: a few lines of prose; dropping `needs-triage` outright is the simpler alternative but loses the outsider path.
6. **Never put `ready-for-agent` in an issue template's `labels`,** and say so in the tracker file. Template labels apply for any reporter; hand-applied labels need triage access ([managing labels](https://docs.github.com/en/issues/using-labels-and-milestones-to-track-work/managing-labels), [issue forms](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms)). Trade-off: none beyond one sentence.
7. **Keep kind labels; do not move to issue types yet.** Types reached personal accounts on 2026-11-11, cover issues but not PRs, and scripting them for a personal account is **UNCONFIRMED** ([changelog](https://github.blog/changelog/2026-11-11-issue-types-and-fields-are-available-for-personal-accounts/)). Revisit in a few months. Trade-off: every account now has default Bug/Task/Feature types that can disagree with the kind label.
8. **Keep one issue per PR group, with no sub-issues and no spec issue.** Sub-issues suit a parent that people track on GitHub; here the spec is local by choice and the PR group is the unit of work ([sub-issues](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/adding-sub-issues)). Trade-off: no progress bar for a multi-PR feature on the board.
9. **Keep the issue body as a full prompt, and make sure it carries acceptance criteria and the files to touch.** That is GitHub's own recipe for agent-ready issues ([Copilot best practices](https://docs.github.com/en/copilot/tutorials/cloud-agent/get-the-best-results)). Trade-off: longer issue bodies in a public tracker.
10. **Keep `board.sh` as is: template copied per repo, auto-add turned on by hand.** Copying carries every workflow except auto-add, and personal accounts cannot mark templates ([copying a project](https://docs.github.com/en/issues/planning-and-tracking-with-projects/creating-projects/copying-an-existing-project), [project templates](https://docs.github.com/en/issues/planning-and-tracking-with-projects/managing-your-project/managing-project-templates-in-your-organization)). Trade-off: one manual step per new repo; GitHub Free allows only one auto-add workflow.

## Sources

- GitHub Docs, Managing issue types: https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/managing-issue-types
- GitHub Docs, Managing issue fields: https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/managing-issue-fields
- GitHub Docs, Adding sub-issues: https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/adding-sub-issues
- GitHub Docs, Creating issue dependencies: https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/creating-issue-dependencies
- GitHub Docs, Using artifacts with issues: https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/using-artifacts-with-issues
- GitHub Docs, Managing labels: https://docs.github.com/en/issues/using-labels-and-milestones-to-track-work/managing-labels
- GitHub Docs, About milestones: https://docs.github.com/en/issues/using-labels-and-milestones-to-track-work/about-milestones
- GitHub Docs, Using the built-in automations: https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-built-in-automations
- GitHub Docs, Adding items automatically: https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/adding-items-automatically
- GitHub Docs, Archiving items automatically: https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/archiving-items-automatically
- GitHub Docs, Copying an existing project: https://docs.github.com/en/issues/planning-and-tracking-with-projects/creating-projects/copying-an-existing-project
- GitHub Docs, Managing project templates in your organization: https://docs.github.com/en/issues/planning-and-tracking-with-projects/managing-your-project/managing-project-templates-in-your-organization
- GitHub Docs, Best practices for Projects: https://docs.github.com/en/issues/planning-and-tracking-with-projects/learning-about-projects/best-practices-for-projects
- GitHub Docs, About iteration fields: https://docs.github.com/en/issues/planning-and-tracking-with-projects/understanding-fields/about-iteration-fields
- GitHub Docs, Configuring issue templates: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository
- GitHub Docs, Syntax for issue forms: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms
- GitHub Docs, Linking a pull request to an issue: https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/linking-a-pull-request-to-an-issue
- GitHub Docs, Pull request merges: https://docs.github.com/en/pull-requests/reference/pull-request-merges
- GitHub Docs, Using Copilot in the cloud on GitHub: https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent/use-cloud-agent-on-github
- GitHub Docs, Best practices for using Copilot to work on tasks: https://docs.github.com/en/copilot/tutorials/cloud-agent/get-the-best-results
- GitHub Docs, Creating automations with Copilot cloud agent: https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent/create-automations
- GitHub Docs, Dependabot options reference: https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference
- GitHub Changelog 2026-11-11, Issue types and fields for personal accounts: https://github.blog/changelog/2026-11-11-issue-types-and-fields-are-available-for-personal-accounts/
- GitHub Changelog 2026-06-10, Sub-issues, types and dependencies from GitHub CLI: https://github.blog/changelog/2026-06-10-manage-sub-issues-types-and-dependencies-from-github-cli/
- GitHub Changelog 2025-04-09, Evolving GitHub Issues and Projects: https://github.blog/changelog/2025-04-09-evolving-github-issues-and-projects/
- GitHub Changelog 2024-12-12, Close issue as a duplicate: https://github.blog/changelog/2024-12-12-github-issues-projects-close-issue-as-a-duplicate-rest-api-for-sub-issues-and-more/
- GitHub Blog 2025-12-26, WRAP up your backlog: https://github.blog/ai-and-ml/github-copilot/wrap-up-your-backlog-with-github-copilot-coding-agent/
- Kubernetes, Issue triage guidelines: https://github.com/kubernetes/community/blob/master/contributors/guide/issue-triage.md
- Rust Forge, Issue triaging: https://github.com/rust-lang/rust-forge/blob/master/src/release/issue-triaging.md
- VS Code wiki, Issues Triaging: https://github.com/microsoft/vscode/wiki/Issues-Triaging
- Node.js, Collaborator guide: https://github.com/nodejs/node/blob/main/doc/contributing/collaborator-guide.md
- uv, CONTRIBUTING: https://github.com/astral-sh/uv/blob/main/CONTRIBUTING.md
- ruff, CONTRIBUTING: https://github.com/astral-sh/ruff/blob/main/CONTRIBUTING.md
- Astral, AI policy: https://github.com/astral-sh/.github/blob/main/AI_POLICY.md
- Conventional Commits 1.0.0: https://www.conventionalcommits.org/en/v1.0.0/
- Matt Pocock skills, triage: https://github.com/mattpocock/skills/blob/main/skills/engineering/triage/SKILL.md
