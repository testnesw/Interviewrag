# LEVEL 3 · System Design — Enterprise LLM Gateway

> Synthesis scenario. Combines: APIM · AOAI · security · cost · monitoring ·
> multi-tenancy · rate limiting.

---

## 0. The prompt
> *"Many teams in the company want to use LLMs. Build a central 'AI gateway' so they don't each manage their own keys, quotas, and safety. Provide cost attribution, rate limits per team, failover across regions, and central governance."*

---

## 1. Clarify — requirements
**Functional**: single endpoint for all LLM access; multiple models/providers; per-team quotas + cost tracking; central logging + safety.
**Non-functional**: high availability (failover), low added latency (<50ms overhead), security (no raw keys to teams), governance/audit.
**Killer constraints**: **multi-tenant fairness** (one team can't starve others) + **cost attribution** + **resilience** across AOAI capacity limits.

## 2. Architecture
```
Teams → [APIM Gateway] → AOAI (region A, PTU) ─┐
          │  policies:                          ├─ load-balance / failover
          │  - validate JWT (Entra)             └─ AOAI (region B, PAYG backup)
          │  - per-subscription rate-limit/quota
          │  - token counting → cost log
          │  - Content Safety
          │  - retry / circuit breaker
          └─ Log Analytics (usage, cost, audit)
```
- **APIM** is the core: it fronts AOAI, applies cross-cutting policies, and gives each team a **subscription key** (not the real AOAI key).

## 3. Key design decisions (with "why")
- **APIM as the control plane** → centralizes auth, throttling, transformation, logging without teams touching AOAI directly (they never see the real key).
- **Per-team products/subscriptions** → **rate limit + quota per subscription** → multi-tenant fairness + isolation.
- **Cost attribution**: log **prompt+completion tokens per subscription** (APIM policy parses usage) → chargeback/showback (FinOps).
- **Resilience**: **load-balance across multiple AOAI deployments/regions**; on 429 (capacity) → retry with backoff then **failover** to backup deployment. Circuit breaker on a failing backend.
- **PTU + PAYG mix**: PTU deployment for guaranteed throughput/latency, PAYG as burst overflow.
- **Model routing**: route by requested model/tier (cheap model for simple, GPT-4o for hard) → cost control.

## 4. Security & governance
- **Entra JWT validation** at the gateway (`validate-jwt`); **Managed Identity** from APIM → AOAI (no stored key).
- **Private endpoints**: AOAI not public; APIM in VNet (internal or WAF-fronted).
- **Content Safety** centrally enforced (prompt shields + moderation) → every team gets safety for free.
- **Central audit**: every request (team, model, tokens, latency, safety verdict) → Log Analytics; **Key Vault** for any secrets.

## 5. Performance & scale
- APIM **caching** for identical prompts (optional semantic cache in front).
- Keep gateway overhead low (avoid heavy synchronous policies); **streaming** passthrough for token-by-token responses.
- Scale APIM (Premium, multi-region units); AOAI capacity via multiple deployments.

## 6. Observability
- Dashboards: tokens/cost per team, latency, 429 rate (capacity pressure), safety blocks, model mix.
- **Alerts**: approaching quota, capacity saturation, error spikes.
- Enables **capacity planning** (when to buy more PTU).

## 7. The follow-ups
1. **"Why APIM in front of AOAI?"** → central auth/throttle/cost/safety; teams never hold the real key. (§2/§3)
2. **"Stop one team starving others?"** → per-subscription **rate limits + quotas**. (§3)
3. **"Attribute cost per team?"** → APIM policy logs tokens per subscription → chargeback. (§3)
4. **"Handle AOAI 429 / region outage?"** → retry+backoff then **failover** across deployments/regions; circuit breaker. (§3)
5. **"Guarantee latency for critical team?"** → **PTU** deployment (+ PAYG burst), model routing. (§3)
6. **"Secure AOAI?"** → private endpoints + MI + JWT validation + Content Safety. (§4)
7. **"Stream responses through APIM?"** → streaming passthrough, keep policies light. (§5)
8. **"Know when to buy capacity?"** → monitor 429 rate + token trends → capacity planning. (§6)

## 8. One-screen recall
- **APIM = AI control plane**: teams hit one endpoint with **subscription keys**, never the AOAI key.
- **Multi-tenant**: per-subscription **rate limit + quota**; token logging → **cost attribution/chargeback**.
- **Resilience**: load-balance + **failover** across AOAI deployments/regions; retry/backoff + circuit breaker on 429.
- **Capacity**: **PTU** (guaranteed) + PAYG (burst); **model routing** for cost.
- **Secure**: Entra JWT + **MI** + private endpoints + central **Content Safety** + audit.
- **Observe**: cost/latency/429/safety dashboards → capacity planning.

> Next L3: High-Scale Real-Time GenAI API.
