# LEVEL 3 · System Design — High-Scale Real-Time GenAI API

> Synthesis scenario. Combines: AOAI · caching · async · autoscale · resilience ·
> streaming · cost · performance.

---

## 0. The prompt
> *"Expose a public-facing GenAI feature (e.g., AI writing assistant) to 1M daily users, bursty traffic, streaming responses, p95 first-token < 1s. Keep it reliable and cost-efficient."*

---

## 1. Clarify — requirements
**Functional**: text generation with **streaming**; conversation history; some requests long-running.
**Non-functional**: **1M DAU**, spiky (10x peaks); p95 **time-to-first-token < 1s**; graceful degradation; strict cost ceiling; abuse protection.
**Killer constraints**: **AOAI token-per-minute (TPM) limits** + **bursty load** + **streaming at scale**.

## 2. Architecture
```
Clients → Front Door (WAF, TLS, geo) → API (stateless, autoscaled)
   │           │
   │           ├─ Auth + rate-limit (per user)
   │           ├─ Semantic cache (Redis) — hit? return instantly
   │           ├─ AOAI call (PTU primary + PAYG overflow), STREAMING
   │           └─ persist conversation (Cosmos DB)
   └─ Long jobs → Queue → worker pool → notify (async pattern)
```

## 3. Key design decisions (with "why")
- **Stateless API + horizontal autoscale** (AKS/Container Apps) → absorb bursts; scale on concurrency/queue depth, not just CPU (LLM calls are I/O-bound, CPU stays low).
- **Streaming (SSE/websocket)** end-to-end → first token fast, perceived latency low; backpressure-aware.
- **Async I/O** (FastAPI/async) → each instance handles thousands of concurrent in-flight LLM calls (I/O-bound → don't block threads).
- **Semantic cache (Redis)** → identical/similar prompts served instantly → huge cost + latency win at scale.
- **Capacity**: **PTU** for baseline guaranteed throughput + **PAYG spillover**; spread across **multiple AOAI deployments/regions** to beat TPM limits; retry on 429 → failover.
- **Conversation store**: Cosmos DB (low-latency, global, partition by user) — not in app memory (stateless).

## 4. Resilience & graceful degradation
- **429/timeout** → retry w/ backoff+jitter → failover deployment → if all fail, **degrade** (queue for async, or smaller/cheaper model, or friendly "try again").
- **Circuit breaker** per backend; **bulkheads** (isolate long jobs from fast path via the queue).
- **Timeouts** on every external call; idempotency keys for retried requests.

## 5. Performance / latency budget
- First-token target < 1s: cache-check (~5ms) → AOAI stream start (~500–800ms). Keep pre-processing minimal.
- **Load leveling**: queue for non-interactive/long tasks (async pattern) → smooths spikes, protects AOAI capacity.
- **Connection pooling** to AOAI; prewarm instances (predictive scale for known peaks).

## 6. Cost control (1M DAU is expensive)
- **Semantic + exact cache** (biggest lever), **model routing** (cheap model default, escalate), **max-tokens caps**, trim history/context, streaming stop-early, PTU break-even vs PAYG.
- Per-user **rate limits + quotas** to cap abuse and runaway cost.

## 7. Security & abuse
- **Front Door WAF** + DDoS; per-user auth + rate limit; **Content Safety** (input + output); prompt-injection shields; audit + anomaly detection on usage.

## 8. Observability
- Metrics: first-token latency, full latency, cache-hit %, 429 rate, tokens/cost per user, error rate.
- Traces (App Insights); alerts on capacity saturation + cost anomalies → capacity planning.

## 9. The follow-ups
1. **"Autoscale signal for LLM API?"** → **concurrency/queue depth** (I/O-bound; CPU misleads). (§3)
2. **"Beat AOAI TPM limits at peak?"** → multi-deployment/region spread + **PTU + PAYG overflow** + retry/failover + cache. (§3)
3. **"First token < 1s?"** → streaming + minimal pre-processing + cache + warm instances. (§5)
4. **"All AOAI capacity exhausted?"** → graceful degradation: queue async / cheaper model / friendly retry. (§4)
5. **"Biggest cost lever?"** → **semantic cache** + model routing + token caps. (§6)
6. **"Handle a huge burst?"** → stateless autoscale + **queue load-leveling** + bulkheads. (§3/§4)
7. **"Store conversation where?"** → Cosmos DB partitioned by user (stateless app). (§3)
8. **"Abuse / injection?"** → WAF + rate limits + Content Safety + prompt shields. (§7)

## 10. One-screen recall
- **Stateless autoscaled API** (scale on **concurrency/queue**, async I/O) + **streaming** end-to-end.
- **Capacity**: **PTU + PAYG overflow** across **multi-region AOAI**; retry/backoff→failover on 429.
- **Cache (Redis semantic)** = top cost/latency lever; model routing + token caps.
- **Resilience**: circuit breaker, bulkheads, **graceful degradation** (queue/cheaper model), timeouts + idempotency.
- **Store**: Cosmos by user. **Secure**: Front Door WAF + rate limits + Content Safety.
- **Observe**: first-token latency, cache-hit%, 429, $/user → capacity planning.

> Next L3: Secure & Compliant GenAI Landing Zone.
