# DEEP MECHANICS · Mixture of Experts (MoE)

> 🧠 **Hook:** *Hospital of specialists* — a receptionist (router) sends each token to 2 relevant doctors, not all of them. Huge staff (total params), small visit (active params).
>
> Level 2 — how MoE gives large capacity at small compute, the router, load
> balancing, and the serving trade-offs.

---

## 0. The precise mental model
A dense model runs **every** parameter for **every** token. A **Mixture of Experts** replaces the feed-forward layer with **many parallel expert FFNs** plus a **router** that sends each token to only a **few** experts (e.g., 2 of 8). So the model has a **huge total parameter count** (capacity/knowledge) but only activates a **small slice per token** (compute/cost). You get big-model quality at small-model FLOPs — the catch is you must hold **all** experts in memory.

---

## 1. The MoE layer
- Replace the transformer block's **FFN** with **N experts** (each its own FFN) + a **gating network (router)**.
- **Router**: a small learned layer scores experts per token → pick **top-k** (often k=2) → token is processed only by those experts → outputs combined (weighted by gate scores).
- **Sparse activation**: only k/N experts run per token.

## 2. Total vs active parameters (the key number)
- **Total params** = all experts (defines capacity/knowledge & **memory** needed).
- **Active params** = what actually runs per token (defines **compute/latency/cost**).
- Example (Mixtral 8×7B): ~**47B total** but only ~**13B active** per token → 13B-ish speed, far-better-than-13B quality.
- Interview line: "MoE decouples **capacity** from **compute**."

## 3. Load balancing (the main training challenge)
- Routers tend to **collapse** onto a few favorite experts → others starve, capacity wasted.
- Fixes:
  - **Auxiliary load-balancing loss** — penalize uneven expert usage → spread tokens.
  - **Expert capacity factor** — cap tokens per expert; overflow tokens are **dropped**/passed through (token dropping).
  - **Noisy top-k gating** — add noise for exploration.
- Goal: each expert gets roughly equal, specialized traffic.

## 4. Serving trade-offs
- **Memory-heavy**: must load **all** experts into VRAM even though few run per token → high memory footprint for the "active-param" speed.
- **Expert parallelism**: shard experts across GPUs → routing becomes an **all-to-all** communication → network-bound; batching complicated by uneven expert load.
- **Throughput vs latency**: great FLOPs efficiency, but routing + all-to-all + imbalance add complexity; good for high-throughput serving.

## 5. Where it shows up
- **Mixtral 8×7B / 8×22B**, **DeepSeek-V3/MoE**, **Qwen-MoE**, **GPT-4-class** models are widely believed to be MoE, **Grok**, Switch Transformer / GLaM (research lineage).
- Trend: many experts, low active fraction (DeepSeek uses many small experts + **shared experts** always on).

## 6. Pros / cons summary
- **Pros**: more knowledge/capacity per FLOP; cheaper training & inference compute for a given quality; experts can specialize.
- **Cons**: high **memory** (all experts resident); **training instability** (load balancing, routing); harder to serve (all-to-all, batching); can be less robust to distribution shift.

## 7. The hard follow-ups (with answers)
1. **"What problem does MoE solve?"** → decouples **capacity (total params)** from **compute (active params)** → big-model quality at small-model FLOPs. (§0/§2)
2. **"How does routing work?"** → gating net scores experts per token → **top-k (e.g., 2 of 8)** → combine weighted outputs. (§1)
3. **"Total vs active params — example?"** → Mixtral 8×7B ≈ **47B total / 13B active**. (§2)
4. **"Biggest training challenge?"** → **load balancing** — router collapse → aux loss + capacity factor + noisy gating. (§3)
5. **"What is token dropping?"** → tokens over an expert's **capacity factor** get dropped/passed through. (§3)
6. **"Why is MoE memory-heavy if compute is low?"** → **all** experts must be **resident in VRAM**; only a few run per token. (§4)
7. **"Serving challenge across GPUs?"** → **expert parallelism** → **all-to-all** comms + uneven load → network-bound. (§4)
8. **"Name MoE models."** → Mixtral, DeepSeek-V3, Qwen-MoE, Switch/GLaM. (§5)

## 8. One-screen recall
- **MoE**: replace FFN with **N experts + router**; each token → **top-k experts** (e.g., 2/8) → **sparse activation**.
- **Total params** = capacity + **memory**; **active params** = compute + latency. "Decouples capacity from compute." (Mixtral 8×7B = 47B total / 13B active.)
- **Load balancing** is the hard part: **aux loss**, **capacity factor** (token dropping), noisy gating → avoid router collapse.
- **Serving**: memory-heavy (all experts resident), **expert parallelism → all-to-all** comms, batching complexity.
- **Models**: Mixtral, DeepSeek-V3, Qwen-MoE, Switch/GLaM.
- **Pros**: quality/FLOP; **Cons**: memory + training/serving complexity.

> Next: back to the deep-dive index.
