# Changelog templates

Files `setup-dan-skills` copies into a GitHub repo when the user accepts a
changelog. Pick one set: towncrier when the repo ships releases, git-cliff when
it does not.

## Placeholders

Setup replaces every occurrence before writing the file.

| Placeholder | Filled with | Example |
| --- | --- | --- |
| `__GITHUB_REPO__` | `gh repo view --json nameWithOwner -q .nameWithOwner` | `davner/proj` |
| `__DEFAULT_BRANCH__` | `gh repo view --json defaultBranchRef -q .defaultBranchRef.name` | `main` |

## towncrier (ships releases)

| Template | Goes to | Placeholders |
| --- | --- | --- |
| `towncrier/towncrier.toml` | `towncrier.toml` | `__GITHUB_REPO__` |
| `towncrier/changelog-check.yml` | `.github/workflows/changelog-check.yml` | `__DEFAULT_BRANCH__` |
| `towncrier/release.yml` | `.github/workflows/release.yml` | `__DEFAULT_BRANCH__` |

Setup also creates an empty `changes/.gitkeep`, so the fragment folder exists
before the first fragment. A fragment is `changes/<issue#>.<type>.md`, with type
one of `breaking`, `feat`, `fix`, `perf`, `docs`, `chore`.

`CHANGELOG.md` needs the line `<!-- towncrier release notes start -->`; each
release is written below it. With no `CHANGELOG.md`, setup writes
`# Changelog`, a blank line, and that marker. With one, setup puts the marker
above the first existing entry, so old entries stay below the new ones.

- **Check job:** `towncrier-check` in workflow `changelog-check`. This is the
  check name setup passes to `repo-settings.sh` as a required check. It is
  skipped, which GitHub counts as passing, when the PR has the `skip-changelog`
  label.
- **Release job:** `release` in workflow `release`, run by hand with a
  `version` input such as `1.4.0`. It builds the changelog, commits
  `chore(release): v<version>`, tags `v<version>` and pushes both.

## git-cliff (no releases)

| Template | Goes to | Placeholders |
| --- | --- | --- |
| `git-cliff/cliff.toml` | `cliff.toml` | `__GITHUB_REPO__`, `__DEFAULT_BRANCH__` |
| `git-cliff/changelog.yml` | `.github/workflows/changelog.yml` | `__DEFAULT_BRANCH__` |

- **Job:** `regenerate` in workflow `changelog`, on every push to the default
  branch. It is not a PR check, so it is never a required check.
