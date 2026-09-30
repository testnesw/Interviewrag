# DEEP MECHANICS · RAG (Retrieval-Augmented Generation)

> Level 2 — the "3rd/4th follow-up" depth interviewers actually probe.
> This goes past *what* RAG is into *exactly how* each piece works, the math,
> the failure modes, and the hard questions with real answers.

---

## 0. The one-paragraph mental model (precise version)
RAG converts a user query into a **dense vector**, finds the **nearest neighbor** chunks in an index using an **approximate nearest-neighbor (ANN)** graph, optionally fuses that with **lexical (BM25)** results, **reranks** the candidates with a cross-encoder, packs the top survivors into the prompt **under a token budget**, and has the LLM generate an answer **conditioned on** that context. Every one of those verbs has a failure mode and a tuning knob. Retrieval quality — not the LLM — is where 80% of RAG quality lives.

---

## 1. Embeddings — what the vector actually is

**What happens mechanically:**
- Text → tokenizer → token IDs → transformer encoder → a pooled **fixed-length float vector** (e.g., `text-embedding-3-large` = 3072 dims; `-small` = 1536).
- The vector is a point in high-dimensional space where **semantic similarity ≈ geometric proximity**.

**The math you must be able to say:**
- Similarity is **cosine similarity**:
  $$\text{cos}(\mathbf{a},\mathbf{b}) = \frac{\mathbf{a}\cdot\mathbf{b}}{\|\mathbf{a}\|\,\|\mathbf{b}\|}$$
- If vectors are **L2-normalized** (`‖v‖=1`), cosine similarity == dot product, and cosine distance relates to Euclidean by $\|\mathbf{a}-\mathbf{b}\|^2 = 2(1-\cos)$. **This is why normalized embeddings let you use dot-product indexes interchangeably** — a classic follow-up.

**Why cosine, not Euclidean?**
Direction encodes meaning; magnitude often encodes length/frequency artifacts. Cosine ignores magnitude, comparing *orientation*. For normalized vectors they're monotonically equivalent anyway.

**Deep follow-up: "Why do embeddings from two different models not work together?"**
Each model defines its own coordinate space during training — dimension *k* in model A has no relationship to dimension *k* in model B. You **must re-embed the whole corpus** when you change embedding models. There's no adapter.

**Interview trap:** *"Can you average word embeddings to get a sentence embedding?"* — You can (mean-pooling) but modern sentence/passage encoders are trained end-to-end with contrastive loss to produce far better pooled vectors; naive averaging loses word order and is weaker.

---

## 2. The vector index — how ANN actually finds neighbors (HNSW)

Exact nearest neighbor over millions of vectors = O(N) per query = too slow. So we use **ANN**, trading a little recall for huge speed. The dominant algorithm (Azure AI Search, most vector DBs) is **HNSW — Hierarchical Navigable Small World**.

**How HNSW is built (mechanically):**
- A **multi-layer graph**. Each node = one vector. Higher layers are sparse (long-range "highway" links); the bottom layer contains every node with short-range links.
- Each inserted node is assigned a max layer by an exponentially decaying random function → few nodes reach the top (like a skip list in graph form).
- When inserting, you greedily find the nearest nodes at each layer and connect to up to **M** neighbors (the graph degree).

**How a search runs (this is the answer they want):**
1. Enter at the **top layer** at a fixed entry point.
2. **Greedy descent**: move to the neighbor closest to the query; when no neighbor is closer, drop down a layer.
3. At the bottom layer, do a **best-first search** maintaining a dynamic candidate list of size **efSearch**, expanding neighbors until the list can't improve.
4. Return the top-k from that list.

**The three knobs and their tradeoffs:**
| Knob | Meaning | ↑ increases | ↓ decreases |
|---|---|---|---|
| **M** | neighbors per node (graph degree) | recall, memory, build time | speed, memory |
| **efConstruction** | candidate breadth at build | index quality/recall | build speed |
| **efSearch** | candidate breadth at query | recall/accuracy | query latency |

