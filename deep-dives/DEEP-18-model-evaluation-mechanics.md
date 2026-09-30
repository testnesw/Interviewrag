# DEEP MECHANICS · Model Evaluation (LLM)

> Level 2 — how you actually measure an LLM/RAG system: offline vs online,
> LLM-as-judge, the RAG triad, classic NLP metrics, and guarding against
> regression.

---

## 0. The precise mental model
LLM evaluation is hard because outputs are **open-ended** (no single correct string). So you evaluate along **dimensions** (correctness, relevance, groundedness, safety) using a mix of **reference-based metrics**, **LLM-as-judge**, and **human review**, plus **online** signals from production. The goal: a **repeatable eval harness** that catches regressions when you change prompts/models/retrievers.

---

## 1. Offline vs online evaluation
- **Offline** — a curated **test set** run before deploy: golden Q&A pairs, scored automatically + spot human review. Gates releases.
- **Online** — production signals: user feedback (👍/👎), task success, escalation rate, A/B tests, latency/cost. Reality check.
Use both — offline prevents regressions, online measures real value.

## 2. The RAG evaluation triad (know this cold)
For RAG systems, score three relationships:
- **Context Relevance** — did retrieval fetch relevant chunks? (retriever quality)
- **Groundedness / Faithfulness** — is the answer supported by the retrieved context (not hallucinated)?
- **Answer Relevance** — does the answer address the question?
Diagnosing which one fails tells you whether to fix **retrieval** vs **generation**. (Frameworks: RAGAS, Azure AI Foundry evaluators.)

## 3. LLM-as-judge
Use a strong LLM to **score** outputs against criteria (correctness, coherence, safety) or **compare** two responses (pairwise). Scalable and correlates reasonably with humans.
- **Risks:** position bias, verbosity bias, self-preference → mitigate with rubrics, randomized order, reference answers, and calibration against human labels.

## 4. Classic / reference-based metrics
- **BLEU / ROUGE** — n-gram overlap (translation/summarization) — crude for open-ended text.
- **BERTScore / semantic similarity** — embedding-based, better than n-gram.
- **Exact match / F1** — for extractive QA.
- **Task metrics** — accuracy/precision/recall for classification-style tasks.
These need reference answers and miss semantic nuance → complement with LLM-judge/human.

## 5. Dimensions to evaluate
Correctness/accuracy · relevance · groundedness · coherence/fluency · **safety/toxicity** · bias/fairness · format compliance · latency · cost. Weight by use case (a medical bot weights safety/groundedness heavily).

## 6. Building the harness (the practical answer)
```
1. Curate a representative test set (+ edge cases, adversarial)
2. Define metrics per dimension (auto + LLM-judge + human sample)
3. Run on every prompt/model/retriever change (CI for prompts)
4. Track scores over versions → catch regressions
5. Close the loop with online feedback → grow the test set
```
This is the "**evals are the new unit tests**" mindset. Azure AI Foundry provides built-in evaluators + eval runs.

## 7. The hard follow-ups (with answers)
1. **"How do you evaluate an open-ended LLM output?"** → dimensions (correctness/relevance/groundedness/safety) via reference metrics + LLM-judge + human, offline & online. (§0,1)
2. **"Evaluate a RAG system?"** → the triad: context relevance, groundedness, answer relevance → isolates retrieval vs generation faults. (§2)
3. **"LLM-as-judge risks?"** → position/verbosity/self bias → rubrics, randomized order, references, human calibration. (§3)
4. **"Why not just BLEU/ROUGE?"** → n-gram overlap misses semantics; use embedding-based + judge + human. (§4)
5. **"Prevent regressions when changing a prompt?"** → offline eval harness run in CI on every change, track over versions. (§6)
6. **"Detect hallucination?"** → groundedness/faithfulness metric vs retrieved context. (§2)

## 8. One-screen recall
- LLM eval = score **dimensions** (correctness, relevance, groundedness, safety) — no single correct string.
- **Offline** (golden test set, gates release) + **online** (feedback, task success, A/B).
- **RAG triad**: **context relevance** (retrieval) · **groundedness/faithfulness** (no hallucination) · **answer relevance** (addresses Q). Isolates retrieval vs generation.
- **LLM-as-judge**: scalable scoring/pairwise; beware position/verbosity/self bias → rubrics + references + human calibration.
- **Reference metrics**: BLEU/ROUGE (n-gram, crude), **BERTScore/semantic**, EM/F1 — complement, don't rely alone.
- **Harness = "evals are the new unit tests"**: test set → metrics → run in CI on every change → track versions → close loop. Azure AI Foundry evaluators.

> Next: LLMOps.
