# DEEP MECHANICS · Positional Encodings (RoPE & context extension)

> 🧠 **Hook:** *Clock hands* — position = angle; what matters is the *difference* between two tokens' angles (relative distance).
>
> Level 2 — why transformers need position info, how RoPE works, and how
> context windows get extended (NTK / YaRN).

---

## 0. The precise mental model
Attention is **permutation-invariant** — on its own it has no idea of token *order* ("dog bites man" = "man bites dog"). **Positional encoding** injects order information. Modern LLMs use **RoPE (Rotary Position Embeddings)**: instead of adding a position vector, it **rotates** the Q and K vectors by an angle proportional to the token's position, so that the **dot product between two tokens depends on their relative distance**. That relative property is what lets models generalize and get extended to longer contexts.

---

## 1. Why position is needed
- Self-attention computes token-to-token scores with **no inherent order** → without position, word order is invisible.
- So we encode position and feed it in — the question is *how*.

## 2. The old way: absolute encodings
- **Sinusoidal** (original Transformer): add fixed sin/cos vectors per position.
- **Learned absolute** (early BERT/GPT): a learnable vector per position index.
- **Limitation**: tied to absolute positions → **poor extrapolation** beyond trained length; doesn't naturally capture *relative* distance.

## 3. RoPE (Rotary Position Embeddings) — the modern default
- **Rotates** each Q and K vector by an angle = position × frequency (applied in 2D pairs of dimensions).
- Key property: the attention score between positions $m$ and $n$ becomes a function of **$m-n$ (relative distance)** → captures relative position *inside* the dot product.
- **Benefits**: relative-distance aware, no extra params, works with the KV-cache, **extrapolates** better and is **extendable**. Used by Llama, Mistral, Qwen, most modern LLMs.
- Different dimensions rotate at different **frequencies** (like a clock's second/minute/hour hands) → encodes both fine and coarse position.

## 4. Extending the context window
A model trained at 4k can be pushed to 32k+ by manipulating RoPE frequencies:
- **Position Interpolation (PI)**: **squeeze** positions into the trained range (scale them down) → works but blurs fine resolution.
- **NTK-aware scaling**: adjust frequencies **non-uniformly** (high-freq dims less, low-freq more) → preserves local detail while extending reach; can be training-free.
- **YaRN**: refined NTK method → efficient long-context extension with a short fine-tune; widely used.
- These change *how far* the model can attend; **effective use** of that context still needs eval (long-context ≠ good recall → "lost in the middle").

## 5. ALiBi (alternative)
- **ALiBi**: add a distance-based **linear bias** to attention scores (penalize far-apart tokens) instead of rotating → naturally extrapolates to longer sequences; used by some models (e.g., MPT).

## 6. "Lost in the middle" (why bigger ≠ better)
- Models often recall info at the **start and end** of a long context better than the **middle** → don't assume a 128k window is uniformly usable.
- Mitigate: put key info early/late, use RAG to keep context tight, re-rank, and **test recall** across positions.

## 7. The hard follow-ups (with answers)
1. **"Why do transformers need positional encoding?"** → attention is **permutation-invariant** → no order without it. (§1)
2. **"How does RoPE work?"** → **rotates** Q/K by position-dependent angles so the dot product depends on **relative distance** $m-n$. (§3)
3. **"RoPE vs absolute sinusoidal?"** → RoPE is relative, param-free, KV-cache-friendly, extrapolates far better. (§2/§3)
4. **"How extend a 4k model to 32k?"** → scale RoPE frequencies: **Position Interpolation**, **NTK-aware**, **YaRN** (± short fine-tune). (§4)
5. **"What is YaRN?"** → efficient NTK-based context extension with a small fine-tune. (§4)
6. **"What is ALiBi?"** → linear distance **bias** on attention scores → extrapolates, no rotation. (§5)
7. **"Does a 128k window mean uniform recall?"** → no — **lost in the middle**; test recall by position. (§6)

## 8. One-screen recall
- Attention is **order-blind** → need positional encoding.
- **Absolute (sinusoidal/learned)**: simple but **poor extrapolation**.
- **RoPE**: **rotate Q/K** by position → attention depends on **relative distance ($m-n$)**; param-free, KV-cache-friendly, modern default (Llama/Mistral/Qwen).
- **Extend context** via RoPE freq scaling: **PI → NTK-aware → YaRN** (± fine-tune).
- **ALiBi** = linear distance bias alternative.
- **Lost in the middle**: long windows aren't uniformly usable → keep context tight, test recall.

> Next: Mixture of Experts (MoE).