**Complexity:** search is ~**O(log N)** hops instead of O(N). That's the whole point — say this.

**Deep follow-up: "HNSW recall isn't 100% — when does it miss?"**
Greedy search can get stuck in a local region if the graph lacks a link bridging to the true nearest cluster (especially with low M / low efSearch, or highly clustered data). You raise efSearch to widen the beam, or M to add connectivity — at latency/memory cost. **There is a recall/latency Pareto curve; you pick a point.**

**Alternative index families (know them for comparison):**
- **IVF (inverted file / clustering)**: k-means partitions space into *nlist* cells; query probes *nprobe* nearest cells. Faster build, lower memory than HNSW, slightly worse recall at same latency.
- **PQ (Product Quantization)**: compresses vectors into codes (e.g., 8 bytes) so billions fit in RAM; approximate distances via lookup tables. Used with IVF (IVF-PQ) at massive scale. Trades precision for memory.
- **Flat**: brute-force exact; correct but O(N) — fine for <50k vectors.

---

## 3. Chunking — the highest-leverage, least-glamorous step

**Why it dominates quality:** the LLM can only cite what retrieval returns; retrieval can only return what chunking created. A bad chunk boundary = a fact split in half = permanent recall loss.

**Mechanics & tradeoffs:**
- **Fixed-size (token) chunking** (e.g., 300 tokens, 15% overlap): simple, predictable, but blindly cuts mid-sentence/mid-table.
- **Structure-aware / recursive** chunking: split on document structure (headings → paragraphs → sentences) so a chunk = a coherent semantic unit. Almost always better.
- **Overlap** exists so a fact near a boundary appears whole in at least one chunk. Cost: duplication → more vectors → more storage + potential duplicate retrievals.

**The size tension (be precise):**
- Too **large** → the embedding averages many topics → vector becomes "muddy," similarity to a specific query drops (dilution), and you burn prompt tokens.
- Too **small** → each vector is sharp but lacks surrounding context the LLM needs to answer → high recall of fragments, low answer quality.
- Sweet spot is empirical (often 256–512 tokens) — **tuned via retrieval eval, not guessed.**

**Advanced patterns interviewers love:**
- **Parent-document / small-to-big**: embed *small* chunks for precise matching, but return the *parent* (larger) chunk to the LLM for context. Best of both.
- **Contextual retrieval (prepend a summary)**: prefix each chunk with a short LLM-generated description of its place in the doc before embedding — measurably lifts recall on ambiguous chunks.
- **Metadata on chunks** (source, section, date, tenant) → enables **filtered** search and security trimming.

---

## 4. Retrieval fusion — vector + lexical + rerank (why one isn't enough)

**Failure of pure vector search:** it's semantic, so it can *miss exact tokens* — product codes, error IDs, rare proper nouns, acronyms. "Error `KB-4021`" may not be near anything semantically.

**Failure of pure keyword (BM25):** matches tokens, misses paraphrase ("car" vs "automobile").

