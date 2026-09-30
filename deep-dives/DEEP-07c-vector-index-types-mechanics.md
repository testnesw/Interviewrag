# DEEP MECHANICS · Vector Index Types (ANN: HNSW, IVF, PQ)

> Level 2 — exact vs approximate search, HNSW, IVF, product quantization, and
> the recall/latency/memory trade-offs.

---

## 0. The precise mental model
Finding the nearest vectors to a query by checking **all** of them (exact / brute-force / "flat") is **O(N)** — too slow for millions. **Approximate Nearest Neighbor (ANN)** indexes trade a little **recall** for massive **speed** by only searching a smart subset. The main families: **HNSW** (graph), **IVF** (clustering), and **PQ** (compression) — often combined.

---

## 1. Exact (Flat) vs ANN
- **Flat/brute-force**: compare query to every vector → 100% recall, but **O(N·d)** → fine for small sets, too slow at scale.
- **ANN**: navigate/prune to candidates → sub-linear search, **~95–99% recall** at a fraction of the cost. You tune the recall/speed trade-off.

## 2. HNSW (Hierarchical Navigable Small World) — the default
- A **multi-layer graph**: top layers = long-range "highway" links (few nodes), lower layers = dense local links.
- **Search**: enter at the top, greedily hop toward the query, descend layers → logarithmic-ish navigation.
- **Params**:
  - **M** — links per node (higher = better recall, more memory).
  - **efConstruction** — build-time candidate list (higher = better index, slower build).
  - **efSearch** — query-time candidate list (higher = better recall, slower query). **The main recall/latency dial.**
- **Pros**: excellent recall + low latency. **Cons**: **memory-heavy** (graph in RAM), updates/deletes costlier. Default in Azure AI Search, pgvector, FAISS, Qdrant, Milvus.

## 3. IVF (Inverted File Index) — clustering
- **Cluster** vectors into `nlist` cells (k-means centroids). Query searches only the **`nprobe` nearest cells**, not all.
- **Params**: `nlist` (number of clusters), `nprobe` (cells searched per query → recall/speed dial).
- **Pros**: lower memory than HNSW, fast for large sets. **Cons**: recall sensitive to `nprobe`; needs a **training step** (fit centroids); edge-of-cell misses.

## 4. PQ (Product Quantization) — compression
- **Compresses** each vector into a short code (split into sub-vectors, quantize each to a codebook) → huge **memory reduction** (e.g., 32×).
- Enables **billions** of vectors in RAM; distances approximated from codes.
- **Cost**: some accuracy loss. Often **combined**: `IVF+PQ` (FAISS), or HNSW for routing + PQ for storage.

## 5. Choosing / tuning
| Need | Pick |
|---|---|
| Best recall+latency, RAM available | **HNSW** |
| Huge corpus, memory-constrained | **IVF+PQ** |
| Small dataset, exactness | **Flat** |
- The universal dial: **more candidates searched (efSearch/nprobe) → higher recall, higher latency.** Measure recall@k vs latency and pick your point.
- Also choose the **distance metric** (cosine/dot/L2) to match your embeddings.

## 6. Operational notes
- **Updates/deletes**: HNSW handles inserts well but deletes leave tombstones; IVF may need periodic retraining as data drifts.
- **Filtering**: combining metadata filters + ANN ("filtered vector search") can hurt recall → pre- vs post-filtering strategies matter (Azure AI Search does this for you).
- Memory sizing: HNSW ≈ vectors + graph; plan RAM accordingly.

## 7. The hard follow-ups (with answers)
1. **"Why not brute-force search?"** → O(N) too slow at millions → **ANN** trades a little recall for big speed. (§1)
2. **"How does HNSW work?"** → multi-layer graph, greedy navigation from sparse top to dense bottom; tune **efSearch** for recall/latency. (§2)
3. **"HNSW vs IVF?"** → HNSW = graph, best recall/latency but RAM-heavy; IVF = clustering, cheaper memory, needs training + `nprobe` tuning. (§2/§3)
4. **"Billions of vectors, limited RAM?"** → **PQ** compression (often **IVF+PQ**). (§4)
5. **"The main recall dial?"** → candidates searched: **efSearch** (HNSW) / **nprobe** (IVF). (§5)
6. **"Trade-off of ANN?"** → slightly <100% recall for large speed/memory gains. (§1)
7. **"Metadata filter + vector search issue?"** → filtering can reduce recall → pre/post-filter strategy. (§6)

## 8. One-screen recall
- **Flat** = exact O(N) (small only); **ANN** = approximate, ~95–99% recall, fast.
- **HNSW** (default): multi-layer graph; params **M / efConstruction / efSearch**; best recall+latency, **RAM-heavy**.
- **IVF**: cluster into `nlist`, search `nprobe` cells; cheaper memory, needs training.
- **PQ**: compress vectors (codebooks) → billions in RAM, small accuracy loss; often **IVF+PQ**.
- **Dial**: more candidates (**efSearch/nprobe**) → higher recall + latency.
- Match **distance metric** to embeddings; mind updates/deletes + **filtered search** recall.

> Next: Speculative Decoding & inference optimization.
