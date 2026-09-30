# Deep Dive · RAG (Retrieval-Augmented Generation)

> Phase 1 (Highest ROI) · Azure GenAI Architect Interview Prep
> Format: 30 sections × 5 seniority levels (Engineer → Principal Architect)

---

## 1. Executive Summary (30-second answer)
RAG (Retrieval-Augmented Generation) **grounds an LLM in your own data at inference time**: instead of relying on the model's frozen training knowledge, you **retrieve relevant chunks** from a knowledge store (usually a **vector + keyword hybrid** index like Azure AI Search), inject them into the prompt as context, and the LLM answers **from that context with citations**. It's the #1 pattern for enterprise GenAI because it delivers **fresh, accurate, source-attributed answers** over private data **without retraining** — cheaper and more current than fine-tuning, and the primary defense against hallucination.

---

## 2. Architect-Level Explanation
RAG is a **two-pipeline system**: an offline **ingestion/indexing pipeline** and an online **retrieval + generation pipeline**.
- **Ingestion (offline)**: load → parse/OCR → **chunk** → **embed** → store vectors + metadata + text in an index.
- **Query (online)**: embed the user query → **retrieve** top-K chunks (vector + keyword **hybrid**, then **semantic rerank**) → **assemble** a grounded prompt → **LLM generates** an answer with citations → optionally **evaluate/guardrail**.
- **Core levers an architect tunes**: chunking strategy, embedding model, hybrid vs pure vector, reranking, K, context budget, query transformation (rewrite/HyDE/multi-query), metadata filtering, and **security trimming** (per-user authorization).
- **Quality equation**: **Answer quality ≈ Retrieval quality**. Most RAG failures are *retrieval* failures, not model failures. "Garbage retrieved = garbage generated."
- **Advanced forms**: **agentic RAG** (the model decides what/when to retrieve, multi-step), **GraphRAG** (knowledge-graph-augmented), **hybrid + reranking**, **query planning**.

---

## 3. Why It Exists
- **LLMs have three gaps**: (1) **knowledge cutoff** (stale), (2) **no private/enterprise data**, (3) **hallucination** (plausible but wrong).
- **Fine-tuning is a poor fit for knowledge**: expensive, slow, must retrain on every data change, no citations, still hallucinated.
- **Context windows can't hold everything**: you can't stuff 10M documents into a prompt — you must **retrieve the relevant slice**.
- **RAG solves all three**: inject **fresh, private, relevant** facts at query time, with **source citations** for trust/compliance, updated by simply reindexing — no model retraining.

---

## 4. Internal Working
**Ingestion pipeline**
1. **Load**: pull from SharePoint/Blob/DBs/APIs.
2. **Parse/extract**: PDFs, Office, HTML → text (+ OCR for scans, table/layout extraction — e.g., Document Intelligence).
3. **Chunk**: split into retrievable units. Strategies: **fixed-size + overlap**, **recursive/structural** (by heading/section), **semantic** (embedding-based boundaries), **sentence-window**. Typical 300–800 tokens with 10–20% overlap.
4. **Enrich metadata**: source, title, section, ACL/security labels, timestamps, page.
5. **Embed**: each chunk → vector via an embedding model (e.g., `text-embedding-3-large`, 3072-dim).
6. **Index**: store vector (for ANN search) + original text + metadata in a vector store (Azure AI Search with **HNSW** ANN).

