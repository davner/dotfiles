---
type: research
updated: 2026-11-13
---

# When an unattended agent should park a design decision

2026-11-13. Question: an LLM coding agent runs grill -> spec -> tickets -> implement -> code review with no human present. It asks itself design questions and takes its own recommendation. Which decisions should it flag as "low confidence" and park for a human, using signals that published studies back, not the model's own feeling? The agent runs inside Claude Code: it can spawn subagents, run tools and read the repo, but cannot read token logprobs (the model's probability for each output token).

Tags: **UNCONFIRMED** marks a claim I could not check at its primary source this session, or a judgment of mine. Every paper below was read from its arXiv PDF (text extracted locally) or its publisher full text, except where a line says "abstract page only".

## Answer

- **Do not trust a stated percentage on its own.** Verbalized confidence (the model writing "I'm 90% sure") is overconfident and poor at telling right answers from wrong ones. Xiong et al. (ICLR 2024) found stated values bunch in 80-100% in multiples of 5, and on GSM8K the verbalized score separated right from wrong at AUROC 54.8%, about a coin flip. Tian et al. (EMNLP 2023) found verbalized scores *better calibrated than token probabilities* for RLHF models, but only on short factual recall, and they say reasoning tasks are an open question.
- **Agreement across independent samples is the best black-box signal the literature offers.** Self-consistency (Wang et al., ICLR 2023): the share of samples agreeing with the majority answer is "highly correlated with accuracy", so "low consistency" means low confidence. Xiong et al.: 5 samples with consistency aggregation raised GSM8K AUROC from 54.8% to 92.7%. Semantic entropy (Farquhar et al., Nature 2024) does the same over meanings, works without probabilities in its "discrete" form, and uses 10 samples.
- **Sample counts: 5 is the floor the studies use, 10 is the Nature setting.** Wang et al.: "5 or 10" paths get "most of the gains". SelfCheckGPT: performance rises with samples, with diminishing gains, up to 20. Xiong et al. fixed M = 5.
- **Agreement is not correctness.** Farquhar et al. say semantic entropy "does not help when LLM outputs are systematically bad". Kim et al. (2025) found that when two models both err, they agree 60% of the time on one leaderboard, and larger, more accurate models are more correlated. Same-model subagents share every bias, so unanimity can be a shared mistake.
- **Reversibility is a separate gate, not a confidence signal.** OpenAI's agent guide: actions that are "sensitive, irreversible, or have high stakes" go to a human "until confidence in the agent's reliability grows", and tools get a low/medium/high risk rating from read-only vs write, reversibility, permissions and financial impact.
- **Grounding in the repo is the strongest signal but the least measured.** Anthropic says agents must get "ground truth" from the environment at each step. ClarifyGPT decides a requirement is ambiguous by running sampled code on the same inputs and comparing outputs. Kadavath et al. found the model's "I know" estimate rises when source material is in context. No study measures "the answer cites a file" as a confidence signal for design choices (**UNCONFIRMED** as a measured effect; it is my inference).
- **Models are poor at noticing what is underspecified.** Ambig-SWE (ICLR 2026): models "struggle to distinguish between well-specified and underspecified instructions"; only Claude Sonnet 4 (89%) and Sonnet 3.5 (84%) did well. Asking, when it happened, raised resolve rates by up to 74%. So "ask the model whether it should ask" is a weak trigger by itself.
- **Every threshold must be tuned on your own decisions.** The two methods that give guarantees, selective classification (Geifman and El-Yaniv 2017) and KnowNo's conformal prediction (Ren et al. 2023), both set the cut-off from a labelled calibration set. No paper gives a threshold that carries over to design decisions.

The proposed rule is in section 6.

## 1. Verbalized confidence

### 1.1 Kadavath et al. 2022, "Language Models (Mostly) Know What They Know" (Anthropic)

https://arxiv.org/abs/2207.05221

- Larger models are well calibrated on multiple-choice and true/false questions in the right format. Self-evaluation: sample an answer, then ask "Is the proposed answer: (A) True (B) False" and read P(True).
- **P(True) is the token probability of "(A)"**, not a number the model writes (section 4 prompt format). So it needs logprobs and does not apply directly here. Farquhar et al. (methods) approximate it black-box by running the True/False prompt 10 times at temperature 1 and taking the fraction of "yes"; that version is usable from Claude Code.
- "Brainstorming other possibilities" helps: self-evaluation improves when the model sees many of its own samples before judging one.
- P(IK) ("probability I know") needs a trained value head; it generalizes partly and "struggle[s] with calibration of P(IK) on new tasks". It rises when source material or hints are in the context.

### 1.2 Xiong et al., ICLR 2024, "Can LLMs Express Their Uncertainty?"

