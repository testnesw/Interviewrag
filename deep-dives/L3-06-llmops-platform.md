# LEVEL 3 · System Design — LLMOps / Evaluation Platform

> Synthesis scenario. Combines: LLMOps · model evaluation · CI/CD · prompt
> management · monitoring · fine-tuning · MLflow.

---

## 0. The prompt
> *"Teams keep shipping prompt/model changes that silently degrade quality. Design an LLMOps platform: version prompts, evaluate changes before release, catch quality/cost/safety regressions in production, and enable safe rollout."*

---

## 1. Clarify — requirements
**Functional**: version prompts + models + configs; automated eval on changes; safe deployment; production monitoring + feedback loop.
**Non-functional**: reproducibility, fast iteration, catch regressions pre-prod, cost + safety tracking.
**Killer constraints**: **LLM output is non-deterministic + hard to test** → need eval-as-gate + continuous monitoring (no simple pass/fail).

## 2. Architecture — the LLMOps lifecycle
```
Prompt/model change (Git) → CI: automated EVAL suite →
  gate (quality ≥ baseline? cost ok? safe?) →
  deploy canary → monitor prod metrics → feedback → iterate

Registry: prompts (versioned) + models + eval datasets + results (MLflow)
```

## 3. Key design decisions (with "why")
- **Everything versioned in Git + registry**: prompts, model IDs, params, retrieval config, **eval datasets** → reproducibility + rollback (a prompt is code).
- **Evaluation as a CI gate** (the core): on every change, run an **eval suite** against a curated dataset → block merge if quality drops below baseline.
  - **Metrics**: task-specific (accuracy/F1), **LLM-as-judge** (groundedness, relevance, coherence), **safety** (toxicity/jailbreak), **cost** (tokens), **latency**.
  - **Golden dataset** of representative + edge + adversarial cases; grow it from production failures.
- **Offline + online eval**: offline (pre-deploy, dataset) + **online** (prod, sampled, real traffic) — offline can't catch everything.
- **Safe rollout**: **canary** new prompt/model to small % → compare live quality/cost vs baseline → promote or auto-rollback.
- **Prompt management**: decouple prompts from code (registry/config) → iterate without redeploy; A/B test versions.

## 4. Production monitoring (online)
- Track per request: tokens/cost, latency, safety verdicts, **groundedness** (sampled LLM-judge), user feedback (thumbs), refusal rate, cache-hit.
- **Drift detection**: input distribution shift (new question types), quality drop over time → alert.
- **Feedback loop**: bad responses + thumbs-down → triage → add to eval dataset → fine-tune or fix prompt.

## 5. Fine-tuning / model management (when needed)
- Decide **RAG vs fine-tune vs prompt** first (RAG for knowledge, fine-tune for style/format/narrow tasks).
- Fine-tuning pipeline: dataset curation → train → **eval vs base model** → register (MLflow/model registry) → gated deploy.
- **Model registry** = versioned models + lineage + stage (dev/staging/prod) + approval.

## 6. Tooling map
- **MLflow** (tracking runs, prompts, eval metrics, model registry), **Azure AI Foundry** (prompt flow + eval), CI/CD (GitHub Actions), App Insights (prod telemetry), AOAI (models + fine-tune).

## 7. The follow-ups
1. **"How test a non-deterministic LLM?"** → **eval suite** (golden dataset) with **LLM-as-judge** + task metrics as a **CI gate**, not exact-match. (§3)
2. **"Catch silent quality regressions?"** → eval gate pre-merge + **canary + online eval** + drift alerts. (§3/§4)
3. **"Where do eval cases come from?"** → curated golden set + **harvested production failures** (feedback loop). (§3/§4)
4. **"Roll out a new prompt safely?"** → canary %, compare live metrics, auto-rollback. (§3)
5. **"Prompt without redeploy?"** → **prompt registry/config** decoupled from code + A/B. (§3)
6. **"RAG vs fine-tune?"** → RAG for fresh/knowledge, fine-tune for style/format/narrow behavior; measure both. (§5)
7. **"Track what's in prod?"** → model+prompt **registry** with versions + lineage + stages. (§5)
8. **"Monitor cost/safety in prod?"** → per-request token/safety/groundedness telemetry + alerts. (§4)

## 8. One-screen recall
- **LLM = non-deterministic** → **evaluation-as-CI-gate** on a **golden dataset** (LLM-judge groundedness/relevance + safety + cost + task metrics).
- **Version everything** (prompts/models/params/datasets) in Git + **MLflow registry** → reproducible + rollback.
- **Offline eval (gate) + online eval (canary + sampled prod)**; auto-rollback on regression.
- **Prompt management** decoupled from code (config/registry, A/B).
- **Monitor prod**: tokens/cost, latency, safety, groundedness, feedback, **drift** → alerts.
- **Feedback loop**: prod failures → eval set → fix prompt / fine-tune; **RAG vs fine-tune vs prompt** decision.

> Next L3: Mock Interview — Rapid-Fire Drills.
