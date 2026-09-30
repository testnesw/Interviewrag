# DEEP MECHANICS · Evaluation Benchmarks

> Level 2 — how LLMs are measured: capability benchmarks, arenas, contamination,
> and why your own eval set beats leaderboards.

---

## 0. The precise mental model
A **benchmark** is a fixed dataset + scoring rule used to compare models on a capability (knowledge, reasoning, code, safety). They give **comparable numbers**, but they're **proxies** — a model can top a leaderboard and still fail *your* task. The pro move: know the major benchmarks, know their **failure modes (contamination, gaming)**, and always build a **task-specific eval set**.

---

## 1. Major capability benchmarks (name-drop + what they test)
- **MMLU / MMLU-Pro** — broad multitask knowledge (57 subjects, multiple-choice). The classic "how smart" number; MMLU-Pro is harder/cleaner.
- **GPQA** — graduate-level "Google-proof" science questions (hard reasoning).
- **GSM8K** — grade-school **math word problems**; **MATH** — competition math.
- **HumanEval / MBPP** — **code generation** (pass@k: does generated code pass unit tests?).
- **SWE-bench** — real GitHub issues → can the model produce a working patch? (agentic coding).
- **BIG-Bench / BBH** — diverse hard reasoning tasks.
- **HellaSwag, ARC, WinoGrande, TruthfulQA** — commonsense / truthfulness.
- **MMMU** — multimodal (image+text) reasoning.

## 2. Human-preference & holistic
- **LMSYS Chatbot Arena** — humans blind-vote head-to-head → **Elo** ranking. Captures real-world preference better than static MCQ, but subjective/style-biased.
- **HELM** (Stanford) — **holistic**: measures many scenarios × metrics (accuracy, calibration, robustness, bias, toxicity, efficiency) → multi-dimensional, not one score.
- **MT-Bench** — multi-turn quality via LLM-as-judge.

## 3. Scoring methods
- **Exact match / multiple-choice accuracy** (MMLU).
- **pass@k** — for code: fraction where ≥1 of k samples passes tests.
- **LLM-as-judge** — a strong model scores open-ended answers against a rubric (scalable, but bias: position/verbosity/self-preference → mitigate with pairwise + randomized order).
- **Elo / win-rate** — head-to-head preference.

## 4. The big caveat: contamination & gaming
- **Data contamination** — benchmark questions leak into training data → inflated scores. Mitigate: **held-out/private** sets, fresh benchmarks (e.g., LiveBench, LiveCodeBench refresh over time), canary strings.
- **Overfitting to leaderboards** — tuning for the benchmark, not the capability ("Goodhart's law": when a measure becomes a target it stops being a good measure).
- **Style bias** in arenas/LLM-judges (longer/formatted answers win regardless of correctness).

## 5. Building YOUR eval (what interviewers want to hear)
- Leaderboards pick a **shortlist**; your **domain eval set** picks the winner.
- Build: representative prompts + **golden answers / rubrics** + edge/adversarial cases, drawn from **real usage/failures**.
- Metrics that match the job: RAG → faithfulness/context-recall (RAGAS); agents → success rate/trajectory; classification → F1.
- **Regression-test** every model/prompt change against it; track over time.

## 6. The hard follow-ups (with answers)
1. **"Benchmark for broad knowledge? Code? Math?"** → **MMLU**; **HumanEval/SWE-bench**; **GSM8K/MATH**. (§1)
2. **"What's pass@k?"** → code eval: fraction where ≥1 of k samples passes unit tests. (§3)
3. **"How does Chatbot Arena rank models?"** → blind human head-to-head votes → **Elo**. (§2)
4. **"What does HELM add?"** → **holistic** multi-metric (accuracy, robustness, bias, toxicity, efficiency), not one number. (§2)
5. **"Why distrust a high MMLU score?"** → **contamination** (leak into training) + **leaderboard overfitting** (Goodhart). (§4)
6. **"Fix contamination?"** → private/held-out + **continuously-refreshed** benchmarks (LiveBench), canaries. (§4)
7. **"LLM-as-judge biases?"** → position/verbosity/self-preference → pairwise + randomized order. (§3)
8. **"Best way to pick a model for prod?"** → shortlist via leaderboards, **decide on your own domain eval set**. (§5)

## 7. One-screen recall
- **Knowledge**: MMLU/MMLU-Pro, GPQA. **Math**: GSM8K, MATH. **Code**: HumanEval/MBPP (**pass@k**), SWE-bench. **Reasoning**: BBH. **Truthfulness**: TruthfulQA. **Multimodal**: MMMU.
- **Preference/holistic**: **Chatbot Arena (Elo)**, **HELM** (multi-metric), MT-Bench.
- **Scoring**: accuracy / pass@k / **LLM-as-judge** (mind bias) / Elo.
- **Caveats**: **contamination**, **leaderboard overfitting (Goodhart)**, style bias → use **fresh/private** sets.
- **Always** build a **domain eval set** from real usage; regression-test every change.

> Next: Decoding & Sampling.
