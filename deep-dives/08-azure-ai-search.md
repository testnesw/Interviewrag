# Deep Dive · Azure AI Search

> Phase 1 (Highest ROI) · Azure GenAI Architect Interview Prep
> Format: 30 sections × 5 seniority levels (Engineer → Principal Architect)

---

## 1. Executive Summary (30-second answer)
Azure AI Search (formerly Cognitive Search) is Microsoft's **managed search-as-a-service** and the **de facto retrieval engine for enterprise RAG**. It combines **full-text (BM25) keyword search, vector (ANN/HNSW) semantic search, and hybrid fusion + an L2 semantic reranker** in one index, plus an **indexer + skillset** pipeline for ingestion (including **integrated vectorization** — chunk + embed at index time). Architecturally you design an **index schema** (fields: text, vectors, filterable metadata, ACLs), scale it with **partitions (storage/throughput) and replicas (QPS/HA)**, and secure it with **Entra RBAC + security trimming** — it's the "R" in RAG.

---

## 2. Architect-Level Explanation
AI Search is a **document index + query engine** with three retrieval modes and an ingestion pipeline:
- **Index**: schema of typed fields; each field can be searchable (analyzed text), filterable, sortable, facetable, retrievable, and/or a **vector** field (with a vector search profile → HNSW or exhaustive KNN).
- **Retrieval modes**: **keyword (BM25)**, **vector (ANN)**, **hybrid** (both fused via **RRF**), and **semantic ranking** (an L2 cross-encoder reranker + captions/answers).
- **Ingestion**: **push** (your code upserts docs) or **pull** via **indexers** (Blob/SQL/Cosmos/ADLS) + **skillsets** (enrichment: OCR, entity/key-phrase extraction, **split**, and **AzureOpenAIEmbedding** for **integrated vectorization**).
- **Scale unit**: **Search Units = partitions × replicas**. Partitions = storage + throughput; replicas = QPS + availability (SLA needs ≥2 read / ≥3 read-write).
- **Security**: Entra **RBAC** (data-plane roles), Private Endpoints, and **security trimming** via filterable ACL fields.
As an architect you own **index/schema design, chunking + vectorization strategy, hybrid+semantic config, scale sizing, and security trimming** — it's the backbone that determines RAG quality.

---

## 3. Why It Exists
- **RAG needs fast, relevant retrieval over massive private corpora** — you can't stuff millions of docs into a prompt, and naive DB queries don't do semantic relevance or ranking.
- **Enterprises need one engine that does keyword + vector + reranking** with enterprise security (RBAC, Private Link, residency), rather than stitching a vector DB + search engine + reranker themselves.
- **Managed pipeline**: indexers + skillsets + **integrated vectorization** remove the need to build custom parse/chunk/embed infrastructure.
- **Relevance is hard**: BM25 tuning, ANN, and semantic reranking are provided out-of-the-box, tuned by Microsoft.

---

## 4. Internal Working
**Indexing path**
1. **Ingest**: push API or **indexer** crawls a data source (change tracking for incremental).
2. **Skillset enrichment** (optional): OCR/Document cracking → **Split skill** (chunking) → **AzureOpenAIEmbedding skill** (vectorize) → map outputs to index fields (**integrated vectorization**).
3. **Index build**: text fields analyzed (tokenized/stemmed) into an **inverted index** (for BM25); vector fields built into an **HNSW graph** (approximate nearest neighbor).

**Query path**
1. Parse query; apply **filters** (OData `$filter`, incl. ACL trimming) — filters run *before* scoring.
2. **BM25** scores keyword matches over the inverted index.
3. **Vector search**: ANN traversal of HNSW returns top-K by cosine/dot similarity.
4. **Hybrid fusion**: **Reciprocal Rank Fusion (RRF)** merges keyword + vector result sets.
5. **Semantic ranker (L2)**: a cross-encoder reranks the top ~50 candidates, producing **@search.rerankerScore**, plus **captions** and extractive **answers**.
6. Return top results with fields, scores, highlights, facets.

**Key internals**: HNSW params (`m`, `efConstruction`, `efSearch`) trade recall vs latency; analyzers affect keyword matching; scoring profiles boost by field/freshness; vector compression (**scalar/binary quantization**, MRL dimension truncation) shrinks index.

---

