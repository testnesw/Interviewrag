# Deep Dive · Enterprise System Design

> Phase 5 (Senior/architect breadth) · Azure GenAI Architect Interview Prep
> Format: 30 sections × 5 seniority levels (Engineer → Principal Architect)
> This is the capstone: how to run a system-design interview end-to-end.

---

## 1. Executive Summary (30-second answer)
Enterprise system design is the discipline of turning **fuzzy requirements into a concrete, defensible architecture** that meets **functional + non-functional requirements (scale, latency, availability, security, cost)** under real constraints. In an interview you **drive a structured process**: clarify requirements → estimate scale → define APIs & data model → draw a high-level design → deep-dive bottlenecks → address the "-ilities" (scalability, availability, consistency, security, observability, cost) → state tradeoffs. There is **no single right answer** — you're judged on **reasoning, tradeoffs, and communication**, not memorized diagrams.

---

## 2. Architect-Level Explanation
The framework (memorize the flow):
1. **Clarify requirements** — functional (what it does) + **non-functional** (scale, latency, availability, consistency, security, cost). Ask, don't assume.
2. **Estimate scale** — users, RPS, read/write ratio, data volume, growth. Back-of-envelope.
3. **APIs** — define the contract (endpoints, params, responses).
4. **Data model** — entities, storage choice (SQL vs NoSQL), partitioning.
5. **High-level design** — boxes and arrows: client → gateway → services → data → cache → queue.
6. **Deep dive** — pick bottlenecks; detail one or two (caching, sharding, async).
7. **Address the -ilities** — scale, HA, consistency (CAP), security, observability, DR, cost.
8. **Tradeoffs & wrap-up** — state what you optimized and what you'd revisit.

Building blocks: load balancer, API gateway, stateless services, cache (Redis), CDN, queue/broker, SQL/NoSQL, sharding/replication, search index, blob storage.

---

## 3. Why It Exists
- **Problem**: real systems have competing constraints — you can't maximize scale, consistency, cost, and simplicity simultaneously.
- **The discipline exists** to make **deliberate, justified tradeoffs** aligned to business needs, and to communicate them so teams build the right thing.
- **In interviews**: it tests whether you can reason under ambiguity, handle scale, and defend decisions — the core of the architect role.
- **CAP theorem** underpins it: under partition you choose consistency **or** availability — a forced tradeoff you must name.

---

## 4. Internal Working
**The reasoning loop:**
```
Requirements ──► Scale estimate ──► APIs + Data model
       │                                  │
       └──────► High-level design ◄───────┘
                       │
          Identify bottleneck (read-heavy? write-heavy? hot key?)
                       │
      Apply pattern: cache · shard · replicate · async queue · CDN · CQRS
                       │
        Re-check -ilities (scale/HA/consistency/security/cost)
                       │
                 State tradeoffs
```
Key mechanics to reason about:
- **Read-heavy** → caching + read replicas + CDN.
- **Write-heavy** → sharding/partitioning + async ingestion + write-optimized store.
- **Hot partition** → better partition key / consistent hashing.
- **Latency** → cache, edge/CDN, precompute, denormalize.
- **Consistency vs availability** → CAP choice per data type (strong for money, eventual for feeds).

---

## 5. Enterprise Use Case
Design an **enterprise GenAI knowledge assistant** for 100k employees: clarify (RAG over internal docs, <3s latency, 50 RPS peak, strict data isolation) → estimate (docs, embeddings volume, token cost) → design (client → APIM → orchestrator → Azure AI Search vector store + AOAI, Redis semantic cache, async ingestion pipeline) → deep-dive (caching to cut cost/latency, chunking/retrieval quality, per-tenant security) → -ilities (scale via stateless HPA, HA multi-zone, DR multi-region, security via Managed Identity + private endpoints + RBAC filtering, observability via OTel + token metrics, cost via caching + model routing). State tradeoffs: semantic cache freshness vs cost.

