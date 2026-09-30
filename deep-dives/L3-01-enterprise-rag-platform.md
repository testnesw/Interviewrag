# LEVEL 3 · System Design — Enterprise RAG Platform

> Synthesis scenario. Combines: RAG · AI Search · AOAI · security · monitoring · cost.
> Practice delivering this end-to-end in ~15 minutes.

---

## 0. The prompt
> *"Design an enterprise knowledge assistant: 50k employees ask natural-language questions over 10M internal documents (SharePoint, Confluence, PDFs). Answers must cite sources, respect per-user permissions, and never leak data externally."*

---

## 1. Clarify first (always) — requirements
**Functional**: Q&A with citations; multi-source ingestion; freshness (docs change daily); conversational follow-ups.
**Non-functional**: p95 < 3s; ~5 QPS peak (50k users, bursty); **security/permission trimming**; auditability; data residency (EU); cost ceiling.
**The killer constraint**: *per-user document-level security* → the retrieval layer must filter by the asker's access rights.

## 2. High-level architecture
```
User → App (Entra auth) → Orchestrator (API)
         │
         ├─ 1. Rewrite/condense query (AOAI)
         ├─ 2. Retrieve: Azure AI Search (hybrid + semantic rerank)
         │        with SECURITY FILTER on user's group SIDs
         ├─ 3. Assemble prompt (top-k chunks + citations)
         ├─ 4. Generate answer (AOAI GPT-4o) + grounding
         └─ 5. Post: guardrails (Content Safety), cite, log

Ingestion (async): Sources → chunk → embed (AOAI) → index (AI Search)
                    + capture ACLs per document
```

## 3. Key design decisions (with the "why")
- **Retrieval = hybrid search** (BM25 + vector) **+ semantic reranker** → best recall+precision; pure vector misses exact terms (IDs, acronyms).
- **Chunking**: ~300–500 tokens, overlap, preserve headings → balances context vs precision. Store metadata (source, section, ACL).
- **Security trimming**: index each chunk with **group IDs (SIDs)**; at query time add a **filter** `groups/any(g: search.in(g, userGroups))`. Trim at retrieval, never post-hoc (don't send unauthorized text to the LLM).
- **Citations/grounding**: return source URLs + require the model to answer *only* from context ("if not in context, say you don't know") → reduce hallucination.
- **Freshness**: event-driven ingestion (change feed / webhooks) → re-embed changed docs; incremental indexing.

## 4. Scale & performance
- **Cache**: semantic cache for repeated questions (embedding similarity) → cut cost + latency.
- **AOAI capacity**: **PTU (Provisioned Throughput Units)** for predictable latency at scale; fall back to PAYG. Monitor TPM limits.
- **AI Search**: replicas for QPS, partitions for index size (10M docs → size the tier); enable semantic ranker.
- Latency budget: retrieval ~300ms + rerank ~200ms + generation ~1.5s streaming.

## 5. Security & governance
- **Entra ID** auth; **Managed Identity** for service-to-service (no keys).
- **Private endpoints** on AOAI + AI Search + Storage → no public exposure; VNet.
- **Content Safety** (prompt shields for jailbreak, output moderation).
- **Key Vault** for secrets; **RBAC** least-privilege; **audit log** every Q&A (who/what/sources) → Log Analytics.
- Data residency: deploy in EU region; AOAI data not used for training.

## 6. Observability & evaluation
- **App Insights** traces (retrieval hits, tokens, latency per stage).
- **Quality eval**: offline groundedness/relevance scoring (LLM-as-judge), track answer quality over time; user thumbs feedback loop.
- Cost telemetry: tokens per query → $/query unit economics.

## 7. Cost levers
- Semantic cache; right-size model (route simple Qs to cheaper model); PTU vs PAYG break-even; embedding batch; AI Search tier sizing; trim retrieved chunks (fewer input tokens).

## 8. Failure modes & the follow-ups
1. **"How stop hallucination?"** → grounding prompt + citations + "say I don't know" + groundedness eval + Content Safety.
2. **"User sees a doc they shouldn't?"** → **security trimming at retrieval** via ACL filter; never rely on the LLM to hide.
3. **"10M docs, latency?"** → hybrid + rerank on top-k, partitions/replicas, caching, streaming.
4. **"Docs change hourly?"** → event-driven incremental re-embed/index.
5. **"Cost explodes?"** → cache, model routing, PTU, fewer input tokens.
6. **"Evaluate quality?"** → LLM-as-judge groundedness/relevance + human feedback.
7. **"Multi-turn?"** → condense history into a standalone query before retrieval.

## 9. One-screen recall
- **Flow**: auth → query-rewrite → **hybrid retrieve + rerank (ACL filter)** → grounded generate → guardrails + cite + log.
- **Security trimming at retrieval** (SIDs filter) = the signature requirement.
- **Hybrid + semantic reranker**; chunk 300–500 w/ overlap + metadata.
- **Scale**: PTU, replicas/partitions, semantic cache, streaming.
- **Secure**: Entra + MI + private endpoints + Content Safety + audit.
- **Eval**: groundedness LLM-judge + feedback; **cost**: cache/route/PTU/fewer tokens.

> Next L3: Production Multi-Agent System.
