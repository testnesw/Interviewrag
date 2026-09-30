# 08 · Azure AI Search

> Domain: Generative AI & Azure AI · Level: Principal GenAI Architect

## 1. Beginner Explanation
Azure AI Search (formerly Cognitive Search) is a **managed search engine**. You put content in, it builds an index, and you query it by keyword, meaning (vector), or both — the go-to retriever for RAG on Azure.

## 2. Architect-Level Explanation
A PaaS search service combining lexical + vector + semantic ranking:
- **Index**: schema of fields (searchable, filterable, facetable, vector).
- **Retrieval modes**: keyword (BM25), **vector** (HNSW), **hybrid**, plus **semantic ranker** (L2 reranking with a Microsoft model).
- **Skillsets + indexers**: pull from Blob/SQL/Cosmos, apply AI enrichment (OCR, chunking, embedding via **integrated vectorization**), and index automatically.
- **Scale**: replicas (QPS/HA) × partitions (storage/throughput) = search units.
- **Security**: RBAC/data-plane keys, Private Endpoint, CMK, document-level ACL via filters.

## 3. Real Enterprise Use Case
A manufacturer builds an engineering copilot over 5M PDFs. Indexer + skillset chunk and embed automatically (integrated vectorization); hybrid + semantic ranker returns top clauses; ACL filters restrict by project; GPT-4o generates cited answers.

## 4. Architecture Diagram (ASCII)
```
 Blob/SQL/Cosmos ─► Indexer ─► Skillset (chunk, OCR, embed)
                                      │
                               [Search Index]
                          (keyword + vector + semantic)
 Query ─► hybrid search ─► semantic rerank ─► ACL filter ─► top-k
                                      │
                                 RAG ─► GPT-4o (cited answer)
 Scale = replicas × partitions       Secure = PE + RBAC + CMK
```

## 5. Interview Questions
1. Keyword vs vector vs hybrid vs semantic ranker?
2. What is integrated vectorization?
3. Replicas vs partitions?
4. How do you enforce document-level security?
5. How do indexers/skillsets automate RAG ingestion?

## 6. Strong Interview Answers
- **Modes**: "Keyword (BM25) for exact terms, vector for semantic recall, hybrid fuses both (RRF), and the semantic ranker reranks the top results with an ML model for precision. For enterprise RAG I use hybrid + semantic ranker."
- **Integrated vectorization**: "The service chunks and calls an embedding model during indexing and at query time, so I don't build a separate embedding pipeline — huge operational simplification."
- **Replicas vs partitions**: "Replicas add QPS and HA (need ≥3 for the read SLA); partitions add storage and index throughput. Scale them independently to the workload."
- **Doc security**: "Store group/ACL fields and apply an OData filter (`search.in`) at query time bound to the user's identity — enforce access in the query, never in the LLM."

## 7. Common Mistakes
- Pure vector, skipping hybrid + semantic ranker.
- Manual embedding pipeline when integrated vectorization suffices.
- 1 replica in prod (no read SLA/HA).
- Forgetting ACL filters → data leakage.
- Over-large indexes with no partition planning.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Semantic ranker | precision↑ | extra cost/latency |
| Hybrid | best recall | slightly more compute |
| More replicas | QPS/HA | cost |
| More partitions | storage/throughput | cost, reindex effort |

## 9. Production Best Practices
- Hybrid + semantic ranker as default.
- Integrated vectorization for ingestion.
- ≥3 replicas for read SLA; plan partitions for growth.
- Incremental indexers with change detection.
- Alias indexes for zero-downtime reindex/schema changes.

## 10. Security Considerations
- Private Endpoint; disable public access.
- Managed Identity for indexers/connections; RBAC over keys.
- CMK encryption; document-level ACL filters.
- Trim results to user permissions before generation.

## 11. Cost Optimization
- Right-size tier/SKU; scale replicas to real QPS.
- Use semantic ranker selectively (top-k only).
- Smaller embedding dimensions; compress content fields.
- Delete stale docs; tier cold content.

## 12. Troubleshooting Scenarios
- **Poor relevance** → enable hybrid + semantic ranker, fix chunking.
- **Slow queries** → add replicas, reduce fields returned, tune vector params.
- **Indexer failures** → check skillset errors, source permissions, throttling.
- **Missing docs** → indexer schedule/change-tracking, field mapping.

## 13. Hands-on Example
```bash
az search service create -n rag-search -g rg-ai --sku standard \
  --replica-count 3 --partition-count 1 -l eastus
```

## 14. Terraform Example
```hcl
resource "azurerm_search_service" "s" {
  name                = "rag-search"
  resource_group_name = azurerm_resource_group.rg.name
  location            = "eastus"
  sku                 = "standard"
  replica_count       = 3
  partition_count     = 1
  semantic_search_sku = "standard"
  public_network_access_enabled = false
  identity { type = "SystemAssigned" }
}
```

## 15. Azure Example (index with vector field, REST)
```jsonc
// PUT /indexes/docs?api-version=2024-07-01
{ "name": "docs",
  "fields": [
    {"name":"id","type":"Edm.String","key":true},
    {"name":"content","type":"Edm.String","searchable":true},
    {"name":"acl","type":"Collection(Edm.String)","filterable":true},
    {"name":"contentVector","type":"Collection(Edm.Single)",
     "dimensions":1024,"vectorSearchProfile":"hnsw"}]
}
```

## 16. FastAPI / Python Example
```python
from azure.search.documents import SearchClient
from azure.search.documents.models import VectorizedQuery

@app.post("/retrieve")
def retrieve(q: str, groups: list[str]):
    res = sc.search(search_text=q,
        vector_queries=[VectorizedQuery(vector=embed(q),
            k_nearest_neighbors=5, fields="contentVector")],
        query_type="semantic", semantic_configuration_name="default",
        filter=f"acl/any(g: search.in(g, '{','.join(groups)}'))", top=5)
    return [r["content"] for r in res]
```

## 17. AKS Example
RAG API in AKS calls AI Search over a Private Endpoint using Workload Identity; scale the retrieval service with HPA on latency while Search scales via replicas.

## 18. How to Remember
**"Managed retriever for RAG."** It does keyword + vector + rerank + ingestion so you don't build a search stack.

## 19. Real-World Analogy
A world-class librarian who understands both the exact title you asked for and what you *meant*, then hands you the best few pages — and only the ones you're allowed to read.

## 20. One-Page Cheat Sheet
- **What**: managed keyword + vector + semantic search; primary Azure RAG retriever.
- **Default**: hybrid + semantic ranker.
- **Ingest**: indexers + skillsets + integrated vectorization.
- **Scale**: replicas (QPS/HA, ≥3) × partitions (storage).
- **Secure**: PE + Managed Identity + CMK + ACL filters.
- **Zero-downtime**: index aliases for reindex.
