# 07 · Vector Databases

> Domain: Generative AI & Azure AI · Level: Principal GenAI Architect

## 1. Beginner Explanation
A vector database stores **embeddings** (lists of numbers representing meaning) and finds the **most similar** ones fast. It powers "search by meaning" for RAG and recommendations.

## 2. Architect-Level Explanation
- **Embeddings**: text/image → high-dimensional vector; similar meaning → close vectors (cosine/dot/L2).
- **ANN index**: exact search is O(n); vector DBs use **Approximate Nearest Neighbor** (HNSW, IVF, PQ) for sub-linear search with tunable recall/latency.
- **Hybrid**: combine vector + keyword (BM25) + filters + reranking for precision.
- **Operational**: sharding, replication, metadata filtering, upserts/TTL, freshness.
- Options on Azure: **Azure AI Search** (vector+hybrid+semantic), Cosmos DB (vector), PostgreSQL pgvector, Redis, plus Pinecone/Weaviate/Milvus/Qdrant.

## 3. Real Enterprise Use Case
A media company indexes 50M articles as embeddings for semantic search + recommendations. HNSW index with metadata filters (date, category, ACL), hybrid search for exact names, reranking for top results — millisecond retrieval at scale.

## 4. Architecture Diagram (ASCII)
```
 Content ─► Embed ─► [Vector DB]
                       ├ ANN index (HNSW/IVF)
                       ├ metadata (filters/ACL)
                       └ replicas/shards
 Query ─► Embed ─► ANN top-k ─► filter ─► rerank ─► results
```

## 5. Interview Questions
1. Exact vs approximate nearest neighbor?
2. HNSW vs IVF vs PQ — trade-offs?
3. Why hybrid search + metadata filters?
4. How do you choose a vector DB for enterprise?
5. How do you keep the index fresh and secure?

## 6. Strong Interview Answers
- **Exact vs ANN**: "Exact is accurate but O(n) — infeasible at millions of vectors. ANN trades a little recall for huge speed; I tune parameters (ef/nprobe) to hit a recall/latency target."
- **Index types**: "HNSW: great recall/latency, higher memory; IVF: cluster-based, memory-efficient, needs training; PQ: compresses vectors, saves memory at some recall cost. HNSW is my default; add PQ for scale/cost."
- **Hybrid**: "Vectors miss exact tokens (IDs, names); keyword catches them. Hybrid + filters + rerank maximizes precision, especially for enterprise jargon."
- **Choosing**: "For most Azure shops, Azure AI Search (managed, hybrid, semantic, security). Dedicated DBs (Qdrant/Milvus) for very large/specialized workloads; pgvector when data already lives in Postgres."

## 7. Common Mistakes
- Pure vector, no keyword/filters.
- Wrong distance metric vs embedding model.
- Ignoring memory cost of HNSW at scale.
- No ACL metadata → data leakage in RAG.
- Re-embedding everything on each update.

## 8. Trade-offs
| Index | Recall | Speed | Memory |
|-------|--------|-------|--------|
| HNSW | high | fast | high |
| IVF | medium-high | fast | medium |
| PQ/IVF-PQ | lower | fast | low |

## 9. Production Best Practices
- Match metric to embedding model (usually cosine).
- Hybrid + rerank; tune ANN params for SLA.
- Incremental upserts; track document changes.
- Store ACL/metadata for filtering.
- Monitor recall/latency; capacity plan for growth.

## 10. Security Considerations
- Query-time ACL filtering per user.
- Encrypt at rest (CMK); private networking.
- Isolate tenants (index/namespace per tenant).
- Embeddings can leak info — protect them like data.

## 11. Cost Optimization
- Quantization/PQ to cut memory.
- Right-size dimensions (smaller embedding models).
- Tier cold data; cache hot queries.
- Scale replicas to load, not peak-always.

## 12. Troubleshooting Scenarios
- **Poor relevance** → wrong metric, bad chunking, need hybrid/rerank.
- **Slow queries** → tune ef/nprobe, add replicas, reduce dimension.
- **High memory/cost** → PQ/quantization, fewer dimensions.
- **Missing recent docs** → indexing/freshness pipeline.

## 13. Hands-on Example
```python
# pgvector similarity query
SELECT id, content FROM docs
ORDER BY embedding <=> %(qvec)s  -- cosine distance
LIMIT 5;
```

## 14. Terraform Example
```hcl
resource "azurerm_search_service" "vs" {
  name                = "vec-search"
  resource_group_name = azurerm_resource_group.rg.name
  location            = "eastus"
  sku                 = "standard"
  replica_count       = 2
  partition_count     = 2
  identity { type = "SystemAssigned" }
}
```

## 15. Azure Example
```bash
# Cosmos DB with integrated vector search
az cosmosdb create -n vecdb -g rg-ai \
  --capabilities EnableNoSQLVectorSearch
```

## 16. FastAPI / Python Example
```python
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams

qc = QdrantClient(url="http://qdrant:6333")
qc.recreate_collection("docs",
    vectors_config=VectorParams(size=1024, distance=Distance.COSINE))

@app.post("/search")
def search(q: str):
    hits = qc.search("docs", query_vector=embed(q), limit=5,
                     query_filter=acl_filter(current_user()))
    return [h.payload for h in hits]
```

## 17. AKS Example
Run Qdrant/Milvus as a StatefulSet in AKS with premium managed disks, anti-affinity across zones, and HPA on the query service (not the stateful store).

## 18. How to Remember
**"GPS for meaning."** Everything becomes coordinates; the DB finds the nearest neighbors quickly.

## 19. Real-World Analogy
A library that shelves books by *topic similarity* instead of alphabetically — ask for "space adventure" and it instantly hands you the closest matches, even without the exact title.

## 20. One-Page Cheat Sheet
- **What**: stores embeddings, finds nearest neighbors via ANN.
- **Indexes**: HNSW (default), IVF (memory), PQ (compress).
- **Always**: hybrid (vector+keyword) + metadata filters + rerank.
- **Metric**: match to embedding model (usually cosine).
- **Secure**: ACL filter at query time, CMK, tenant isolation.
- **Azure**: AI Search (managed), Cosmos vector, pgvector, Redis.
- **Cost**: quantization/PQ, smaller dims, cache hot queries.
