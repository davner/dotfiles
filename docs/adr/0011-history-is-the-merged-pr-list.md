# History is the merged PR list

Every change reaches `main` through a pull request, squash-merged with the PR title as the commit subject, so `git log --oneline` on `main` reads as one Conventional Commits line per change. Work is tracked as GitHub issues on this repo's board. There is no `CHANGELOG.md`: this repo ships no releases, so a changelog file would only repeat that log.

This replaces ADR 0008, where a `changelog.yml` workflow regenerated `CHANGELOG.md` with git-cliff and pushed it straight to `main`. Branch protection now requires a PR for every push, admins included, and the workflow's `GITHUB_TOKEN` cannot get past that. The alternatives were a token or app with admin rights stored as a secret, which undoes the protection, or regenerating the file inside each PR, where any two open PRs conflict on it.

## Consequences

- A PR title is the history entry, so it follows the commit-message rules: one Conventional Commits subject, imperative, at most 72 characters.
- `main` takes no direct pushes, from agents or from the user. A fix lands through a PR like anything else.
- A PR opened by a workflow with `GITHUB_TOKEN` starts no other workflow, so its required `test` check would never report. `update.yml` starts `test.yml` on its branch with `gh workflow run`: `workflow_dispatch` and `repository_dispatch` are the only events that token may trigger.
- Local work lives on a branch, so a plain `git pull` on `main` only ever fast-forwards.