---

## 6. Real Production Architecture
```
 Users ─► Front Door(WAF/CDN) ─► APIM (auth, rate limit)
                                     │
                        Orchestrator service (stateless, HPA)
                          │           │              │
                   Semantic cache   Retrieval     Azure OpenAI
                     (Redis)      (AI Search PE)   (PE, MI)
                          │
        Async ingestion: Blob ─► chunk/embed ─► AI Search index
                          │
     OpenTelemetry ─► App Insights (latency, tokens, cache hit, cost)
     Security: Managed Identity · Private Endpoints · Key Vault · RBAC
     HA: multi-zone · DR: multi-region via Front Door
```

---

## 7. Security Best Practices
- **Zero trust**: authenticate every layer (Entra JWT at gateway, per-service authz).
- **Managed Identity + Key Vault** (no secrets); **private endpoints** (no public data plane).
- **Data isolation/multi-tenancy**: enforce tenant/user filters at retrieval (row-level / index filters) — never leak cross-tenant data.
- **Defense in depth**: WAF → gateway → network policy → service authz → data RBAC.
- **Encryption** in transit (TLS) + at rest (CMK where required); **PII handling** + audit logs.
- **Responsible AI / guardrails** for GenAI (content filters, prompt-injection defenses).

---

## 8. Scaling Strategy
- **Stateless services + horizontal scale** (HPA/load balancer); externalize state.
- **Cache aggressively** (Redis/semantic cache/CDN) for read-heavy paths.
- **Shard/partition** write-heavy data by a good key (avoid hot partitions).
- **Async + queues** to absorb spikes and decouple.
- **Read replicas** + **CQRS** to scale reads; **precompute/denormalize** for latency.
- **Autoscale on the right metric** (queue depth, RPS, GPU/token load for GenAI).

---

## 9. High Availability Strategy
- **Redundancy at every tier** across **availability zones**; no single point of failure.
- **Load balancers + health checks**; **stateless** services for easy failover.
- **Replicated data** (multi-zone) + failover; **graceful degradation** (serve cached/partial results).
- **Resilience patterns** (timeout/retry/circuit breaker/bulkhead) between components.
- Target explicit SLA (e.g., 99.9%) and design tiers to meet it.

---

## 10. Disaster Recovery Strategy
- **Define RTO/RPO** per business criticality → pick DR pattern (active-active / active-passive / backup-restore).
- **Geo-replicated data** (SQL geo-replication / Cosmos multi-region / GRS blob).
- **IaC** to rebuild the region; **Front Door** for regional failover.
- **Backups + tested restore**; runbooks; regular DR drills.
- For GenAI: replicate the search index + ensure AOAI capacity in the secondary region.

---

## 11. Cost Optimization Strategy
- **Cache to avoid recompute** (semantic cache saves AOAI tokens; CDN saves egress/compute).
- **Right-size + autoscale + scale-to-zero** off-peak.
- **Model/tier routing** (cheap model for easy queries, premium for hard) in GenAI.
- **Storage tiering** (hot/cool/archive); reserved capacity/PTUs for steady load.
- **Tag + monitor + budget alerts**; kill idle resources; watch egress.
- **Design cost in from day one** — architecture drives 80% of cost.

---

## 12. Common Production Challenges
- **Hot partitions / hot keys** → better partition key, consistent hashing, cache.
- **Cache invalidation / staleness** → TTL, write-through, versioning.
- **Thundering herd on cache miss** → request coalescing / locks.
- **Consistency bugs** → wrong CAP choice for the data type; pick per-use-case.
- **Cascading failures** → resilience patterns + bulkheads.
- **Unbounded cost** (GenAI tokens, egress) → caching + routing + budgets.
- **Single points of failure** hiding in "shared" components.

---

