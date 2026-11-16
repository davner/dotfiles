---
type: research
updated: 2026-11-16
---

# GitHub credentials for AI coding agents, scoped to chosen repos

2026-11-16. Question: what is the right way to give AI coding agents (Claude Code on this Mac, sometimes unattended in loops) GitHub credentials that let them open PRs, create and edit issues, merge PRs with auto-merge, add issues to a Projects (v2) board, link sub-issues and dependencies, and move items across the board - only for repos the owner chooses, while the owner keeps a full-access login? The owner is a personal account (`davner`), not an organization.

Tags: **UNCONFIRMED** marks a claim I could not check at its primary source this session, or a judgment of mine. GitHub docs were read as Markdown from `docs.github.com/api/article/body`, the per-endpoint token notes from the rendered REST pages, the `gh` manual from cli.github.com, `gh` internals from the `cli/cli`, `cli/go-gh` and `zalando/go-keyring` source on GitHub, and the Claude Code docs from their Markdown source on code.claude.com. The hook was read and fed test commands locally. Read-only `gh api` calls checked the live repo settings. Nothing was written to GitHub.

## Answer

- **No GitHub App or fine-grained token can touch a Projects board owned by a personal account.** The REST pages for user-owned project items say each endpoint "does not work with GitHub App user access tokens, GitHub App installation access tokens, or fine-grained personal access tokens." The fine-grained PAT page lists "access Projects owned by a user account" as a known gap, and its account permissions have no Projects entry. Only a classic token (OAuth or classic PAT) with the `project` scope reaches a user-owned board.
- **A fine-grained PAT from a second account cannot work on the owner's repos either.** The same gap list says fine-grained PATs cannot "contribute to repositories where the user is an outside or repository collaborator". A bot account invited as a collaborator therefore needs a classic PAT too.
- **So the one credential that covers every action is a classic PAT on a machine user (a second GitHub account run by the owner for automation).** GitHub's terms allow one free machine account per person. Its reach is set by what the owner invites it to: the chosen repos as collaborator, and the board as a Write collaborator. The `repo` scope means "every repo this account can reach", which for the bot is only the invited ones.
- **The local hook is a seatbelt, not a lock.** `guard-bash.sh` blocked `gh pr merge`, `gh pr create` and `git push` in a repo without the switches, but let through `bash -c "gh pr merge 5"`, `eval`, `gh api -X PUT .../pulls/5/merge`, the GraphQL auto-merge mutation, `curl` with `$(gh auth token)`, `gh issue create`, `gh project item-add`, and `git send-pack`. Claude Code's own docs say deny rules are "not a security boundary around the program".
- **Any token the agent's macOS user can read, the agent can use.** `gh` stores tokens through `/usr/bin/security`, keyed by host and user, and `gh auth token --user <name>` prints any stored account. An empty `GH_TOKEN=` makes `gh` fall back to the keyring. A real wall between the owner's token and an unattended agent needs a separate macOS user, a VM or container, or the Claude Code sandbox with the right settings (whether the sandbox blocks keychain reads is **UNCONFIRMED**).
- **Branch protection can require the owner's review only when the PR author is someone else.** "Pull request authors cannot approve their own pull requests." With a bot as the author, the owner's approval counts. On a personal repo classic protection has no bypass list, so requiring a review with `enforce_admins` on also blocks the owner's own PRs; a ruleset with a Repository admin bypass avoids that (bypass on a personal repo is **UNCONFIRMED**).
- **The live repo does not match the brief.** On 2026-11-16, `GET repos/davner/dotfiles/branches/main/protection` returned "Branch not protected", the repo has 0 rulesets, and `allow_auto_merge` is `false`. Auto-merge needs that setting on and a rule (required check or review) that holds the PR open.

The setup is in "Recommendation" at the end.

## 1. Keep the broad OAuth token and rely on the hook

### What `guard-bash.sh` enforces

Read from `home/.claude/hooks/guard-bash.sh`, run by `settings.base.json` as a `PreToolUse` hook on the Bash tool only. It parses the command with `shell-parse.sh`, follows `cd`, `git -C` and wrappers (`env`, `sudo`, `command`, `exec`, `nohup`, `time`, `nice`, `timeout`), and exits 2 to block when:

