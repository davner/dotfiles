---
type: research
updated: 2026-11-13
---

# How many times an unattended agent should try to fix a failing check

2026-11-13. Question: an unattended LLM coding agent (a Claude Code session driven by skills) meets a failing check: a failing test, a lint or type error, a red CI job, or a code-review finding. How many fix attempts should it make before it stops and hands the problem to a human, so it wastes few tokens without giving up on fixes that would have worked? Grounded in published evidence.

This follows `agent-decision-confidence.md`, whose rule 6 said "park after 2 failed attempts at the same step", citing OpenAI's agent guide and marking the number 2 as the author's own choice. This note checks that number against token cost and success.

Tags: **UNCONFIRMED** marks a claim I could not check at its primary source this session, or a judgment of mine. Every paper below was read from its arXiv PDF (text extracted locally with pypdf). The Claude Code docs were read from their Markdown source, the Anthropic post from its HTML, the OpenAI guide from its PDF. Venues are given only where the PDF header states them; others are marked.

## Answer

- **Most of the gain comes from the first repair attempt.** Self-Debug: "typically one debugging turn is sufficient, and the accuracy improvement after one turn is within 0.1%" (Spider); on code translation "the major improvement comes from the first debugging turn". Self-Refine: the first round gives the biggest jump (Code Optimization 22.0 -> 27.0, then 27.9, 28.8). Debugging Decay Index: "most models lose 60-80% of their debugging capability within just 2-3 attempts".
- **The odds of recovery fall sharply after the first failure.** SWE-agent (NeurIPS 2024): an edit has a 90.5% chance of eventually succeeding; after one failed edit, 57.2%. Successful recoveries took about 2 attempts (2.03 on resolved runs, 2.2 overall); failed ones ran 4.22-5.59 attempts before the agent gave up.
- **Agents succeed quickly and fail slowly.** SWE-agent: successful runs had a median cost of $1.21 and 12 steps, unsuccessful ones a mean of $2.52 and 21 steps; 93.0% of resolved runs finished before the budget ran out, so the authors "suspect that increasing the maximum budget or token limit are unlikely to substantially increase performance".
- **At equal tokens, a fresh attempt often beats more repair on the same attempt.** Olausson et al. (ICLR 2024): self-repair's gains are "often modest ... and are sometimes not present at all" once cost is counted; budget is better spent on diverse first attempts than on "extensive repair". Kapoor et al.: plain retry with the test as signal matched or beat Reflexion and LDB at lower cost on HumanEval.
- **A fresh context beats a long one after a few failures.** Debugging Decay Index: clearing history and restarting from the problem statement at the decay point raised accuracy for most models at the same attempt budget and similar or fewer tokens (preprint, small models). Laban et al.: "when LLMs take a wrong turn in a conversation, they get lost and do not recover"; they advise starting a new conversation and consolidating what was learned. Claude Code's own docs: "after two failed corrections run `/clear` and write a better prompt instead of a third."
- **Feedback quality decides whether repair works at all.** Olausson: self-repair is "bottlenecked by the model's ability to provide feedback"; human explanations raised the repair rate 1.58x (33.3% -> 52.6%). Self-Debug: richer feedback with execution results helps most; without execution, GPT-3.5 and GPT-4 "tend to be overconfident in their own initial predictions". Huang et al. (ICLR 2024): without an outside correctness signal, self-correction lowered accuracy on every benchmark tried.
- **No vendor gives a number.** OpenAI's guide says "set limits on agent retries" without a value. Anthropic says agents commonly include "stopping conditions (such as a maximum number of iterations)". Only Claude Code's best-practices page names a count: two failed corrections, then start fresh.

The proposed rule is in section 6.

## 1. Returns per repair round

### 1.1 Olausson et al., ICLR 2024, "Is Self-Repair a Silver Bullet for Code Generation?"

https://arxiv.org/abs/2306.09896