## 13. Monitoring and Observability
- **Golden signals** (latency, traffic, errors, saturation) per tier.
- **Distributed tracing** (OpenTelemetry) + correlation IDs across the whole request.
- **Business/GenAI metrics**: cache hit rate, token usage, cost per request, retrieval quality.
- **SLO dashboards + alerts** on error budget burn; capacity/saturation alerts.
- **Logs + traces + metrics** unified (App Insights / Log Analytics).

---

## 14. Troubleshooting Scenarios
- **Latency spike** → check cache hit rate drop, hot partition, downstream (AOAI) throttling; trace the hop.
- **Partial outage** → find the SPOF or missing circuit breaker; add redundancy/resilience.
- **Cost blowout** → cache misses / no model routing / egress; add caching + routing + budgets.
- **Inconsistent reads** → replication lag or wrong consistency level; adjust per-use-case.
- **Overload/cascading** → bulkheads + backpressure (queues) + autoscale on correct metric.

---

## 15. Tradeoffs (the heart of the interview)
| Tension | Option A | Option B |
|---------|----------|----------|
| CAP (partition) | Consistency | Availability |
| Consistency | Strong (money) | Eventual (feeds) |
| SQL vs NoSQL | ACID, relations | scale, flexible schema |
| Cache | speed/cost | staleness risk |
| Sync vs async | simple, immediate | decoupled, resilient |
| Monolith vs microservices | simple | independent scale |
| Cost vs performance | cheaper | faster |

**Always name the tradeoff you chose and why.**

---

## 16. When NOT to over-engineer
- **Premature scale**: don't design for 1B users when you have 1k — start simple, evolve.
- **Unneeded microservices/multi-region** add cost + complexity without payoff.
- **Over-caching** creates consistency bugs for low-traffic data.
- **Gold-plating DR** beyond the business RTO/RPO wastes money.
- The senior move is **matching complexity to actual requirements**.

---

## 17. Comparison with Alternatives (design approaches)
| Approach | Pro | Con |
|----------|-----|-----|
| Monolith-first | fast, simple | scale limits later |
| Microservices | independent scale | distributed complexity |
| Serverless | no ops, scale-to-zero | cold start, limits |
| Event-driven | decoupled, resilient | eventual consistency, harder to trace |

Match approach to scale, team, and consistency needs.

---

## 18. Interview Questions
1. Walk me through your system-design process.
2. How do you estimate scale (back-of-envelope)?
3. Explain CAP and how it drives your choices.
4. SQL vs NoSQL — how do you decide?
5. How do you scale a read-heavy system? Write-heavy?
6. How do you handle a hot partition?
7. Strong vs eventual consistency — give examples.
8. How do you make a system highly available?
9. How do you design for a target RTO/RPO?
10. How do you keep cost under control at scale?

---

## 19. Strong Interview Answers
- **Process**: "I clarify functional + non-functional requirements, estimate scale, define APIs and data model, draw a high-level design, deep-dive the bottleneck, then walk the -ilities — scalability, availability, consistency, security, observability, cost — and finish with explicit tradeoffs."
- **CAP**: "Under a network partition you must choose consistency or availability. I choose **per data type**: strong consistency for payments/inventory, eventual for feeds/recommendations. Naming that tradeoff is the point."
- **Read-heavy**: "Cache (Redis + CDN), read replicas, denormalize/precompute, and consider CQRS. I'd measure cache hit rate and watch for thundering herd on misses."
- **Write-heavy**: "Partition/shard by a key that spreads load, ingest asynchronously via a queue, use a write-optimized store, and avoid hot partitions with a good key or consistent hashing."
- **Don't over-engineer**: "I match complexity to requirements — start with a modular monolith and single region, and evolve to microservices/multi-region when scale and business need justify it. Premature complexity is a failure mode."

---

## 20. Architecture Diagrams
**Generic scalable web system:**
```
Client ─► CDN ─► LB ─► API Gateway ─► [stateless services x N]
                                        │        │        │
                                     Cache    Queue    Primary DB
                                    (Redis)  (async)   ├─ read replicas
                                                        └─ sharded/partitioned
```

