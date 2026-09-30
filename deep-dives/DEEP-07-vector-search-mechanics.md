# DEEP MECHANICS · Vector Databases & Azure AI Search

> Level 2 — how vector indexes actually store and search, what Azure AI Search
> does under the hood (hybrid + semantic ranker), filtering mechanics, and the
> scaling/sharding internals interviewers probe.

---

## 0. The precise mental model
A vector database stores embeddings + metadata and answers **"which stored vectors are nearest to this query vector?"** using an **ANN index** (approximate, to be fast). Azure AI Search is a **full retrieval engine** — it combines a classic **inverted index (BM25)**, a **vector index (HNSW)**, **filters**, and an optional **semantic reranker** — i.e., it's not "just a vector DB," it's a hybrid search engine. Retrieval quality is a *systems* problem: index choice + filters + fusion + rerank.

---

## 1. What a vector index physically is (recap + depth)

- Stored: `id`, the **float vector** (e.g., 1536/3072 dims), and **filterable metadata** (tenant, source, date, tags).
- Query: embed the query → **ANN search** returns top-k by similarity (cosine/dot).
- **Distance metric must match** how the embeddings were trained (cosine for OpenAI embeddings). Wrong metric = silently bad results.

**The index families and when each (say the tradeoffs):**
| Family | How | Strength | Weakness |
|---|---|---|---|
| **Flat (brute force)** | compare to all | exact, simple | O(N) — only <~50k |
| **HNSW** | multi-layer graph, greedy descent | best recall/latency | high **RAM** (graph + full vectors) |
| **IVF** | k-means cells, probe nprobe | lower memory, fast | recall depends on nprobe |
| **IVF-PQ** | IVF + compressed codes | **billions** in RAM | approximate distances, precision loss |

**Azure AI Search uses HNSW** for its vector index (with `m`, `efConstruction`, `efSearch` knobs), which is why it's excellent recall/latency at moderate-to-large scale but memory-bound at extreme scale.

---

## 2. HNSW knobs — the tuning you must explain
- **m** — graph degree (neighbors/node). ↑ recall + memory + build time.
- **efConstruction** — build-time candidate breadth. ↑ index quality, slower build.
- **efSearch** — query-time beam width. ↑ recall/accuracy, ↑ latency.

**The recall/latency Pareto**: you can't have max recall AND min latency AND min memory — pick a point. Start with defaults, raise **efSearch** if recall is low, raise **m** if the graph is poorly connected (highly clustered data).

---

## 3. Azure AI Search — the actual retrieval pipeline

A query can hit **three stages**:

**Stage 1 — Retrieval (two parallel retrievers):**
- **Keyword / BM25** over the **inverted index** — great for exact terms, IDs, rare proper nouns, acronyms.
- **Vector / HNSW** — great for semantic paraphrase.

**Stage 2 — Fusion (hybrid):** results merged by **Reciprocal Rank Fusion (RRF)** — rank-based so incompatible score scales don't matter:
$$\text{RRF}(d)=\sum_r \frac{1}{k+\text{rank}_r(d)}$$
Hybrid beats either alone because it covers both lexical and semantic misses.

