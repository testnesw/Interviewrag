# DEEP MECHANICS · GraphRAG

> 🧠 **Hook:** *A detective's corkboard* — entities connected by strings to answer "how are these related?"
>
> Level 2 — knowledge-graph RAG, entity/relationship extraction, community
> summaries, and global vs local queries.

---

## 0. The precise mental model
GraphRAG augments retrieval with a **knowledge graph**: instead of only chunking + embedding text, an LLM **extracts entities and relationships** into a graph, clusters them into **communities**, and **pre-summarizes** each community. This lets you answer **"global" questions** ("what are the main themes across all documents?") that vanilla vector RAG fails — because no single chunk contains the holistic answer.

---

## 1. The problem with vanilla RAG
- Vector RAG retrieves **local** chunks → great for "what does the contract say about X?"
- It **fails at global/aggregative** questions ("summarize the key risks across 1000 reports") — the answer isn't in any k chunks; it's spread across the whole corpus.
- It also misses **multi-hop** reasoning connecting entities across documents.

## 2. The GraphRAG build pipeline (indexing)
```
Docs → chunk → LLM extracts (entities, relationships, claims)
     → build knowledge graph (nodes = entities, edges = relations)
     → community detection (e.g., Leiden) clusters related entities
     → LLM writes a SUMMARY per community (hierarchical)
```
- Entities + relationships become a queryable graph; **community summaries** pre-digest themes at multiple levels.

## 3. Query modes
- **Global search**: answer whole-corpus questions by **map-reduce over community summaries** (each community → partial answer → combined) → holistic themes.
- **Local search**: start from specific entities → traverse their neighborhood (related entities/relationships/text) → precise, multi-hop grounded answer.
- Choose mode by question type (aggregative vs specific).

## 4. Why it works
- The graph captures **structure/relationships** text chunks lose.
- **Community summaries** make global synthesis tractable (don't stuff the whole corpus into context).
- **Multi-hop**: traverse edges to connect facts across documents.

## 5. Trade-offs (be honest in interviews)
- **Expensive indexing**: many LLM calls to extract entities + summarize communities → high upfront cost + time.
- More complex pipeline than vanilla RAG; graph must be rebuilt/updated as data changes.
- **Use when**: large corpus + need global/thematic/multi-hop answers + justified by value. **Don't** for simple lookup Q&A (vanilla/hybrid RAG is cheaper).

## 6. Variants & tooling
- **Microsoft GraphRAG** (open-source) is the reference implementation.
- **LazyGraphRAG** reduces indexing cost; hybrids combine graph + vector retrieval.
- Can back the graph with a graph DB (e.g., Cosmos DB Gremlin) or store derived structures.

## 7. The hard follow-ups (with answers)
1. **"When does vanilla RAG fail?"** → **global/aggregative** + multi-hop questions where the answer isn't in any k chunks. (§1)
2. **"How does GraphRAG fix it?"** → extract entities/relations → graph → **community summaries** → map-reduce for global answers. (§2/§3)
3. **"Global vs local search?"** → global = map-reduce over community summaries (themes); local = entity-neighborhood traversal (specific/multi-hop). (§3)
4. **"Main downside?"** → **expensive indexing** (lots of LLM extraction/summarization) + complexity. (§5)
5. **"When NOT to use it?"** → simple fact lookup — hybrid RAG is cheaper/sufficient. (§5)
6. **"Handle updates?"** → re-extract/re-summarize affected parts (graph maintenance cost). (§5)

## 8. One-screen recall
- **Graph-augmented RAG**: LLM extracts **entities + relationships** → knowledge graph → **community clusters + summaries**.
- Solves vanilla RAG's failure on **global/aggregative + multi-hop** questions.
- **Query**: **global** (map-reduce over community summaries = themes) vs **local** (entity neighborhood traversal = specific/multi-hop).
- **Cost**: expensive **indexing** (many LLM calls); complex; rebuild on change.
- **Use for** large corpora needing holistic/relationship answers; **not** for simple lookup.
- **MS GraphRAG** = reference impl; LazyGraphRAG + graph+vector hybrids reduce cost.

> Next: Structured Outputs & JSON Mode.
