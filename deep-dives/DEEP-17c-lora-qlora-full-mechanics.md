# DEEP MECHANICS · LoRA & QLoRA (Full Detail)

> Level 2+ — the math, the hyperparameters, memory accounting, QLoRA's 3
> innovations, serving adapters, and every common interview follow-up.

---

## 0. The precise mental model
Fine-tuning a full LLM updates **all** weights $W$ — billions of parameters, needing optimizer state + gradients for every one → enormous memory. **LoRA's insight**: the *change* you need, $\Delta W$, has **low intrinsic rank**, so you can represent it as the product of two **small** matrices and train only those, freezing $W$. **QLoRA** goes further: keep the frozen base in **4-bit**, train LoRA adapters on top → fine-tune a 65B model on a **single 48GB GPU** with essentially no quality loss.

---

## 1. The LoRA math (know this precisely)
A linear layer computes $h = Wx$, where $W \in \mathbb{R}^{d \times k}$.

Full fine-tuning learns $W' = W + \Delta W$ (update all $d \times k$ params).

**LoRA** freezes $W$ and models the update as a **low-rank decomposition**:
$$\Delta W = B A, \quad B \in \mathbb{R}^{d \times r}, \; A \in \mathbb{R}^{r \times k}, \; r \ll \min(d,k)$$

So the forward pass becomes:
$$h = Wx + \Delta W x = Wx + B A x \cdot \tfrac{\alpha}{r}$$

- Only **$A$ and $B$** are trained → number of trainable params = $r(d + k)$ instead of $d \times k$.
- Example: $d = k = 4096$, $r = 8$ → full = 16.7M params/layer; LoRA = $8 \times 8192 = 65.5$K → **~0.4%**.
- **Initialization**: $A$ ~ random Gaussian, $B = 0$ → at start $\Delta W = 0$ → training begins exactly at the pretrained model (no disruption).
- **$\alpha$ scaling**: the update is scaled by $\alpha / r$ so you can change $r$ without re-tuning the learning rate.

## 2. Why low rank works
- Pretrained models are **over-parameterized**; adapting to a *narrow* task lives on a **low-dimensional manifold** → the needed weight change has a **low effective rank**.
- Empirically, tiny $r$ (4–64) recovers **most of full fine-tuning quality** for style/task specialization.

## 3. LoRA hyperparameters (what interviewers probe)
| Param | Meaning | Guidance |
|---|---|---|
| **r (rank)** | capacity of the update | 8–16 typical; ↑ for harder/broader tasks (diminishing returns; overfit risk) |
| **alpha** | scaling ($\alpha/r$) | often 2×r (e.g., r=16, α=32); effective LR knob |
| **target modules** | which layers get adapters | attention **q,k,v,o**; adding MLP (gate/up/down) → more capacity |
| **dropout** | LoRA dropout | small (0.05) to regularize |
| **learning rate** | adapter LR | higher than full FT (e.g., 1e-4–3e-4) |
- More target modules + higher r = more capacity + more memory/params. Attention-only is the cheap default; add MLP for tougher adaptation.

## 4. Memory accounting (why LoRA saves so much)
Full fine-tuning memory per parameter ≈ weights + **gradients** + **Adam optimizer state (m, v)** + activations. Adam alone = 2× params in FP32.
- **LoRA**: base weights have **no gradients/optimizer state** (frozen) → optimizer state only for the **tiny adapter** → the dominant optimizer-memory term collapses.
- You still hold the base weights in memory (for the forward pass) — that's what **QLoRA** attacks next.

