# DEEP MECHANICS · Embeddings & Embedding Models

> Level 2 — what embeddings are, how they're trained/used, model choice,
> dimensions, and similarity.

---

## 0. The precise mental model
An **embedding** maps text (or image/audio) to a **dense vector** in a high-dimensional space where **semantic similarity = geometric closeness**. "King" and "queen" land near each other; unrelated text is far. Embeddings are the bridge between language and math — they power **retrieval, clustering, classification, and RAG**.

---

## 1. What & why
- A vector of floats (e.g., 1536 dims) capturing **meaning**, not keywords.
- Similar meaning → small distance; enables **semantic search** ("car" matches "automobile").
- Contrast with **sparse/lexical** (BM25, one-hot) which match exact tokens.

## 2. How similarity is measured
- **Cosine similarity** (angle) — most common for text; magnitude-invariant.
- **Dot product** — used when vectors are normalized (then ≡ cosine).
- **Euclidean (L2)** — straight-line distance.
- Normalize embeddings → cosine and dot product agree.

## 3. Model families
- **Text embedding models**: OpenAI `text-embedding-3-small/large`, Cohere, `bge`, `e5`, Sentence-Transformers (open).
- **`3-large` vs `3-small`**: large = higher quality, more dims, more cost; small = cheaper/faster.
- **Dimensions**: newer models (OpenAI v3) support **shortening dims** (Matryoshka) → trade accuracy for storage/speed.
- **Multimodal**: CLIP-style (text+image in same space) for cross-modal search.

## 4. Key properties & gotchas
- **Same model for index + query** — you must embed documents and queries with the *identical* model (different models = incompatible spaces).
- **Max input length** — models truncate beyond a token limit → **chunk** long docs.
- **Domain fit** — general models may underperform on specialized jargon → consider domain models or **fine-tuned embeddings**.
- **Normalization** matters for the chosen metric.

## 5. Where embeddings are used
- **RAG retrieval** (embed chunks → vector DB → similarity search).
- **Semantic search**, **clustering**, **classification** (embedding + classifier), **deduplication**, **recommendations**, **anomaly detection**.

## 6. Cost & performance
- Embedding is cheap vs generation; **batch** requests; **cache** embeddings (text rarely changes).
- Store in a **vector DB / index** (Azure AI Search, pgvector, Pinecone) with **ANN** indexing (HNSW) for fast search.
- Dimension size drives storage + query cost → pick the smallest that meets quality.

## 7. The hard follow-ups (with answers)
1. **"What is an embedding?"** → dense vector where semantic similarity = geometric closeness. (§0)
2. **"Cosine vs dot vs Euclidean?"** → cosine (angle, text default); dot = cosine if normalized; L2 = distance. (§2)
3. **"Can I embed docs with model A and query with B?"** → no — must use the **same model** (shared space). (§4)
4. **"Doc longer than the model limit?"** → chunk it; embeddings truncate. (§4)
5. **"3-small vs 3-large?"** → small cheaper/faster, large higher quality/more dims. (§3)
6. **"Reduce storage cost?"** → fewer dimensions (Matryoshka shortening) trading some accuracy. (§3/§6)
7. **"Poor results on jargon?"** → domain-specific or fine-tuned embedding model. (§4)

## 8. One-screen recall
- **Embedding** = dense vector; **semantic similarity = closeness** (vs lexical BM25).
- **Metric**: **cosine** (text default); dot = cosine if normalized; L2 distance. Normalize!
- **Models**: OpenAI v3 small/large, bge/e5/Cohere; multimodal (CLIP); v3 supports **dim shortening**.
- **Rules**: **same model for index + query**; chunk long inputs; domain fit matters.
- **Uses**: RAG, semantic search, clustering, classification, dedup, recs.
- **Ops**: cheap + cacheable + batch; store in vector DB with **HNSW/ANN**; smaller dims = cheaper.

> Next: Reranking.
