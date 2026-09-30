# DEEP MECHANICS · System Design (Worked, with the Math)

> Level 2 — the actual estimation math, the caching/sharding/consistency
> mechanics with *why*, and a fully worked GenAI system design you can narrate
> end-to-end. This is the capstone interview skill.

---

## 0. The precise mental model
System design is **constraint-driven decision-making**: you extract requirements, **quantify** them (RPS, data, latency budget), pick building blocks whose mechanics fit those numbers, deep-dive the bottleneck, and **name every tradeoff** (CAP, consistency, cost vs latency). There is no "right" diagram — you're scored on **reasoning, numbers, and tradeoffs**. Drive the process; think out loud.

---

## 1. The framework (drive it, don't recite it)
**C-E-A-D-H-D-I-T:** Clarify → Estimate → APIs → Data model → High-level design → Deep-dive bottleneck → -ilities → Tradeoffs.
1. **Clarify** functional + **non-functional** (scale, latency SLO, consistency, security, budget). Ask before assuming.
2. **Estimate** scale (below).
3. **APIs** — the contract.
4. **Data model** — entities + storage choice + partition key.
5. **High-level** — client → CDN → gateway → services → cache → queue → data.
6. **Deep-dive** the actual bottleneck (read-heavy? write-heavy? hot key?).
7. **-ilities** — scale, HA, consistency, security, observability, DR, cost.
8. **Tradeoffs** — state what you optimized and what you'd revisit.

---

## 2. Estimation math (be fluent — they watch you do this)

**Convert users → RPS:**
```
DAU × actions/user/day = requests/day
requests/day ÷ 86,400 = average RPS
peak RPS = average × peak factor (3–5× typical, spikier for consumer)
```
**Worked (GenAI assistant):**
```
100,000 users × 10 queries/day = 1,000,000 req/day
1,000,000 ÷ 86,400 ≈ 12 RPS average
peak (×5) ≈ 60 RPS
```
**Storage:**
```
items × size × replication × growth-horizon
e.g., 10M docs × 5 chunks × 3 KB embedding+text ≈ 150 GB (× replicas)
```
**Bandwidth:** `RPS × avg payload`. **Latency budget:** split an SLO across hops (e.g., 2 s total = 50  ms gateway + 50 ms retrieval + ~1.8 s LLM).
**GenAI tokens:** `queries/day × tokens/query`; apply cache hit-rate to get billable tokens.

**Round aggressively** — the interviewer wants the *method* and order-of-magnitude, not precision. State assumptions out loud.

---

## 3. Read-heavy vs write-heavy — different mechanics

**Read-heavy (most systems):**
- **Cache** (Redis/CDN) — cache-aside is the workhorse: check cache → miss → load DB → populate cache (TTL). Turns DB reads into memory reads.
- **Read replicas** — offload reads to replicas (accept **replication lag** → eventual consistency on reads).
- **Denormalize / precompute** — store data in the shape you read it (fewer joins).
- **CDN** — cache static/edge content near users.

**Write-heavy:**
- **Shard/partition** by a key that **spreads load evenly** (avoid hot partitions).
- **Async ingestion** — buffer writes through a **queue**; process at a sustainable rate (smooths spikes, decouples).
- **Write-optimized stores** (LSM-tree DBs like Cassandra) — sequential writes, high throughput.
- **Batch** writes where possible.

**Deep follow-up: "Reads are fine but writes are melting the DB — what do you change?"**
Introduce a **queue** in front of writes (async ingestion) to smooth bursts, **shard** by a high-cardinality key to spread load, and consider a write-optimized store. Don't just scale up the single DB — you'll hit a wall.

---

## 4. Caching mechanics & the traps
- **Cache-aside (lazy)** — app manages cache; stale until TTL/invalidation. Most common.
- **Write-through** — write cache + DB together (fresh, slower writes).
- **Write-behind** — write cache, async to DB (fast, risk of loss).