**Query pipeline**
1. **(Optional) query transform**: rewrite, expand, **multi-query**, **HyDE** (generate a hypothetical answer, embed that).
2. **Embed query** → vector.
3. **Retrieve**: **vector (ANN)** for semantic + **keyword/BM25** for exact terms → **hybrid** fusion (RRF).
4. **Rerank**: a cross-encoder/**semantic reranker** reorders top candidates by true relevance.
5. **Filter/trim**: metadata + **security trimming** (drop chunks the user can't see); fit top-K into the **context budget**.
6. **Assemble prompt**: system instruction ("answer only from context, cite, else say unknown") + retrieved chunks + question.
7. **Generate**: LLM produces grounded answer + **citations**.
8. **(Optional) post**: content safety, groundedness check, guardrails.

---

## 5. Enterprise Use Case
A law firm builds a **legal research assistant** over 5M documents (contracts, case law, memos). Attorneys ask natural-language questions; RAG retrieves the exact clauses/cases via **hybrid search + semantic reranking**, and GPT-4o answers **with citations to the source paragraph**. **Security trimming** ensures each attorney only sees matters they're authorized for. Because answers are **grounded + cited**, attorneys can verify — turning a multi-hour research task into minutes, safely.

---

## 6. Real Production Architecture
```
 INGESTION (offline, event/schedule-driven)
 Blob/SharePoint → Doc Intelligence (parse/OCR) → Chunker → Embeddings (AOAI)
      → Azure AI Search index (vector HNSW + text + metadata + ACLs)
      (indexer / Function pipeline; incremental on change)

 QUERY (online)
 User(Entra) → Front Door/APIM → Orchestrator (FastAPI/.NET on AKS)
   ├─ query rewrite (LLM) ─ optional
   ├─ embed query (AOAI embeddings)
   ├─ Azure AI Search: hybrid (vector+BM25) + semantic reranker + $filter(ACL)
   ├─ assemble grounded prompt (top-K within token budget)
   ├─ AOAI GPT-4o → answer + citations (streamed)
   └─ Content Safety + groundedness eval
 Observability: tokens, retrieval hit-rate, groundedness, latency, cost
```

---

## 7. Security Best Practices
- **Security trimming / document-level authorization**: store ACLs (group IDs) in the index; filter retrieval by the user's Entra groups so they only get authorized chunks. **Never rely on the prompt to hide data.**
- **Prompt injection defense**: retrieved content is **untrusted** — delimit it, instruct the model to treat it as data not instructions, validate output, use **prompt shields**.
- **Identity**: Managed Identity + Entra between orchestrator, embeddings, and search; Private Endpoints on AOAI + AI Search.
- **PII handling**: classify/redact during ingestion; respect residency.
- **Data governance**: track source lineage; honor deletion (right-to-be-forgotten → remove from index).
- **Least privilege** on the index (query vs admin keys → prefer RBAC).

---

## 8. Scaling Strategy
- **Index scale**: Azure AI Search **partitions** (storage/throughput) + **replicas** (QPS/HA); size vector index (dimensions × chunks) deliberately.
- **Embedding throughput**: batch embeddings; cache embeddings; incremental (only re-embed changed chunks).
- **Retrieval latency**: ANN (HNSW) tuning (efSearch), reranker only on top candidates, metadata pre-filtering.
- **Caching**: **semantic cache** for repeated questions; cache retrieved context.
- **Async ingestion**: event-driven (Blob trigger/queue), scale-out workers (KEDA).
- **Context budget management**: cap K + chunk size to control tokens/latency/cost.

---

## 9. High Availability Strategy
- **Azure AI Search replicas** (≥3 for read SLA) + zone redundancy; multi-region index replication for regional failover.
- **Stateless orchestrator** autoscaled multi-zone; retries with backoff.
- **AOAI multi-region** (embeddings + chat) behind load balancing (see Azure OpenAI deep dive).
- **Graceful degradation**: if reranker/AOAI throttled → fall back to vector-only / smaller model / cached answer.

---

## 10. Disaster Recovery Strategy
- **Rebuildable index**: keep the **source data + ingestion pipeline as IaC/code** → the index is reconstructable (it's derived state).
- **Replicate the index** to a secondary region (or re-run ingestion there); pre-provision AOAI quota in DR region.
- **Backups**: source docs in geo-redundant storage; embeddings cache to avoid re-paying embedding cost on rebuild.
- **RTO/RPO**: RPO driven by ingestion cadence; RTO by index rebuild/replication time — measure both, drill failover.

---

## 11. Cost Optimization Strategy
- **RAG over fine-tuning** for changing knowledge (no retraining cost).
- **Embedding cost**: batch, **cache**, and **incremental re-embed** only changed chunks (don't re-embed the whole corpus).
- **Right-size chunks + K**: fewer/smaller chunks in context = fewer tokens per query (biggest recurring cost).
- **Cheaper embedding model** where quality allows (`3-small` vs `3-large`); **dimension reduction** (MRL) to shrink index.
- **Semantic caching** of Q→A; **model routing** (mini for easy answers).
- **Right-size AI Search tier**; scale replicas/partitions to actual load.

---

## 12. Common Production Challenges
- **Poor retrieval** (wrong/missing chunks) → the #1 issue; fix chunking, hybrid+rerank, query rewrite.
- **Chunking too big/small** → context dilution or lost meaning.
- **Hallucination despite RAG** → weak grounding prompt, retrieved-but-ignored context, or bad retrieval.
- **"Lost in the middle"** → too many chunks; the model ignores mid-context. Fewer, better chunks + reranking.
- **Stale index** → no incremental ingestion; data drift.
- **Security leakage** → missing trimming; users see unauthorized content.
- **Prompt injection** via poisoned documents.
- **Evaluation gap** → "is it actually good?" unanswered.

---

## 13. Monitoring and Observability
- **Retrieval metrics**: hit rate, recall@K, reranker score distribution, % queries with no good hit.
- **Generation quality**: **groundedness** (is the answer supported by context?), relevance, citation correctness — via Azure AI evaluation / LLM-as-judge + human feedback.
- **Ops**: end-to-end latency (retrieval vs generation split), tokens, cost per query, cache hit rate, index freshness lag.
- **Tracing (OTel)**: query → rewrite → retrieve → rerank → generate spans.
- **Alerts**: groundedness drop, retrieval-miss spike, latency/cost SLO breach, stale index.

---

## 14. Troubleshooting Scenarios
- **Answer is wrong/hallucinated** → inspect *retrieved chunks first*: were the right ones returned? If no → retrieval problem (chunking/hybrid/rerank/query). If yes → grounding prompt / model.
- **"I don't know" too often** → K too low, over-strict prompt, or chunk mismatch; add query rewrite/hybrid.
- **Right doc exists but not retrieved** → pure vector missing exact terms → add **keyword/hybrid**; check chunk boundaries.
- **Slow** → split latency: reranker on too many candidates? big context? embedding call? Optimize each.
- **User sees unauthorized data** → security trimming missing/broken → enforce ACL `$filter`.
- **Quality dropped after data update** → index stale or re-chunk changed semantics; reindex + re-eval.
- **Costs rising** → context too large / re-embedding everything → trim K, incremental embed, cache.

---

## 15. Tradeoffs
| Decision | Pro | Con |
|---|---|---|
| RAG vs fine-tuning | fresh, cited, cheap to update | retrieval complexity, latency |
| Larger chunks | more context/coherence | dilution, fewer distinct hits, more tokens |
| Smaller chunks | precise hits | lost surrounding context |
| Hybrid + rerank | best relevance | more latency + cost |
| More K | higher recall | lost-in-middle, cost, latency |
| Semantic chunking | quality boundaries | ingestion cost/complexity |

---

## 16. When NOT to Use It
- **Knowledge already in the model** / general questions — retrieval adds latency for no gain.
- **Small, static, prompt-fittable** knowledge → just put it in the system prompt.
- **Behavior/format/style** changes → that's **fine-tuning**, not RAG.
- **Deterministic lookups** (exact record by ID) → query the DB directly, no LLM.
- **Real-time structured analytics** → SQL/BI, not RAG.
- **When you can't secure/authorize** the data properly (leakage risk).

---

## 17. Comparison with Alternatives
| Approach | Freshness | Citations | Cost to update | Best for |
|---|---|---|---|---|
| **RAG** | high | yes | low (reindex) | private, changing knowledge |
| Fine-tuning | low (retrain) | no | high | style/format/narrow tasks |
| Long-context stuffing | high | partial | n/a | small corpora that fit |
| Prompt-only | frozen | no | n/a | general tasks |
| GraphRAG | high | yes | medium | multi-hop, relationship-heavy |
| Agentic RAG | high | yes | higher (multi-step) | complex, tool-using queries |

---

## 18. Interview Questions
1. What is RAG and why is it preferred over fine-tuning for knowledge?
2. Walk through the ingestion and query pipelines.
3. What chunking strategies exist and how do you choose?
4. Vector vs keyword vs hybrid search — why hybrid + reranking?
5. Why is "answer quality ≈ retrieval quality"? How do you debug bad answers?
6. How do you implement per-user security (document-level authorization)?
7. What is "lost in the middle" and how do you avoid it?
8. How do you evaluate a RAG system?
9. What are query transformations (rewrite/HyDE/multi-query)?
10. What is agentic RAG / GraphRAG?

---

## 19. Strong Interview Answers
- **RAG vs fine-tune**: "RAG injects **fresh, private, cited** facts at inference by retrieving relevant chunks — update it by reindexing, not retraining. Fine-tuning bakes in **behavior/format**, is expensive to update, and gives no citations and still hallucinates facts. Rule of thumb: **Facts → RAG, Form → Fine-tune**; often combine."
- **Retrieval = quality**: "The LLM can only answer from what you give it, so **most RAG failures are retrieval failures**. When debugging a wrong answer I **inspect the retrieved chunks first** — if the right context wasn't retrieved, no prompt tweak helps. I fix retrieval with better chunking, **hybrid search + semantic reranking**, and query rewriting."
- **Hybrid + rerank**: "Pure **vector** captures semantic similarity but misses exact terms (IDs, names, acronyms); **keyword/BM25** nails exact matches but misses paraphrase. **Hybrid** fuses both (RRF), then a **semantic reranker** (cross-encoder) reorders by true relevance — this combination gives the best recall *and* precision."
- **Security trimming**: "I store document ACLs (Entra group IDs) as metadata in the index and **filter retrieval by the user's groups** at query time, so unauthorized chunks are never even retrieved. Security lives in the **retrieval filter**, never in the prompt — prompts can be bypassed."
- **Evaluation**: "I build an eval set of question/ground-truth pairs and measure **retrieval** (recall@K) and **generation** (**groundedness**, relevance, citation accuracy) using LLM-as-judge + human review, gating prompt/chunking/model changes on it. Plus production signals: user thumbs, no-hit rate, groundedness monitoring."

---

## 20. Architecture Diagrams
**Two pipelines**
```
INGEST:  docs → parse → chunk → embed → [vector + text + ACL] index
QUERY:   q → (rewrite) → embed → hybrid retrieve → rerank → filter(ACL)
             → assemble context → LLM → grounded answer + citations
```
**Retrieval fusion**
```
        ┌─ vector (ANN/HNSW) ─┐
query ──┤                     ├─ RRF fuse ─► semantic rerank ─► top-K
        └─ keyword (BM25) ────┘                 (cross-encoder)
```

---

## 21. Real Project Example
An insurer's **policy assistant**: 2M policy/claim documents ingested via Blob-triggered Functions → Document Intelligence → recursive chunking (by clause) → `text-embedding-3-large` → Azure AI Search (hybrid + semantic reranker). Agents ask "what's covered for water damage on policy type X?"; the system retrieves exact clauses with **ACL trimming per business unit**, GPT-4o answers with **clause citations**, and a nightly **groundedness eval** guards quality. Handling time dropped 50%; every answer is verifiable via citation.

---

## 22. Whiteboard Design Question
> "Design a RAG system over 10M documents for 50k employees with per-user permissions, <2s latency, and verifiable answers."

Expected: incremental ingestion (parse→chunk→embed→index) with ACLs in metadata; Azure AI Search (partitions/replicas, HNSW, hybrid + semantic reranker); query pipeline with rewrite, security `$filter` by Entra groups, top-K within token budget; AOAI embeddings + GPT-4o with citations; caching for latency; evaluation harness (groundedness/recall); HA (replicas/multi-region) + rebuildable-index DR; observability + FinOps. Discuss chunking choice, lost-in-the-middle, and injection defense.

---

## 23. Design Review Questions
- What's the **chunking strategy** and how was it validated?
- **Hybrid + reranking** enabled? What's recall@K on your eval set?
- How is **document-level security** enforced at retrieval time?
- How does the **index stay fresh** (incremental? latency)? Deletion handling?
- What's your **groundedness/eval** gate for changes?
- How do you defend against **poisoned documents** (injection)?
- **Latency budget** split (retrieval vs generation) and caching?
- Is the index **rebuildable** for DR? Embedding cache to avoid re-cost?

---

## 24. Hands-on Example
```python
# End-to-end RAG query (hybrid + semantic rerank + security filter)
from azure.search.documents import SearchClient
from azure.search.documents.models import VectorizedQuery

def answer(query, user_groups):
    qvec = embed(query)                                   # AOAI embeddings
    results = search_client.search(
        search_text=query,                                # keyword (BM25)
        vector_queries=[VectorizedQuery(vector=qvec, k_nearest_neighbors=30,
                                        fields="contentVector")],   # vector
        query_type="semantic", semantic_configuration_name="sem",   # reranker
        filter=f"acl/any(g: search.in(g, '{','.join(user_groups)}'))",  # security trim
        top=5)
    chunks = [(r["content"], r["source"]) for r in results]
    context = "\n\n".join(f"[{s}] {c}" for c, s in chunks)
    return llm_answer(query, context)                     # grounded prompt + citations
```

---

## 25. Terraform Example
```hcl
resource "azurerm_search_service" "search" {
  name                = "rag-search"
  resource_group_name = var.rg
  location            = "eastus"
  sku                 = "standard"      # semantic reranker available
  replica_count       = 3               # HA + QPS
  partition_count     = 2               # storage/throughput
  local_authentication_enabled = false  # Entra RBAC
  identity { type = "SystemAssigned" }
}
resource "azurerm_role_assignment" "orch_reads_search" {
  scope                = azurerm_search_service.search.id
  role_definition_name = "Search Index Data Reader"
  principal_id         = var.orchestrator_mi
}
```

---

## 26. Azure Example
```bash
# Create search + enable semantic ranker; index schema carries vector + acl fields
az search service create -n rag-search -g rg --sku standard \
  --replica-count 3 --partition-count 2
# (Index schema via REST/SDK: fields = content(text), contentVector(Collection Edm.Single,
#  dims=3072, hnsw), acl(Collection Edm.String, filterable), source, title;
#  semantic config over content/title.)
```

---

## 27. Code Example
```python
# Incremental ingestion: only (re)embed changed chunks (cost control) + ACLs
def ingest(doc):
    text = extract(doc)                          # Document Intelligence
    chunks = recursive_chunk(text, size=600, overlap=100)
    batch = []
    for i, ch in enumerate(chunks):
        h = sha256(ch)
        if embedding_cache.get(h):               # skip re-embed if unchanged
            vec = embedding_cache[h]
        else:
            vec = embed(ch); embedding_cache[h] = vec
        batch.append({"id": f"{doc.id}-{i}", "content": ch, "contentVector": vec,
                      "acl": doc.group_ids, "source": doc.url, "title": doc.title})
    search_client.merge_or_upload_documents(batch)   # incremental upsert
```

---

## 28. Things Architects Must Remember
- **Answer quality ≈ retrieval quality** — debug retrieval *first*, always inspect retrieved chunks.
- **Hybrid (vector+keyword) + semantic reranking** beats pure vector — near-default for enterprise.
- **Security lives in the retrieval filter (ACLs), never in the prompt.**
- **Chunking is the highest-leverage design choice** — test it.
- **Fewer, better chunks** beat many (avoid lost-in-the-middle + cost).
- **The index is derived state** — keep source + pipeline as code so it's rebuildable (DR).
- **Incremental embedding** (cache + only-changed) controls the biggest recurring cost.
- **You must evaluate** (groundedness/recall) — RAG without eval is flying blind.
- **Retrieved content is untrusted** — defend against injection.

---

## 29. Mnemonics and Memory Tricks
- **Ingestion "L-P-C-E-I"**: **L**oad → **P**arse → **C**hunk → **E**mbed → **I**ndex.
- **Query "E-R-R-A-G"**: **E**mbed → **R**etrieve → **R**erank → **A**ssemble → **G**enerate.
- **Golden rule**: *"Garbage retrieved = garbage generated."*
- **RAG vs FT**: *"Facts → RAG, Form → Fine-tune."*
- **Security**: *"Trim in the filter, not the prompt."*
- **Hybrid**: *"Vectors for meaning, keywords for names, reranker for the win."*

---

## 30. One-Page Interview Revision Sheet
- **What**: ground the LLM in your data by **retrieving relevant chunks** and injecting them as cited context — fresh, private, verifiable, no retraining.
- **Two pipelines**: **Ingest** (Load→Parse→**Chunk**→Embed→Index) · **Query** (Embed→Retrieve→**Rerank**→Assemble→Generate).
- **Retrieval**: **hybrid** (vector ANN/HNSW + keyword BM25) + **semantic reranker**; metadata + **ACL security $filter**.
- **Golden rule**: **answer quality ≈ retrieval quality** — debug retrieval first; *garbage retrieved = garbage generated*.
- **Security**: ACL trimming in the retrieval filter (not prompt); injection defense on untrusted docs; MI + Private Endpoints.
- **Quality**: chunking is king; fewer/better chunks (avoid **lost-in-the-middle**); query rewrite/HyDE/multi-query; **evaluate groundedness + recall@K**.
- **Scale/HA/DR**: AI Search partitions(throughput)+replicas(QPS/HA); rebuildable index; incremental embedding; multi-region.
- **Cost**: RAG-over-fine-tune; **incremental/cached embeddings**; trim K/chunk size; cheaper embed model + MRL dims; semantic cache.
- **Remember**: *Facts→RAG, Form→Fine-tune*; **L‑P‑C‑E‑I** / **E‑R‑R‑A‑G**; *trim in the filter*; advanced = agentic RAG / GraphRAG.
