# DEEP MECHANICS · Reranking

> 🧠 **Hook:** *Resume shortlist → real interview* — a cheap filter first, an expensive judge second.
>
> Level 2 — two-stage retrieval, cross-encoders vs bi-encoders, semantic
> reranking, and why it boosts RAG quality.

---

## 0. The precise mental model
Reranking is the **second stage** of retrieval: a fast, cheap retriever fetches a **broad candidate set** (recall), then a slower, smarter **reranker re-scores those candidates** for precise relevance to the query, keeping the **top-k**. It fixes the core weakness of vector search — embeddings capture *general* similarity, not precise *query-document relevance*.

---

## 1. Why rerank (the problem it solves)
- Vector search = **bi-encoder**: query and doc embedded **independently** → fast (precompute doc vectors) but **coarse** (no query-doc interaction).
- Result: top vector hits are "in the neighborhood" but the *best* answer may be ranked #7, not #1.
- Reranker re-orders so the truly relevant doc rises to the top → better context → better LLM answer.

## 2. Two-stage retrieval
```
Query → [Stage 1: retrieve top ~50-100]  (bi-encoder / BM25 / hybrid — fast, high recall)
      → [Stage 2: rerank to top ~3-5]     (cross-encoder — slow, high precision)
      → context for LLM
```
- Stage 1 optimizes **recall** (don't miss the answer); Stage 2 optimizes **precision** (pick the best few).

## 3. Cross-encoder vs bi-encoder (the key distinction)
| | Bi-encoder (retrieval) | Cross-encoder (rerank) |
|---|---|---|
| Input | query & doc **separately** | query + doc **together** |
| Interaction | none (just vector distance) | **full attention** over the pair |
| Speed | very fast (precomputed) | slow (per query-doc pass) |
| Accuracy | coarse | **precise relevance** |
| Scale | millions | tens–hundreds |
- Cross-encoder reads query and document **jointly** → models fine-grained relevance, but can't pre-index → only feasible on a small candidate set (hence two-stage).

## 4. Reranker options
- **Managed**: **Azure AI Search semantic ranker**, Cohere Rerank, Voyage.
- **Open**: `bge-reranker`, cross-encoder models (Sentence-Transformers).
- **LLM-as-reranker**: prompt an LLM to score/order candidates (flexible, pricier/slower).

## 5. Trade-offs & tuning
- **Latency/cost** added (extra model pass) → rerank only top-N candidates (e.g., 50), not the whole corpus.
- Pick **N** (candidates in) and **k** (kept out): bigger N = better recall but slower rerank.
- Biggest RAG quality lever after hybrid search; often **hybrid retrieve → rerank** together.

## 6. The hard follow-ups (with answers)
1. **"Why rerank if vector search already ranks?"** → bi-encoder similarity is coarse (no query-doc interaction); cross-encoder re-scores for **precise relevance**. (§1/§3)
2. **"Bi-encoder vs cross-encoder?"** → separate vs joint encoding → fast/coarse vs slow/precise. (§3)
3. **"Why two stages, not just cross-encoder?"** → cross-encoders can't pre-index → too slow for millions; retrieve broad then rerank few. (§2)
4. **"Where does it fit in RAG?"** → after hybrid retrieval, before assembling LLM context. (§2)
5. **"Downside?"** → extra latency/cost → limit to top-N candidates. (§5)
6. **"Azure option?"** → **AI Search semantic ranker**. (§4)

## 7. One-screen recall
- **Two-stage**: fast retrieve **top ~50 (recall)** → **rerank to top ~3-5 (precision)**.
- **Bi-encoder** (retrieval): query/doc encoded **separately** → fast, coarse.
- **Cross-encoder** (rerank): query+doc encoded **together** (full attention) → precise, slow → only on candidates.
- **Options**: AI Search semantic ranker, Cohere/Voyage, bge-reranker, LLM-as-judge.
- **Tune N (in) / k (out)**; adds latency/cost → limit candidates.
- **Biggest RAG quality lever** after hybrid search.

> Next: GraphRAG.