https://arxiv.org/abs/2306.13063

- LLMs "tend to be highly overconfident when verbalizing their confidence"; values "predominantly fall within the 80% to 100% range and are typically in multiples of 5". Many wrong answers sit in the 100% bar (appendix figure).
- Prompting tricks (CoT, multi-step, Top-K) reduce calibration error (ECE: average gap between stated confidence and actual accuracy) but "failure prediction still remains a challenge". For parking, failure prediction (AUROC: how well the score ranks wrong answers below right ones) is the metric that matters, not ECE.
- Table 3 (GPT-3.5, M = 5): verbalized CoT with one sample averages AUROC 56.4; Self-Random sampling with consistency aggregation averages 73.0; on GSM8K 54.8 -> 92.7. On professional law it stays weak (around 60-66).
- Mixing verbalized confidence into the vote (Avg-Conf, Pair-Rank) helps "when LLM queries are costly" (M = 5): "Verbalized confidence, albeit imprecise, reflects the model's uncertainty tendency and can enhance results when combined with ensemble methods."
- Sampling by "misleading" cues ("I think the answer might be ...") measures whether the model wavers; it worked on arithmetic (AUROC 88.6 on GSM8K) and less elsewhere.
- Limits: tasks where "the ground truth answer is unique"; summarization and open-ended tasks left for future work. Their practitioner pick: Top-K prompt + Self-Random sampling + Avg-Conf or Pair-Rank.

### 1.3 Tian et al., EMNLP 2023, "Just Ask for Calibration"

https://arxiv.org/abs/2305.14975

- For RLHF models (ChatGPT, GPT-4, Claude), verbalized confidence is "typically better-calibrated than the model's conditional probabilities", "often reducing the expected calibration error by a relative 50%" on TriviaQA, SciQ, TruthfulQA.
- Limits stated by the authors: factual recall only; "the extent to which our observations would hold for reasoning-heavy settings is an interesting open question"; short-form QA only; 1-stage vs 2-stage prompts "sometimes differ drastically".
- Reconciling with Xiong: Tian measures calibration against token probabilities on recall; Xiong measures discrimination on reasoning and finds it near chance. A design decision is closer to Xiong's setting.

## 2. Sampling consistency without logprobs

### 2.1 Self-consistency, Wang et al., ICLR 2023

https://arxiv.org/abs/2203.11171

- Sample several reasoning paths, take the majority answer. Ablation over 1, 5, 10, 20, 40 paths: more is better, but "a small number of paths (e.g., 5 or 10) ... realize most of the gains", "performance saturates quickly" (section 5).
- "The consistency (in terms of % of decodes agreeing with the final aggregated answer) is highly correlated with accuracy (Figure 5, over GSM8K) ... one can use low consistency as an indicator that the model has low confidence." One dataset, arithmetic.

### 2.2 SelfCheckGPT, Manakul et al., EMNLP 2023

https://arxiv.org/abs/2303.08896

- Black-box hallucination check: if the model knows a fact, samples agree; invented facts diverge. Uses N = 20 samples. Performance "increases smoothly as more samples are used, with diminishing gains". The prompt-based variant (ask an LLM whether each sample supports the sentence) was the best; with ChatGPT as checker, N = 4 scored 76.47 vs 78.32 Pearson at N = 20.
- Limits: 238 GPT-3 WikiBio passages about people.

### 2.3 Semantic entropy, Kuhn et al. ICLR 2023 and Farquhar et al. Nature 2024

https://arxiv.org/abs/2302.09664 (abstract page only)
https://doi.org/10.1038/s41586-024-07421-0 (read via Europe PMC full text, PMC11186750)

- Sample answers, cluster those that "entail each other bidirectionally" (A implies B and B implies A, judged by an NLI model or an LLM), then take entropy over the clusters. Different wordings of one answer count as agreement.
- "Discrete" semantic entropy counts generations per cluster and ignores token probabilities; it "performs similarly" and was used for all GPT-4 results. So it runs from Claude Code.
- "We use ten generations to compute entropy."
- Scope: detects "confabulations", arbitrary wrong answers. It "does not help when LLM outputs are systematically bad", and "does not directly address situations in which LLMs are confidently wrong" from training, systematic reasoning errors, or misleading.

### 2.4 Can "ask N subagents and measure agreement" be a sound proxy?

Partly. What carries over:

- Fresh subagents given the same prompt are the "Self-Random" sampling in Xiong et al. and the sampled paths in Wang et al. Agreement among them is the consistency score those papers validate.
- Option labels make clustering trivial (exact match). Free-text answers need the bidirectional-entailment check from Farquhar et al.

What does not carry over, or is unmeasured:

