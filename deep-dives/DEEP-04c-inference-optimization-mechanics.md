# DEEP MECHANICS · Inference Optimization (Speculative Decoding & Serving)

> Level 2 — why decoding is slow, speculative decoding, batching, KV-cache
> tricks, and throughput vs latency.

---

## 0. The precise mental model
LLM generation is **autoregressive** — one token at a time, each requiring a full forward pass → **memory-bandwidth bound**, not compute bound. Inference optimization attacks this from two angles: **generate more tokens per pass** (speculative decoding) and **serve more requests per GPU** (batching + KV-cache management). Goal = higher **throughput** and/or lower **latency** per token.

---

## 1. Why decoding is slow
- Each new token = one forward pass over the whole model → **sequential** (can't parallelize across future tokens).
- Dominated by **loading weights from memory** (bandwidth bound); the GPU is often under-utilized on compute during decode.
- **Prefill** (process the prompt) is parallel/compute-bound; **decode** (generate) is the slow sequential part.

## 2. Speculative decoding (the headline technique)
- Use a **small fast "draft" model** to propose the next **k tokens**, then the **big "target" model verifies them all in one parallel pass**.
- Accepted tokens (those the big model agrees with) are kept; on first rejection, resample from the target → **same output distribution as the target model** (lossless quality).
- **Win**: multiple tokens per expensive forward pass → **2–3× faster** when the draft is often right.
- Variants: **Medusa** (extra decoding heads instead of a separate draft), **EAGLE**, **n-gram/prompt lookup** (draft from the prompt).

## 3. Batching for throughput
- **Static batching**: group requests → one pass serves many → better GPU utilization, but slowest request gates the batch.
- **Continuous (in-flight) batching**: add/remove sequences from the batch each step → huge throughput gains for mixed-length generation (vLLM, TGI). The standard for serving.

## 4. KV-cache management
- KV cache grows with sequence length × batch → **memory bottleneck** limiting concurrency.
- **PagedAttention (vLLM)**: page the KV cache like virtual memory → less fragmentation → more concurrent requests.
- **Quantized / shared KV cache**, prefix sharing (reuse KV of a common system prompt across requests — ties to prompt caching).

## 5. Other levers
- **Quantization** (INT8/INT4) → less memory bandwidth → faster (see context/quantization file).
- **FlashAttention** → faster exact attention (fused kernels, less memory IO).
- **Tensor/pipeline parallelism** → split a big model across GPUs.
- **Distillation** → smaller model entirely.
- **Streaming** → lower *perceived* latency (first token fast) even if total unchanged.

## 6. Throughput vs latency (the trade-off)
- **Latency** (time per token / TTFT) matters for interactive UX; **throughput** (tokens/sec across all users) matters for cost.
- Bigger batches → higher throughput but can raise per-request latency → tune to your SLO.
- Managed APIs (AOAI) handle all this; relevant when **self-hosting** open models.

## 7. The hard follow-ups (with answers)
1. **"Why is LLM generation slow?"** → autoregressive, one token/pass, **memory-bandwidth bound**, sequential decode. (§1)
2. **"What is speculative decoding?"** → small draft model proposes k tokens, big model **verifies in one pass**; lossless quality, 2–3× faster. (§2)
3. **"Does speculative decoding change output quality?"** → no — verification preserves the target model's distribution. (§2)
4. **"Serve more users per GPU?"** → **continuous batching** + **PagedAttention** KV management. (§3/§4)
5. **"KV cache problem?"** → grows with length×batch → memory limit on concurrency → PagedAttention/quantized KV. (§4)
6. **"Throughput vs latency?"** → larger batches raise throughput but can hurt per-request latency → tune to SLO. (§6)
7. **"Prefill vs decode?"** → prefill = parallel/compute-bound (prompt); decode = sequential/bandwidth-bound (generation). (§1)

## 8. One-screen recall
- Generation = **autoregressive, memory-bandwidth bound**; decode is the slow sequential part (prefill is parallel).
- **Speculative decoding**: small **draft** proposes k tokens → big **target verifies in one pass** → 2–3× faster, **lossless** (Medusa/EAGLE/n-gram variants).
- **Continuous (in-flight) batching** (vLLM/TGI) = throughput; **PagedAttention** = efficient KV cache → more concurrency.
- Levers: **quantization**, **FlashAttention**, tensor/pipeline parallelism, distillation, **streaming** (perceived latency).
- **Throughput vs latency** trade-off → tune batch size to SLO. Mostly for **self-hosting**.

> Next: back to the deep-dive index.