## 5. Enterprise Use Case
A manufacturer builds an **engineering knowledge base** over 3M technical docs, drawings, and manuals. An **indexer** pulls from Blob, a **skillset** does OCR + splits + **integrated vectorization**, producing a hybrid index. Engineers query in natural language; **hybrid + semantic ranking** returns exact part numbers (keyword) *and* conceptually related procedures (vector), with **security trimming** by plant/role. This index is the retrieval layer for their GPT-4o RAG copilot.

---

## 6. Real Production Architecture
```
 INGEST
 Blob/ADLS/SQL/Cosmos ─► Indexer (change tracking, incremental)
     └─ Skillset: OCR/crack → Split(chunk) → AzureOpenAIEmbedding(vectorize)
        → Index (text + vector[HNSW] + filterable metadata + ACL)

 QUERY
 Orchestrator (MI/Entra) ─► AI Search (Private Endpoint)
     hybrid (BM25 + vector RRF) + semantic reranker + $filter(ACL)
     → top-K chunks + captions/answers → LLM (grounded RAG)

 Scale: SearchUnits = partitions(storage/throughput) × replicas(QPS/HA, ≥3)
 Secure: Entra RBAC (Index Data Reader/Contributor) · Private Link · CMK
 Observe: latency, QPS, throttling, index size, semantic ranker usage
```

---

## 7. Security Best Practices
- **Entra RBAC (data plane)**: `Search Index Data Reader` (query) vs `...Contributor` (write) vs `Search Service Contributor` (manage); **disable API keys** (`disableLocalAuth`) where possible.
- **Security trimming**: store ACLs (Entra group IDs) as a filterable field; enforce `$filter=acl/any(g: search.in(g,'<user-groups>'))` at query time — retrieval-level, never prompt-level. (Native **document-level permissions / ADLS ACL** support increasingly available.)
- **Private Endpoints** + `publicNetworkAccess=Disabled`; **shared private link** from the service to data sources/AOAI for skillsets.
- **CMK** for encryption-at-rest; TLS in transit.
- **Managed Identity** for indexers/skillsets to reach data sources + embeddings (no keys).
- **Least privilege** + audit via diagnostic logs.

---

## 8. Scaling Strategy
- **Partitions** ↑ for **storage + indexing/query throughput**; **replicas** ↑ for **QPS + HA**. Total **Search Units = P × R**.
- **Tier (SKU)** sets per-partition storage + limits (Basic → Standard S1/S2/S3 → Storage-Optimized L1/L2); pick by corpus size + QPS.
- **Vector index size control**: **quantization** (scalar/binary) + **MRL dimension truncation** + `stored=false` to cut storage/cost.
- **HNSW tuning**: `efSearch` up for recall, down for latency.
- **Incremental indexing** (indexer change tracking / high-water mark) — don't rebuild everything.
- **Semantic ranker** applies to top candidates only (bounded cost/latency).

---

## 9. High Availability Strategy
- **Replicas ≥ 3** for the **99.9% read/write SLA** (≥2 for read-only); replicas are load-balanced copies.
- **Zone redundancy** (supported tiers/regions) spreads replicas across AZs.
- **Multi-region**: deploy parallel services + keep indexes in sync (dual indexing or geo-replicated ingestion) behind Front Door/Traffic Manager for regional failover.
- **Stateless clients** with retry/backoff on 503/429.

---