---

## 21. Real Project Example
**Enterprise GenAI assistant, 100k users.** Requirements clarified (RAG, <3s p95, strict tenant isolation, cost ceiling). Design: Front Door/CDN → APIM → stateless orchestrator (HPA) → semantic cache (Redis) → Azure AI Search (vector, private endpoint) + Azure OpenAI (private endpoint, Managed Identity); async ingestion pipeline builds the index. Deep-dived semantic caching (cut token cost ~40% and latency) and per-tenant retrieval filters (security). -ilities: multi-zone HA, multi-region DR via Front Door, OTel tracing with token/cost metrics, model routing for cost. Stated tradeoff: semantic-cache staleness vs cost — chose short TTL + versioning.

---

## 22. Whiteboard Design Question
> *"Design a globally scalable GenAI chat assistant for 1M users with <2s latency and strict data isolation."*

Drive the full framework: clarify (RPS, read/write, latency, isolation, budget) → estimate scale/tokens → APIs (`/chat`, `/ingest`) → data model (docs, embeddings, chat history) → high-level (CDN/Front Door → gateway → stateless orchestrator → semantic cache → vector retrieval + AOAI → async ingestion) → deep-dive (caching, sharding chat history, retrieval quality) → -ilities (HPA scale, multi-zone HA, multi-region DR, Managed Identity + private endpoints + tenant filtering, OTel + cost metrics, model routing for cost) → tradeoffs (cache freshness, strong vs eventual for history). Keep talking; state assumptions.

---

## 23. Design Review Questions
- **Requirements clarified** (functional + non-functional) before designing?
- **Scale estimated** (RPS, data, growth)?
- **Bottleneck identified + deep-dived**?
- **CAP/consistency chosen per data type**?
- **-ilities all addressed** (scale/HA/consistency/security/observability/DR/cost)?
- **Tradeoffs explicitly stated**?
- **Not over-engineered** for the actual scale?
- **Security + observability + cost designed in** (not bolted on)?

---

## 24. Hands-on Example (back-of-envelope estimation)
```
GenAI assistant: 100k users, 10 queries/user/day
= 1,000,000 queries/day ≈ 1,000,000 / 86,400 ≈ 12 RPS avg
Peak (5x)  ≈ 60 RPS
Avg tokens/query ≈ 2,000 (prompt+completion)
Daily tokens ≈ 1,000,000 * 2,000 = 2.0B tokens/day
Cost lever: 40% semantic-cache hit ⇒ ~0.8B billable tokens saved/day
Instances: 60 RPS / (say 20 RPS per pod) ⇒ 3 pods + headroom ⇒ HPA 4–10
```

---

## 25. Terraform Example
```hcl
# Skeleton: gateway + stateless service + cache + private data plane (design in IaC)
resource "azurerm_redis_cache" "semantic" {           # cache tier = read/cost lever
  name = "genai-cache" resource_group_name = var.rg location = var.loc
  capacity = 1 family = "P" sku_name = "Premium"       # zone-redundant for HA
  zones = ["1","2","3"]
}
# APIM (gateway), Container App (stateless, HPA), AI Search + AOAI with private endpoints,
# Managed Identity role assignments — composed per the reference architecture (omitted for brevity)
```

---

## 26. Azure Example
```bash
# Multi-region DR posture: Front Door fronting two regional stamps
az afd endpoint create -g rg --profile-name genai-fd --endpoint-name assistant
az afd origin create -g rg --profile-name genai-fd --origin-group-name stamps \
  --origin-name eastus --host-name eastus.assistant.internal --priority 1 --weight 1000
az afd origin create -g rg --profile-name genai-fd --origin-group-name stamps \
  --origin-name westeu --host-name westeu.assistant.internal --priority 2 --weight 1000
# priority 1 active, 2 failover ⇒ active-passive DR meeting RTO
```

