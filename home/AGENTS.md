# Global agent instructions

- Never use the em dash "—". Use plain dash "-" instead
- Never manually modify CHANGELOG.md files or any files that are marked as auto-generated
- When making technical decisions, do not give much weight to development cost.
  Instead, prefer quality, simplicity, robustness, scalability, and long term maintainability.
- For one-off or infrequent operational work, start with the simplest direct end-to-end path. Do not build wrappers, control planes, policy layers, custom verifiers, or automation unless the direct path exposes a concrete blocker or repeated need that justifies the added machinery.
- When doing bug fixes, always start with reproducing the bug in an E2E setting as closely aligned with how an end user would experience it as possible.
  This makes sure you find the real problem so your fix will actually solve it.
- When end-to-end testing a product, be picky about the UI you see and be obsessed with pixel perfection.
  If something clearly looks off, even if it is not directly related to what you are doing, try to get it fixed along the way.
- Apply that same high standard to engineering excellence: lint, test failures, and test flakiness.
  If you see one, even if it is not caused by what you are working on right now, still get it fixed.
- Before using "dynamic workflows", "ultra code" or any harness feature that immediately spawns a large swarm of subagents, always explain the tradeoffs and ask the user for explicit approval.

## Skills

Skills that should be installed, if not, install them.
- `shadcn` - add, search, compose, style, and debug shadcn/ui components; registries, presets, `--preset` codes, and any project with a `components.json`.
- `migrate-radix-to-base` - migrate a shadcn or React project from Radix UI to Base UI.
- `humanizer` - strip AI tells from writing so it reads as human-written.
- `chrome-devtools-axi` - drive a real Chrome session: navigate, inspect, screenshot, and debug a page.
- `gh-axi` - operate GitHub from the CLI: issues, PRs, CI runs, releases, Projects.
- `lavish` - turn a plan, diff, or report into a reviewable HTML artifact.

This set is reinstalled from `home.nix` on every rebuild, so a fresh machine ends up with the same skills.

## Git workflow

- Do not commit or push changes unless explicitly instructed.
- Never use `git add .`; stage only the files relevant to the current task.
- Before proposing a commit, run the appropriate tests and formatting checks.
- Show `git status --short` and summarize the staged diff.
- Use Conventional Commits messages (`type(scope): summary`). If a ticket ID (e.g. `GPP-123`) appears in the branch name or was given earlier in conversation, use it as the scope, e.g. `fix(GPP-123): fix for this thing`.
- Never auto-add your agent name as a commit co-author.
- Never amend, rebase, reset, force-push, or delete branches without explicit approval.