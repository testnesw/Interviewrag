# DEEP MECHANICS · LLM Observability (Tracing, LangSmith, Evals)

> Level 2 — tracing LLM apps, spans, cost/latency/quality telemetry, online
> evals, and debugging non-deterministic chains.

---

## 0. The precise mental model
LLM apps are **non-deterministic, multi-step, and opaque** — a bad answer could come from retrieval, the prompt, the model, or a tool. **LLM observability** captures a **trace** of every step (inputs, outputs, tokens, latency, tool calls) so you can **debug, evaluate, and monitor** quality/cost in dev and production. It's APM adapted to prompts + chains + agents.

---

## 1. Why standard logging isn't enough
- A single user request = **many LLM/tool calls** (retrieve → rerank → generate → tool → generate).
- Failures are **semantic** ("wrong answer"), not exceptions → you need to see **what went into and out of each step**.
- Non-determinism → need to **replay + compare** runs, not just read a stack trace.

## 2. Traces & spans (the data model)
- **Trace** = one end-to-end request; **spans** = nested steps (each LLM call, retrieval, tool).
- Each span records: **inputs, outputs, prompt, model, tokens, latency, cost, metadata** (user, version).
- Parent-child spans reconstruct the full chain/agent flow → pinpoint the failing hop.

## 3. What to capture
- **Prompts + responses** (the actual rendered prompt, not just the template).
- **Retrieved chunks** + scores (was the right context retrieved?).
- **Token usage + cost** per step; **latency** per step (find the slow hop).
- **Tool calls** + arguments + results; errors/retries.
- **Feedback**: user thumbs, and **eval scores**.

## 4. Evaluation (offline + online)
- **Offline**: run a **dataset** through the app → score with **LLM-as-judge** (groundedness, relevance, correctness) + heuristics → gate releases (see LLMOps).
- **Online**: sample **production** traces → run evals on real traffic → catch regressions/drift the dataset missed.
- Attach scores to traces → filter "low groundedness" runs to debug.

## 5. Tooling
- **LangSmith** (LangChain), **Langfuse**, **Phoenix/Arize**, **Azure AI Foundry** tracing + evaluation, **App Insights / OpenTelemetry** (GenAI semantic conventions now standardize LLM spans).
- OpenTelemetry GenAI conventions → vendor-neutral LLM tracing into any backend.

## 6. Production monitoring
- Dashboards: **cost/tokens per feature/user**, latency (first-token + total), **quality** (sampled groundedness), error/refusal rate, cache-hit, **drift** (input shift).
- **Alerts** on cost anomalies, latency, quality drop.
- **Feedback loop**: bad traces → add to eval dataset → fix prompt / fine-tune.

## 7. The hard follow-ups (with answers)
1. **"Why not just log?"** → requests are multi-step + failures are semantic → need **traces/spans** with inputs/outputs per step. (§1/§2)
2. **"Trace vs span?"** → trace = whole request; spans = nested steps (each LLM/tool call). (§2)
3. **"Debug a wrong RAG answer?"** → inspect the trace: were the right **chunks retrieved**? was the prompt right? → isolate the hop. (§3)
4. **"Evaluate quality continuously?"** → offline dataset evals (gate) + **online sampled** prod evals (LLM-as-judge). (§4)
5. **"Vendor-neutral tracing?"** → **OpenTelemetry GenAI** conventions → any backend. (§5)
6. **"Track cost/latency?"** → per-span tokens/cost/latency telemetry + dashboards/alerts. (§3/§6)
7. **"Close the loop?"** → harvest bad traces into the eval set → fix prompt/fine-tune. (§6)

## 8. One-screen recall
- LLM apps = **non-deterministic, multi-step, opaque** → need **tracing**, not just logs.
- **Trace** (request) → **spans** (each LLM/tool/retrieval step) with inputs/outputs/tokens/cost/latency.
- **Capture**: rendered prompts, **retrieved chunks+scores**, tool calls, feedback.
- **Eval**: offline dataset (gate) + **online sampled** prod (LLM-as-judge groundedness/relevance).
- **Tools**: LangSmith/Langfuse/Phoenix/Foundry; **OpenTelemetry GenAI** = vendor-neutral.
- **Monitor**: cost/latency/quality/drift dashboards + alerts; **feedback loop** → eval set.

> Next: back to the deep-dive index.