- **Independence.** Subagents share the model and its training. Kim et al. 2025 (https://arxiv.org/abs/2506.07962): models "agree 60% of the time when both models err" on one leaderboard, and "larger and more accurate models have highly correlated errors". Agreement detects arbitrary guesses, not shared blind spots.
- **Anchoring.** If subagents see the parent's recommendation, the sample is no longer independent. Xiong's "misleading" sampling shows answers move with a stated hint, and Sharma et al. (https://arxiv.org/abs/2310.13548; abstract page only) show assistants "match user beliefs over truthful ones". So subagents must not see the parent's pick.
- **Unique answer assumption.** All of these studies score against one right answer. A design question can have two good answers; disagreement then means "a real preference", which is still a fair reason to ask a human, but the accuracy numbers above do not measure it (**UNCONFIRMED** transfer).
- **Subagent sampling settings.** Claude Code does not let a skill set temperature for a subagent (**UNCONFIRMED**; I did not check the docs this session). The papers sample at temperature around 0.7-1. Default sampling is probably diverse enough, but this was not measured.

## 3. Evidence grounding and blast radius

### 3.1 Grounding

- Anthropic, "Building effective agents" (https://www.anthropic.com/engineering/building-effective-agents): "it's crucial for the agents to gain 'ground truth' from the environment at each step (such as tool call results or code execution)"; agents "can then pause for human feedback at checkpoints or when encountering blockers"; include "stopping conditions"; autonomy brings "higher costs, and the potential for compounding errors".
- ClarifyGPT, Mu et al. 2023 (https://arxiv.org/abs/2310.10996): sample n code solutions (temperature 0.8), run them on generated test inputs; identical outputs -> unambiguous; differing outputs -> ask a clarifying question. Raised GPT-4 Pass@1 on MBPP-sanitized from 70.96% to 80.80%. This is consistency judged by execution, the strongest form of grounding in the literature for code.
- Kadavath et al.: P(IK) rises when relevant source material is in context. This shows the model's sense of knowing tracks evidence in context, not that cited evidence makes the answer correct.
- No study I found measures "the recommendation cites a checkable repo artifact" as a predictor of a correct design choice (**UNCONFIRMED** as a measured signal). The case for it is that a cited rule can be checked by a tool, which turns a judgment into the "ground truth from the environment" Anthropic asks for.

### 3.2 Reversibility and blast radius

- OpenAI, "A practical guide to building agents" (https://cdn.openai.com/business-guides-and-resources/a-practical-guide-to-building-agents.pdf), "Plan for human intervention": two triggers, "Exceeding failure thresholds" (limits on retries or actions) and "High-risk actions: Actions that are sensitive, irreversible, or have high stakes should trigger human oversight until confidence in the agent's reliability grows." "For a coding agent, this means handing control back to the user." Under "Tool safeguards": rate each tool low, medium or high by "read-only vs. write access, reversibility, required account permissions, and financial impact".
- This axis is about cost of being wrong, not chance of being wrong. A decision can be well grounded and still need a human because it cannot be undone.

## 4. Abstention and selective prediction

- Wen et al. 2024, "Know Your Limits: A Survey of Abstention in LLMs" (https://arxiv.org/abs/2407.18418): "neither probability-based measures nor verbalized confidence may be well-calibrated"; consistency-based methods "establish model certainty based on its output distribution, helping to identify queries for which a model should abstain". Warns of over-abstention (refusing when not needed) and that abstention "is highly sensitive to prompt wording".
- Geifman and El-Yaniv 2017, "Selective Classification for Deep Neural Networks" (https://arxiv.org/abs/1705.08500; abstract page only; NeurIPS 2017 venue **UNCONFIRMED**): trade coverage (share answered) for risk (error among those answered); the user sets a risk level and the threshold is fit on held-out data.
- Ren et al. 2023 (CoRL venue **UNCONFIRMED**), "Robots That Ask For Help" / KnowNo (https://arxiv.org/abs/2307.01928): the LLM scores candidate actions; conformal prediction (a method that sets a cut-off from a labelled calibration set so the true answer lands in the kept set at a chosen rate 1-ε) keeps the plausible options; if more than one survives, ask for help. Guarantees task success at 1-ε while reducing help by 10-24% vs baselines. It uses next-token likelihoods, so as published it needs logprobs; sample frequencies are a substitute but lose the guarantee unless recalibrated (**UNCONFIRMED**).

## 5. Agents deciding when to ask

- Ambig-SWE, Vijayvargiya et al., ICLR 2026 (https://arxiv.org/abs/2502.13069): an underspecified SWE-Bench Verified. Models "struggle to distinguish between well-specified and underspecified instructions" and "default to non-interactive behavior"; Claude Sonnet 4 and 3.5 reach 89% and 84% at telling them apart. Interaction lifts performance "up to 74% over the non-interactive settings".
- ClarifyGPT (above): the ask/no-ask trigger is execution disagreement, not the model's judgment.
- KnowNo (above): the trigger is "more than one option survives calibration".
- Common pattern across all three: the trigger that works is an external, countable disagreement (between samples, between executions, among surviving options), not the model's opinion that it is unsure.

## 6. Proposed rule

Apply in order. Any "park" stops the decision; record the question, options, votes and evidence for the human.

1. **Blast-radius gate (OpenAI guide, 3.2).** Park if the chosen option is hard to reverse: deletes or migrates data, changes a public interface or file format others read, touches secrets, permissions, money, or anything outside the repo. Grounding and agreement do not override this.
2. **Grounding check (Anthropic "ground truth", ClarifyGPT, 3.1).** The recommendation names its basis: a file and line, a test, a doc or ADR rule. A tool call confirms it (read the line, run the test). Classify as *grounded* (the artifact decides the question), *partly grounded*, or *preference*. A grounded decision that passes gate 1 is taken without sampling. A cited artifact that does not say what was claimed -> park.
3. **Execution check where possible (ClarifyGPT).** If the options lead to code whose behavior can be compared, sample 3-5 implementations and run them on the same inputs; different outputs -> park.
4. **Agreement vote for partly grounded and preference decisions (Wang; Xiong; Farquhar).** Spawn **N = 5** fresh subagents. Each gets the question, the options with stable labels, and repo pointers, but **not** the parent's pick (Sharma; Xiong "misleading"). Each returns one label plus its evidence. Cluster by label; free text clusters by two-way entailment.
   - 5/5 agree with the parent's pick -> proceed.
   - 4/5 -> proceed only if the decision is cheap to reverse; otherwise run 5 more (N = 10, Farquhar's setting) and proceed only at >= 9/10.
   - <= 3/5, or the majority differs from the parent's pick -> park.
5. **Verbalized confidence only as a weight (Xiong Avg-Conf).** It may break a 4/5 tie; it never gates alone.
6. **Failure threshold.** OpenAI's guide asks for a limit on retries but gives no number. Park after a set number of failed attempts at the same step; `agent-retry-limits.md` checks the count against cost and success and gives the rule.
7. **Calibrate (Geifman; KnowNo).** Log every decision, its vote and grounding class; when the human reviews parked and unparked ones, retune the cut-offs so the error rate among unparked decisions meets a target.

The cut-offs 5/5, 4/5 and 9/10 are starting points chosen from the sample sizes in the studies, not thresholds any study validated for design decisions (**UNCONFIRMED**).

### What the evidence does NOT support

- Parking on a stated percentage ("park below 80% confidence"): stated values cluster at 80-100 and barely separate right from wrong (Xiong).
- Treating unanimous subagents as correct: errors are correlated and systematic errors pass consistency checks (Kim; Farquhar).
- Any specific agreement threshold for design questions: all studies use tasks with one right answer (Xiong limitations; Tian limitations).
- Asking the agent "is this underspecified?" as the only trigger: models are poor at it (Ambig-SWE).
- That citing a repo file makes a decision correct: plausible, not measured.
- That KnowNo's or selective prediction's guarantees hold without a labelled calibration set of your own decisions.

## Sources

- Kadavath et al. 2022: https://arxiv.org/abs/2207.05221
- Xiong et al. ICLR 2024: https://arxiv.org/abs/2306.13063
- Tian et al. EMNLP 2023: https://arxiv.org/abs/2305.14975
- Wang et al. ICLR 2023: https://arxiv.org/abs/2203.11171
- Manakul et al. EMNLP 2023: https://arxiv.org/abs/2303.08896
- Kuhn et al. ICLR 2023: https://arxiv.org/abs/2302.09664
- Farquhar et al. Nature 2024: https://doi.org/10.1038/s41586-024-07421-0
- Kim et al. 2025: https://arxiv.org/abs/2506.07962
- Sharma et al. 2023: https://arxiv.org/abs/2310.13548
- Mu et al. (ClarifyGPT) 2023: https://arxiv.org/abs/2310.10996
- Ren et al. (KnowNo) 2023: https://arxiv.org/abs/2307.01928
- Vijayvargiya et al. (Ambig-SWE) ICLR 2026: https://arxiv.org/abs/2502.13069
- Wen et al. 2024 abstention survey: https://arxiv.org/abs/2407.18418
- Geifman and El-Yaniv 2017: https://arxiv.org/abs/1705.08500
- Anthropic, Building effective agents: https://www.anthropic.com/engineering/building-effective-agents
- OpenAI, A practical guide to building agents: https://cdn.openai.com/business-guides-and-resources/a-practical-guide-to-building-agents.pdf