- `git push` runs in a repo whose local config lacks `claude.allowPush=true` (or the directory cannot be worked out), or any force push.
- `gh pr create|new|merge` or `gh-axi pr create|merge` runs in a repo without `claude.allowPrs=true`, or with `-R/--repo` naming another repo.
- An agent tries to set `claude.allowPush` / `claude.allowPrs` or runs `cc-push` other than `cc-push status`.
- A PR body or commit message credits an AI, plus the history-safety rules (`reset --hard`, `clean -f`, `branch -D`, merge commits, and so on).

`settings.base.json` adds deny rules: `Bash(gh auth token *)`, `Bash(security find-*)`, `Bash(gh repo delete *)`, `Bash(env *GH_TOKEN*)`, `Bash(unset *GH_TOKEN*)`, force-push forms, and `Read(~/.ssh/**)`.

### What it cannot enforce

Tested by piping a hook payload with each command into the hook, cwd outside any repo (2026-11-16):

| Command | Hook exit |
| --- | --- |
| `gh pr merge 5 --auto`, `gh pr create --fill`, `git push origin x`, `git -c ... push` | 2 (blocked) |
| `bash -c "gh pr merge 5"`, `eval "gh pr merge 5"`, `G=gh; $G pr merge 5` | 0 |
| `gh api -X PUT repos/davner/dotfiles/pulls/5/merge` | 0 |
| `gh api graphql -f query="mutation{enablePullRequestAutoMerge(...)}"` | 0 |
| `curl -H "Authorization: token $(gh auth token)" -X PUT .../merge` | 0 |
| `gh issue create`, `gh project item-add` | 0 (not in scope of the hook) |
| `git send-pack origin HEAD:refs/heads/x` | 0 |

Beyond the Bash tool, the hook does not see MCP servers (a GitHub MCP server would use its own token), mods, or any program the agent writes and runs. The Claude Code permissions page says the same of deny rules: `Bash(git push *)` "doesn't stop" `git -C . push`, and `Bash(rm *)` doesn't stop `bash -c 'rm -rf build/'`; "a deny or ask rule ... isn't a security boundary around the program". It does say deny rules apply inside command substitutions, so `Bash(gh auth token *)` should catch `$(gh auth token)` in the Claude Code permission check, though the hook above does not (**UNCONFIRMED** in practice).

Two gaps in the deny list follow from code read this session:

- `GH_TOKEN= gh api ...`: `go-gh`'s `TokenFromEnvOrConfig` only uses `GH_TOKEN` when it is `!= ""`, so an empty value falls back to stored credentials. The deny rules match `env *GH_TOKEN*` and `unset *GH_TOKEN*`, not a leading `GH_TOKEN=` assignment.
- `/usr/bin/security find-generic-password ...` and `bash -c 'gh auth token'` are other spellings the text rules miss, per the permissions doc table above.

### The token itself