**The hard problems:**
- **Invalidation** — "the two hard things." Use TTL + explicit invalidation on write; version keys.
- **Thundering herd / cache stampede** — a hot key expires → thousands of concurrent misses hammer the DB simultaneously. Fix: **request coalescing / locks** (only one recomputes), staggered TTLs, or refresh-ahead.
- **Hot key** — one key gets disproportionate traffic → replicate it across nodes or add a local in-process cache layer.

**Deep follow-up: "A popular item's cache entry expires and the DB gets hammered — name it and fix it."**
Cache stampede/thundering herd. Fix with a **mutex/single-flight** so only one request recomputes while others wait for the result, plus jittered TTLs and optionally refresh-ahead before expiry.

---

## 5. Consistency & CAP — decide per data type

**CAP:** under a **network partition (P)** you must choose **Consistency** or **Availability** — you can't have both *during* the partition. (When there's no partition you can have both.)

**Apply per data type (this is the senior move):**
- **Strong consistency** — money, inventory counts, auth. Correctness > availability.
- **Eventual consistency** — feeds, recommendations, view counts, search indexes. Availability/scale > instant correctness.

**PACELC (deeper):** even without a partition (Else), there's a **Latency vs Consistency** trade — synchronous replication is consistent but slower; async is faster but stale. So the real question is "how much staleness can this data tolerate?"

**Deep follow-up: "Your feed shows a slightly stale like-count — is that a bug?"**
No — for a like-count, **eventual consistency** is the correct, deliberate choice (availability + scale). You'd only pick strong consistency where staleness causes real harm (double-spend, oversell). Naming this per-data-type decision is what they want.

---

## 6. Sharding & hot partitions
- **Sharding** = horizontal partitioning of data across nodes by a **partition key**.
- **The key choice is everything:** it must have **high cardinality** and **even access distribution**. A bad key (e.g., `country` when 80% of traffic is one country, or a monotonically increasing timestamp) creates a **hot partition** that bottlenecks the whole system.
- **Consistent hashing** — spreads keys around a ring so adding/removing nodes only remaps a fraction of keys (vs modulo hashing which remaps almost everything). This is how caches/DBs rebalance with minimal movement.

**Deep follow-up: "You sharded by customer_id but one whale customer is 40% of traffic — what happens and fix?"**
That shard becomes a **hot partition** (bottleneck + uneven load). Fix: a **composite/finer key** (e.g., customer_id + sub-entity), separate handling for the whale, or add a caching layer in front. Sharding only helps if the key spreads load.

---

## 7. HA / DR / SLA (the math from Azure Architecture, applied)
- **Composite SLA**: series dependencies **multiply** (each added dependency lowers total); redundant/parallel components **raise** it (`1 − ∏ failure-probabilities`). → remove SPOFs, add replicas.
- **HA** = **zone-redundant** (survive a datacenter), stateless services, health checks, resilience patterns.
- **DR** = **multi-region**; **RPO** driven by replication (sync≈0 vs async lag), **RTO** by failover mechanism (automated minutes vs manual hours). Pick backup-restore / warm-standby / active-active to hit the numbers.

---

## 8. Fully worked example — narrate this end-to-end

> **"Design a GenAI knowledge assistant for 100k employees, <3 s p95, strict tenant isolation, cost-capped."**

