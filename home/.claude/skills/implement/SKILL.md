---
name: implement
description: "Implement a piece of work based on a spec or set of tickets."
disable-model-invocation: true
---

Implement the work described by the user in the spec or tickets.

Use /tdd where possible, at pre-agreed seams.

Run typechecking regularly, single test files regularly, and the full test suite once at the end.

Build user interface work through `impeccable`, and check it once on desktop and on mobile in Chrome device emulation.

Once done, use /code-review to review the work.

Commit your work to the current branch. When that is the repo's default branch, create a branch for the work first and commit there.
