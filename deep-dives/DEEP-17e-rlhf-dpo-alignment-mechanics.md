# DEEP MECHANICS · RLHF, DPO & Alignment

> Level 2 — how base models become aligned assistants: SFT → reward model → RLHF/PPO,
> and the simpler DPO alternative.

---

## 0. The precise mental model
A pretrained base model just **predicts next tokens** — it isn't helpful, honest, or safe by default. **Alignment** turns it into an assistant in stages: **SFT** (teach the format/behavior from demonstrations), then **preference optimization** (teach it which of two answers humans prefer). Classic path = **RLHF** (train a reward model, then RL-optimize against it); modern shortcut = **DPO** (optimize directly on preference pairs, no separate reward model or RL loop).

---

## 1. The three-stage pipeline (RLHF)
1. **SFT (Supervised Fine-Tuning)**: fine-tune the base model on human-written **(prompt → ideal answer)** demonstrations → learns the assistant style/instruction-following.
2. **Reward Model (RM)**: humans rank multiple responses to a prompt (A > B). Train a model to output a **scalar reward** matching human preference (trained on pairwise comparisons → Bradley-Terry loss).
3. **RL (PPO)**: optimize the SFT policy to **maximize reward** from the RM, with a **KL-divergence penalty** to a frozen reference so it doesn't drift too far (avoids gibberish that games the reward).

## 2. Why the KL penalty matters
- Without it the policy **reward-hacks** — drifts to weird high-reward text. The **KL term** keeps outputs close to the SFT model → stability. Balanced by a coefficient $\beta$.
- Objective ≈ maximize `reward − β·KL(policy‖reference)`.

## 3. DPO (Direct Preference Optimization)
- Skips the reward model **and** RL. Uses the same **preference pairs** (chosen vs rejected) and a **classification-style loss** that directly makes the model raise probability of *chosen* and lower *rejected*, **implicitly** relative to a frozen reference.
- **Why popular**: simpler, more stable, cheaper (no RM, no PPO rollouts), comparable quality → now a default for open models.
- **Cost**: still needs good preference data; can be less flexible than full RL for complex reward shaping.

## 4. The family (name-drop + one-liners)
- **RLHF/PPO** — original (InstructGPT/ChatGPT).
- **DPO** — direct, no RM/RL.
- **RLAIF / Constitutional AI** — use **AI feedback** (a model + a set of principles) instead of humans to scale labeling.
- **GRPO** — RL variant (used in reasoning models, e.g., DeepSeek) that drops the value network, normalizes rewards across a group of samples → efficient for verifiable-reward RL.
- **RLVR (verifiable rewards)** — reward = did it get the math/code right? → trains reasoning without human raters.
- **KTO, ORPO, IPO** — other preference-optimization variants (ORPO folds preference into SFT; KTO needs only good/bad labels, not pairs).

## 5. Reasoning models (RL for thinking)
- Modern reasoning models (o-series, R1) use **RL on verifiable rewards** to elicit long **chain-of-thought** → the model learns to "think" before answering. RLVR + GRPO is the engine.

## 6. Cautions
- **Reward hacking / sycophancy** — model games the RM or just agrees with the user → need diverse data + KL control.
- **Alignment tax** — alignment can slightly reduce raw capability.
- **Data quality is everything** — preferences encode *your* values/biases.
- Distinct from **guardrails** (runtime filtering) — alignment is *baked into weights*.

## 7. The hard follow-ups (with answers)
1. **"Three RLHF stages?"** → **SFT → Reward Model → PPO**. (§1)
2. **"What does the reward model do?"** → outputs a **scalar reward** trained on human **pairwise rankings**. (§1)
3. **"Why the KL penalty in PPO?"** → prevent **reward hacking / drift** from the SFT reference → stability. (§2)
4. **"DPO vs RLHF?"** → DPO skips RM + RL, optimizes **directly on preference pairs** → simpler/cheaper/stable. (§3)
5. **"Scale labeling without humans?"** → **RLAIF / Constitutional AI** (AI feedback + principles). (§4)
6. **"How are reasoning models trained?"** → **RL on verifiable rewards** (RLVR) + **GRPO** → long chain-of-thought. (§4/§5)
7. **"What is reward hacking?"** → policy games the RM for high reward with bad text → KL + diverse data. (§6)
8. **"Alignment vs guardrails?"** → alignment = **in the weights** (training); guardrails = **runtime** filtering. (§6)

## 8. One-screen recall
- **Base = next-token predictor** → align via **SFT → preference optimization**.
- **RLHF**: SFT → **Reward Model** (pairwise human ranks) → **PPO** maximizing reward with a **KL penalty** to the reference (stops reward hacking).
- **DPO**: no RM, no RL — optimize **directly on chosen/rejected pairs** → simpler, cheaper, stable (modern default).
- **Variants**: RLAIF/Constitutional (AI feedback), **GRPO + RLVR** (reasoning models, verifiable rewards), KTO/ORPO/IPO.
- **Watch**: reward hacking, sycophancy, alignment tax, data-encoded bias.
- Alignment = **baked into weights**; guardrails = **runtime**.

> Next: Evaluation Benchmarks.
