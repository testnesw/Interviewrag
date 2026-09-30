# DEEP MECHANICS · Prompt Caching & Semantic Caching

> Level 2 — prompt (prefix) caching vs semantic caching, how each works, cost/
> latency wins, and when to use them.

---

## 0. The precise mental model
Two different "caches" in LLM apps, often confused:
1. **Prompt (prefix) caching** — the *provider* caches the **computed attention state** of a repeated **prompt prefix** (system prompt, few-shot examples, long context) → cheaper + faster for the cached tokens.
2. **Semantic caching** — *you* cache **whole responses** keyed by **meaning** (embedding similarity) → a similar question returns a stored answer, skipping the LLM entirely.

---

## 1. Prompt / prefix caching (provider-side)
- LLMs recompute attention over the **entire prompt** each call. If a large **prefix is identical** across calls (same system prompt + tools + few-shot), the provider can **reuse** its computation.
- **Benefit**: cached input tokens are **much cheaper** (e.g., large discount) + **lower latency (TTFT)**.
- **Requirements**: the prefix must be **identical and at the start**; put **static content first**, dynamic/user content last → maximizes cache hits.
- OpenAI/AOAI do this **automatically** for long prompts; Anthropic uses explicit cache breakpoints.

## 2. Semantic caching (application-side)
```
Query → embed → search cache (vector similarity ≥ threshold)?
   hit  → return stored answer (no LLM call)
   miss → call LLM → store (embedding → answer)
```
- Keyed by **semantic similarity**, not exact string → "reset my password" ≈ "how do I change my password".
- **Benefit**: skips the LLM for repeat questions → biggest **cost + latency** lever at scale.
- Backed by Redis / vector store; set a **similarity threshold** (too low = wrong answers served).

## 3. Exact vs semantic response cache
- **Exact-match cache**: identical prompt → identical answer (simple, safe, low hit rate).
- **Semantic cache**: similar meaning → cached answer (high hit rate, risk of serving a slightly-off answer) → tune threshold + scope per domain.

## 4. When to use which
- **Prefix caching**: long shared system prompts / few-shot / big static context (RAG instructions) → nearly free win, enable by ordering prompt static-first.
- **Semantic cache**: high-volume, repetitive user questions (FAQ, support) → huge savings; less useful for highly unique queries.
- They **combine**: semantic cache to skip calls; prefix cache to cheapen the calls that remain.

## 5. Risks & tuning
- **Staleness**: cached answers can go out of date → TTL + invalidation when source data changes.
- **Wrong-answer risk** (semantic): threshold too loose serves a similar-but-different answer → tune + optionally verify.
- **Personalization/security**: don't serve one user's answer to another; scope cache keys by user/permissions where needed.

## 6. The hard follow-ups (with answers)
1. **"Prompt caching vs semantic caching?"** → provider caches repeated **prefix computation** (cheaper tokens) vs you cache **whole responses by meaning** (skip the call). (§0)
2. **"Maximize prefix cache hits?"** → put **static content first** (system/few-shot), dynamic/user content last. (§1)
3. **"Biggest cost lever at scale?"** → **semantic cache** for repetitive questions. (§2/§4)
4. **"Risk of semantic cache?"** → serving a similar-but-wrong answer → tune **threshold** + TTL + scope. (§5)
5. **"Exact vs semantic?"** → exact = safe/low hit; semantic = high hit/needs threshold. (§3)
6. **"Handle stale cache?"** → TTL + invalidate on source change. (§5)
7. **"Can you use both?"** → yes — semantic skips calls, prefix cheapens the rest. (§4)

## 7. One-screen recall
- **Prefix caching** (provider): reuse computation of an identical **leading prefix** → cheaper input tokens + lower TTFT; **static-first** prompt ordering; often automatic.
- **Semantic caching** (app): embed query → similarity hit → **return stored answer, skip LLM** → top cost/latency lever for repetitive traffic.
- **Exact** cache (safe, low hit) vs **semantic** (high hit, threshold risk).
- **Risks**: staleness (TTL/invalidate), wrong-answer (tune threshold), personalization/security (scope keys).
- **Combine** both.

> Next: back to the deep-dive index.