**Stage 3 — Semantic ranker (optional, the precision boost):** a **cross-encoder** (Microsoft's Bing-derived model) re-scores the top ~50 by running *query + passage together* → much better ordering, plus **semantic captions** and **answers** (extractive snippets). This is the "retrieve cheap, rerank expensive" funnel built-in.

**Deep follow-up: "Why is hybrid + semantic ranker better than pure vector?"**
Pure vector misses exact tokens (error codes, acronyms) and gives only approximate ordering from a bi-encoder. BM25 catches exact matches; RRF fuses; the cross-encoder reranker models query-passage token interaction for precise top-k. Three complementary mechanisms.

---

## 4. Filtering — pre-filter vs post-filter (a real performance trap)

Metadata filters (`tenant eq 'X'`, `date gt ...`) can apply **before** or **after** the ANN search:
- **Post-filter**: ANN returns top-k, *then* drop non-matching → you may end up with **too few** results (the k nearest were all filtered out).
- **Pre-filter**: restrict the candidate set first, then search → correct counts but can be slower / interact awkwardly with the graph.

Azure AI Search lets you choose filter mode. **For strict multi-tenant security you must ensure the tenant filter genuinely restricts results** — this is the mechanism that prevents cross-tenant leakage, enforced at query time by the app, never by the LLM.

**Deep follow-up: "You filter by tenant and sometimes get 0 results for a valid query — why?"**
Post-filtering: the k nearest vectors were all other tenants and got filtered out afterward. Switch to pre-filtering (or raise k) so the search considers the tenant's vectors in the first place.

---

## 5. Indexing pipeline & freshness

- **Push model**: your app upserts documents (chunk → embed → index) via the API — full control, event-driven on source change.
- **Pull model (indexers)**: AI Search connects to a source (Blob, SQL, Cosmos) and pulls on a schedule; **skillsets** can chunk + call an embedding model + extract entities during ingestion (integrated vectorization).
- **Freshness**: upsert changed docs only; **deletes must propagate** (remove/ tombstone) or you serve stale/deleted content. Track a content hash/version per chunk.
- **Re-embedding**: change the embedding model → the entire vector field is invalid → **rebuild** (new coordinate space). Plan for it.

---

## 6. Scaling internals — replicas vs partitions

Azure AI Search scales on **two axes** (know the difference):
- **Partitions** = **storage + index shards** → more partitions = more documents/vectors and higher indexing throughput. Data is split across partitions.
- **Replicas** = **copies of the index** → more replicas = higher **query QPS** and availability (SLA needs ≥2 for read, ≥3 for read-write SLA).
- **Search Units = partitions × replicas** (the billing/scale unit).

**Deep follow-up: "Queries are slow under load but the index isn't huge — scale what?"**
**Replicas** (QPS/throughput problem). Add **partitions** only when you're storage-bound or indexing-throughput-bound. Mixing these up is a classic wrong answer.

---

## 7. Cost & performance levers
- **Dimensions matter**: `text-embedding-3-large` (3072) is more accurate but 2× the storage/RAM and slower than `-small` (1536); some models support **dimension reduction** (MRL) to trade accuracy for cost.
- **Vector compression** (scalar/binary quantization in AI Search) shrinks the index (less RAM/cost) at a small recall cost — like PQ.
- **Semantic ranker** is a paid add-on and adds latency — apply only to the top candidates.
- **Cache** at the app layer (semantic cache) to avoid repeat retrievals.

---

## 8. The hard follow-up questions (with answers)
1. **"Walk a query through Azure AI Search hybrid + semantic."** → BM25 (inverted index) ∥ vector (HNSW) → **RRF** fusion → **cross-encoder semantic reranker** on top ~50 → top-k + captions. (§3)
2. **"Pure vector misses exact product codes — fix?"** → add **keyword/BM25** (hybrid); RRF fuses lexical + semantic. (§3)
3. **"Multi-tenant: filter returns 0 for valid queries — why & fix?"** → post-filtering removed the top-k; use **pre-filtering** / raise k. (§4)
4. **"HNSW recall too low — which knob?"** → raise **efSearch** (query beam); raise **m** if graph poorly connected. (§2)
5. **"Slow queries, small index — replicas or partitions?"** → **replicas** (QPS); partitions are for storage/indexing throughput. (§6)
6. **"Change embedding model — what breaks?"** → whole vector field invalid; **rebuild/re-embed** (new space). (§5)
7. **"Billions of vectors, limited RAM — index choice?"** → **IVF-PQ** (compression) or vector quantization; HNSW alone is RAM-bound. (§1)
8. **"Reduce index cost with minimal quality loss?"** → smaller/MRL-reduced embedding dims + **quantization**, keep semantic ranker on top-k only. (§7)

---

## 9. One-screen deep-recall sheet
- **Vector index**: store vector + filterable metadata; ANN top-k by **cosine/dot** (match training metric). Families: Flat(exact,<50k) · **HNSW**(best recall/latency, RAM-heavy) · IVF(cheaper) · **IVF-PQ**(billions, compressed).
- **HNSW knobs**: **m** (degree), **efConstruction** (build), **efSearch** (query beam) — recall vs latency vs memory Pareto.
- **Azure AI Search = hybrid engine**: **BM25 inverted index** ∥ **HNSW vector** → **RRF** (rank-based fusion) → **cross-encoder semantic ranker** (rerank top ~50 + captions). Hybrid+rerank > pure vector (covers exact terms + precise ordering).
- **Filtering**: **pre-filter** (restrict then search, correct counts) vs **post-filter** (search then drop, can yield too few). Tenant filter = security, enforced at query time, pre-filter for correctness.
- **Ingestion**: push (app upsert) vs pull (indexers + skillsets/integrated vectorization); propagate deletes; re-embed on model change.
- **Scale**: **partitions** = storage/shards; **replicas** = QPS/availability; SU = P×R. Slow-under-load → add **replicas**.
- **Cost**: smaller/MRL dims + **quantization** shrink RAM; semantic ranker on top-k only; app-layer semantic cache.

---

> Next: **Terraform State**.