- Setup: generate programs, run unit tests, a feedback model explains the failure, a repair model rewrites. Compared with drawing more samples i.i.d. (independent fresh samples) "at an equivalent compute budget", measured in tokens. HumanEval and APPS, Code Llama 13B, GPT-3.5, GPT-4.
- "When the cost of carrying out repair is taken into account, performance gains are often modest, vary a lot between subsets of the data, and are sometimes not present at all." Self-repair loses to plain resampling "especially when the budget is small".
- Width of repair does not pay: "fixing np and increasing nfr ... does not appear to be worth the additional cost incurred, giving marginal gains at higher budgets and oftentimes even decreasing performance at lower budgets"; nfr = 1 (one repair per failing program) was "the best overall choice". GPT-4 on APPS: 10 first attempts + 1 repair each = 1.05x the resampling baseline; 2 first attempts + 10 repairs each = 0.97x.
- "The most important factor ... is the diversity of the base samples that are generated up-front, rather than the diversity of the repairs sampled."
- Gains were larger on harder problems (GPT-3.5 up to +34% relative on competition-level APPS) and smaller near the ceiling.
- Appendix A.2 models a chat user "who spends some time trying to get the assistant to debug it, before finally giving up and starting over from scratch in a new session" as depth-first search; there "self-repair appears to be somewhat less beneficial".
- Limits: self-contained Python puzzles with a test suite; the main experiments use one round of repair, not several sequential rounds; 2023 models.

### 1.2 Chen et al., "Teaching Large Language Models to Self-Debug"

https://arxiv.org/abs/2304.05128 (venue **UNCONFIRMED**; the PDF header does not say)

- Max 10 debugging turns, but "empirically the successful debugging processes mostly end within 3 turns".
- Spider: "typically one debugging turn is sufficient, and the accuracy improvement after one turn is within 0.1%". Code translation: "the major improvement comes from the first debugging turn", about +12% over greedy.
- Repair can beat resampling here: on Spider, debugging a single greedy sample matched the 16-sample baseline. This is the opposite sign to Olausson on a different task and model, which is why the per-round evidence matters more than the repair-vs-resample verdict.
- Feedback ablation (Table 2): unit-test feedback beats a bare "this is wrong" (MBPP GPT-4: 72.8 baseline, 78.8 simple, 80.6 with unit tests). Without execution (Table 3) gains shrink to about 1-4%, and GPT-3.5/GPT-4 "tend to be overconfident in their own initial predictions".

### 1.3 Madaan et al., "Self-Refine"

https://arxiv.org/abs/2303.17651 (NeurIPS 2023 venue **UNCONFIRMED**)

- Up to 4 iterations. Per-round scores (Figure 4): Code Optimization 22.0, 27.0, 27.9, 28.8; Constrained Generation 29.0, 40.3, 46.7, 49.7. The paper names "the diminishing returns in the improvement as the number of iterations increases"; on multi-aspect tasks quality "may not always monotonically increase".
- Feedback quality (Table 2): specific feedback vs generic vs none: Sentiment Reversal 43.2 / 31.2 / 0; Code Optimization 27.5 / 26.0 / 24.8.
- Against 4 plain samples, humans preferred the refined output. Their feedback came from the same LLM, but on preference tasks without a pass/fail check, so it does not transfer to failing checks directly.

### 1.4 Shinn et al., "Reflexion"

https://arxiv.org/abs/2303.11366 (venue **UNCONFIRMED**)

- Verbal reflection on test failures, memory capped at 1-3 reflections. HumanEval pass@1 91% vs GPT-4 80%. On AlfWorld the no-reflection baseline stopped improving "between trials 6 and 7".
- Its own tests can mislead: on MBPP Python, 16.3% of solutions passed the self-written tests yet were wrong, and Reflexion scored below the base model (77.1 vs 80.1). Without test feedback the agent did worse than the baseline (52% vs 60%) "performing harmful edits".
- No token cost is reported; Kapoor et al. (2.2) measure it.

### 1.5 Huang et al., ICLR 2024, "Large Language Models Cannot Self-Correct Reasoning Yet"

https://arxiv.org/abs/2310.01798

- Reflexion-style gains depend on "oracle labels" (being told the answer is wrong). Without them, two rounds of self-correction lowered accuracy everywhere: GPT-4 GSM8K 95.5 -> 91.5 -> 89.0, HotpotQA 49.0 -> 49.0 -> 43.0, at 3 and 5 model calls vs 1.
- Multi-agent debate was "no better than self-consistency ... when considering an equivalent number" of responses.
- The authors exempt code with unit tests: "the code executor serves as the perfect verifier".
- Bearing on this question: a failing test is an oracle; an LLM review finding is not.

### 1.6 Adnan and Kuhn 2025, "The Debugging Decay Index"

https://arxiv.org/abs/2506.18403 (preprint)

