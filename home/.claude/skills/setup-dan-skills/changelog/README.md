# Changelog templates

Files `setup-dan-skills` copies into a GitHub repo when the user accepts a
changelog. They are for a repo that ships releases; a repo without releases
gets no changelog setup.

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
- **Release job:** `release` in workflow `release`, on every push to the
  default branch. It runs only when the head commit's subject is
  `chore(release): v<version>`, optionally followed by the ` (#<PR>)` a squash
  merge appends. It then creates tag and GitHub release `v<version>` at that
  commit with `gh release create --target`, using that version's section of
  `CHANGELOG.md` as the notes. It writes no commit, so branch protection never
  blocks it. It fails when the tag already exists or `CHANGELOG.md` has no
  section for the version. It is not a PR check, so it is never a required
  check.

## Releasing

A release is a PR, so the changelog lands through the same review and
protection as any change. The agent or the user runs, from an up-to-date
default branch:

1. `git switch -c release-v<version>`, with `<version>` semver and no leading
   `v`, such as `1.4.0`.
2. `uvx towncrier build --yes --version <version>`. It writes the release into
   `CHANGELOG.md` and deletes the fragments in `changes/`.
3. Commit everything that moved, as the branch's one commit:
   `chore(release): v<version>`.
4. Open a PR with that same title and the `skip-changelog` label, since a
   release carries no fragment of its own.
5. Merge it by squash or rebase, so the default branch's head commit keeps the
   title as its subject. A merge commit's subject is `Merge pull request ...`,
   and the release workflow would not run.

The `release` job then tags and publishes `v<version>`.
