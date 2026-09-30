# DEEP MECHANICS · Attention & KV-Cache (MHA / GQA / MLA)

> Level 2 — how self-attention works, why the KV-cache exists, and how GQA/MLA/
> FlashAttention make long-context inference affordable.

---

## 0. The precise mental model
**Self-attention** lets each token look at every previous token and pull in relevant information. For each token the model computes a **Query (Q)**, **Key (K)**, and **Value (V)**. A token's output = a weighted sum of all **V**s, where weights come from how much its **Q** matches each **K**. At inference, past tokens' **K** and **V** don't change, so we **cache** them (the **KV-cache**) to avoid recomputing — this is the single biggest memory cost of long-context generation.

---

## 1. The attention computation
$$\text{Attention}(Q,K,V) = \text{softmax}\!\left(\frac{QK^\top}{\sqrt{d_k}}\right)V$$
- $QK^\top$ = similarity of each query to each key → **scores**.
- $/\sqrt{d_k}$ = scale so softmax gradients stay stable.
- **Causal mask** = set future positions to $-\infty$ so a token can't see the future.
- softmax → weights → weighted sum of **V** = the output.

## 2. Multi-Head Attention (MHA)
- Run attention **h times in parallel** with different learned projections ("heads") → each head attends to different relationships (syntax, coreference, etc.) → concatenate → project.
- More heads = richer representation; cost scales with heads.

## 3. The KV-cache (why generation is memory-bound)
- **Prefill**: process the whole prompt once, compute K/V for all tokens → store.
- **Decode**: generate one token at a time; each new token only needs its own Q against **all cached K/V** → **cache avoids recomputing** the prompt every step.
- **Cost**: cache size = `2 (K+V) × layers × heads × head_dim × seq_len × batch × bytes`. Grows **linearly with context length and batch** → often the real limit on throughput/max context.
- This is why long context is expensive and why the optimizations below target the cache.

## 4. Shrinking the cache: MQA → GQA → MLA
- **MQA (Multi-Query)**: all query heads share **one** K/V head → tiny cache, but some quality loss.
- **GQA (Grouped-Query)**: query heads split into **groups**, each group shares one K/V head → **sweet spot** between MHA quality and MQA size (used by Llama-2/3, Mistral).
- **MLA (Multi-head Latent Attention)** (DeepSeek): compress K/V into a **low-rank latent** that's cached, decompressed on the fly → large cache reduction with near-MHA quality.
- All three attack the **same bottleneck**: KV-cache memory.

## 5. Faster attention: FlashAttention & friends
- **FlashAttention**: compute attention in **tiles** in fast SRAM without materializing the full $N\times N$ score matrix in HBM → same math, far less memory traffic → big speedup (IO-aware). Enables longer context.
- **PagedAttention** (vLLM): manage the KV-cache in **non-contiguous pages** (like OS virtual memory) → little fragmentation, enables **prefix sharing** across requests → higher throughput.
- **Sliding-window attention** (Mistral): each token attends only to the last **W** tokens → linear cost, bounded cache for long sequences.

## 6. Complexity & long context
- Vanilla attention is **O(n²)** in sequence length (every token attends to every token) → the long-context pain point.
- Mitigations: sliding-window/sparse attention, FlashAttention (constant-memory), and KV-cache compression (GQA/MLA). Combined with RoPE scaling for length extrapolation (see Positional Encodings).

## 7. The hard follow-ups (with answers)
1. **"What are Q, K, V?"** → query (what I'm looking for), key (what I offer), value (the info); output = softmax(QKᵀ/√d)·V. (§1)
2. **"Why divide by √dₖ?"** → keep softmax gradients stable (prevents saturation). (§1)
3. **"What is the KV-cache and why?"** → cache past K/V so each new token doesn't recompute the prompt → avoids O(n²) rework per step. (§3)
4. **"What dominates long-context memory?"** → **KV-cache**, grows linearly with seq_len × batch × layers × heads. (§3)
5. **"MHA vs MQA vs GQA?"** → MHA = separate K/V per head (big cache); MQA = one shared K/V (tiny, lossy); **GQA = grouped** (best trade-off). (§4)
6. **"What is MLA?"** → compress K/V to a **low-rank latent** cached & decompressed → near-MHA quality, small cache (DeepSeek). (§4)
7. **"What does FlashAttention change?"** → same math, **IO-aware tiled** compute in SRAM → no full N×N matrix → faster, less memory. (§5)
8. **"PagedAttention?"** → paged KV-cache (vLLM) → less fragmentation + prefix sharing → higher throughput. (§5)
9. **"Attention complexity?"** → **O(n²)** in sequence length → sliding-window/sparse/Flash to mitigate. (§6)

## 8. One-screen recall
- Attention = **softmax(QKᵀ/√dₖ)·V** with a **causal mask**; **MHA** = many heads in parallel.
- **KV-cache**: store past **K/V** so decode doesn't recompute the prompt; size grows **linearly with context × batch** → dominates long-context memory.
- **Cache shrinkers**: **MQA** (1 shared K/V), **GQA** (grouped — best trade-off, Llama/Mistral), **MLA** (low-rank latent, DeepSeek).
- **Speed**: **FlashAttention** (IO-aware tiling, no full N×N), **PagedAttention** (vLLM paging + prefix sharing), **sliding-window** (Mistral).
- Vanilla attention = **O(n²)** in length → the long-context bottleneck.

> Next: Positional Encodings (RoPE).