- Fits debugging effectiveness per attempt to an exponential decay; "most models lose 60-80% of their debugging capability within just 2-3 attempts". Literature review lines: LDB's extra 15 attempts after the fifth added 2.4%; PyCapsule found GPT-4's debugging effectiveness exhausted by the third attempt (both relayed, not read at source: **UNCONFIRMED**).
- Fresh starts ("completely clears conversation history and begins anew with only the original problem statement") at the decay point, inside the same 6-attempt budget: e.g. llama3.1:8b 72.6 -> 82.3, deepseek-coder-v2:16b 84.1 -> 92.1; tokens similar or lower (DeepSeek 108,289 -> about 89,000).
- Weak points: HumanEval only, small open models, not peer reviewed. The text says "six models evaluated, all showed performance improvements" but Table 2 lists nine, and some got worse at one threshold (codestral 89.0 -> 88.4, devstral 94.5 -> 93.9). The decay constants are dataset-specific by the authors' own account.

## 2. Agent benchmarks: turns, cost and success

### 2.1 Yang et al., NeurIPS 2024, "SWE-agent"

https://arxiv.org/abs/2405.15793

- $4 per-instance budget; past it, edits were auto-submitted.
- "Agents succeed quickly and fail slowly": resolved runs median $1.21 / 12 steps; unresolved mean $2.52 / 21 steps; 93.0% of resolved runs finished inside budget vs 69.0% of all runs; raising the budget is "unlikely to substantially increase performance".
- Failed edits here are edits rejected by the linter, so this is the closest data to "fix a lint error". P(edit eventually succeeds) = 90.5% with no prior failure, 57.2% after one. Recoveries took about 2 consecutive attempts; unsuccessful streaks ran 4.22 (resolved runs) to 5.59 (all runs). "Cascading failed edits" were 23.4% of failures.
- "If a language agent's initial problem solving approach, typically reflected in the first 10 to 20 turns, does not yield a good solution, it struggles to make use of later turns that build upon past mistakes."
- Limits: GPT-4 Turbo and Claude 3 Opus, 2024.

### 2.2 Kapoor et al. 2024, "AI Agents That Matter"

https://arxiv.org/abs/2407.01502 (venue **UNCONFIRMED**)

- Argues agent evaluations "must be cost-controlled", since accuracy "can be improved by scientifically meaningless methods such as retrying".
- HumanEval baselines: Retry (up to 5 times at temperature 0 when the given tests fail), Warming (same, temperature rising to 0.5), Escalation (cheap model first, stronger model on failure).
- Table A1 (5 runs, 164 problems, total USD): Warming GPT-4 93.2% / $2.45; Retry GPT-4 92.0% / $2.51; Reflexion GPT-4 87.8% / $3.90; LDB GPT-4 93.3% / $6.36; LATS GPT-4 88.0% / $134.50; Escalation 85.0% / $0.27; plain GPT-4 89.6% / $1.93.
- "Whether debugging, reflection, and other such 'System 2' approaches are useful for code generation remains open"; they may help on harder tasks such as SWE-bench (not tested).

### 2.3 Xia et al., "Agentless"

https://arxiv.org/abs/2407.01489 (venue **UNCONFIRMED**)

- No agent loop: localize, sample candidate patches, filter by regression and reproduction tests, majority vote. 32.00% on SWE-bench Lite at $0.70 per issue.
- Gains plateau at about 40 patch samples because selection cannot use later ones; with perfect selection, 42.0% of issues had a correct patch somewhere. The limit is choosing among attempts, not making more.

### 2.4 Brown et al. 2024, "Large Language Monkeys"

https://arxiv.org/abs/2407.21787 (venue **UNCONFIRMED**)

- Repeated sampling on SWE-bench Lite: DeepSeek-Coder-V2 coverage 15.9% at 1 sample -> 56% at 250. Coverage means some sample passes the hidden tests, i.e. an oracle verifier.
- Without an automatic verifier, majority voting and reward models "plateau beyond several hundred samples".
- Bearing: when the failing check itself is the verifier, independent fresh attempts keep paying, at a token cost that grows linearly. The 250-sample scale is far beyond what an unattended session should spend on one check.

### 2.5 OpenHands (Wang et al., ICLR 2025)

https://arxiv.org/abs/2407.16741

- Read for attempt or iteration findings; the paper reports none relevant here. Its stuck-detection code was not checked (**UNCONFIRMED**).

## 3. Feedback quality and fresh context

### 3.1 Feedback quality