**Clarify:** RAG over internal docs; 60 RPS peak; per-tenant data isolation; groundedness required; budget ceiling.
**Estimate:** 12 RPS avg / 60 peak; ~2000 tokens/query → 2B tokens/day; ~150 GB embeddings; latency budget: 50 ms gateway + 50 ms retrieval + rerank 150 ms + LLM ~1.8 s (stream to hide it).
**APIs:** `POST /chat` (stream), `POST /ingest`.
**Data model:** chunks (id, vector, text, **tenant_id**, source, date) in Azure AI Search; chat history in Cosmos (partition by tenant/user).
**High-level:** Front Door(WAF/CDN) → APIM (auth, **token rate-limit**) → stateless orchestrator (HPA) → **semantic cache (Redis)** → hybrid retrieval (AI Search, **pre-filter tenant_id**) → AOAI (private endpoint, Managed Identity) → stream tokens back; async ingestion pipeline builds the index.
**Deep-dive (bottleneck = cost + latency):** semantic cache cuts ~40% of tokens + latency; rerank only top-50; model routing (cheap model for simple Q). **Security deep-dive:** tenant isolation via **query-time pre-filter** + per-tenant auth — never trust the prompt.
**-ilities:** scale = stateless HPA + queue for ingestion; HA = multi-zone; DR = second region via Front Door (replicate index, RPO≈mins); observability = OTel + token/cost/cache-hit metrics; security = MI + private endpoints + Key Vault; cost = cache + routing + budgets.
**Tradeoffs:** semantic-cache **staleness vs cost** (chose short TTL + versioning); eventual consistency for chat history is fine; strong consistency not needed anywhere here.

---

## 9. The hard follow-up questions (with answers)
1. **"Estimate RPS and tokens for 100k users, 10 queries/day."** → ~12 avg / 60 peak RPS; ~2B tokens/day; apply cache hit-rate for billable. (§2)
2. **"Read-heavy vs write-heavy — different fixes?"** → reads: cache/replicas/denormalize/CDN; writes: shard + async queue + write-optimized store. (§3)
3. **"Hot key expires, DB hammered — name and fix."** → cache stampede → single-flight/mutex + jittered TTL + refresh-ahead. (§4)
4. **"CAP — give a per-data-type decision."** → strong for money/inventory; eventual for feeds/recommendations; PACELC = latency vs consistency even without partitions. (§5)
5. **"Bad shard key — symptom and fix."** → hot partition; pick high-cardinality even-distribution key / composite key / consistent hashing. (§6)
6. **"Three services in series at 99.9% — SLA and improvement?"** → 99.7%; add redundancy, remove dependencies, add caching/circuit breakers. (§7)
7. **"Hit RTO 5 min / RPO 1 min — what do you build?"** → warm-standby multi-region, async geo-replication (RPO secs–min), Front Door health failover (RTO min), IaC + drills. (§7)
8. **"Where would you NOT add complexity?"** → premature multi-region/microservices/sharding below the scale that needs it; match complexity to requirements; start simpler, evolve. (§0)

---

## 10. One-screen deep-recall sheet
- **Process C-E-A-D-H-D-I-T**: Clarify → Estimate → APIs → Data model → High-level → Deep-dive → -ilities → Tradeoffs. Non-functional first.
- **Estimate**: DAU×actions ÷ 86,400 = avg RPS; ×(3–5) = peak; storage = items×size×replicas×growth; latency = split SLO across hops; tokens = queries×tokens×(1−cache).
- **Read-heavy**: **cache-aside** + read replicas (lag) + denormalize + CDN. **Write-heavy**: **shard** (even key) + **async queue** + write-optimized store + batch.
- **Cache**: aside/through/behind; hard = **invalidation** + **stampede** (single-flight/mutex, jittered TTL) + **hot key** (replicate).
- **CAP**: under partition pick **C or A**; decide **per data type** (strong=money, eventual=feeds); **PACELC** = latency vs consistency otherwise.
- **Sharding**: partition key must be **high-cardinality + even**; bad key = **hot partition**; **consistent hashing** minimizes remap on rebalance.
- **SLA math**: series **multiply** (worse), parallel **1−∏fail** (better) → kill SPOFs, add replicas. HA=zones; DR=regions (RPO=replication, RTO=failover).
- **Judgment**: no single right answer — **numbers + tradeoffs + communication**; don't over-engineer; **always name the tradeoff**.

---

> ✅ Batch 3 complete (Agentic AI · Microservices · System Design).
> Remaining high-ROI: Semantic Kernel, Event-driven, Managed Identity/Entra,
> Observability/OTel, Cost/FinOps. Say "continue" for the final batch.
