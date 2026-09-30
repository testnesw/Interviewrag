# DEEP MECHANICS · Fine-Tuning Methods (LoRA / QLoRA / PEFT / RLHF)

> 🧠 **Hook:** *Teach a skill (fine-tune) vs hand a reference book (RAG)* — style → tune, facts → RAG.
>
> Level 2 — full vs parameter-efficient fine-tuning, LoRA/QLoRA mechanics,
> alignment (RLHF/DPO), and fine-tune vs RAG vs prompt.

---

## 0. The precise mental model
Fine-tuning **updates a model's weights** to specialize behavior. Doing it **fully** (all billions of params) is expensive, so **PEFT** (Parameter-Efficient Fine-Tuning) — chiefly **LoRA** — trains a **tiny number of extra weights** while freezing the base, getting ~full-tune quality for a fraction of the cost. Separately, **alignment** (RLHF/DPO) tunes a model to human **preferences**, not just to imitate data.

---

## 1. When to fine-tune at all (decide first)
- **Prompt engineering** → fastest, no training; try first.
- **RAG** → for **knowledge/facts** (fresh, large, citeable, access-controlled) — *not* solved by fine-tuning.
- **Fine-tuning** → for **behavior/style/format/tone**, narrow specialized tasks, reducing prompt length, or teaching a skill the base lacks.
- Often **combine**: fine-tune for style + RAG for facts. "Fine-tuning teaches *form*, RAG supplies *knowledge*."

## 2. Full fine-tuning vs PEFT
- **Full**: update all weights → best adaptation, but huge GPU/memory + a full model copy per task + catastrophic forgetting risk.
- **PEFT**: freeze base, train small add-on params → cheap, fast, tiny artifacts, many task adapters share one base.

## 3. LoRA (Low-Rank Adaptation)
- Insight: the weight *update* is **low-rank** → represent ΔW as **B·A** (two small matrices, rank r) instead of a full matrix.
- Train only **A, B** (e.g., <1% of params); base weights frozen. At inference, add BA to W (or keep as a swappable **adapter**).
- **Params**: **rank r** (capacity vs size), **alpha** (scaling), target modules (attention projections).
- **Wins**: ~full quality, tiny checkpoints (MBs), **swap adapters** per task, no forgetting of base.

## 4. QLoRA
- LoRA **on top of a 4-bit quantized base** → fine-tune a large model on a **single/consumer GPU**.
- Base stays quantized + frozen; LoRA adapters trained in higher precision → big models, small hardware, minimal quality loss.

## 5. Alignment: RLHF & DPO
- **RLHF** (Reinforcement Learning from Human Feedback): train a **reward model** from human preference rankings → optimize the LLM (PPO) to maximize reward → aligns to helpfulness/safety. Powerful but complex/unstable.
- **DPO** (Direct Preference Optimization): skip the separate reward model + RL → directly optimize on preference pairs → simpler, stable, popular.
- Used for **instruction-following + safety**, after supervised fine-tuning (SFT).

## 6. Process & pitfalls
- **Data quality > quantity**: a few thousand high-quality, consistent examples beat noisy bulk.
- Pipeline: curate data → SFT (often LoRA) → optional preference tuning (DPO) → **eval vs base** → register → gated deploy.
- **Pitfalls**: overfitting, catastrophic forgetting (full FT), data leakage, evaluating only on train-like data. Always **eval against the base model** to prove lift.

## 7. The hard follow-ups (with answers)
1. **"Fine-tune vs RAG vs prompt?"** → prompt first; RAG for **knowledge/facts**; fine-tune for **style/format/behavior**; combine. (§1)
2. **"What is LoRA?"** → train a **low-rank** update (B·A) on a frozen base → ~full quality, <1% params, swappable adapters. (§3)
3. **"QLoRA?"** → LoRA on a **4-bit quantized** base → fine-tune big models on one GPU. (§4)
4. **"Full vs PEFT trade-off?"** → full = best adaptation, huge cost + forgetting; PEFT = cheap, tiny artifacts, multi-task. (§2)
5. **"RLHF vs DPO?"** → RLHF = reward model + RL (complex); **DPO** = directly optimize preference pairs (simpler/stable). (§5)
6. **"Data amount needed?"** → **quality over quantity**; a few thousand clean examples often suffice. (§6)
7. **"How know it worked?"** → **eval vs the base model** on held-out + task metrics (avoid forgetting/overfit). (§6)

## 8. One-screen recall
- **Decide**: prompt → **RAG (facts)** → **fine-tune (style/format/behavior)**; combine (form vs knowledge).
- **PEFT vs full**: PEFT freezes base, trains small add-ons → cheap, tiny, multi-task, no forgetting.
- **LoRA**: ΔW ≈ **B·A** (low rank r), train <1% params, **swappable adapters**; **QLoRA** = LoRA on 4-bit base (one GPU).
- **Alignment**: **RLHF** (reward model + PPO) vs **DPO** (direct preference pairs, simpler) after SFT.
- **Data quality > quantity**; pipeline SFT→(DPO)→**eval vs base**→register→gated deploy.

> Next: back to the deep-dive index.
