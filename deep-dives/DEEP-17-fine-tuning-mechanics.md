# DEEP MECHANICS · Fine-Tuning

> Level 2 — full vs parameter-efficient (LoRA/QLoRA), when fine-tuning beats
> RAG/prompting, data requirements, catastrophic forgetting, and the Azure
> workflow.

---

## 0. The precise mental model
Fine-tuning = **continuing training** of a pre-trained model on **your labeled examples** to change its **behavior, style, or format** — updating weights so the desired output becomes the most-likely one. It teaches the model **how to respond**, not **new facts** (that's RAG). Modern practice uses **parameter-efficient** methods (LoRA) that train a tiny fraction of weights, making it cheap and avoiding wrecking the base model.

---

## 1. When to fine-tune (vs prompting vs RAG)
| Need | Use |
|---|---|
| Current/proprietary **facts** | **RAG** (not fine-tuning) |
| Consistent **style/tone/format** | **Fine-tuning** |
| Narrow task, shorter prompts, lower latency/cost | Fine-tuning (small model matches big model on the task) |
| Quick iteration / general tasks | Prompting |
| Complex behavior + fresh facts | **RAG + fine-tuning** together |

**Rule:** fine-tune for **form/behavior**, RAG for **knowledge**. Try prompting → RAG → fine-tuning in that order.

## 2. Full fine-tuning vs PEFT
- **Full fine-tuning** — update all weights. Powerful but expensive (GPU/memory), risks **catastrophic forgetting**, needs lots of data, and you host a full model copy.
- **PEFT — LoRA (Low-Rank Adaptation)** — freeze base weights; inject small **low-rank adapter matrices** and train only those (often <1% of params). Cheap, fast, and you can swap adapters per task on one base model.
- **QLoRA** — LoRA on a **quantized** (4-bit) base → fine-tune large models on a single GPU.
LoRA is the default for most real work.

## 3. Data requirements
- **Quality > quantity** — clean, representative, consistent input→output pairs. Hundreds–thousands of good examples often beat tens of thousands of noisy ones.
- Match the **format** to inference (same prompt template).
- **Split** train/validation; watch for **overfitting** (val loss rising).
- Balanced/representative to avoid injecting bias.

## 4. Failure modes
- **Catastrophic forgetting** — model loses general ability. Mitigate: PEFT, lower LR, fewer epochs, mix in general data.
- **Overfitting** — memorizes training set. Mitigate: validation, early stopping, regularization, more diverse data.
- **Wrong tool** — fine-tuning to add facts → they go stale and hallucinate; use RAG.

## 5. The Azure workflow
Azure OpenAI / Azure AI Foundry fine-tuning:
```
1. Prepare JSONL of prompt/completion (or chat) pairs
2. Upload dataset → validate
3. Create fine-tuning job (base model, hyperparams: epochs, LR multiplier)
4. Evaluate on validation; check metrics
5. Deploy the fine-tuned model to an endpoint
6. Monitor + iterate (versioning in model registry)
```
Costs: training compute + hosting the fine-tuned deployment. Consider whether RAG/prompting is cheaper first.

## 6. RLHF / preference tuning (context)
Beyond SFT: **RLHF/DPO** aligns to human preferences. Rarely done by app teams (expensive); usually the base model already has it. Know it exists.

## 7. The hard follow-ups (with answers)
1. **"Fine-tune or RAG to add company docs?"** → **RAG**; fine-tuning is for behavior/style, not fresh facts. (§1)
2. **"What is LoRA?"** → freeze base, train small low-rank adapters (<1% params) → cheap, swappable, no forgetting. (§2)
3. **"QLoRA?"** → LoRA on a 4-bit quantized base → fine-tune big models on one GPU. (§2)
4. **"How much data?"** → quality over quantity; hundreds–thousands of clean, format-matched pairs; validate for overfit. (§3)
5. **"Catastrophic forgetting — what/fix?"** → losing general ability; PEFT, low LR, fewer epochs, mix general data. (§4)
6. **"Azure fine-tuning steps?"** → JSONL → upload → job(hyperparams) → evaluate → deploy → monitor. (§5)

## 8. One-screen recall
- Fine-tuning = continue training on your pairs to change **behavior/style/format**, not facts (**RAG for facts**).
- Order: **prompt → RAG → fine-tune**. Fine-tune for form, RAG for knowledge; combine when both.
- **Full FT** (all weights, costly, forgetting) vs **PEFT/LoRA** (train tiny low-rank adapters, cheap, swappable) vs **QLoRA** (4-bit quantized base, one GPU). LoRA = default.
- **Data**: quality>quantity, format-matched, train/val split, watch overfitting.
- **Failure**: catastrophic forgetting, overfitting, wrong-tool (stale facts).
- **Azure**: JSONL → upload → job(epochs/LR) → evaluate → deploy → monitor; pay train+hosting.

> Next: Model Evaluation.
