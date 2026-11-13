---
name: grilling
description: Grill the user relentlessly about a plan, decision, or idea. Use when the user wants to stress-test their thinking, or uses any 'grill' trigger phrases.
---

Interview the user relentlessly until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it.

The tree's **root** is the need: what needs this to exist, and what breaks without it. The first round always asks the root, with the **prior art** beside it: what established tools do for the same need, which you look up. Every how-question hangs off the root, so it waits for the root's answer: a settled root often moves or cuts whole branches.

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are already settled: the questions you can ask _now_ without guessing at answers you haven't heard yet. Ask the whole frontier in one round: number each question and give your recommended answer. Then wait for the user's answers before the next round.

Format a round like so:

```
❓ **Q1** - **<question title>**: <question body, might be multiple paragraphs, including multiple choices>

➡️ <your recommended answer>

---

❓ **Q2** - **<question title>**: <question body, might be multiple paragraphs, including multiple choices>

➡️ <your recommended answer>
```

Each round the user answers reshapes the tree: settled decisions push the frontier outward and unblock questions that depended on them. Recompute the frontier and ask the next round. A question whose answer depends on another question still open in this round belongs to a _later_ round, not this one.

Finding _facts_ is your job, never the user's. When a frontier question needs a fact from the environment (filesystem, tools, etc.), dispatch a sub-agent to find it; don't ask the user for anything you could look up yourself. Don't block on it: a running exploration is an unsettled prerequisite, so only the questions downstream of it wait for the sub-agent to report; ask the rest of the frontier now. The _decisions_ are the user's: put each to them and wait.

In a repo, read the open items of the TODO list (the one the tracker file names, else `.scratch/TODO.md`) before the first round, and say which ones touch this plan. When a branch turns out to be separate work rather than part of this plan, take it off the tree and add it to that TODO list in the entry format the tracker file gives (in a repo without one, the format in `setup-dan-skills/issue-tracker.md`), telling the user; outside a repo, list such work at the end instead.

The session is done when the frontier is empty: every branch of the design tree visited, nothing left silently assumed. Do not act on it until the user confirms you have reached a shared understanding.

## When headless:

When the conversation has said the run is headless, nobody will answer. Put each round's frontier to yourself and settle every question with the confidence rule, in place of waiting. The grill ends when the frontier is empty or a question parks.

**Confidence rule.** Take the checks in order. A **park** ends the grill: stop, and say which question parked, its options, and why.

1. Hard to undo (deletes or migrates data, changes a public interface or file format, touches secrets, permissions or money, reaches outside the repo): park. Nothing below overrides this.
2. Evidence: your recommendation names a file and line, a test, or a doc or ADR rule, and your own tool call confirms it. If it settles the question, decide. If the cited thing does not say what was claimed, park.
3. Runnable options: when every option is code, write 3 to 5 versions and run them on the same inputs. Different outputs park.
4. Vote: 5 fresh Haiku or Sonnet voters, each given the question, the labelled options and the evidence, never your pick, each returning one label and nothing else. 5 of 5 for your pick: decide. 4 of 5: decide if cheap to undo, else ask 5 more and decide at 9 or 10 of 10. 3 or fewer, or a majority for another option: park. At most 50 voters per run; after that, every undecided question parks.
5. Your stated confidence only breaks a tie.

**Research.** Facts still come from subagents: Haiku `Explore` agents for the repo, Sonnet agents for the web and prior art (standard search first, extended only when it comes back thin, about 10 sources each). One round per question. A finding is evidence only when it cites a file and line, a URL or a test that you confirm with one tool call. Research agents count toward the run's agent cap of about 10; voters do not.

**Decision log.** Append every question you settle or park to `.scratch/<feature-slug>/decisions.md` in the main checkout (`dirname "$(git rev-parse --path-format=absolute --git-common-dir)"`): the question, the options, the pick, the step that settled it (the evidence with its citation, the run comparison, or the vote count), and why. Mark a parked question parked.

The evidence behind these checks and cut-offs is in `~/.dotfiles/docs/research/agent-decision-confidence.md`, and the limit on repair attempts in `~/.dotfiles/docs/research/agent-retry-limits.md`. The cut-offs are starting points that no study tested on design decisions.