Today's OAuth token has `repo` (every repo the owner can reach), `project`, `read:org`, `gist`, `admin:public_key`. Anything the agent does is attributed to `davner`, so branch protection cannot tell the agent from the owner, and the owner cannot approve the agent's PRs. The token lacks `delete_repo`, so `gh repo delete` fails server-side whatever the hook does (scope meaning per GitHub's OAuth scopes doc; not tested).

Verdict: fine for attended sessions as a convenience layer; not a scope limit for unattended loops.

## 2. Fine-grained PAT limited to selected repos

Source: "Managing your personal access tokens" and "Permissions required for fine-grained personal access tokens".

### Permissions per action

| Action | Repository permission | Source |
| --- | --- | --- |
| Clone, fetch, push branches | Contents: write | REST perms (`git/refs` under Contents) |
| Push changes to `.github/workflows/*` | Workflows: write | Workflows section lists `git/refs` and `contents/{path}` writes; App docs: "If your app specifically needs to access or edit Actions files in the `.github/workflows` directory, request the Workflows permission" |
| Open and edit a PR | Pull requests: write | `POST /repos/{owner}/{repo}/pulls` |
| Merge a PR | Contents: write | `PUT .../pulls/{pull_number}/merge` is listed under Contents |
| Enable auto-merge (`gh pr merge --auto`, GraphQL) | Contents + Pull requests write | **UNCONFIRMED**; the GraphQL mutation's permission is not in the REST table |
| Create and edit issues, labels, comments | Issues: write | `POST .../issues`, `PATCH .../issues/{n}` |
| Sub-issues | Issues: write | `POST .../issues/{n}/sub_issues` |
| Dependencies (blocked by) | Issues: write | `POST .../issues/{n}/dependencies/blocked_by` |
| Everything | Metadata: read | Always granted with any repo permission |
| Add to or move on a **user-owned** board | none exists | See below |

### Projects on a personal account

- The limitations list on the PAT page: "Using fine-grained personal access token to access Projects owned by a user account."
- The account permissions table (blocking, emails, followers, gists, keys, profile, starring, watching and others) has no Projects entry. The `organization_projects` permission is under organization permissions, which "can only be used if the resource owner is an organization".
- The REST items page, for "Add item to user owned project" and "Update project item for user": "This endpoint does not work with GitHub App user access tokens, GitHub App installation access tokens, or fine-grained personal access tokens." The org-owned versions work with all three, with "Projects" organization permission (write).

So a fine-grained PAT covers everything except the board. The board would still need a classic token.

### Expiry

The PAT page's URL-template table gives `expires_in` as "Integer between 1 and 366, or `none`", default 30 days, and says "Infinite lifetimes are allowed but may be blocked by a maximum lifetime policy set by your organization or enterprise owner." Optional expiry for fine-grained PATs arrived on 2024-10-18 (changelog title, not read in full: **UNCONFIRMED** detail). Fine-grained PATs went GA on 2025-03-18. Tokens unused for a year are removed automatically.

### Identity

A fine-grained PAT belongs to the owner, so actions are attributed to `davner`: same review problem as option 1. Made on a bot account instead, it hits the collaborator gap ("contribute to repositories where the user is an outside or repository collaborator").

## 3. GitHub App, or a machine user

### GitHub App

Sources: "Generating an installation access token for a GitHub App", "Choosing permissions for a GitHub App", "Permissions required for GitHub Apps", "Using the API to manage Projects".

- An app is installed on selected repos. Its installation token is minted by signing a JWT with the app's private key and calling `POST /app/installations/{id}/access_tokens`; it "will expire after 1 hour", can be narrowed further with `repositories` and `permissions`, and "cannot be granted access to repositories that the installation was not granted access to".
- Acts as its own identity (`<app-name>[bot]`), so the owner can review and approve its PRs. Apps do not use a seat.
- **User-owned boards: no.** The GitHub App permission list has organization "Projects" and no user-level Projects permission; the REST pages above exclude installation and user access tokens for user-owned project endpoints. The Projects API guide says a token "can be a personal access token (classic) for a user or an installation access token", but every example of the installation case is an org board. A GraphQL call from an installation token to a user board is **UNCONFIRMED** (expected to fail with "Resource not accessible by integration").
- Locally, `gh` has no command to mint an app token. A script (or a `gh` extension, third-party, **UNCONFIRMED**) has to sign the JWT, call the endpoint, export `GH_TOKEN`, and repeat within the hour. That means a private key on disk the agent's user can read, which is a longer-lived secret than the token it mints.

### Machine user

Sources: GitHub Terms of Service section B, "Types of GitHub accounts", "Permission levels for a personal account repository", "Managing access to your projects".

- Terms: "A machine account is an Account set up by an individual human who accepts the Terms on behalf of the Account, provides a valid email address, and is responsible for its actions ... You may maintain no more than one free machine account in addition to your free Personal Account."
- On a personal repo, collaborators "can pull (read) the contents of the repository and push (write) changes"; there is no finer role. The owner keeps settings, collaborator invites, visibility, auto-merge setting, deletion.
- "Admins of user-level projects can invite individual collaborators and manage their access", with Read, Write and Admin roles. So the bot can be a Write collaborator on the user-owned board.
- Token: a classic PAT on the bot. Its `repo` scope reaches what the bot can reach: the invited repos, plus public repos read-only. `project` reaches boards it is a collaborator on. `gh auth login --with-token` asks for "repo, read:org, and gist" at minimum; with `GH_TOKEN` set no login is needed (whether `gh` then complains about missing `gist` or `read:org` is **UNCONFIRMED**).
- Whether GitHub's two-factor requirement for code contributors applies to a machine account is **UNCONFIRMED**.

## 4. Making the scoped token the one the agent uses

### How `gh` and git pick a token

- `gh help environment`: "GH_TOKEN, GITHUB_TOKEN (in order of precedence) ... takes precedence over previously stored credentials." Source confirms an empty value is ignored (falls back to the keyring).
- Git: this Mac's `~/.config/git/config` sets `credential.https://github.com.helper` to `gh auth git-credential` (and clears the Nix `osxkeychain` helper for that host). That helper calls `ActiveTokenWithRefresh`, which reads environment variables first (`cli/cli` `internal/config/config.go`). So with `GH_TOKEN` set, HTTPS pushes use the same token. The remote is HTTPS.
- `gh auth login` for a second account plus `gh auth switch` changes the active account for every shell on the machine; `gh auth token --user <name>` prints either one. Multi-account storage is a convenience for the owner, not a separation.
- Keyring keys are `keyringServiceName(hostname)` plus username, not tied to `GH_CONFIG_DIR`, so a separate config directory still shares the keyring entries.
- `gh` writes the keyring through `zalando/go-keyring`, which runs `/usr/bin/security add-generic-password` and `find-generic-password`. The ACL then trusts `/usr/bin/security`, so any process of the same user can read the item without a prompt (macOS keychain ACL behavior, **UNCONFIRMED** by test).

### Where to put the agent's token

| Place | Effect | Problem |
| --- | --- | --- |
| Claude Code settings `env` | Applies to every session and subprocess | `settings.base.json` is in a public repo; the merged `~/.claude/settings.json` is a plain file |
| Wrapper (`cc` in `functions.zsh`) exporting `GH_TOKEN` from a keychain item | Every agent session gets the bot token; the owner's own shell does not | Agent's user can still read both keychain items |
| direnv `.envrc` per repo | Token only in chosen repos | Claude Code's Bash tool is a non-interactive shell; whether direnv's hook runs there is **UNCONFIRMED**; and the bot's invitations already scope repos server-side |
| Sandbox `credentials.envVars` with `mode: mask` | Commands see a placeholder; the proxy swaps in the real value for `injectHosts` | Needs `network.tlsTerminate` and an allowlist; must be in user settings, not the repo's |
| Separate macOS user (or VM/container) for loops | That user's keychain holds only the bot token | More setup; Claude Code login needed there too |

Claude Code sandbox facts (sandboxing doc): it limits file reads, writes and network for Bash commands and their children; `credentials.envVars` `deny` unsets a variable, `mask` substitutes it on allowed hosts; `allowUnsandboxedCommands: false` makes Claude Code ignore `dangerouslyDisableSandbox`; on macOS a masked file is blocked outright. The sandbox doc does not mention the macOS keychain, so whether a sandboxed `security find-generic-password` or `gh auth token` still reads the owner's token is **UNCONFIRMED**. `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1` "leaves GitHub tokens ... in place", so it does not help here.

What stops the agent using the keyring token anyway: nothing at the OS level while it runs as the owner's macOS user. The hook and deny rules stop the usual spellings. Only a separate OS user, a VM or container, or a sandbox that blocks keychain access (to be tested) closes it.

## 5. Branch protection and rulesets

Sources: "About protected branches", "Available rules for rulesets", "Creating rulesets for a repository", "Approving a pull request with required reviews", "Automatically merging a pull request".

- Classic protection on a personal repo: "Actors may only be added to bypass lists when the repository belongs to an organization." With `enforce_admins` ("Do not allow bypassing the above settings") on, the owner obeys the same rules as the bot.
- Reviews: approvals count from "people with write permissions"; "Pull request authors cannot approve their own pull requests"; "Repository owners and administrators can merge a pull request even if it hasn't received an approving review" unless bypass is disallowed.
- Consequence: requiring 1 approval with `enforce_admins` on means the owner's own PRs need someone else's approval, and the bot (a write collaborator) could give it. That is the wrong way round.
- Rulesets: bypass can go to "Repository admins", "The maintain or write role", teams, GitHub Apps, Dependabot, optionally "For pull requests only". A ruleset requiring 1 approval and the `test` check, with Repository admin as bypass, holds the bot to review while the owner can still merge alone. That a personal-account repo's ruleset offers the Repository admin role in its bypass list is **UNCONFIRMED** (the doc does not say it is org-only, but does not show a personal repo either).
- "Require approval of the most recent reviewable push" stops a bot from pushing after the owner approves.
- Auto-merge: must be allowed in repo settings (owner only on a personal repo), "People with write permissions to a repository can enable auto-merge", and the option "is shown only on pull requests that cannot be merged immediately" (a required check or review pending). `gh pr merge --auto` "Automatically merge[s] only after necessary requirements are met." A bot collaborator can therefore enable auto-merge; the merge then waits for `test` and any required approval.
- Who is credited with the final merge when the bot enabled auto-merge is **UNCONFIRMED**.

## Comparison

| | 1. OAuth + hook | 2. Fine-grained PAT (owner) | 3a. GitHub App | 3b. Machine user, classic PAT |
| --- | --- | --- | --- | --- |
| Limited to chosen repos | No (hook only, bypassable) | Yes | Yes | Yes, by invitation |
| PRs, issues, merge, auto-merge | Yes | Yes | Yes | Yes |
| Sub-issues, dependencies | Yes | Yes (Issues write) | Yes (Issues write) | Yes |
| User-owned Projects board | Yes | **No** | **No** | Yes (Write collaborator + `project`) |
| Separate identity, owner can approve | No | No | Yes | Yes |
| Token lifetime | Non-expiring OAuth | 1-366 days or none | 1 hour, minted from a key | Owner sets, or none |
| Local setup | None | Paste token | Key, JWT script, refresh loop | Second account, invites, one token |
| Granularity inside a repo | n/a | Per permission | Per permission | Collaborator = write, all of it |

## Recommendation

Pick option 3b: a machine user with one classic PAT, given to agent sessions through `GH_TOKEN`, with the owner's own login untouched and the hook kept as a second layer. It is the only credential this research found that does every listed action on a personal account, including the board, and it gives the agent its own name so branch protection and reviews can tell it apart. Unattended loops run under a separate macOS user so the owner's keyring token is out of reach.

If the owner later moves the repos and board to a free organization, re-solve with a GitHub App (1-hour tokens, per-permission scope, org Projects permission). That is a bigger move and changes repo URLs, so it is not the first step.

### Steps (the owner runs these; nothing here was run)

1. Create the machine account in a private browser window, for example `davner-agent`, with its own email and two-factor auth. Its profile can say it is run by `davner`.
2. As `davner`, invite it to each chosen repo: repo Settings, Collaborators, Add people. Accept the invite as the bot.
3. As `davner`, open the board (`https://github.com/users/davner/projects/1` is the one `gh project list` shows today), menu, Settings, Manage access, invite `davner-agent` with the Write role. Accept as the bot.
4. As the bot: Settings, Developer settings, Personal access tokens, Tokens (classic), Generate new token. Scopes: `repo`, `project`, `read:org`; add `workflow` only if the agent should edit `.github/workflows`. Set an expiry (for example 90 days) and a calendar reminder.
5. Store it in the login keychain under its own name, typed so it stays out of shell history:
   `security add-generic-password -a davner-agent -s agent-github-token -w`
   (prompts for the value).
6. In `home/.config/zsh/functions.zsh`, have `cc` export the token for the session it starts, for example
   `GH_TOKEN="$(security find-generic-password -a davner-agent -s agent-github-token -w)" claude ...`
   and keep `GH_TOKEN` out of the owner's own shell. `gh` and git (through `gh auth git-credential`) then act as the bot.
7. For each chosen repo, as `davner`: Settings, General, tick "Allow auto-merge". Then Settings, Rules, Rulesets, New branch ruleset on `main`: require a pull request (1 approval, or 0 for hands-off loops), require approval of the most recent push, require status check `test`, block force pushes; add Repository admin to the bypass list. Remove the classic rule if one exists, or leave `enforce_admins` off there, so the owner is not locked out of solo merges.
8. Keep `claude.allowPush` and `claude.allowPrs` per repo as now. They stay a cheap local brake, and the bot's invitations are the real scope.
9. For unattended loops: create a standard macOS user (for example `agent`), sign Claude Code in there, check out the repos there, and store only the bot token in that user's keychain. Do not log `gh` in as `davner` in that account.
10. Optional hardening for attended sessions in your own account: turn on the Claude Code sandbox in `~/.claude/settings.json` with `credentials.envVars` `{ "name": "GH_TOKEN", "mode": "mask", "injectHosts": ["api.github.com", "github.com"] }`, `network.tlsTerminate`, an allowlist with `*.github.com`, and `allowUnsandboxedCommands: false`. Then test, inside a sandboxed command, whether `/usr/bin/security find-generic-password -s gh:github.com -w` or `GH_TOKEN= gh auth status` still reaches your own token. Until that test passes, treat your own token as reachable from attended sessions. Git sends the token Base64-encoded in a Basic auth header, so whether the proxy's swap works for `git push` is **UNCONFIRMED**; test a push too.

### The agent's environment afterwards

- `GH_TOKEN` holds the bot's classic PAT; `gh api user` answers `davner-agent`.
- `git push` over HTTPS authenticates as the bot through the existing `gh auth git-credential` helper. Commit authorship stays whatever `user.name` and `user.email` say.
- PRs are authored by `davner-agent`; the owner approves them, or the ruleset needs 0 approvals and auto-merge fires when `test` passes.
- In a repo the bot was not invited to, private reads and every write fail with 404 or 403; public repos stay readable.
- Board edits (add item, move status, set fields) work on boards the bot is a collaborator on.
- The guard hook and deny rules still apply on top.
- In the loop user account, the owner's token does not exist; in the owner's account it is still in the keyring.

### Trade-offs

- A classic PAT is all-or-nothing inside an invited repo: the bot can push any unprotected branch, close any issue, delete branches. Protection on `main` is what limits the damage.
- One more account to keep: its email, two-factor auth, token expiry. Classic PATs do not narrow by repo, so leaking it exposes every invited repo until revoked.
- The token is long-lived compared with an app's 1-hour token.
- Private repos not on the invite list become unreadable to agents, since the credential helper hands git the bot token.
- The separate macOS user adds a second checkout and a second Claude Code sign-in.
- If the owner prefers attribution to stay on `davner`, only option 1 or 2 does that, and neither gives a reviewable identity; option 2 also leaves the board on a classic token.

### Which credential does which part

| Part | Credential |
| --- | --- |
| Push, PRs, merge, auto-merge, issues, sub-issues, dependencies on chosen repos | Bot classic PAT (`repo`, plus `workflow` if needed) |
| Add items to and move them on the user-owned board | Same bot PAT (`project`), as a Write collaborator on the board |
| Repo settings, invitations, rulesets, approving bot PRs | Owner's own OAuth login, never in the agent's environment |

## What I checked and what I took on trust

Verified this session:

- Fine-grained PAT limitations, account and repository permission lists, expiry range (PAT docs).
- The REST "does not work with" notes for user-owned project items, and the org version's token list (rendered REST page).
- GitHub App permission list has no user-level Projects; installation token lifetime and narrowing (App docs).
- Repository permissions per endpoint for PRs, merge, issues, sub-issues, dependencies, workflows (fine-grained perms page).
- Machine account terms; personal repo collaborator rights; user project collaborator roles.
- Protection and ruleset bypass texts; "authors cannot approve their own pull requests"; auto-merge rules.
- `gh` env precedence, empty `GH_TOKEN` fallback, keyring through `/usr/bin/security`, keyring keyed by host, git credential helper reading env first (manual and source).
- `guard-bash.sh` behavior on the commands in the table (run locally), and the deny rules in `settings.base.json`.
- Live repo: `main` unprotected, 0 rulesets, `allow_auto_merge: false`, one user-owned board (`mtg-decks`, number 1); this Mac's git credential helper and HTTPS remote.
- Claude Code: `env` key, deny rules not a boundary, sandbox credential deny/mask, `allowUnsandboxedCommands`, `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` keeps GitHub tokens.

Taken on trust (**UNCONFIRMED**):

- Permissions for the GraphQL auto-merge mutation.
- GraphQL from an app installation token to a user-owned board failing.
- A third-party `gh` extension for minting app tokens.
- Whether `gh` complains about missing scopes when the token is in `GH_TOKEN`.
- Two-factor requirement for a machine account.
- Same-user processes reading `gh`'s keychain item without a prompt.
- Whether the Claude Code sandbox blocks keychain reads on macOS.
- Whether the sandbox mask works for `git push`, which sends the token Base64-encoded.
- Whether direnv runs in Claude Code's Bash tool.
- Whether a personal repo's ruleset bypass list offers Repository admin.
- Who is credited with an auto-merge enabled by the bot.
- The 2024-10-18 optional-expiry change details.
- That `gh repo delete` fails server-side for lack of `delete_repo` (not tested).
- That deny rules catch `$(gh auth token)` inside a substitution in practice.

## Sources

- Managing your personal access tokens: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens
- Permissions required for fine-grained personal access tokens: https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens
- Permissions required for GitHub Apps: https://docs.github.com/en/rest/authentication/permissions-required-for-github-apps
- REST API endpoints for Project items: https://docs.github.com/en/rest/projects/items
- Using the API to manage Projects: https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-api-to-manage-projects
- Managing access to your projects: https://docs.github.com/en/issues/planning-and-tracking-with-projects/managing-your-project/managing-access-to-your-projects
- Generating an installation access token: https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-an-installation-access-token-for-a-github-app
- Choosing permissions for a GitHub App: https://docs.github.com/en/apps/creating-github-apps/registering-a-github-app/choosing-permissions-for-a-github-app
- Deciding when to build a GitHub App: https://docs.github.com/en/apps/creating-github-apps/about-creating-github-apps/deciding-when-to-build-a-github-app
- GitHub Terms of Service: https://docs.github.com/en/site-policy/github-terms/github-terms-of-service
- Types of GitHub accounts: https://docs.github.com/en/get-started/learning-about-github/types-of-github-accounts
- Permission levels for a personal account repository: https://docs.github.com/en/account-and-profile/reference/permission-levels-for-a-personal-account-repository
- About protected branches: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches
- Available rules for rulesets: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets
- Creating rulesets for a repository: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/creating-rulesets-for-a-repository
- Approving a pull request with required reviews: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/approving-a-pull-request-with-required-reviews
- Automatically merging a pull request: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/automatically-merging-a-pull-request
- Changelog, fine-grained PATs GA (2025-03-18): https://github.blog/changelog/2025-03-18-fine-grained-pats-are-now-generally-available/
- Changelog, sub-issues GA (2025-04-09): https://github.blog/changelog/2025-04-09-evolving-github-issues-and-projects/
- Changelog, REST API for Projects (2025-09-11): https://github.blog/changelog/2025-09-11-a-rest-api-for-github-projects-sub-issues-improvements-and-more/
- Changelog, sub-issues and dependencies in `gh` 2.94.0 (2026-06-10): https://github.blog/changelog/2026-06-10-manage-sub-issues-types-and-dependencies-from-github-cli/
- `gh help environment`: https://cli.github.com/manual/gh_help_environment
- `gh auth login`: https://cli.github.com/manual/gh_auth_login
- `gh auth switch`: https://cli.github.com/manual/gh_auth_switch
- `gh auth token`: https://cli.github.com/manual/gh_auth_token
- `gh pr merge`: https://cli.github.com/manual/gh_pr_merge
- `cli/cli` auth config: https://github.com/cli/cli/blob/trunk/internal/config/config.go
- `cli/go-gh` token lookup: https://github.com/cli/go-gh/blob/trunk/pkg/auth/auth.go
- `zalando/go-keyring` macOS backend: https://github.com/zalando/go-keyring/blob/master/keyring_darwin.go
- Claude Code permissions: https://code.claude.com/docs/en/permissions
- Claude Code sandboxing: https://code.claude.com/docs/en/sandboxing
- Claude Code settings reference (`env`): https://code.claude.com/docs/en/settings-reference
- Claude Code environment variables: https://code.claude.com/docs/en/env-vars