- Clear external signal (failing test with output, compiler or linter error): repair works and the first round carries most of the gain (Self-Debug Table 2; Reflexion's Rust ablation on "verbose error logs").
- Self-generated or vague signal: small or negative returns. Huang (no oracle: accuracy drops), Self-Debug Table 3 (no execution: 1-4%), Self-Refine Table 2 (generic feedback much weaker), Reflexion (16.3% false-positive self-tests on MBPP).
- Better explanations lift repair more than more attempts do: Olausson's stronger-model feedback "beats both the corresponding i.i.d. baseline and the corresponding self-repair configuration at all budgets"; human feedback 1.58x.
- No study measures code-review findings specifically. Treating an LLM review finding as "feedback without an oracle" is my mapping (**UNCONFIRMED**).

### 3.2 Fresh context vs continuing

- For a fresh restart: Debugging Decay Index (restart beats continuing at equal budget, preprint); Laban et al. 2025, https://arxiv.org/abs/2505.06120 (preprint): 39% average drop in multi-turn settings, "persisting in a conversation with the model is ineffective", and "Consolidate before retrying": carry a summary of the requirements into a new conversation; Olausson: diversity of first attempts beats depth of repair.
- Against delegating blindly: Claude Code best practices: "Handing the same task to a subagent doesn't make the answer any better. A fresh reviewer does help, because it hasn't seen your reasoning." A fresh subagent also re-gathers context, which costs tokens.
- Where the line falls: no study tests "fresh context on the first retry". Debugging Decay restarts at the decay point, Claude Code says after two failed corrections, Laban after the conversation "did not lead to expected outcomes". So: continue for the first retry, go fresh after that (**UNCONFIRMED** as optimal).
- Laban's multi-turn setting is a user revealing requirements over turns, not test feedback; the transfer to a repair loop is partial (**UNCONFIRMED**).

## 4. Vendor guidance

- Claude Code, Best practices (https://code.claude.com/docs/en/best-practices): "after two failed corrections run `/clear` and write a better prompt instead of a third", because "a third correction mostly adds to a conversation that already contains two failed attempts for Claude to keep re-reading. `/clear` plus one new prompt that folds in what you learned works better almost every time." Also: give Claude "something it can run that comes back pass or fail"; reviews by "someone who didn't write the code" in a fresh subagent. This is guidance, not a published measurement.
- Claude Code, Hooks (https://code.claude.com/docs/en/hooks): Stop hooks that block are capped at 8 consecutive continuations (`CLAUDE_CODE_STOP_HOOK_BLOCK_CAP`), and the docs say to check `stop_hook_active` "to avoid blocking on a condition that will never resolve". This is a runaway guard, not a retry recommendation.
- Anthropic, Building effective agents (https://www.anthropic.com/engineering/building-effective-agents): agents "pause for human feedback at checkpoints or when encountering blockers", with "stopping conditions (such as a maximum number of iterations)". No number.
- OpenAI, A practical guide to building agents (https://cdn.openai.com/business-guides-and-resources/a-practical-guide-to-building-agents.pdf): "Exceeding failure thresholds: Set limits on agent retries or actions ... escalate to human intervention"; "For a coding agent, this means handing control back to the user." No number. The earlier note's "2" did not come from this guide.

## 5. What carries over to a Claude Code session, and what does not

- The repair papers use single functions with given tests and 2023-2024 models; SWE-agent and Agentless use real repositories but 2024 models. Frontier models in 2026 may repair better and decay later. The shape (first round best, fast decay, fresh start helps) is consistent across all of them; the exact counts are not portable (Debugging Decay authors say so).
- A failing check in a repo differs from a benchmark: the check may itself be wrong (flaky test, broken CI runner, a finding that is mistaken). No study here measures flaky CI or infrastructure failures (**UNCONFIRMED** territory).

## 6. Proposed rule

Count attempts per failing check, keyed by the check name and its first error line, across the whole run (so the same failure reappearing later is not a fresh budget).

1. **Attempt 1, same context, with the full check output.** Read the actual error or failing assertion, fix, rerun. Most of the gain is here (Self-Debug "within 0.1%" after one turn; Self-Refine round 1; SWE-agent 90.5% first-try success).
2. **Attempt 2, same context, only if attempt 1 changed the failure** (different error, fewer failing tests). If the failure is identical, skip to step 3. Recovery after a failure drops to 57.2% and real recoveries took about 2 tries (SWE-agent); the progress gate is my inference (**UNCONFIRMED**).
3. **Attempt 3, fresh context.** A new subagent gets a consolidated brief: the task, the check command, its current output, and one line per failed attempt saying what was tried and why it failed. Not the transcript. Sources: Claude Code "after two failed corrections ... `/clear` and write a better prompt"; Laban "consolidate before retrying"; Debugging Decay fresh starts; Olausson on diversity over depth.
4. **Then park.** Write up the check, the output, the three attempts, and the best hypothesis for the human. More attempts in the same failing approach are where SWE-agent's failures spend their extra cost ($2.52 vs $1.21).

By check type:

| Check | Feedback | Attempts before parking | Notes |
|---|---|---|---|
| Lint, format, type error | Exact, local | 3 as above; run the tool's auto-fix first if it has one | SWE-agent lint-recovery data is the closest match. Auto-fix first is my inference (**UNCONFIRMED**). |
| Failing test with assertion output | Exact, oracle | 3 as above | Self-Debug, Reflexion, Huang's "perfect verifier" exemption. Before editing the test itself, park: changing the check is not fixing it (**UNCONFIRMED** policy). |
| Red CI job | Mixed | Reproduce locally first. Reproduces: treat as the test or lint row. Does not reproduce: one rerun, then park | No primary data on flaky or infra failures (**UNCONFIRMED**). |
| Code-review finding (LLM reviewer) | No oracle | 1 attempt, then a fresh reviewer that did not see the fix reasoning rechecks that finding; still open, park | Huang (no oracle, self-correction hurts); Self-Refine (vague feedback weak); Olausson (feedback quality is the bottleneck); Claude Code (fresh reviewer helps). Where possible, first turn the finding into a failing test, which moves it to the test row (**UNCONFIRMED** as measured). |

**Token cap as a backstop, not the main stop.** Attempt counts do most of the work; SWE-agent shows that raising the budget barely helps. Set the per-check cap from your own logs at about twice the median tokens of fixes that succeeded, following SWE-agent's 2x cost gap between successful and failed runs. The ratio is borrowed from one study and the cap must be measured locally (**UNCONFIRMED** as a threshold). Never rely on the Stop hook's 8-continuation cap as the retry limit; it exists to stop runaway loops.

**Calibrate.** Log per check: type, attempts, which attempt fixed it, tokens. If the fresh attempt (3) almost never succeeds, drop it; if attempt-3 fixes are common, the checks may deserve a fourth. The Debugging Decay authors say decay rates must be fit per dataset.

### What the evidence does NOT support

- A universal attempt number. Every count above is a starting point; no study tested frontier 2026 models in a real repo repair loop.
- That OpenAI's guide recommends 2. It gives no number.
- That more than 2-3 attempts in one context pays off. Every source shows sharp decay; none shows a late rebound.
- That a fresh subagent beats continuing on the first retry. No study tests that; the docs say delegating the same task does not improve the answer.
- That repair always beats resampling, or the reverse. Olausson and Self-Debug disagree depending on task and model.
- That self-review without an outside signal fixes anything. Huang shows it can make answers worse.
- Any data on flaky tests, broken CI infrastructure, or human code-review findings.
- That the Debugging Decay fresh-start gains hold for large models; it tested small open models and its text and table disagree.

## Sources

- Olausson et al. ICLR 2024: https://arxiv.org/abs/2306.09896
- Chen et al. Self-Debug: https://arxiv.org/abs/2304.05128
- Madaan et al. Self-Refine: https://arxiv.org/abs/2303.17651
- Shinn et al. Reflexion: https://arxiv.org/abs/2303.11366
- Huang et al. ICLR 2024: https://arxiv.org/abs/2310.01798
- Adnan and Kuhn 2025, Debugging Decay Index: https://arxiv.org/abs/2506.18403
- Yang et al. SWE-agent, NeurIPS 2024: https://arxiv.org/abs/2405.15793
- Kapoor et al. AI Agents That Matter: https://arxiv.org/abs/2407.01502
- Xia et al. Agentless: https://arxiv.org/abs/2407.01489
- Brown et al. Large Language Monkeys: https://arxiv.org/abs/2407.21787
- Wang et al. OpenHands, ICLR 2025: https://arxiv.org/abs/2407.16741
- Laban et al. 2025, LLMs Get Lost in Multi-Turn Conversation: https://arxiv.org/abs/2505.06120
- Claude Code, Best practices: https://code.claude.com/docs/en/best-practices
- Claude Code, Hooks: https://code.claude.com/docs/en/hooks
- Anthropic, Building effective agents: https://www.anthropic.com/engineering/building-effective-agents
- OpenAI, A practical guide to building agents: https://cdn.openai.com/business-guides-and-resources/a-practical-guide-to-building-agents.pdf
