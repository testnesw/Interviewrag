# DEEP MECHANICS · Distillation & Model Compression

> 🧠 **Hook:** *Apprentice learning from a master* — the student copies the teacher's instincts (soft labels).
>
> Level 2 — how to shrink models for cheaper/faster inference: distillation,
> quantization, pruning, and the trade-offs.

---

## 0. The precise mental model
Compression makes a model **smaller/faster/cheaper** while keeping as much quality as possible. Four main levers: **distillation** (train a small "student" to mimic a big "teacher"), **quantization** (fewer bits per weight), **pruning** (remove weights/structures), and **architecture** changes (MoE, smaller models). You trade a little accuracy for large gains in latency, memory, and cost.

---

## 1. Knowledge distillation
- Train a **small student** to reproduce a **large teacher's** behavior.
- **Soft labels**: student learns from the teacher's **full probability distribution** (logits, with temperature), not just the hard answer → richer signal ("dark knowledge" — relative probabilities of wrong classes).
- **Types**: response/logit distillation, feature (intermediate-layer) distillation, **sequence-level** distillation for generation.
- **Data distillation for LLMs**: generate Q→A (and reasoning traces) from a strong model → fine-tune a smaller model on it (e.g., distilled reasoning models). *Check licensing on using model outputs.*

## 2. Quantization (fewer bits)
- Represent weights/activations in **INT8 / INT4 / FP8** instead of FP16/32 → less memory + faster.
- **PTQ (post-training quantization)**: quantize an already-trained model (fast, some accuracy loss). Methods: **GPTQ, AWQ** (weight-only, calibration-based), **bitsandbytes** (NF4 — see QLoRA).
- **QAT (quantization-aware training)**: simulate quantization during training → best accuracy at low bits, but costs a training run.
- **Weight-only vs weight+activation**: weight-only (INT4) is common for LLM inference; activations often kept higher precision.
- Rough: INT8 ≈ near-lossless; INT4 = big memory win with small quality drop (model-dependent).

## 3. Pruning (remove weights)
- **Unstructured**: zero out individual low-magnitude weights → sparse; needs sparse-kernel/hardware support to actually speed up.
- **Structured**: remove whole **heads/neurons/layers/channels** → real speedups on standard hardware.
- **2:4 semi-structured sparsity** (NVIDIA) → hardware-accelerated. Usually **fine-tune after** pruning to recover accuracy.

## 4. Other levers
- **Smaller base models / SLMs** (Phi, Gemma) for the task.
- **MoE**: large capacity, but only a few experts active per token → compute like a smaller model.
- **Distill + quantize** stack well (distill to a small model, then quantize it).
- Pairs with inference-optimization (KV-cache, batching, speculative decoding — see that file).

## 5. Choosing (interview reasoning)
- Need **max accuracy retention, have data** → distillation (+ QAT).
- Need **fast, cheap win on an existing model** → **PTQ (INT8/INT4 via AWQ/GPTQ)**.
- Need **real latency on standard GPUs** → **structured pruning** (+ fine-tune) or a smaller model.
- **Edge/on-device** → aggressive quantization (INT4) + small model.
- Always **measure quality on your eval set** after compressing — losses are task-dependent.

## 6. The hard follow-ups (with answers)
1. **"Distillation — what does the student learn from?"** → the teacher's **soft label distribution** (logits/temperature), not just hard answers. (§1)
2. **"PTQ vs QAT?"** → PTQ = quantize after training (fast, some loss); QAT = train with simulated quantization (best low-bit accuracy, costs training). (§2)
3. **"Common INT4 methods?"** → **GPTQ, AWQ** (weight-only, calibration); **NF4** (QLoRA). (§2)
4. **"Structured vs unstructured pruning?"** → unstructured = sparse weights (needs sparse kernels); structured = remove heads/layers → real speedup. (§3)
5. **"Do you retrain after pruning?"** → usually **fine-tune to recover** accuracy. (§3)
6. **"Distill a proprietary model's outputs — concern?"** → **licensing/ToS** on using outputs for training. (§1)
7. **"Stack techniques?"** → distill → then quantize; combine with MoE/small models. (§4)
8. **"How verify it's safe to ship?"** → re-run your **eval set**; losses are task-dependent. (§5)

## 7. One-screen recall
- **Distillation**: small **student** mimics big **teacher** via **soft labels** (logits/temperature); data distillation = fine-tune small model on strong model's outputs (mind licensing).
- **Quantization**: fewer bits (INT8/INT4/FP8). **PTQ** (GPTQ/AWQ/NF4, fast) vs **QAT** (best low-bit, costs training). INT8≈lossless, INT4=big win/small drop.
- **Pruning**: **unstructured** (sparse, needs kernels) vs **structured** (heads/layers → real speedup); fine-tune after.
- **Other**: SLMs, **MoE** (sparse activation), stack distill+quantize.
- **Choose** by accuracy-retention vs speed-on-hardware vs edge; **always re-eval**.

> Next: back to the deep-dive index.
