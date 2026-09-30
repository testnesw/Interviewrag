# DEEP MECHANICS · LLMOps

> Level 2 — how operating LLM apps differs from classic MLOps: prompt/version
> management, eval-in-CI, RAG data pipelines, guardrails, observability of
> tokens/cost, and continuous improvement.

---

## 0. The precise mental model
LLMOps = **MLOps adapted to foundation-model apps**. You usually **don't train** the model — you operate around a hosted LLM: manage **prompts, RAG data, evaluations, guardrails, cost/latency, and feedback loops**. The unit of change shifts from "model weights" to "**prompts + retrieval + orchestration**," and the core discipline is **evaluation-driven deployment** (evals as tests) plus **production observability**.

---

## 1. What's different from classic MLOps
| | Classic MLOps | LLMOps |
|---|---|---|
| Core asset | trained model | **prompts + RAG + orchestration** (model often external) |
| Change unit | retrain on data | edit prompt / swap model / update index |
| Testing | accuracy metrics | **LLM evals** (open-ended, LLM-judge) |
| Key costs | training compute | **token/inference cost + latency** |
| New risks | drift | hallucination, injection, safety, cost blow-up |

## 2. Prompt & config management
- **Version prompts like code** (git), with metadata (model, temperature). Changing a prompt = a deployable change → run evals.
- **Prompt registry / templates** decoupled from code so you can iterate without redeploying.
- Track which prompt+model+index version served each response (for debugging/repro).

## 3. Evaluation-driven CI/CD
- **Evals as gates**: on every prompt/model/retriever change, run the offline eval harness (RAG triad, correctness, safety) → block regressions. "Evals are the new unit tests."
- **Staged rollout**: canary/A-B new prompt or model version, compare online metrics, roll back on regression.
- Model/version pinning so provider updates don't silently change behavior.

## 4. RAG data operations
- **Ingestion pipeline** — load → chunk → embed → index, run on a schedule/trigger as source data changes.
- **Freshness & reindexing** — keep the vector index current; handle deletes.
- **Retrieval quality monitoring** — track context relevance over time.
(RAG data is now part of the "MLOps" surface.)

## 5. Guardrails & safety in the loop
Content filters, Prompt Shields, groundedness checks, PII redaction wired into the request path (see Guardrails). Treated as operational components with their own monitoring (block rates, false positives).

## 6. Observability — the LLM-specific signals
Beyond latency/errors, track:
- **Token usage** (prompt/completion) and **$ cost per request/user** — primary cost driver.
- **Quality signals** — thumbs up/down, groundedness scores, eval scores in prod.
- **Traces** of the full chain (retrieval → prompt → model → tools) with correlation IDs.
- **Drift/abuse** — input distribution shifts, jailbreak attempts.
Azure: Azure AI Foundry tracing + Application Insights / OpenTelemetry.

## 7. Continuous improvement loop
```
Serve → collect feedback + traces + failures
     → mine failures into new eval cases + prompt fixes / RAG tuning / fine-tune
     → eval → canary → promote
```
Production failures become test cases → the system improves over time.

## 8. The hard follow-ups (with answers)
1. **"LLMOps vs MLOps?"** → operate around a hosted model; change unit = prompts/RAG/orchestration; evals not accuracy; token cost + new risks. (§1)
2. **"How do you deploy a prompt change safely?"** → version it, run eval harness in CI, canary/A-B, roll back on regression. (§2,3)
3. **"Keep RAG answers fresh?"** → scheduled ingestion/reindex pipeline + retrieval-quality monitoring. (§4)
4. **"What do you monitor that MLOps doesn't?"** → token usage + $/request, groundedness/quality scores, chain traces, jailbreak attempts. (§6)
5. **"How does the system improve over time?"** → mine prod failures/feedback into new eval cases + prompt/RAG fixes → eval → canary. (§7)
6. **"Provider updates the model — risk?"** → silent behavior change → pin versions + eval before adopting. (§3)

## 9. One-screen recall
- LLMOps = MLOps for hosted-model apps; **change unit = prompts + RAG + orchestration**, **evals not accuracy**, **token cost + new risks** (hallucination/injection/safety).
- **Prompt management**: version like code (+model/temp), prompt registry, track prompt+model+index per response.
- **Eval-driven CI/CD**: evals as gates on every change ("evals = new unit tests"), canary/A-B, version pinning, rollback.
- **RAG ops**: scheduled ingest→chunk→embed→index, reindex/freshness, retrieval-quality monitoring.
- **Guardrails** in the request path, monitored (block rate/false positives).
- **Observability**: **token usage + $/request**, quality/groundedness scores, full-chain traces (correlation IDs), drift/abuse. Azure AI Foundry tracing + App Insights.
- **Improvement loop**: prod failures/feedback → new eval cases + fixes → eval → canary → promote.

> Next: Azure AI Foundry.
