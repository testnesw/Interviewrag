# 06 · RAG Architecture (Retrieval-Augmented Generation)

> Domain: Generative AI & Azure AI · Level: Principal GenAI Architect

## 1. Beginner Explanation
RAG makes an LLM answer using **your** data. Instead of relying only on what the model memorized, you fetch relevant chunks from your documents and paste them into the prompt so the model answers grounded in facts.

## 2. Architect-Level Explanation
RAG = **Retriever + Generator**. Pipeline:
1. **Ingestion**: load → chunk → embed → store vectors + metadata.
2. **Retrieval**: embed query → vector/hybrid search → top-k chunks → optional **rerank**.
3. **Augmentation**: build a grounded prompt (context + citations + guardrails).
4. **Generation**: LLM answers only from context; return citations.
Key architectural levers: chunking strategy, hybrid (keyword+vector) search, reranking, freshness/indexing pipeline, and **grounding/citation enforcement** to reduce hallucination.

## 3. Real Enterprise Use Case
Insurance company builds a claims-assistant over 2M policy/claims documents. Nightly ingestion to Azure AI Search (vector + semantic ranker), GPT-4o generation with mandatory citations, PII redaction, and answer-evaluation scoring before rollout.

## 4. Architecture Diagram (ASCII)
```
 Docs ─► Chunk ─► Embed(ada/te-3) ─► [Azure AI Search: vector+keyword]
                                              ▲
 User Q ─► Embed ─► Retrieve top-k ───────────┘
             │
             ▼  (rerank / filter by ACL)
        Grounded Prompt ─► GPT-4o ─► Answer + Citations
             │
        Guardrails (Content Safety, grounding check)
```

## 5. Interview Questions
1. How do you reduce hallucination in RAG?
2. Fixed vs semantic chunking — trade-offs?
3. Why hybrid search over pure vector?
4. How do you handle document-level security/ACLs in RAG?
5. How do you evaluate RAG quality?
6. RAG vs fine-tuning — when each?

## 6. Strong Interview Answers
- **Hallucination**: "Ground strictly — instruct the model to answer only from context, require citations, add a 'grounding/faithfulness' check, and return 'I don't know' when retrieval is weak. Improve retrieval quality (hybrid + rerank) since most hallucination is a retrieval failure."
- **Chunking**: "Fixed-size is simple but splits meaning; semantic/recursive chunking respects structure and improves recall. I chunk ~300–800 tokens with overlap, tuned per corpus."
- **Hybrid**: "Vector captures semantics, keyword captures exact terms (IDs, codes, names). Hybrid + semantic reranker gives best recall/precision, especially for enterprise jargon."
- **Security**: "Store ACLs in metadata and filter at query time (trim to the user's permissions) — never rely on the LLM to enforce access."
- **RAG vs fine-tune**: "RAG for fresh/changing knowledge and citations; fine-tune for style/format/behavior, not for injecting facts. Often combine both."

## 7. Common Mistakes
- Pure vector search (misses exact keywords/IDs).
- No reranking → noisy context.
- Too-large top-k → cost + distraction.
- Ignoring document ACLs (data leakage).
- No evaluation harness → silent quality regressions.

## 8. Trade-offs
| Lever | More | Less |
|-------|------|------|
| top-k | recall↑, cost/noise↑ | cheaper, may miss facts |
| chunk size | context↑ | precision↓ |
| rerank | quality↑ | latency/cost↑ |

## 9. Production Best Practices
- Hybrid search + semantic reranker.
- Incremental/scheduled indexing with change tracking.
- Enforce citations + grounding checks.
- Query rewriting / HyDE for weak queries.
- Golden-set evaluation in CI (faithfulness, relevance).

## 10. Security Considerations
- Query-time ACL filtering per user identity.
- PII redaction on ingest and on logs.
- Private networking to AOAI + Search.
- Prompt-injection defenses (treat retrieved text as untrusted).

## 11. Cost Optimization
- Cache embeddings and frequent answers.
- Tune top-k (often 3–5).
- Use gpt-4o-mini for retrieval-heavy, cheap paths.
- Compress/summarize context before generation.

## 12. Troubleshooting Scenarios
- **Wrong/empty answers** → inspect retrieved chunks first (retrieval bug, not model).
- **Slow** → reduce top-k, async retrieval, smaller model, PTU.
- **Stale answers** → check indexing pipeline/freshness.
- **Leakage** → verify ACL filter is applied to the query.

## 13. Hands-on Example (flow)
```
1) az search + create vector index
2) embed docs with text-embedding-3-large
3) push docs + vectors + acl metadata
4) query: hybrid search -> top5 -> prompt -> gpt-4o
```

## 14. Terraform Example
```hcl
resource "azurerm_search_service" "search" {
  name                = "rag-search"
  resource_group_name = azurerm_resource_group.rg.name
  location            = "eastus"
  sku                 = "standard"
  semantic_search_sku = "standard"   # enables semantic reranker
  identity { type = "SystemAssigned" }
}
```

## 15. Azure Example
```bash
az search service create -n rag-search -g rg-ai --sku standard -l eastus
# create index + vector field via REST (2024-07-01) with "vectorSearch" profile
```

## 16. FastAPI / Python Example
```python
from openai import AzureOpenAI
from azure.search.documents import SearchClient
from azure.search.documents.models import VectorizedQuery

def answer(q: str, user_groups: list[str]):
    qvec = embed(q)                      # text-embedding-3-large
    results = search_client.search(
        search_text=q,                   # hybrid: keyword + vector
        vector_queries=[VectorizedQuery(vector=qvec, k_nearest_neighbors=5,
                        fields="contentVector")],
        filter=f"acl/any(g: search.in(g, '{','.join(user_groups)}'))",
        query_type="semantic", semantic_configuration_name="default")
    context = "\n".join(r["content"] for r in results)
    prompt = f"Answer ONLY from context. Cite sources.\nContext:\n{context}\nQ:{q}"
    return client.chat.completions.create(model="gpt-4o",
        messages=[{"role":"user","content":prompt}]).choices[0].message.content
```

## 17. AKS Example
Deploy retriever + generator as separate services; scale the embedding/retrieval service with **HPA** on CPU/latency, keep generation calls to AOAI via Workload Identity.

## 18. How to Remember
**"Open-book exam for the LLM."** Retrieve the right pages, then let it write the answer.

## 19. Real-World Analogy
A lawyer who doesn't memorize every law — they pull the exact statute from the library (retrieval) and then argue the case (generation), always citing the source.

## 20. One-Page Cheat Sheet
- **Pipeline**: chunk → embed → store → retrieve(hybrid) → rerank → ground → generate → cite.
- **Anti-hallucination**: strict grounding + citations + "I don't know" + better retrieval.
- **Search**: hybrid + semantic reranker beats pure vector.
- **Security**: ACL filter at query time; retrieved text is untrusted.
- **Cost**: tune top-k, cache, mini models, compress context.
- **RAG vs fine-tune**: RAG = facts/freshness; fine-tune = behavior/style.