---

## 27. Code Example
```python
# Cache-aside (read-heavy pattern) — the single most useful design building block
async def get_answer(query: str) -> str:
    key = semantic_key(query)                 # embedding-based cache key
    cached = await redis.get(key)
    if cached:                                # cache hit → cheap + fast
        return cached
    answer = await rag_pipeline(query)        # miss → compute (retrieval + AOAI)
    await redis.set(key, answer, ex=3600)     # TTL controls staleness vs cost
    return answer
```

---

## 28. Things Architects Must Remember
- **Clarify requirements first** (functional + non-functional) — never assume.
- **Estimate scale** (RPS, data, growth) before designing.
- **There's no single right answer** — you're judged on **reasoning + tradeoffs + communication**.
- **CAP is a forced choice** under partition — pick consistency vs availability **per data type**.
- **Read-heavy → cache/replicas/CDN; write-heavy → shard/async**.
- **Address every -ility**: scale, HA, consistency, security, observability, DR, cost.
- **Design security, observability, and cost in from day one.**
- **Don't over-engineer** — match complexity to actual requirements; evolve.
- **Always state your tradeoffs out loud.**

---

## 29. Mnemonics and Memory Tricks
- **Process "C-E-A-D-H-D-I-T"**: **C**larify → **E**stimate → **A**PIs → **D**ata model → **H**igh-level → **D**eep-dive → **I**lities → **T**radeoffs.
- **The "-ilities" S-A-C-S-O-D-C**: **S**calability, **A**vailability, **C**onsistency, **S**ecurity, **O**bservability, **D**R, **C**ost.
- **CAP "pick 2 under P"** — Consistency or Availability when Partitioned.
- **"Read → cache; Write → shard."**
- **"Match complexity to requirements"** — don't gold-plate.
- **"Name the tradeoff"** — every decision has a cost.

---

## 30. One-Page Interview Revision Sheet
- **Framework (C-E-A-D-H-D-I-T)**: Clarify → Estimate scale → APIs → Data model → High-level design → Deep-dive bottleneck → -ilities → Tradeoffs.
- **Non-functional first**: scale, latency, availability, consistency, security, cost.
- **Estimate**: users × actions → RPS → peak (×5); data volume; tokens (GenAI).
- **CAP**: under partition choose C or A; pick **per data type** (strong for money, eventual for feeds).
- **Read-heavy**: cache (Redis/CDN) + read replicas + denormalize + CQRS.
- **Write-heavy**: shard/partition (good key) + async queue + write-optimized store.
- **-ilities (S-A-C-S-O-D-C)**: scalability, availability, consistency, security, observability, DR, cost.
- **HA**: redundancy across zones, stateless, health checks, resilience patterns.
- **DR**: define RTO/RPO → active-active/passive/backup; geo-replication + Front Door.
- **Cost**: cache, autoscale, tiering, model routing, budgets — design in from day one.
- **Don't over-engineer**; **always state tradeoffs**.
- **Remember**: no single right answer — reasoning + tradeoffs + communication win.

---

## 🔥 Challenge: 10 Interview Questions (answer these out loud)
1. Walk your full system-design framework in 60 seconds.
2. Estimate RPS, data, and token cost for a 100k-user GenAI assistant.
3. Explain CAP and give a per-data-type consistency decision.
4. Scale a read-heavy system, then a write-heavy one — concretely.
5. You have a hot partition in production — diagnose and fix.
6. Design HA to hit 99.9%, then 99.99% — what changes?
7. Design DR for RTO 15 min / RPO 5 min — what pattern and why?
8. How do you keep GenAI token cost bounded at scale?
9. Where would you deliberately choose NOT to add complexity?
10. Name three tradeoffs you made in your last design and defend them.

---

> Phase 5 deep-dives complete. Next: **Question Banks** (Top 100 Architect + Top 50 per domain).