## 10. Disaster Recovery Strategy
- **Index is rebuildable derived state**: keep **source data + indexer/skillset definitions as IaC/code** → recreate the index in a secondary region.
- **Multi-region replication**: run the ingestion pipeline into both regions, or back up + restore index (via re-index; there's no built-in cross-region index copy — script it).
- **Pre-provision** the secondary service + AOAI embedding quota; store schema/skillset in Git.
- **RTO** = reindex/replication time; **RPO** = ingestion cadence — measure + drill.

---

## 11. Cost Optimization Strategy
- **Right-size tier + Search Units** to actual storage/QPS; scale replicas down off-peak.
- **Shrink the vector index** (biggest cost driver): **quantization**, **MRL truncation**, `stored=false` for vectors you don't return, fewer dimensions.
- **Incremental indexing** to avoid re-embedding/re-indexing everything.
- **Semantic ranker** billed per query — apply selectively (it's on the top-K, but still metered).
- **Integrated vectorization** reduces custom-pipeline compute cost.
- **Consolidate indexes**; delete stale docs; monitor index growth.

---

## 12. Common Production Challenges
- **Vector index too big/expensive** → quantize + MRL + `stored=false`.
- **Poor relevance** → not using hybrid + semantic; wrong analyzer; bad chunking (fix upstream).
- **Indexer failures** → source auth/throttling/doc-cracking errors; check indexer execution history.
- **Stale results** → change tracking not configured / indexer schedule too slow.
- **Throttling (503/429)** → under-provisioned replicas/partitions; scale + backoff.
- **Security leakage** → missing ACL trimming.
- **Schema change pain** → many changes require **index rebuild** (plan schema carefully up front).
- **Semantic ranker cost/latency** underestimated.

---

## 13. Monitoring and Observability
- **Metrics (Azure Monitor)**: search latency, **QPS**, throttled query %, indexing rate, index size/storage, semantic query count.
- **Indexer telemetry**: execution history, docs succeeded/failed, warnings (skill errors).
- **Diagnostic logs → Log Analytics (KQL)**: slow queries, errors, per-index usage.
- **RAG-quality signals** (upstream): recall@K, reranker score distribution, no-hit rate.
- **Alerts**: throttling, latency SLO breach, indexer failures, storage nearing quota.

---

## 14. Troubleshooting Scenarios
- **Relevant doc not returned** → enable **hybrid** (keyword catches exact terms vector misses); check chunking + analyzer; raise `efSearch`/K.
- **Slow queries** → too many replicas saturated? big vectors? semantic ranker on too many? scale replicas, quantize, bound candidates.
- **Indexer stuck/failing** → check execution history: source throttling, unsupported doc, skill error, MI permission to source/AOAI.
- **`503`/throttled** → add replicas (QPS) / partitions (throughput); add client backoff.
- **Index full** → add partitions or shrink vectors (quantization/MRL).
- **User sees unauthorized docs** → ACL field/`$filter` missing or wrong group mapping.
- **Can't change a field type** → requires **rebuild**; create new index + reindex + swap alias.

---

## 15. Tradeoffs
| Decision | Pro | Con |
|---|---|---|
| Hybrid + semantic | best relevance | more latency + per-query cost |
| More replicas | QPS + HA | linear cost |
| More partitions | storage + throughput | cost; reindex to change |
| Quantization/MRL | smaller/cheaper index | slight recall loss |
| Integrated vectorization | less to build | less control of chunking |
| Indexer (pull) | managed | less flexible than push |

---

## 16. When NOT to Use It
- **Small/static knowledge** that fits in a prompt → skip a search service.
- **Pure relational/analytical queries** → SQL/BI, not search.
- **Simple exact-key lookup** → a database/KV store is cheaper.
- **A single embedded vector need** at tiny scale → a lightweight vector lib may suffice (though AI Search still wins on hybrid+security at enterprise scale).
- **Ultra-low-cost hobby projects** → managed tier may be overkill.

---

## 17. Comparison with Alternatives
| Option | Hybrid + rerank | Managed ingestion | Enterprise security | Notes |
|---|---|---|---|---|
| **Azure AI Search** | yes (BM25+vector+L2) | indexers+skillsets | Entra RBAC, Private Link, trimming | best for Azure RAG |
| Elasticsearch/OpenSearch | keyword strong, vector ok | self-managed | self-managed | ops overhead |
| Pinecone/Weaviate/Milvus | vector-first | limited | varies | great vectors, weaker hybrid/security |
| Cosmos DB vector | vector in DB | n/a | Azure | good if already in Cosmos |
| pgvector (Postgres) | vector add-on | n/a | DB-level | simple, smaller scale |

---

## 18. Interview Questions
1. What retrieval modes does AI Search support and how do they combine?
2. Explain partitions vs replicas and Search Units.
3. What are indexers and skillsets? What is integrated vectorization?
4. How does hybrid search + semantic ranking work (RRF, L2)?
5. How do you control vector index size/cost?
6. How do you implement security trimming?
7. How do you scale for HA and QPS (SLA requirements)?
8. What requires an index rebuild and how do you do it with zero downtime?
9. How do you tune relevance (analyzers, scoring profiles, HNSW)?
10. AI Search vs a dedicated vector DB?

---

## 19. Strong Interview Answers
- **Retrieval modes**: "It does **BM25 keyword**, **vector ANN (HNSW)**, and **hybrid** — fusing both with **RRF** — then an optional **L2 semantic reranker** (cross-encoder) reorders the top candidates and returns captions/answers. Hybrid + semantic is the enterprise default: keywords catch exact terms, vectors catch meaning, the reranker maximizes precision."
- **Partitions vs replicas**: "**Partitions** add storage and indexing/query throughput; **replicas** add QPS and availability. Billing is **Search Units = partitions × replicas**. For the write SLA I need **≥3 replicas** (≥2 for read-only). I size partitions to corpus + vector index size, replicas to QPS + HA."
- **Indexer/skillset/integrated vectorization**: "**Indexers** pull from sources (Blob/SQL/Cosmos) with change tracking; **skillsets** enrich (OCR, split/chunk, embeddings). **Integrated vectorization** uses the built-in AzureOpenAIEmbedding skill to chunk + embed at index *and* query time — so I don't build a custom parse/chunk/embed pipeline."
- **Vector cost control**: "Vectors dominate index size, so I use **scalar/binary quantization**, **MRL dimension truncation**, and `stored=false` for vectors I don't need to return — cutting storage and cost with minimal recall loss, validated against my eval set."
- **Rebuild with zero downtime**: "Many schema changes (field type, analyzer) require a **rebuild**. I create a **new index**, reindex into it, then **swap an alias** so clients cut over atomically — no downtime. This is why I design the schema carefully up front."

---

## 20. Architecture Diagrams
**Index anatomy**
```
Index
 ├─ id (key)
 ├─ content         (searchable text → inverted index / BM25)
 ├─ contentVector   (Collection<Single>, dim=3072, profile→HNSW)
 ├─ acl             (Collection<String>, filterable)  ← security trim
 ├─ title/source/page (retrievable/filterable/facetable)
 └─ semantic config over (title, content) → L2 reranker
```
**Query fusion + rerank**
```
q ─┬─ BM25 (inverted index) ─┐
   └─ vector (HNSW ANN) ──────┴─ RRF ─► semantic reranker (L2) ─► top-K + captions
                      ($filter ACL applied before scoring)
```

---

## 21. Real Project Example
A retailer's **support KB**: 1M articles + tickets. An **indexer** on Blob runs a **skillset** (crack → split 500-token chunks → integrated vectorization) into an S1 index with 2 partitions / 3 replicas. Queries use **hybrid + semantic ranker** with `$filter` on product-line ACLs. They enabled **binary quantization + MRL(1024)**, cutting vector storage ~70% with negligible recall loss (validated on a 200-question eval set). This index powers the GPT-4o support copilot at ~120 QPS with 99.9% availability.

---

## 22. Whiteboard Design Question
> "Design the retrieval layer for a RAG copilot over 8M documents, 200 QPS, per-user security, EU residency, 99.9% SLA."

Expected: tier + **Search Units** sizing (partitions for 8M docs + vector size; **≥3 replicas** for SLA + QPS), **indexer + skillset with integrated vectorization**, index schema (text + vector + **ACL** + metadata), **hybrid + semantic** config, **security trimming** `$filter` by Entra groups, **quantization/MRL** for cost, Private Endpoints + EU region for residency, monitoring + alias-based reindex for DR/updates.

---

## 23. Design Review Questions
- Are you using **hybrid + semantic ranking**? What's recall@K on the eval set?
- **Partition/replica** sizing vs SLA (≥3) and QPS headroom?
- **Vector index size** — quantization/MRL/`stored=false` applied?
- **Security trimming** enforced at query time via ACL `$filter`?
- **Indexer** incremental (change tracking)? Failure monitoring?
- **Reindex strategy** (alias swap) for schema changes — zero downtime?
- **Private Endpoints + RBAC**, local auth disabled?
- **Semantic ranker cost** budgeted per query?

---

## 24. Hands-on Example
```python
from azure.search.documents import SearchClient
from azure.search.documents.models import VectorizableTextQuery
from azure.identity import DefaultAzureCredential

sc = SearchClient("https://rag-search.search.windows.net", "kb-index",
                  DefaultAzureCredential())          # Entra RBAC, no keys

results = sc.search(
    search_text=user_query,                          # BM25
    vector_queries=[VectorizableTextQuery(            # integrated vectorization at query time
        text=user_query, k_nearest_neighbors=30, fields="contentVector")],
    query_type="semantic", semantic_configuration_name="sem",   # L2 reranker
    filter=f"acl/any(g: search.in(g, '{user_groups}'))",        # security trimming
    select=["content","source","title"], top=5)
for r in results:
    print(r["@search.rerankerScore"], r["source"], r["content"][:80])
```

---

## 25. Terraform Example
```hcl
resource "azurerm_search_service" "search" {
  name                          = "rag-search"
  resource_group_name           = var.rg
  location                      = "westeurope"      # residency
  sku                           = "standard"        # semantic ranker
  replica_count                 = 3                 # 99.9% SLA + QPS
  partition_count               = 2                 # storage/throughput
  local_authentication_enabled  = false             # Entra only
  public_network_access_enabled = false
  identity { type = "SystemAssigned" }              # indexer → sources/AOAI
}
resource "azurerm_role_assignment" "reader" {
  scope                = azurerm_search_service.search.id
  role_definition_name = "Search Index Data Reader"
  principal_id         = var.orchestrator_mi
}
```

---

## 26. Azure Example
```bash
az search service create -n rag-search -g rg --sku standard \
  --replica-count 3 --partition-count 2 \
  --public-network-access disabled --disable-local-auth true
# Assign the service's Managed Identity access to Blob + Azure OpenAI (for skillset)
az role assignment create --assignee <search-mi> --role "Storage Blob Data Reader" --scope <blob>
az role assignment create --assignee <search-mi> --role "Cognitive Services OpenAI User" --scope <aoai>
# Index + indexer + skillset (integrated vectorization) defined via REST/SDK JSON.
```

---

## 27. Code Example
```python
# Zero-downtime reindex via alias swap (schema change)
from azure.search.documents.indexes import SearchIndexClient
ic = SearchIndexClient(endpoint, DefaultAzureCredential())

new_index = f"kb-index-{version}"
ic.create_index(build_schema(name=new_index))        # new schema (e.g., quantized vectors)
reindex_all_documents(target=new_index)              # push/indexer into new index
ic.create_or_update_alias(SearchAlias(name="kb",     # atomic cutover
                                      indexes=[new_index]))
# clients query the "kb" alias → now points to new index; delete old after validation
```

---

## 28. Things Architects Must Remember
- **Hybrid + semantic ranking is the enterprise default** — rarely pure vector.
- **Search Units = partitions × replicas**; **≥3 replicas for the write SLA**.
- **Vectors dominate cost** — quantize + MRL + `stored=false`.
- **Security trimming via filterable ACL field** at query time (not prompt).
- **The index is derived state** — keep source + skillset as code → rebuildable (DR).
- **Schema changes often need a rebuild** — use **alias swap** for zero downtime; design schema up front.
- **Indexers + integrated vectorization** save you from building a parse/chunk/embed pipeline.
- **Filters run before scoring** — great for cheap pre-filtering (ACLs, dates).

---

## 29. Mnemonics and Memory Tricks
- **Scale = "P×R"**: **P**artitions (storage/throughput) × **R**eplicas (QPS/HA). *"3 replicas for the SLA."*
- **Retrieval "K-V-H-S"**: **K**eyword(BM25) + **V**ector(HNSW) → **H**ybrid(RRF) → **S**emantic rerank(L2).
- **Ingestion "I-S-I"**: **I**ndexer → **S**killset → **I**ntegrated vectorization.
- **Cost**: *"Quantize + truncate (MRL) + don't store vectors you won't return."*
- **Change**: *"New index + reindex + alias swap = zero downtime."*

---

## 30. One-Page Interview Revision Sheet
- **What**: managed search-as-a-service = the **retrieval engine for RAG**; keyword + vector + hybrid + **semantic reranker** in one index.
- **Index**: typed fields (searchable/filterable/…); **vector fields → HNSW**; ACL field for trimming; semantic config for L2 rerank.
- **Retrieval**: **BM25 + vector (RRF hybrid)** → **semantic ranker (L2)** → captions/answers; **$filter runs before scoring**.
- **Ingestion**: push, or **indexer + skillset** (OCR/split/**integrated vectorization**), incremental via change tracking.
- **Scale**: **Search Units = Partitions(storage/throughput) × Replicas(QPS/HA)**; **≥3 replicas** for 99.9% write SLA; tiers Basic→S1/S2/S3→L1/L2.
- **Vector cost**: **quantization (scalar/binary) + MRL truncation + stored=false** — vectors dominate size.
- **Security**: Entra **RBAC** (Index Data Reader/Contributor), Private Endpoints, disable local auth, **ACL security trimming**, CMK.
- **HA/DR**: replicas + zones; index = **rebuildable derived state** (source + skillset as code); multi-region reindex.
- **Ops**: schema changes → **rebuild + alias swap** (zero downtime); monitor latency/QPS/throttle/indexer failures.
- **Remember**: **P×R**, *3 replicas for SLA*, **K‑V‑H‑S**, **I‑S‑I**, *quantize vectors*, *trim in the filter*, *alias swap to reindex*.