## 5. QLoRA — three key innovations
QLoRA = LoRA adapters trained on a **4-bit quantized frozen base**. Three contributions:
1. **NF4 (4-bit NormalFloat)** — an **information-theoretically optimal** 4-bit datatype for **normally-distributed** weights (LLM weights are ~Gaussian) → better than plain int4/fp4.
2. **Double quantization** — quantize the **quantization constants** too → saves ~0.4 bits/param more.
3. **Paged optimizers** — use NVIDIA unified memory to **page optimizer state** to CPU RAM during memory spikes (long sequences) → avoids OOM.
- Base stays **4-bit + frozen**; LoRA adapters computed/trained in **bf16**. Forward pass **dequantizes** base weights block-wise on the fly.
- **Result**: fine-tune a **65B** model on **48GB** with full-16-bit-fine-tuning quality (the QLoRA paper's headline: "Guanaco").

## 6. LoRA vs QLoRA (trade-off)
| | LoRA | QLoRA |
|---|---|---|
| Base weights | 16-bit frozen | **4-bit frozen (NF4)** |
| Memory | medium | **lowest** |
| Speed | faster | slightly slower (dequant overhead) |
| Quality | ~full FT | ~full FT (minimal loss) |
| Use when | GPU has room | **big model, small GPU** |
- QLoRA trades a little compute (on-the-fly dequant) for a **huge memory reduction**.

## 7. Serving & adapters (operational superpower)
- A LoRA adapter is **tiny (MBs)** → store many task adapters over **one base model**.
- **Two serving modes**:
  - **Merge**: fold $BA$ into $W$ (`W + BA`) → zero inference overhead, but it's now a single-purpose model.
  - **Keep separate / hot-swap**: load base once, **swap adapters per request** → multi-tenant ("**multi-LoRA serving**", e.g., S-LoRA / vLLM) → serve many fine-tunes from one GPU.
- Enables **per-customer / per-task** fine-tunes cheaply.

## 8. Pitfalls & variants
- **Pitfalls**: r too high → overfit + lost generalization; wrong target modules → weak adaptation; merging then losing the ability to swap; evaluating only on train-like data.
- **Variants**: **DoRA** (weight-decomposed, splits magnitude/direction → better quality), **rsLoRA** (rank-stabilized scaling), **LoRA+** (different LRs for A/B), **AdaLoRA** (adaptive rank allocation), **VeRA** (shared random matrices, even fewer params).

## 9. The hard follow-ups (with answers)
1. **"Explain LoRA mathematically."** → freeze $W$, learn $\Delta W = BA$ (rank $r \ll d,k$); forward $h = Wx + \tfrac{\alpha}{r}BAx$; train only $A,B$ (~0.4% params). (§1)
2. **"Why initialize $B=0$?"** → so $\Delta W=0$ at start → training begins at the pretrained model, no disruption. (§1)
3. **"What does alpha do?"** → scales the update by $\alpha/r$ → decouples rank from effective learning rate. (§1/§3)
4. **"Why does low rank suffice?"** → task adaptation lives on a low-dimensional manifold; over-parameterized base → update is low effective rank. (§2)
5. **"Where does the memory saving come from?"** → frozen base has **no gradients/optimizer state**; Adam state only for tiny adapters. (§4)
6. **"What are QLoRA's innovations?"** → **NF4**, **double quantization**, **paged optimizers** (4-bit frozen base + bf16 adapters). (§5)
7. **"What is NF4 and why?"** → 4-bit NormalFloat, optimal for Gaussian-distributed weights → better than int4/fp4. (§5)
8. **"Does QLoRA hurt quality?"** → minimal — matches 16-bit fine-tuning in the paper. (§5/§6)
9. **"Serve 100 fine-tunes cheaply?"** → **multi-LoRA serving**: one base + hot-swappable adapters (S-LoRA/vLLM). (§7)
10. **"Merge or keep adapters separate?"** → merge = zero overhead single model; separate = swap per request (multi-tenant). (§7)
11. **"Which modules to target?"** → attention q,k,v,o by default; add MLP for more capacity. (§3)
12. **"A better-quality LoRA variant?"** → **DoRA** (decomposes magnitude/direction). (§8)

## 10. One-screen recall
- **LoRA**: freeze $W$, learn $\Delta W = BA$, rank $r \ll d,k$; $h = Wx + \tfrac{\alpha}{r}BAx$; train ~0.4% of params; **B=0 init** (start at base).
- **Hyperparams**: **r** (8–16), **α** (~2r), **target modules** (attn q,k,v,o; +MLP), LR higher than full FT.
- **Memory win**: frozen base → **no optimizer state** on base; Adam state only on adapters.
- **QLoRA** = LoRA on **4-bit NF4** frozen base + **double quantization** + **paged optimizers**; adapters in bf16; 65B on 48GB, ~no quality loss.
- **Serving**: adapters are MBs → **merge** (zero overhead) or **hot-swap multi-LoRA** (many fine-tunes/one base).
- **Variants**: **DoRA**, rsLoRA, LoRA+, AdaLoRA, VeRA. **Pitfall**: r too high → overfit.

> Next: Model Routing & Cascading.
