# DEEP MECHANICS · RAG Evaluation (RAGAS & Metrics)

> Level 2 — how to measure RAG quality, retrieval vs generation metrics, RAGAS,
> LLM-as-judge, and building an eval set.

---

## 0. The precise mental model
You can't improve RAG you can't measure. RAG has **two stages to evaluate separately**: **retrieval** (did we fetch the right context?) and **generation** (did the answer use it faithfully and answer the question?). The modern approach scores both with a mix of **reference-free LLM-as-judge** metrics (e.g., **RAGAS**) and, where you have ground truth, **reference-based** metrics.

---

## 1. Split the problem: retrieval vs generation
- A bad answer has two possible root causes → measure each:
  - **Retrieval failure** → right chunks never fetched (fix: chunking, embeddings, hybrid, rerank).
  - **Generation failure** → good context, but model ignored it / hallucinated (fix: prompt, grounding, model).
- Always diagnose **which stage** is failing before tuning.

## 2. The core RAGAS metrics (know these by name)
| Metric | Stage | Question it answers |
|---|---|---|
| **Context Precision** | retrieval | are the retrieved chunks relevant / ranked well? (signal vs noise) |
| **Context Recall** | retrieval | did we retrieve *all* needed info? (needs ground truth) |
| **Faithfulness** | generation | is the answer grounded in the context (no hallucination)? |
| **Answer Relevancy** | generation | does the answer actually address the question? |
- **Faithfulness** = fraction of answer claims supported by retrieved context → the anti-hallucination metric.
- **Context Precision/Recall** are the retrieval quality signals.

## 3. Reference-free vs reference-based
- **Reference-free** (LLM-as-judge): no gold answer needed → faithfulness, answer relevancy, context relevance → cheap to scale on production traffic.
- **Reference-based**: compare to a **ground-truth answer** → context recall, answer correctness; needs a labeled dataset.
- Classic text metrics (BLEU/ROUGE/exact-match) are **weak for RAG** (surface overlap ≠ correctness) → prefer semantic/LLM-judge.

## 4. LLM-as-judge (the workhorse)
- An LLM scores outputs against a rubric (grounded? relevant? complete?) → scalable, correlates with humans when prompted well.
- **Cautions**: judge bias (position/verbosity/self-preference), needs calibration against human labels, use a strong judge model + structured output scores.

## 5. Building an eval set
- Curate a **golden dataset**: representative + edge + adversarial questions, with (where possible) ground-truth answers + expected source chunks.
- **Grow it from production failures** (thumbs-down traces → new eval cases).
- Run it in **CI as a release gate** (quality must not regress) + **online sampled** in prod (see LLMOps/observability).

## 6. End-to-end + operational metrics
- Beyond quality: **latency** (retrieval + generation), **cost** (tokens), **citation accuracy**, **refusal rate**, user **feedback**.
- Track trends over time; alert on regressions/drift.

## 7. The hard follow-ups (with answers)
1. **"How do you evaluate a RAG system?"** → separately measure **retrieval** (context precision/recall) and **generation** (faithfulness, answer relevancy). (§1/§2)
2. **"Which metric catches hallucination?"** → **Faithfulness** (claims supported by context). (§2)
3. **"No ground-truth answers — can you still eval?"** → yes, **reference-free LLM-as-judge** (faithfulness, answer relevancy). (§3)
4. **"Why not BLEU/ROUGE?"** → surface overlap ≠ semantic correctness → weak for RAG. (§3)
5. **"Answer is wrong — retrieval or generation?"** → low context recall/precision = retrieval; good context but unfaithful = generation. (§1)
6. **"Where do eval cases come from?"** → curated golden set + **harvested prod failures**; run as CI gate. (§5)
7. **"Risks of LLM-as-judge?"** → bias/calibration → validate against human labels, strong judge, structured scores. (§4)

## 8. One-screen recall
- **Evaluate retrieval AND generation separately** (diagnose the failing stage).
- **RAGAS**: **Context Precision/Recall** (retrieval) + **Faithfulness** (anti-hallucination) + **Answer Relevancy** (generation).
- **Reference-free (LLM-judge)** scales on prod; **reference-based** needs ground truth; avoid BLEU/ROUGE.
- **LLM-as-judge** = workhorse; watch bias → calibrate vs humans.
- **Golden dataset** (edge/adversarial) + **grow from prod failures**; run as **CI gate + online sampled**.
- Also track latency/cost/citations/refusals.

> Next: Prompt Injection Defense.