**BM25 in one breath (they may ask):** a bag-of-words relevance score combining **term frequency** (saturating, so repeats matter less), **inverse document frequency** (rare terms weigh more), and **length normalization** (long docs don't win by size). It's the classic lexical baseline.

**Hybrid search + fusion:** run both, then combine ranks. The standard is **Reciprocal Rank Fusion (RRF)**:
$$\text{RRF}(d) = \sum_{r \in \text{rankers}} \frac{1}{k + \text{rank}_r(d)}$$
Rank-based (not score-based) so you don't have to normalize incompatible score scales — that's *why* RRF is used. Azure AI Search does this natively for hybrid.

**Reranking (the precision stage):**
- First-stage retrieval uses a **bi-encoder** (query and doc embedded *separately* → fast, but no cross-token interaction).
- A **cross-encoder reranker** feeds *query + candidate together* through a transformer and outputs a relevance score → far more accurate because it models term interactions, but O(candidates) expensive.
- Pattern: retrieve top **50** cheaply (bi-encoder/ANN) → rerank to top **5** (cross-encoder) → send 5 to the LLM. This two-stage funnel is the modern default (Azure's **semantic ranker** is exactly this).

**Deep follow-up: "Why not rerank everything?"**
Cross-encoders can't scale to millions (no precomputed vectors — every pair is a fresh forward pass). So ANN does cheap recall, reranker does expensive precision on a small candidate set. Retrieval architecture = **cheap-recall then expensive-precision**.

---

## 5. Context assembly — the token-budget packing problem

Retrieved chunks must fit: `prompt = system + instructions + history + retrieved_context + question`, all under the context window, leaving room for the completion.

**Mechanics & pitfalls:**
- **"Lost in the middle"**: LLMs attend most strongly to the **start and end** of the context; facts buried in the middle of a long context are more likely ignored. Mitigation: put the most relevant reranked chunk **first (or last)**, not buried; keep context tight.
- **More context ≠ better**: stuffing 20 chunks raises cost/latency and *dilutes* attention; a tight 3–5 reranked chunks usually beats 20 raw ones.
- **Deduplicate** near-identical chunks (overlap artifacts) before packing.
- **Always include chunk IDs/source metadata** so the model can cite and you can verify.

---

## 6. Generation & grounding — forcing the model to use the context

**The instruction contract:** system prompt must say, in effect, *"Answer only from the provided context. If the answer isn't there, say you don't know. Cite the source IDs."* Without this, the model blends parametric (trained) knowledge with retrieved knowledge and hallucinates confidently.

**Why RAG still hallucinates (rank these causes):**
1. **Retrieval miss** (right doc never retrieved) → the model has no choice but to guess. *Most common.* Fix retrieval, not the prompt.
2. **Distractor chunks** (retrieved but irrelevant) → model latches onto a plausible-but-wrong passage. Fix with reranking/filters.
3. **Context ignored** → weak grounding instruction or lost-in-the-middle. Fix prompt + ordering.
4. **Conflicting sources** → model picks arbitrarily. Fix with recency/authority metadata + instruction to prefer newest/authoritative.

**Temperature for RAG:** keep it **low (0–0.3)** — you want faithful extraction, not creativity.

---

## 7. Evaluation — how you actually prove it works (the RAG triad)

You cannot improve what you don't measure. The **RAG triad** (each scored, often via LLM-as-judge on a golden set):
1. **Context Relevance** — were the retrieved chunks relevant to the query? (measures *retrieval*)
2. **Groundedness / Faithfulness** — is every claim in the answer supported by the retrieved context? (measures *hallucination*)
3. **Answer Relevance** — does the answer actually address the question? (measures *usefulness*)

**Retrieval-only metrics (say these):**
- **Recall@k** — fraction of queries where a relevant chunk is in the top-k. (Recall is king for RAG; if it's not retrieved, nothing downstream can fix it.)
- **MRR / nDCG** — rank-sensitive quality (reward putting the right chunk higher).

**The debugging logic (very common question):**
> "Users get wrong answers — is it retrieval or generation?"
Check **groundedness** vs **context relevance**. If context relevance is *low* → retrieval problem (chunking/embedding/index). If context relevance is *high* but groundedness is *low* → generation problem (prompt/model ignoring context). **This decomposition is the senior answer.**

---

## 8. Production concerns the interviewer will drill

**Freshness / incremental indexing:** source doc changes → event → re-chunk + re-embed *only* changed docs → upsert into index (don't rebuild). Track a version/hash per chunk. Deletes must propagate (tombstones) or you serve stale/deleted content.

**Multi-tenant security (critical):** apply the tenant/user **filter at query time** (`WHERE tenant_id = X`) or use per-tenant indexes — enforced by the app, never by the prompt. A retrieval that ignores ACLs = data leak. Trim by document-level permissions *before* the LLM ever sees a chunk.

**Cost levers (with mechanism):**
- **Semantic cache**: key by query embedding similarity; a near-duplicate question returns the cached answer → saves the *entire* retrieval+generation token cost. Tune the similarity threshold (too loose = wrong cache hits).
- **Embedding cost** is one-time per chunk (+ updates); **generation cost** is per query and dominates → cache and route models.
- **Model routing**: cheap model for simple Q, premium for hard.

**Latency budget (be able to break it down):**
`embed query (~10-30ms) + ANN search (~5-50ms) + rerank (~50-200ms for 50 candidates) + LLM TTFT/generation (hundreds of ms–seconds)`. The **LLM dominates**; streaming hides it. Rerank is the second cost — cap candidate count.

---

## 9. The hard follow-up questions (with the answers)

1. **"Walk me through what happens to a query, function by function, from HTTP request to streamed answer."** → embed → ANN (HNSW greedy descent + efSearch beam) → hybrid fuse (RRF) → cross-encoder rerank 50→5 → dedupe + budget-pack (most-relevant first) → grounded prompt → LLM stream with citations → groundedness check.
2. **"Your recall@5 is 60%. Give me five things you'd try, ranked."** → (1) fix chunking (structure-aware + parent-doc), (2) add hybrid+RRF (lexical misses), (3) add reranker, (4) raise efSearch/M, (5) try a stronger/re-embedded model + query rewriting/HyDE.
3. **"HNSW vs IVF-PQ — when each?"** → HNSW for best recall/latency at moderate scale + enough RAM; IVF-PQ for billions of vectors where memory forces compression.
4. **"Why does cosine equal dot product sometimes?"** → when vectors are L2-normalized.
5. **"How do you stop cross-tenant leakage?"** → query-time metadata filter / per-tenant index + document-level ACL trimming *before* generation; never rely on the prompt.
6. **"The answer cites a source that doesn't support it — what's broken?"** → low groundedness with a distractor chunk; strengthen reranking, add a post-hoc citation-verification pass, tighten the grounding instruction.
7. **"Long context model just dropped — do you still need RAG?"** → yes: cost (you pay per token every call), latency, freshness/updates, security trimming, and citations. Long context complements, doesn't replace, retrieval.
8. **"What breaks when you change the embedding model?"** → the entire index is invalid; you must re-embed the whole corpus (new coordinate space).

---

## 10. One-screen deep-recall sheet
- **Embeddings**: encoder → pooled float vector; **cosine** = dot when normalized; change model ⇒ re-embed all.
- **Index**: HNSW = multi-layer graph, greedy descent + **efSearch** beam, ~O(log N); knobs **M / efConstruction / efSearch** = recall vs latency/memory. IVF-PQ for billions.
- **Chunking** dominates: structure-aware + overlap; small-to-big (parent-doc); size tuned by eval.
- **Retrieval**: hybrid (vector + BM25) fused by **RRF (rank-based)** → **cross-encoder rerank 50→5** (cheap-recall then expensive-precision).
- **Assembly**: token budget; **lost-in-the-middle** → best chunk first; fewer, better chunks; carry citations.
- **Generation**: low temp; "answer only from context, else say I don't know, cite IDs."
- **Hallucination causes ranked**: retrieval miss > distractors > ignored context > conflicts.
- **Eval triad**: context relevance (retrieval) · groundedness (hallucination) · answer relevance (usefulness); **Recall@k** is king. Decompose to locate the fault.
- **Prod**: incremental re-embed + tombstones; **query-time ACL filter** (no leaks); **semantic cache** saves full query cost; LLM dominates latency (stream).

---

> This is the depth standard. If it's what you want across the board, tell me the
> **next topic** (or say "continue in priority order") and I'll produce the same
> deep-mechanics treatment topic by topic.
